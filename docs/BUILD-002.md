# 构建验收记录 002

日期：2026-09-07。版本：3.0.2。

- 构建提交：`443de9b15868bdf9df36ec391e9c24deae66c2ac`
- [GitHub Actions](https://github.com/iuyaa/qinglong_app/actions/runs/34087358392)
- [接口改动与真实面板验证范围](API-002.md)

| 检查 | 结果 |
| --- | --- |
| `flutter pub get`、`git diff --exit-code -- pubspec.lock` | PASS |
| `flutter test` | PASS，4 个测试，覆盖版本分支、HTTP 传输与响应、登录页切换 |
| `git diff --check` | PASS |
| 15 个变更文件的凭据及私有域名特征检查 | PASS，0 命中 |
| `flutter build apk --release --build-name=3.0.2 --build-number=3` | PASS |
| `apksigner verify --verbose --print-certs` | PASS，v1/v2 验签通过 |
| 下载 ZIP 的 SHA256 对照 GitHub Artifact digest | PASS |
| APK SHA256 对照云端 `SHA256SUMS.txt`、ZIP/APK `ZipFile.testzip()` | PASS |
| Apktool 解码成品 Manifest | PASS，`io.github.iuyaa.qinglong`，3.0.2+3，minSdk 21、targetSdk 33 |

首轮运行 `34087277300` 在测试阶段失败：测试遗漏账号服务注册，且路径断言使用未编码文本。修正后重新运行并通过，未跳过测试。

Android 真机启动/登录、真实 OpenAPI 应用密钥与 2FA 登录、完整 `flutter analyze`：NOT_RUN。停止和启用任务没有完成实测；其他资源没有进行写操作。浏览器测试任务 ID 102 已先禁用再删除，现有任务和脚本未改动。此次没有升级 Flutter/Android 工具链。

旧 Android 工具链无法加载三个依赖的自定义 lint 检查（`NoClassDefFoundError: .../Vendor`）；构建成功，但不能据此宣称 Android lint 完整通过。另有 Node/setup-java 版本弃用和旧依赖警告。

签名证书 SHA256：`076dbcb13c02831c52f78abcf9fbe0460ee522bc78763970ae487ad402fa7c12`，与 3.0.1+1 相同，可覆盖升级。

本地安装包：`artifacts/build-3/qinglong-android.apk`，26,580,576 字节。

APK SHA256：`3bd718e619a0eed0bf91a07217d54dc59860d2e44047b174d41f840282dc8ccd`。

产物 `qinglong-android-3`，Artifact ID `10005773325`。ZIP SHA256：`317ff8f183169da58009efd24e11a72b453fb795761d2b3c953428aa9ed349ad`。下载途中发生 TLS/连接中断，经断点续传完成；完整文件通过哈希校验。
