# 构建验收记录 004

日期：2026-09-07。版本：3.0.4+10。

- 构建提交：`9365b5ad62c211f618ce1fc0bf1d54f0923c3ed6`
- [成功的 GitHub Actions](https://github.com/iuyaa/qinglong_app/actions/runs/34098639157)
- [正式 Release](https://github.com/iuyaa/qinglong_app/releases/tag/v3.0.4%2B10)
- [改动范围与集中真机测试清单](MAINTENANCE-004.md)

| 验证 | 结果 |
| --- | --- |
| `flutter pub get`、`git diff --exit-code -- pubspec.lock` | PASS，没有新增 Dart 依赖或改动锁文件 |
| `flutter test` | PASS，10 项测试，包含更新元数据、排序/历史、重复写、离线编辑器与返回保护 |
| 现有回环 HTTP 测试扩展到 env/config/subscription/dependency/app | PASS，账号与 OpenAPI 前缀、参数及响应形状；不是实际业务写入验收 |
| `flutter build apk --release --build-name=3.0.4 --build-number=10` | PASS，包含 Android 原生安装通道 |
| `apksigner verify --verbose --print-certs` | PASS，v1/v2 签名有效，与前版证书一致 |
| Actions Publish App update | PASS，先上传草稿资产再公开，Release 非草稿、非预发布 |
| 不带 Authorization 读取 latest Release 与 update.json | PASS，通过 GitHub API 资产端点匿名下载清单，版本/大小/哈希/下载链接一致 |
| 下载 ZIP SHA256 对照 GitHub Artifact digest | PASS |
| APK SHA256 对照 SHA256SUMS、Release 资产 digest 与公开 update.json | PASS |
| ZIP/APK `ZipFile.testzip()` | PASS |
| Apktool 成品 Manifest、apktool.yml | PASS，`io.github.iuyaa.qinglong`、3.0.4+10、minSdk 21、targetSdk 33 |
| 成品更新权限/Provider/Activity 与编辑器资源检查 | PASS，包含 REQUEST_INSTALL_PACKAGES、专用文件共享 Provider、正确 MainActivity；23 个 CodeMirror 资源/许可证文件与源码一致（换行归一化后比较） |
| `git diff --check` | PASS |

第 8 次运行 `34098065446` 编译失败：历史账号删除函数改为完整身份后，账号列表与设置两个调用仍传地址，补齐后修复。第 9 次运行 `34098312130` 的 10 项测试通过，后因补充编辑器许可证随包分发而被新提交自动取消。第 10 次完整通过，没有绕过测试。

本机 Git HTTPS 连接超时，改用 GitHub Git Data API 上传，树和提交 SHA 均与本地提交逐一匹配，更新 main 时不使用强制覆盖。下载连接较慢，ZIP 使用 Range 补齐，完整文件通过哈希验证；公开 APK 的本地直连下载未完成，最终使用 Actions ZIP 内的 APK，并核对其与公开 Release APK digest 一致。

旧 Android 工具链仍有三个自定义 lint 检查加载失败（`NoClassDefFoundError: .../Vendor`）。APK 构建成功，但完整 Android lint、`flutter analyze`、Android 真机安装/授权/覆盖更新、WebView 真机交互和全部真实业务写操作：NOT_RUN。用户已约定后续集中真机测试；本轮未操作真实面板。

本地成品：`artifacts/build-10/qinglong-android.apk`，26,871,947 字节。

APK SHA256：`2c0cc253859b7013cd0ac5170735bd65a7588c51a3ff7d2a5b194459754b163b`。

签名证书 SHA256：`076dbcb13c02831c52f78abcf9fbe0460ee522bc78763970ae487ad402fa7c12`。

Artifact `qinglong-android-10`，ID `10009750380`，ZIP SHA256：`1944ddae1ac908fc9d4021a36a214ae3eb86a71430eb79ff6460ebcac8f696a0`。

Release ID `383923120`，APK asset `548418659`，更新清单 asset `548418661`。首次需手动覆盖安装此版本，后续可由 App 检查、下载并调用系统安装器；安装行为仍由用户确认。
