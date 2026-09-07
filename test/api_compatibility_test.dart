import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/base/http/api.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/http/url.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/home/system_bean.dart';
import 'package:qinglong_app/utils/login_helper.dart';

void main() {
  test('Version boundaries select the supported API family', () {
    for (final version in ['2.21.0', 'v2.21.0', '2.21.0-beta.1', '2.100.0', '3.0.0']) {
      expect(SystemBean(version: version).isUpperVersion2_13_9(), isTrue);
    }
    for (final version in [null, '', '2.13.8', '2.21.invalid']) {
      expect(SystemBean(version: version).isUpperVersion2_13_9(), isFalse);
    }
    expect(SystemBean(version: '2.13.9').isUpperVersion2_13_9(), isTrue);
    expect(SystemBean(version: '2.10.13').isUpperVersion(), isFalse);
    expect(SystemBean(version: '2.10.14').isUpperVersion(), isTrue);
    expect(LoginHelper('', '', '', false, null).loginByUserName(), isTrue);
    expect(LoginHelper('', '', '', false, null, useSecretLogin: true).loginByUserName(), isFalse);
  });

  test('Real HTTP transport preserves auth, task envelopes and versioned settings', () async {
    // Synthetic loopback server only; CI never connects to a user's panel.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <Map<String, dynamic>>[];
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add({
        'path': request.uri.path,
        'query': request.uri.queryParameters,
        'method': request.method,
        'auth': request.headers.value(HttpHeaders.authorizationHeader),
        'body': body.isEmpty ? null : jsonDecode(body),
      });
      dynamic data;
      var code = 200;
      final path = request.uri.path;
      if (path.endsWith('/crons')) {
        data = {'data': [{'id': 102, 'name': 'synthetic', 'status': 1, 'pid': 123}], 'total': 1};
      } else if (path.endsWith('/config')) {
        data = {'info': {'logRemoveFrequency': 7}};
      } else if (path.endsWith('/log/remove')) {
        data = {'info': {'frequency': 7}};
      } else if (path.contains('/logs/')) {
        data = 'first line\n第二行';
      } else if (path.endsWith('/token') || path.endsWith('/login')) {
        data = {'token': 'synthetic-token', 'token_type': 'Bearer', 'expiration': 123456};
      } else if (path.endsWith('/envs') && request.method == 'GET') {
        data = [{'id': 301, 'name': 'SYNTHETIC', 'value': 'not-a-secret', 'status': 0}];
      } else if (path.endsWith('/configs/files')) {
        data = [{'title': 'test #中.sh', 'value': 'test #中.sh'}];
      } else if (path.contains('/configs/') && request.method == 'GET') {
        data = 'export SYNTHETIC="中文 # &"\n';
      } else if (path.endsWith('/subscriptions')) {
        data = [{'id': 302, 'name': 'synthetic', 'type': 'public-repo', 'is_disabled': 0}];
      } else if (path.endsWith('/dependencies') && request.method == 'GET') {
        data = [{'id': 303, 'name': 'synthetic', 'type': 0, 'status': 0, 'log': []}];
      } else if (path.endsWith('/dependencies/force')) {
        code = 500;
      } else if (path.endsWith('/apps') && request.method == 'GET') {
        data = [{'id': 304, 'name': 'synthetic', 'scopes': ['crons']}];
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'code': code, 'data': data}));
      await request.response.close();
    });
    addTearDown(() async {
      await server.close(force: true);
      await getIt.reset();
    });
    final host = 'http://127.0.0.1:${server.port}';
    final version = SystemBean(version: 'v2.21.0');
    getIt.registerSingleton<SystemBean>(version, instanceName: '0');
    getIt.registerSingleton<UserInfoViewModel>(UserInfoViewModel(token: 'synthetic-token'), instanceName: '0');
    getIt.registerSingleton<Url>(Url(0), instanceName: '0');
    getIt.registerSingleton<Http>(Http(host, 0), instanceName: '0');
    final api = Api(0);

    final tasks = await api.crons2_13_09();
    expect(tasks.success, isTrue);
    expect(tasks.bean!.data!.single.sId, '102');
    expect(requests.last['query'], containsPair('searchValue', ''));
    expect(requests.last['query'], isNot(contains('size')));
    expect(requests.last['auth'], 'Bearer synthetic-token');
    final log = await api.taskLogDetail('a #&中.log', 'folder #&中/sub');
    expect(log.bean, 'first line\n第二行');
    expect(requests.last['path'], '/api/logs/a%20%23%26%E4%B8%AD.log');
    expect(requests.last['query']['path'], 'folder #&中/sub');

    for (final row in [
      ['2.15.0', '/api/system/log/remove', 'frequency'],
      ['2.15.16', '/api/system/log/remove', 'frequency'],
      ['2.15.17', '/api/system/config', 'logRemoveFrequency'],
      ['2.16.0', '/api/system/config', 'logRemoveFrequency'],
      ['2.16.2', '/api/system/config', 'logRemoveFrequency'],
      ['2.17.0', '/api/system/config/log-remove-frequency', 'logRemoveFrequency'],
      ['2.21.0', '/api/system/config/log-remove-frequency', 'logRemoveFrequency'],
    ]) {
      version.version = row[0];
      expect((await api.logDel()).bean!.info!.frequency, 7);
      expect((await api.logDelTime(7)).success, isTrue);
      expect(requests.last['path'], row[1]);
      expect(requests.last['body'], {row[2]: 7});
    }

    expect((await api.loginTwo('synthetic', 'synthetic', '123456')).success, isTrue);
    expect(requests.last['auth'], isNull);
    expect(requests.last['method'], 'PUT');
    expect((await api.loginByClientId('synthetic', 'synthetic')).bean!.token, 'synthetic-token');
    expect(requests.last['auth'], isNull);
    expect(requests.last['path'], '/open/auth/token');

    await getIt.unregister<UserInfoViewModel>(instanceName: '0');
    getIt.registerSingleton<UserInfoViewModel>(UserInfoViewModel(token: 'synthetic-token', useSecret: true), instanceName: '0');
    expect((await api.crons2_13_09()).success, isTrue);
    expect(requests.last['path'], '/open/crons');
    expect((await api.logDelTime(7)).success, isTrue);
    expect(requests.last['path'], '/open/system/config/log-remove-frequency');
    // Same resource contracts under account and OpenAPI prefixes, using synthetic data only.
    for (final secret in [false, true]) {
      await getIt.unregister<UserInfoViewModel>(instanceName: '0');
      getIt.registerSingleton<UserInfoViewModel>(UserInfoViewModel(token: 'synthetic-token', useSecret: secret), instanceName: '0');
      final prefix = secret ? '/open' : '/api';
      expect((await api.envs('SYNTHETIC')).bean!.single.sId, '301');
      expect(requests.last['path'], '$prefix/envs');
      expect(requests.last['query']['searchValue'], 'SYNTHETIC');
      expect((await api.addEnv('SYNTHETIC', '中文 # &', 'test')).success, isTrue);
      expect(requests.last['body'], [{'name': 'SYNTHETIC', 'value': '中文 # &', 'remarks': 'test'}]);
      expect((await api.files()).bean!.single.value, 'test #中.sh');
      expect((await api.content('test #中.sh')).bean, 'export SYNTHETIC="中文 # &"\n');
      expect(requests.last['path'], '$prefix/configs/test%20%23%E4%B8%AD.sh');
      expect((await api.saveFile('test #中.sh', '中文\n')).success, isTrue);
      expect(requests.last['body'], {'name': 'test #中.sh', 'content': '中文\n'});
      expect(jsonDecode((await api.subscribes()).bean!)[0]['id'], 302);
      expect(requests.last['path'], '$prefix/subscriptions');
      expect((await api.startSubscribes([302])).success, isTrue);
      expect(requests.last['body'], [302]);
      expect((await api.dependencies('nodejs')).bean!.single.id, 303);
      expect(requests.last['query']['type'], 'nodejs');
      expect((await api.dependencyReinstall(null, [303])).success, isTrue);
      expect(requests.last['body'], [303]);
      final before = requests.length;
      expect((await api.delDependency(null, [303])).code, 500);
      expect(requests.length, before + 1); // A failure must not trigger another deletion.
      expect(jsonDecode((await api.appKeys()).bean!)[0]['id'], 304);
      expect(requests.last['path'], '$prefix/apps');
      expect((await api.deleteAppKey([304])).success, isTrue);
      expect(requests.last['body'], [304]);
    }
    final count = requests.length;
    expect((await api.user()).code, 403);
    expect(requests.length, count);
  });
}
