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

import '../../code_editor/codemirror/io.dart';
import '../../code_editor/editor.dart';
import '../../config/config_detail_page.dart';

class ScriptEditPage extends ConsumerStatefulWidget {
  final String content;
  final String title;
  final String path;

  const ScriptEditPage(this.title, this.path, this.content, {Key? key}) : super(key: key);

  @override
  _ScriptEditPageState createState() => _ScriptEditPageState();
}

class _ScriptEditPageState extends ConsumerState<ScriptEditPage> {
  bool _saving = false;
  late String result;
  late String preResult;
  late CodeMirrorOptions options;
  EditorController? controller;

  @override
  void dispose() {
    EasyLoading.dismiss();
    super.dispose();
  }

  @override
  void initState() {
    options = CodeMirrorOptions().copyWith(
      readOnly: false,
      mode: getLanguageType(widget.title),
    );
    result = widget.content;
    preResult = widget.content;
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
      backgroundColor: ref.watch(themeProvider).themeColor.codeBgColor(),
      appBar: QlAppBar(
        canBack: true,
        backCall: () => Navigator.of(context).maybePop(),
        title: '编辑${widget.title}',
        actions: [
          CupertinoButton(
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            onPressed: () async {
              codeKey.currentState?.showSearchBar();
            },
            child: Padding(
              padding: const EdgeInsets.only(
                left: 15,
              ),
              child: Center(
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).appBarTheme.iconTheme?.color,
                  size: 22,
                ),
              ),
            ),
          ),
          CupertinoButton(
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            onPressed: _saving ? null : () async {
              if (_saving) return;
              setState(() => _saving = true);
              final api = SingleAccountPageState.ofApi(context);
              final submitted = result;
              try {
                await hideKeyboardFocus();
                await EasyLoading.show(status: " 提交中");
                HttpResponse<NullResponse> response = await api.updateScript(widget.title, widget.path, submitted);
                await EasyLoading.dismiss();
                if (!mounted) return;
                if (response.success) {
                  preResult = submitted;
                  "提交成功".toast();
                  if (result == submitted) Navigator.of(context).pop(submitted);
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
            child: Padding(
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
          codeMirrorKey: codeKey,
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

  GlobalKey<CodeMirrorViewState> codeKey = GlobalKey();
}
