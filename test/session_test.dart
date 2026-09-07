import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/base/http/api.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/task/task_bean.dart';
import 'package:qinglong_app/utils/login_helper.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

late BuildContext panelContext;

// Use production session/provider state, with a small page instead of unrelated home widgets.
class SessionHarness extends SingleAccountPage {
  const SessionHarness({Key? key}) : super(key: key, index: 0);
  @override
  SingleAccountPageState createState() => HarnessState();
}

class HarnessState extends SingleAccountPageState {
  @override
  Widget build(BuildContext context) => Navigator(
    key: navigator,
    observers: [sessionObserver],
    onGenerateRoute: (settings) => MaterialPageRoute(
      settings: settings,
      builder: (context) {
        if (settings.name == '/login') return const Text('relogin');
        panelContext = context;
        return Consumer(builder: (context, ref, _) {
          final host = SingleAccountPageState.ofUserInfo(context).host ?? '';
          final tasks = ref.watch(taskProvider(host));
          return Text('$host:${tasks.list.map((task) => task.name).join(",")}');
        });
      },
    ),
  );
}

class LoopbackHttp extends HttpOverrides {}

void main() {
  testWidgets('Sessions isolate failed login, 2FA, late replies, caches and expiry', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SpUtil.getInstance();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'), (_) async => true);
    final servers = <HttpServer>[];
    final requests = <Map<String, dynamic>>[];
    final logStarted = Completer<void>(), releaseLog = Completer<void>();
    addTearDown(() async {
      if (!releaseLog.isCompleted) releaseLog.complete();
      for (final server in servers) { await server.close(force: true); }
      await getIt.reset();
    });
    Future<T> real<T>(Future<T> Function() work) => HttpOverrides.runWithHttpOverrides(work, LoopbackHttp());
    Future<T?> io<T>(Future<T> Function() work) => tester.runAsync(() => real(work));
    Future<String> server(String panel) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      servers.add(server);
      server.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        final params = body.isEmpty ? <String, dynamic>{} : jsonDecode(body) as Map<String, dynamic>;
        requests.add({'panel': panel, 'path': request.uri.path, 'method': request.method,
          'auth': request.headers.value(HttpHeaders.authorizationHeader)});
        int code = 200;
        String message = '';
        dynamic data = {'token': 'synthetic-$panel'};
        if (request.uri.path.endsWith('/crons/102/log')) {
          logStarted.complete();
          await releaseLog.future;
          data = 'old panel log';
        } else if (request.uri.path.endsWith('/two-factor/login')) {
          code = params['code'] == '123456' ? 200 : 400;
          message = '验证码错误';
        } else if (request.uri.path.endsWith('/user/login')) {
          code = params['username'] == 'empty' ? 200 : (params['password'] == 'wrong' ? 401 : 420);
          if (params['username'] == 'empty') data = {};
        } else if (request.uri.path.endsWith('/scope')) {
          request.response.statusCode = 401;
          code = 401;
          message = 'Access denied';
        } else if (request.uri.path.endsWith('/expired')) {
          request.response.statusCode = 401;
          code = 401;
          message = 'Token expired';
        } else if (request.uri.path.endsWith('/json-expired')) {
          code = 401;
          message = 'Token 已失效';
        }
        try {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'code': code, 'message': message, 'data': data}));
          await request.response.close();
        } on SocketException { /* Expected when an old session closes its connection. */ }
      });
      return 'http://127.0.0.1:${server.port}';
    }
    final a = (await io(() => server('a')))!;
    final b = (await io(() => server('b')))!;
    final accounts = MultiAccountUserInfoViewModel();
    accounts.updateToken(0, a, 'synthetic-a', false, 'A');
    accounts.updateToken(3, 'https://synthetic.invalid', 'synthetic-other', true, 'Other');
    expect(accounts.tokenBeans.length, 4);
    expect(MultiAccountUserInfoViewModel().tokenBeans[3].host, 'https://synthetic.invalid');
    accounts.removeTokenBean(2);
    expect(MultiAccountUserInfoViewModel().tokenBeans.length, 4);
    getIt.registerSingleton<MultiAccountUserInfoViewModel>(accounts);
    final key = GlobalKey<SingleAccountPageState>();
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: SessionHarness(key: key))));
    final owner = key.currentState!;
    owner.registerSystemBean('2.21.0', true);
    final user = getIt<UserInfoViewModel>(instanceName: '0');
    final oldHttp = getIt<Http>(instanceName: '0');
    final oldApi = Api(0);
    final container = ProviderScope.containerOf(panelContext, listen: false);
    final oldTasks = container.read(owner.taskProvider(a));
    oldTasks.list.add(TaskBean(name: 'cached-A'));
    oldTasks.success();
    await tester.pump();
    expect(find.text('$a:cached-A'), findsOneWidget);
    final wrong = LoginHelper(b, 'synthetic', 'wrong', true, 'B');
    expect(await io(() => wrong.login(panelContext)), LoginHelper.failed);
    expect(user.host, a);
    expect(oldHttp.isClosed, isFalse);
    expect(requests.where((r) => r['path'] == '/api/login'), isEmpty);
    wrong.cancel();
    final empty = LoginHelper(b, 'empty', 'ok', true, 'B');
    expect(await io(() => empty.login(panelContext)), LoginHelper.failed);
    expect(user.host, a);
    empty.cancel();

    final cancelled = LoginHelper(b, 'synthetic', 'ok', true, 'B');
    expect(await io(() => cancelled.login(panelContext)), LoginHelper.twiceLogin);
    final prompt = cancelled.completeTwoFactor(panelContext);
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await prompt, LoginHelper.cancelled);
    expect(user.host, a);
    expect(oldHttp.isClosed, isFalse);

    final superseded = LoginHelper(b, 'synthetic', 'ok', true, 'B');
    expect(await io(() => superseded.login(panelContext)), LoginHelper.twiceLogin);
    final login = LoginHelper(b, 'synthetic', 'ok', true, 'B');
    expect(await io(() => login.login(panelContext)), LoginHelper.twiceLogin);
    final count = requests.length;
    expect(await io(() => superseded.loginTwice(panelContext, '123456')), LoginHelper.cancelled);
    expect(requests.length, count);
    superseded.cancel();
    expect(await io(() => login.loginTwice(panelContext, '12')), LoginHelper.twiceLogin);
    expect(requests.length, count);
    expect(await io(() => login.loginTwice(panelContext, '000000')), LoginHelper.twiceLogin);
    Future<HttpResponse<String>>? lateLog;
    await io(() async {
      lateLog = oldApi.inTimeLog('102');
      await logStarted.future;
    });
    expect(await io(() => login.loginTwice(panelContext, '123456')), LoginHelper.success);
    releaseLog.complete();
    expect((await io(() => lateLog!))!.success, isFalse);
    expect(oldHttp.isClosed, isTrue);
    expect(user.host, b);
    expect(user.token, 'synthetic-b');
    expect((await io(() => oldApi.startTasks(['102'])))!.code, -1001);
    expect((await io(() => SingleAccountPageState.ofApi(panelContext).startTasks(['102'])))!.code, -1001);
    expect(requests.where((r) => r['path'] == '/api/crons/run'), isEmpty);
    await tester.pumpAndSettle();
    expect(find.text('$a:cached-A'), findsNothing);
    expect(find.text('$b:'), findsOneWidget);
    expect(container.read(owner.taskProvider(a)).list, isEmpty);

    final app = LoginHelper(b, 'synthetic-id', 'synthetic-secret', true, 'B', useSecretLogin: true);
    expect(await io(() => app.login(panelContext)), LoginHelper.success);
    expect(user.useSecretLogined, isTrue);
    expect(accounts.tokenBeans[0].useSecretLogined, isTrue);
    final http = getIt<Http>(instanceName: '0');
    expect((await io(() => http.get<String>('/open/scope', null)))!.code, 403);
    expect(user.isLogined(), isTrue);
    expect((await io(() => http.post<String>('/open/expired', {})))!.code, 401);
    await tester.pumpAndSettle();
    expect(find.text('relogin'), findsOneWidget);
    expect(user.isLogined(), isFalse);
    expect(user.useSecretLogined, isTrue);
    expect(accounts.tokenBeans[3].token, 'synthetic-other');
    expect(requests.where((r) => r['path'] == '/open/expired').length, 1);
    expect((await io(() => http.get<String>('/open/expired', null)))!.code, -1001);

    user.updateToken(0, b, 'synthetic-new', true, 'B');
    owner.registerHttp(b);
    final renewed = getIt<Http>(instanceName: '0');
    expect((await io(() => renewed.get<String>('/open/json-expired', null)))!.code, 401);
    expect(user.isLogined(), isFalse);
    for (final request in requests.where((r) => r['path'].toString().contains('login') || r['path'] == '/open/auth/token')) {
      expect(request['auth'], isNull);
    }
    expect(requests.where((r) => r['panel'] == 'b' && r['auth'] == 'Bearer synthetic-a'), isEmpty);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await io(() async { for (final server in servers) { await server.close(force: true); } });
    await getIt.reset();
  });
}
