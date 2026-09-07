import 'package:flutter/material.dart';

Future<bool> confirmLeaveEditor(BuildContext context, bool changed, bool saving) async {
  if (saving) return false;
  if (!changed) return true;
  return await showDialog<bool>(context: context, useRootNavigator: false,
    builder: (dialog) => AlertDialog(
      title: const Text('放弃未保存的修改？'),
      content: const Text('离开后，本次修改将丢失。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('继续编辑')),
        TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('放弃修改')),
      ],
    )) ?? false;
}
