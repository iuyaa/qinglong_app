import 'dart:convert';
import 'dart:io';

import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

import 'sp_const.dart';
import 'userinfo_viewmodel.dart';

class MultiAccountUserInfoViewModel {
  static int maxAccount = 1; //1代表普通用户, 5代表付费用户

  List<TokenBean> tokenBeans = [];
  List<UserInfoBean> historyAccounts = [];

  static void payedVIP(int type) {
    if (SpUtil.getInt(spVIP, defValue: typeNormal) == typeSVIP) return;

    SpUtil.putInt(spVIP, type);

    int count = 1;
    if (type == typeNormal) {
      count = 1;
    } else if (type == typeVIP) {
      count = 3;
    } else if (type == typeSVIP) {
      count = 5;
    }
    SpUtil.putInt(spAccountCount, count);
  }

  static void updateMaxAccount(int count) {

    SpUtil.putInt(spAccountCount, count);
  }

  MultiAccountUserInfoViewModel() {
    try {
      List<dynamic>? tempTokenList = jsonDecode(SpUtil.getString(spTokenBeanList, defValue: '[]'));

      if (tempTokenList != null && tempTokenList.isNotEmpty) {
        for (Map<String, dynamic> value in tempTokenList) {
          tokenBeans.add(TokenBean.fromJson(value));
        }
      }

      final order = SpUtil.getObject('pendingAccountOrder')?['indices'];
      if (order is List && order.every((i) => i is int && i >= 0 && i < tokenBeans.length) &&
          order.toSet().length == order.length && order.toSet().containsAll(List.generate(order.length, (i) => i))) {
        tokenBeans = <TokenBean>[...order.map((i) => tokenBeans[i]), ...tokenBeans.skip(order.length)];
        persistTokens();
      }
      SpUtil.remove('pendingAccountOrder');
      List<dynamic>? tempList = jsonDecode(SpUtil.getString(spLoginHistory, defValue: '[]'));

      if (tempList != null && tempList.isNotEmpty) {
        for (Map<String, dynamic> value in tempList) {
          historyAccounts.add(UserInfoBean.fromJson(value));
        }
      }
    } catch (e) {
      e.toString().toast2();
    }
  }

  void initVipState() {
    int vipType = SpUtil.getInt(spVIP, defValue: typeNormal);

    if (vipType == typeNormal) {
      maxAccount = 1;
    } else if (vipType == typeVIP) {
      maxAccount = 3;
    } else {
      maxAccount = SpUtil.getInt(spAccountCount, defValue: 5);
    }
  }

  void save2HistoryAccount(UserInfoBean userInfoBean) {
    historyAccounts.removeWhere((element) => sameHistoryAccount(element, userInfoBean));

    historyAccounts.insert(
      0,
      userInfoBean,
    );

    SpUtil.putString(spLoginHistory, jsonEncode(historyAccounts));
  }

  static bool sameHistoryAccount(UserInfoBean a, UserInfoBean b) =>
      a.host == b.host && a.userName == b.userName && a.useSecretLogined == b.useSecretLogined;

  void removeHistoryAccount(UserInfoBean account) {
    historyAccounts.removeWhere((element) => sameHistoryAccount(element, account));

    SpUtil.putString(spLoginHistory, jsonEncode(historyAccounts));
  }

  void updateToken(int index, String? host, String? token, bool useSecretLogined, String? alias) {
    if (host == null) return;

    if (index < 0) return;
    while (tokenBeans.length <= index) {
      tokenBeans.add(TokenBean());
    }
    final previous = tokenBeans[index];
    tokenBeans[index] = TokenBean(
      userName: previous.host == host && previous.useSecretLogined == useSecretLogined ? previous.userName : null,
      token: token, host: host, useSecretLogined: useSecretLogined, alias: alias,
    );
    SpUtil.putString(spTokenBeanList, jsonEncode(tokenBeans));
  }

  void removeTokenBean(int index) {
    if (index < 0 || index >= tokenBeans.length) return;
    tokenBeans[index].token = null;
    tokenBeans[index].host = null;
    tokenBeans[index].alias = null;
    tokenBeans[index].useSecretLogined = false;
    tokenBeans[index].userName = null;
    SpUtil.putString(spTokenBeanList, jsonEncode(tokenBeans));
  }

  void persistTokens() => SpUtil.putString(spTokenBeanList, jsonEncode(tokenBeans));

  void saveAccountOrder(List<int> order) {
    if (order.length != tokenBeans.length || order.toSet().length != order.length ||
        order.any((i) => i < 0 || i >= tokenBeans.length)) throw ArgumentError('账号列表已变化，请重新打开排序');
    // Apply on restart; active clients and subsequent token writes keep their current slot.
    SpUtil.putObject('pendingAccountOrder', {'indices': order});
  }
}
