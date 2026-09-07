import 'package:flutter/material.dart';
import 'single_account_page.dart';

Future<bool> confirmOperation(BuildContext context, String action, List<String> targets) async {
  if (targets.isEmpty) return false;
  final account = SingleAccountPageState.ofUserInfo(context);
  final host = Uri.tryParse(account.host ?? '');
  final panel = host == null ? '' : '${host.scheme}://${host.authority}${host.path}';
  return await showDialog<bool>(context: context, useRootNavigator: false,
    builder: (dialog) => AlertDialog(
      title: Text('确认$action ${targets.length} 项'),
      content: SingleChildScrollView(child: Text('$panel\n\n${targets.join('\n')}')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('确定')),
      ],
    )) ?? false;
}
