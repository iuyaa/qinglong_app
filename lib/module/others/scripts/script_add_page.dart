import 'package:qinglong_app/module/code_editor/edit_guard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../code_editor/editor.dart';

class ScriptAddPage extends ConsumerStatefulWidget {
  final String title;
  final String path;

  const ScriptAddPage(this.title, this.path, {Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _ScriptAddPageState();
}

class _ScriptAddPageState extends ConsumerState<ScriptAddPage> {
  bool _saving = false;
  late String result;
  FocusNode focusNode = FocusNode();
  late String preResult;

  late CodeMirrorOptions options;
  EditorController? controller;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    options = CodeMirrorOptions().copyWith(
      readOnly: false,
      mode: getLanguageType(widget.title),
    );
    result = "## created by 青龙客户端 ${DateTime.now().toString()}\n\n";
    preResult = result;
    super.initState();
  }

  getLanguageType(String title) {
    if (title.endsWith(".js")) {
      return 'javascript';
    }

    if (title.endsWith(".sh")) {
      return 'shell';
    }

    if (title.endsWith(".py")) {
      return 'python';
    }
    if (title.endsWith(".json")) {
      return 'shell';
    }
    if (title.endsWith(".yaml")) {
      return 'yaml';
    }
    return "shell";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => confirmLeaveEditor(context, preResult != result, _saving),
      child: Scaffold(
      appBar: QlAppBar(
        canBack: true,
        backCall: () => Navigator.of(context).maybePop(),
        title: '新增${widget.title}',
        actions: [
          CupertinoButton(
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            onPressed: _saving ? null : () async {
              if (_saving) return;
              setState(() => _saving = true);
              final api = SingleAccountPageState.ofApi(context);
              final submitted = result;
              try {
                await EasyLoading.show(status: " 提交中");
                HttpResponse<NullResponse> response =
                    await api.addScript(
                  widget.title,
                  widget.path,
                  submitted,
                );
                await EasyLoading.dismiss();
                if (!mounted) return;
                if (response.success) {
                  preResult = submitted;
                  "提交成功".toast();
                  if (result == submitted) Navigator.of(context).pop(true);
                } else {
                  (response.message ?? "").toast();
                }
              } catch (_) {
                if (mounted) '保存失败，修改已保留，请重试'.toast();
              } finally {
                EasyLoading.dismiss();
                if (mounted) setState(() => _saving = false);
              }
            },
            child:  Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: Center(
                child: Text(
                  "提交",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        top: false,
        child: Editor(
          options: options,
          onCreate: (val) {
            controller = val;
            controller?.setOptions(options);
            controller?.setValue(result);
          },
          onValue: (val) {
            result = val;
          },
        ),
      ),
      ),
    );
  }
}
