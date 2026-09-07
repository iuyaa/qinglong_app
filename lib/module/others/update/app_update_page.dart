import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const releasePage = 'https://github.com/iuyaa/qinglong_app/releases/latest';
const releaseApi = 'https://api.github.com/repos/iuyaa/qinglong_app/releases/latest';
const updateChannel = MethodChannel('io.github.iuyaa.qinglong/update');

// Only our published assets can supply an update; panel credentials never enter this client.
String releaseAssetUrl(dynamic value) {
  final uri = Uri.tryParse(value is String ? value : '');
  if (uri == null || uri.scheme != 'https' || uri.host != 'github.com' ||
      uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment || uri.port != 443 ||
      !uri.path.startsWith('/iuyaa/qinglong_app/releases/download/') ||
      uri.pathSegments.any((part) => part == '..')) {
    throw const FormatException('更新下载地址无效');
  }
  return uri.toString();
}

class AppRelease {
  final int code, size;
  final String version, sha256, url, notes;
  AppRelease(this.code, this.size, this.version, this.sha256, this.url, this.notes);

  factory AppRelease.parse(Map<String, dynamic> manifest, Map<String, dynamic> release) {
    final code = manifest['versionCode'];
    final size = manifest['size'];
    final hash = manifest['sha256'];
    final version = manifest['versionName'];
    final url = releaseAssetUrl(manifest['url']);
    if (manifest['packageName'] != 'io.github.iuyaa.qinglong' ||
        code is! int || code <= 0 || size is! int || size <= 0 || size > 200 * 1024 * 1024 ||
        hash is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        version is! String || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
        release['draft'] != false || release['prerelease'] != false ||
        release['tag_name'] != 'v$version+$code') {
      throw const FormatException('更新版本信息不完整');
    }
    final assets = release['assets'];
    if (assets is! List || !assets.any((asset) => asset is Map &&
        asset['name'] == 'qinglong-android.apk' && Uri.decodeFull(asset['browser_download_url']?.toString() ?? '') == Uri.decodeFull(url) && asset['size'] == size)) {
      throw const FormatException('更新安装包与版本信息不一致');
    }
    return AppRelease(code, size, version, hash, url, release['body']?.toString() ?? '稳定性更新');
  }
}

class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({Key? key}) : super(key: key);
  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  final _dio = Dio(BaseOptions(connectTimeout: 20000, receiveTimeout: 30000,
    headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'qinglong-android'}));
  CancelToken? _cancel;
  AppRelease? _release;
  File? _apk;
  bool _busy = false;
  double? _progress;
  String _status = '正在检查更新', _current = '';

  @override
  void initState() { super.initState(); _check(); }

  @override
  void dispose() { _cancel?.cancel(); _dio.close(force: true); super.dispose(); }

  Future<void> _check() async {
    if (_busy) return;
    setState(() { _busy = true; _status = '正在检查更新'; _release = null; _apk = null; });
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      _current = '${info.version} (${info.buildNumber})';
      final response = await _dio.get(releaseApi);
      final data = Map<String, dynamic>.from(response.data as Map);
      final assets = data['assets'] as List;
      final asset = assets.singleWhere((a) => a['name'] == 'update.json');
      final manifest = await _dio.get<String>(releaseAssetUrl(asset['browser_download_url']),
        options: Options(responseType: ResponseType.plain));
      final release = AppRelease.parse(Map<String, dynamic>.from(jsonDecode(manifest.data!) as Map), data);
      if (!mounted) return;
      if (release.code > (int.tryParse(info.buildNumber) ?? 0)) {
        _release = release;
        _status = '发现新版本 ${release.version} (${release.code})';
      } else { _status = '当前已是最新版本'; }
    } catch (_) {
      if (mounted) _status = '检查更新失败，请重试或打开发布页';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    final release = _release;
    if (_busy || release == null) return;
    setState(() { _busy = true; _progress = 0; _status = '正在下载安装包'; });
    final cancel = CancelToken();
    _cancel = cancel;
    File? file;
    try {
      final directory = await getTemporaryDirectory();
      final updates = await Directory('${directory.path}/updates').create(recursive: true);
      file = File('${updates.path}/qinglong-update.apk');
      if (!mounted) return;
      await _dio.download(release.url, file.path, cancelToken: cancel,
        options: Options(headers: {'Accept': 'application/octet-stream'}),
        onReceiveProgress: (received, total) {
          if (received > release.size) { cancel.cancel('安装包大小异常'); return; }
          if (mounted) setState(() => _progress = received / release.size);
        });
      if (await file.length() != release.size) throw const FormatException('下载不完整');
      if (!mounted) return;
      // Android independently verifies the hash, package, version and signing certificate.
      await updateChannel.invokeMethod('verify', {'path': file.path, 'sha256': release.sha256, 'code': release.code});
      if (!mounted) return;
      _apk = file;
      _status = '下载及校验完成，点击安装更新';
    } catch (_) {
      if (file != null && await file.exists()) await file.delete();
      if (mounted) _status = cancel.isCancelled ? '下载已取消，可重新下载' : '下载或校验失败，请重试或打开发布页';
    } finally {
      if (mounted) setState(() { _busy = false; _progress = null; });
    }
  }

  Future<void> _install() async {
    if (_busy || _apk == null || _release == null) return;
    setState(() => _busy = true);
    try {
      final result = await updateChannel.invokeMethod<String>('install', {
        'path': _apk!.path, 'sha256': _release!.sha256, 'code': _release!.code});
      if (mounted) _status = result == 'permission'
          ? '请允许此应用安装更新，返回后再次点击安装更新'
          : '已打开系统安装界面；取消安装后可再次点击';
    } catch (_) {
      if (mounted) _status = '无法安装此更新，请重新下载或打开发布页';
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('App 更新')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('当前版本 $_current'), const SizedBox(height: 16),
      Text(_status), const SizedBox(height: 16),
      if (_busy) LinearProgressIndicator(value: _progress),
      if (_release != null) ...[
        const SizedBox(height: 16), Text(_release!.notes), const SizedBox(height: 16),
        ElevatedButton(onPressed: _busy ? null : (_apk == null ? _download : _install),
          child: Text(_apk == null ? '下载更新' : '安装更新')),
      ],
      if (_busy && _progress != null)
        TextButton(onPressed: () => _cancel?.cancel(), child: const Text('取消下载')),
      TextButton(onPressed: _busy ? null : _check, child: const Text('重新检查')),
      TextButton(onPressed: () async {
        try { await launchUrl(Uri.parse(releasePage), mode: LaunchMode.externalApplication); }
        catch (_) { if (mounted) setState(() => _status = '无法打开浏览器，请稍后重试'); }
      }, child: const Text('打开发布页')),
    ]),
  );
}
