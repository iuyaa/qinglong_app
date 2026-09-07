import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/login/login_page.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Login mode switches fields without mixing credentials', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SpUtil.getInstance();
    getIt.registerSingleton<MultiAccountUserInfoViewModel>(MultiAccountUserInfoViewModel());
    addTearDown(() => getIt.reset());
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginPage(fromAddNewAccount: true)),
    ));
    final account = find.widgetWithText(TextField, '请输入账户');
    await tester.enterText(account, 'synthetic-user');
    await tester.tap(find.text('应用密钥'));
    await tester.pumpAndSettle();
    expect(find.text('应用登录'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Client ID'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Client Secret'), findsOneWidget);
    expect(find.text('synthetic-user'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Client ID'), 'synthetic-id');
    await tester.tap(find.text('账号密码'));
    await tester.pumpAndSettle();
    expect(find.text('synthetic-user'), findsOneWidget);
    expect(find.text('synthetic-id'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
