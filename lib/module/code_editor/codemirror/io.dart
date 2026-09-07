import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/src/consumer.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/main.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../base/theme.dart';
import 'impl.dart';

class CodeMirrorView extends CodeMirrorViewImpl {
  final CodeMirrorOptions options;

  final ValueChanged<EditorController> onCreate;

  final Function(String val) onValue;

  const CodeMirrorView({
    Key? key,
    required this.options,
    required this.onCreate,
    required this.onValue,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return CodeMirrorViewState();
  }
}

Future<String> editorHtml(CodeMirrorOptions options) async {
  var html = await rootBundle.loadString('assets/codemirror.html');
  final mode = ['shell', 'javascript', 'python', 'yaml'].contains(options.mode) ? options.mode : 'shell';
  final theme = options.theme == '3024-night' ? '3024-night' : 'neat';
  html = html.replaceAll('EDITOR_THEME', theme).replaceAll('EDITOR_MODE', mode);
  final pattern = RegExp(r'<link\s+rel="stylesheet"\s+href="([^"]+)"\s*/>|<script src="([^"]+)"></script>');
  for (final match in pattern.allMatches(html).toList()) {
    final css = match.group(1);
    final content = await rootBundle.loadString('assets/${css ?? match.group(2)}');
    html = html.replaceFirst(match.group(0)!, css != null
        ? '<style>$content</style>' : '<script>${content.replaceAll('</script', r'<\/script')}</script>');
  }
  return html;
}

class CodeMirrorViewState extends CodeMirrorViewImplState<CodeMirrorView> {
  late final Future<String> _document;
  @override
  void initState() {
    super.initState();
    _document = editorHtml(widget.options).then((html) => Uri.dataFromString(html, mimeType: 'text/html').toString());
  }

  WebViewController? _controller;

  bool readOnly = false;
  bool isLoaded = false;

  static bool isLoadedJs = false;
  bool isShowSearch = false;

  Future<void> showSearchBar() async {
    if (isShowSearch) {
      await _controller?.runJavascript(
        'clearSearchText()',
      );
    } else {
      await _controller?.runJavascript(
        'searchText()',
      );
    }
    isShowSearch = !isShowSearch;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    return FutureBuilder<String>(
        future: _document,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('编辑器加载失败，请返回重试'));
          if (!snapshot.hasData) {
            return const Center(child: LoadingWidget());
          }
          return LayoutBuilder(
            builder: (context, dimens) {
              return KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
                if (isLoaded) {
                  _controller?.runJavascript(
                    'editor.setSize(${dimens.maxWidth},${dimens.maxHeight})',
                  );
                }

                return WebView(
                  backgroundColor: ref.watch(themeProvider).themeColor.codeBgColor(),
                  debuggingEnabled: kDebugMode,
                  initialUrl: snapshot.data!,
                  navigationDelegate: (request) => request.url.startsWith('data:text/html')
                      ? NavigationDecision.navigate : NavigationDecision.prevent,
                  onWebViewCreated: (controller) {
                    if (MultiAccountPageState.useAction().isEmpty) {
                      if (!isLoadedJs) {
                        isLoadedJs = true;
                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                          EasyLoading.show(status: "加载中");
                        });
                      }
                    }
                    _controller = controller;
                  },
                  onPageFinished: (url) {
                    _controller?.runJavascript(
                      'editor.setSize(${dimens.maxWidth},${dimens.maxHeight})',
                    );
                    widget.onCreate(EditorController(
                      setOptions: (val) async {
                        readOnly = val.readOnly;
                        _controller?.runJavascript(
                          'editor.setSize(${dimens.maxWidth},${dimens.maxHeight})',
                        );

                        await _controller?.runJavascript(
                          'editor.setOption("mode", "${val.mode}")',
                        );
                        await _controller?.runJavascript(
                          'editor.setOption("theme", "${val.theme}")',
                        );
                        await _controller?.runJavascript(
                          'editor.setOption("readOnly", ${val.readOnly ? '\"nocursor\"' : false})',
                        );

                        await _controller?.runJavascript(
                          'editor.setOption("lineNumbers", ${val.showLineNumber})',
                        );
                        await Future.delayed(
                          const Duration(milliseconds: 200),
                        );
                        await _controller?.runJavascript(
                          'editor.refresh()',
                        );
                        await EasyLoading.dismiss();
                      },
                      setValue: (val) async {
                        TextPainter painter = TextPainter(
                          text: TextSpan(
                            text: val,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          textDirection: TextDirection.ltr,
                        );
                        painter.layout(
                          maxWidth: MediaQuery.of(context).size.width,
                        );
                        isLoaded = true;
                        final raw = Uri.encodeComponent(val);
                        _controller?.runJavascript('editor.setValue(decodeURIComponent("$raw"))');
                      },
                      refresh: () async {
                        const delay = Duration(milliseconds: 50);
                        await Future.delayed(delay);
                        _controller?.runJavascript(
                          'editor.refresh()',
                        );
                      },
                    ));
                  },
                  javascriptMode: JavascriptMode.unrestricted,
                  javascriptChannels: {
                    JavascriptChannel(
                      name: 'MessageInvoker',
                      onMessageReceived: (event) => widget.onValue(event.message),
                    ),
                  },
                );
              });
            },
          );
        });
  }
}
