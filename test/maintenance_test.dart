import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/module/code_editor/codemirror/io.dart';
import 'package:qinglong_app/module/code_editor/codemirror/impl.dart';
import 'package:qinglong_app/module/code_editor/edit_guard.dart';
import 'package:qinglong_app/module/others/update/app_update_page.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Update manifest falls back to official asset API without trusting a supplied API URL', () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      requests.add(request);
      if (request.uri.host == 'github.com') {
        handler.reject(DioError(requestOptions: request, type: DioErrorType.connectTimeout));
      } else {
        handler.resolve(Response<String>(requestOptions: request, data: '{"versionCode":10}', statusCode: 200));
      }
    }));
    final asset = {'id': 123, 'url': 'https://evil.invalid/manifest',
      'browser_download_url': 'https://github.com/iuyaa/qinglong_app/releases/download/v3.0.4%2B10/update.json'};
    try {
      expect((await readUpdateManifest(dio, asset))['versionCode'], 10);
      expect(requests.length, 2);
      expect(requests.last.uri.toString(), 'https://api.github.com/repos/iuyaa/qinglong_app/releases/assets/123');
      expect(requests.last.headers['Accept'], 'application/octet-stream');
      expect(requests.last.headers.containsKey('Authorization'), isFalse);
      requests.clear();
      await expectLater(readUpdateManifest(dio, {...asset, 'browser_download_url': 'https://evil.invalid/update.json'}), throwsFormatException);
      expect(requests, isEmpty);
      await expectLater(readUpdateManifest(dio, {...asset, 'id': '../elsewhere'}), throwsA(isA<DioError>()));
      expect(requests.length, 1);
    } finally { dio.close(); }
  });

  test('Update failures distinguish timeout, HTTP errors and malformed metadata', () {
    DioError error(int status) => DioError(requestOptions: RequestOptions(path: releaseApi),
      response: Response(requestOptions: RequestOptions(path: releaseApi), statusCode: status), type: DioErrorType.response);
    expect(updateFailure(error(404)), contains('HTTP 404'));
    expect(updateFailure(error(403)), contains('限流或拒绝访问'));
    expect(updateFailure(DioError(requestOptions: RequestOptions(path: releaseApi), type: DioErrorType.connectTimeout)), contains('超时'));
    expect(updateFailure(const FormatException('private detail')), isNot(contains('private detail')));
  });

  test('Update metadata requires our stable release, matching APK and hash', () {
    const url = 'https://github.com/iuyaa/qinglong_app/releases/download/v3.0.4%2B8/qinglong-android.apk';
    final manifest = <String, dynamic>{'versionCode': 8, 'versionName': '3.0.4', 'size': 123,
      'sha256': List.filled(64, 'a').join(), 'packageName': 'io.github.iuyaa.qinglong', 'url': url};
    final release = <String, dynamic>{'draft': false, 'prerelease': false, 'tag_name': 'v3.0.4+8',
      'body': '更新说明', 'assets': [{'name': 'qinglong-android.apk', 'size': 123, 'browser_download_url': url}]};
    expect(AppRelease.parse(manifest, release).code, 8);
    for (final change in [
      {'sha256': 'broken'}, {'packageName': 'another.app'}, {'versionCode': 0}, {'size': 0},
      {'size': 999}, {'url': 'https://evil.invalid/app.apk'}, {'versionName': '3.0.5'},
      {'url': 'http://github.com/iuyaa/qinglong_app/releases/download/v3/a.apk'},
    ]) {
      expect(() => AppRelease.parse({...manifest, ...change}, release), throwsFormatException);
    }
    expect(() => AppRelease.parse(manifest, {...release, 'prerelease': true}), throwsFormatException);
    expect(() => AppRelease.parse(manifest, {...release, 'draft': true}), throwsFormatException);
    expect(() => AppRelease.parse(manifest, {...release, 'assets': []}), throwsFormatException);
  });

  test('Sorting preserves active slots and latest tokens; same-host histories stay separate', () async {
    SharedPreferences.setMockInitialValues({});
    await SpUtil.getInstance();
    await SpUtil.clear();
    final accounts = MultiAccountUserInfoViewModel();
    accounts.updateToken(0, 'https://synthetic.invalid', 'first', false, 'A');
    accounts.updateToken(3, 'https://synthetic.invalid', 'second', true, 'B');
    accounts.saveAccountOrder([3, 1, 2, 0]);
    expect(accounts.tokenBeans[0].token, 'first');
    accounts.updateToken(0, 'https://synthetic.invalid', 'renewed', false, 'A');
    final restarted = MultiAccountUserInfoViewModel();
    expect(restarted.tokenBeans[0].token, 'second');
    expect(restarted.tokenBeans[3].token, 'renewed');
    expect(restarted.tokenBeans[1].host, isNull);
    expect(MultiAccountUserInfoViewModel().tokenBeans[3].token, 'renewed');
    expect(() => restarted.saveAccountOrder([0, 0, 2, 3]), throwsArgumentError);
    final a = UserInfoBean(host: 'https://synthetic.invalid', userName: 'A');
    final b = UserInfoBean(host: a.host, userName: 'B');
    final key = UserInfoBean(host: a.host, userName: 'A', useSecretLogined: true);
    for (final item in [a, b, key, a]) { restarted.save2HistoryAccount(item); }
    expect(restarted.historyAccounts.length, 3);
    restarted.removeHistoryAccount(b);
    expect(restarted.historyAccounts.length, 2);
    expect(TokenBean.fromJson(TokenBean(userName: 'A').toJson()).userName, 'A');
  });

  test('Identical concurrent writes send once; a completed failure remains retryable', () async {
    // Ordinary test uses real I/O, no Widget fake clock or user panel.
    await HttpOverrides.runWithHttpOverrides(() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final started = Completer<void>(), release = Completer<void>();
      var count = 0;
      server.listen((request) async {
        await request.drain<void>();
        count++;
        if (count == 1) { started.complete(); await release.future; }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'code': count == 1 ? 400 : 200, 'message': 'synthetic'}));
        await request.response.close();
      });
      final http = Http('http://127.0.0.1:${server.port}', 0, authenticated: false);
      try {
        final first = http.put<NullResponse>('/api/crons/run', [123]);
        await started.future.timeout(const Duration(seconds: 5));
        expect((await http.put<NullResponse>('/api/crons/run', [123])).code, -1002);
        expect(count, 1);
        release.complete();
        expect((await first).success, isFalse);
        expect((await http.put<NullResponse>('/api/crons/run', [123])).success, isTrue);
        expect(count, 2);
      } finally {
        if (!release.isCompleted) release.complete();
        http.close(); await server.close(force: true);
      }
    }, _RealHttp());
  });

  test('Editor HTML includes every runtime resource without CDN fetches', () async {
    expect(await rootBundle.loadString('assets/codemirror/LICENSE'), contains('Permission is hereby granted'));
    for (final mode in ['shell', 'javascript', 'python', 'yaml']) {
      final html = await editorHtml(CodeMirrorOptions(mode: mode));
      expect(RegExp(r'<script\s+src=|<link\s+rel=').hasMatch(html), isFalse);
      expect(html, contains('CodeMirror.defineMode'));
      expect(html, contains('MessageInvoker.postMessage'));
      expect(html, isNot(contains('EDITOR_MODE')));
    }
  });

  testWidgets('Unsaved editor exit supports cancel, discard and save-in-progress', (tester) async {
    late BuildContext page;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      page = context; return const Scaffold();
    })));
    expect(await confirmLeaveEditor(page, false, false), isTrue);
    expect(await confirmLeaveEditor(page, true, true), isFalse);
    var result = confirmLeaveEditor(page, true, false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续编辑')); await tester.pumpAndSettle();
    expect(await result, isFalse);
    result = confirmLeaveEditor(page, true, false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃修改')); await tester.pumpAndSettle();
    expect(await result, isTrue);
  });
}

class _RealHttp extends HttpOverrides {}
