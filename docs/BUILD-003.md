# 构建验收记录 003

日期：2026-09-07。版本：3.0.3+7。

- 构建提交：`d3b4188f828ded7acb91f96a7765eace7762bff6`
- [GitHub Actions 成功运行](https://github.com/iuyaa/qinglong_app/actions/runs/34095658457)
- [登录与多面板改动、验证边界](AUTH-003.md)
- 主要变更：`lib/base/http/`、账号状态与页面容器、`lib/utils/login_helper.dart`、登录/首页/设置退出流程及 `test/session_test.dart`。

| 检查 | 结果 |
| --- | --- |
| `flutter pub get`、`git diff --exit-code -- pubspec.lock` | PASS |
| `flutter test` | PASS，5 个测试；新增会话测试中的全部阶段完成 |
| `git diff --check` | PASS |
| 13 个变更源码/测试文件的 GitHub 凭据、真实面板地址及长 Bearer Token 特征扫描 | 0 命中；不是完整安全审计 |
| `flutter build apk --release --build-name=3.0.3 --build-number=7` | PASS |
| `apksigner verify --verbose --print-certs` | PASS，v1/v2 验签通过 |
| 下载 ZIP SHA256 对照 GitHub Artifact digest | PASS |
| APK SHA256 对照 `SHA256SUMS.txt`、ZIP/APK `ZipFile.testzip()` | PASS |
| Apktool 成品 Manifest 与版本元数据 | PASS，`io.github.iuyaa.qinglong`，3.0.3+7，minSdk 21、targetSdk 33 |

边界自查：错误密码与空 Token 不替换原会话；2FA 取消、错误重试与后续登录取代旧登录；旧请求/旧页面不能操作新面板；旧日志迟到及 Provider 缓存清理；权限不足不退出；应用密钥过期返回原登录方式；POST 不重放；多账号空槽位保存/恢复；新面板不收到旧 Token。均使用合成回环服务，未连接真实面板。

第 4 次运行 `34094497186` 因旧版 Dart 将混合 Provider Family 列表推断为 Object 而编译失败，改用逐项 `invalidate`。第 5 次运行 `34094841340` 的新增测试等待异常，主动取消；第 6 次运行 `34095406701` 通过分段输出与 20 秒超时定位到真实 HTTP 与 Widget 假时钟间的信号等待。将测试信号创建/释放放到真实 I/O 环境后，第 7 次完整通过。没有跳过测试。

本地校验首次受 Windows 默认 GBK 解码 UTF-8 Manifest 影响，明确使用 UTF-8 后通过。旧 Android 工具链仍有三个自定义 lint 检查加载失败（`NoClassDefFoundError: .../Vendor`），构建成功不能代表完整 lint 通过；此次未升级工具链。

真实 Client ID/Secret、真实 TOTP、3.0.3 Android 真机交互、账号排序和完整 `flutter analyze`：NOT_RUN。用户反馈的是 3.0.2 真机任务、脚本、日志页面目视正常。本轮没有操作任何真实任务、脚本或登录设置。

签名证书 SHA256：`076dbcb13c02831c52f78abcf9fbe0460ee522bc78763970ae487ad402fa7c12`，与 3.0.2+3 相同，可覆盖升级。

本地安装包：`artifacts/build-7/qinglong-android.apk`，26,586,116 字节。

APK SHA256：`639acbba71f909336077ea65b978a21da5b194dccf313179e878671043e00096`。

产物：`qinglong-android-7`，Artifact ID `10008626098`，ZIP SHA256：`add8f1541a9124777c71fe1556bd9ee1ac6e3ac445c140a79cd00c64a3aa446c`。
