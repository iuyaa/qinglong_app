import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qinglong_app/base/http/api.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/module/login/login_bean.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../main.dart';

class LoginHelper {
  static const success = 0, failed = 1, twiceLogin = 2, cancelled = 3;

  final String host, userName, password;
  final String? alias;
  final bool rememberPassword, useSecretLogin;
  Http? _http;
  Api? _api;
  UserInfoViewModel? _user;
  SingleAccountPageState? _owner;
  int _index = 0, _revision = 0, _attempt = 0;
  bool _cancelled = false;

  LoginHelper(String host, this.userName, this.password, this.rememberPassword,
      this.alias, {this.useSecretLogin = false}) : host = host.trim();

  bool loginByUserName() => !useSecretLogin;

  bool get _current => !_cancelled && (_owner?.mounted ?? true) &&
      getIt.isRegistered<UserInfoViewModel>(instanceName: _index.toString()) &&
      identical(_user, getIt<UserInfoViewModel>(instanceName: _index.toString())) &&
      _user?.revision == _revision && _user?.loginAttempt == _attempt;

  void cancel() {
    _cancelled = true;
    _http?.close();
  }

  Future<int> login(BuildContext context) async {
    final uri = Uri.tryParse(host);
    if (uri == null || !['http', 'https'].contains(uri.scheme) || uri.host.isEmpty ||
        uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment ||
        userName.isEmpty || password.isEmpty) {
      '请填写有效的面板地址和登录凭据'.toast();
      return failed;
    }
    _owner = SingleAccountPageState.of(context);
    _index = _owner?.index ?? 0;
    _user = getIt<UserInfoViewModel>(instanceName: _index.toString());
    _revision = _user!.revision;
    _attempt = ++_user!.loginAttempt;
    // Authenticate against the target without changing the active panel.
    _http = Http(host, _index, authenticated: false);
    _api = Api(_index, http: _http);
    var response = useSecretLogin
        ? await _api!.loginByClientId(userName, password)
        : await _api!.login(userName, password);
    if (!_current) return cancelled;
    if (!useSecretLogin && response.code == 404) {
      response = await _api!.loginOld(userName, password);
    }
    return _finish(response);
  }

  Future<int> loginTwice(BuildContext context, String code) async {
    if (!_current || _api == null || useSecretLogin) return cancelled;
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      '请输入六位验证码'.toast();
      return twiceLogin;
    }
    final response = await _api!.loginTwo(userName, password, code.trim());
    final result = _finish(response);
    return result == failed && response.code != 450 && response.code != 410
        ? twiceLogin : result;
  }

  int _finish(HttpResponse<LoginBean> response) {
    if (!_current) return cancelled;
    if (response.success && (response.bean?.token?.isNotEmpty ?? false)) {
      _user!.updateToken(_index, host, response.bean!.token, useSecretLogin, alias);
      _user!.updateUserName(host, rememberPassword ? userName : '',
          rememberPassword ? password : '', useSecretLogin, alias);
      _owner?.resetProviders();
      if (_owner != null) {
        _owner!.registerHttp(host);
      } else {
        if (getIt.isRegistered<Http>(instanceName: _index.toString())) {
          getIt.unregister<Http>(instanceName: _index.toString());
        }
        getIt.registerSingleton<Http>(Http(host, _index), instanceName: _index.toString());
      }
      _http?.close();
      return success;
    }
    if (!useSecretLogin && response.code == 420) return twiceLogin;
    (response.success ? '登录响应缺少有效 Token' : response.message ?? '登录失败，请稍后重试').toast();
    return failed;
  }

  Future<int> completeTwoFactor(BuildContext context) async {
    while (_current) {
      String code = '';
      final value = await showCupertinoDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('两步验证'),
          content: Material(
            color: Colors.transparent,
            child: TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              onChanged: (value) => code = value,
              decoration: const InputDecoration(hintText: '请输入六位验证码'),
            ),
          ),
          actions: [
            CupertinoDialogAction(child: const Text('取消'),
              onPressed: () => Navigator.of(dialogContext).pop()),
            CupertinoDialogAction(child: const Text('确定'), onPressed: () {
              if (RegExp(r'^\d{6}$').hasMatch(code)) {
                Navigator.of(dialogContext).pop(code);
              } else {
                '请输入六位验证码'.toast();
              }
            }),
          ],
        ),
      );
      if (value == null || !_current) {
        cancel();
        return cancelled;
      }
      final result = await loginTwice(context, value);
      if (result != twiceLogin) return result;
    }
    return cancelled;
  }
}
