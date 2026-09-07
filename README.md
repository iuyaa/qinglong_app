# 青龙客户端 · 自用版

基于旧版 Flutter 青龙客户端继续维护的 Android App。独立仓库，不使用 GitHub Fork 关系。

沿用上游的面板登录、多账号切换、任务、日志、环境变量、配置文件、脚本、订阅及依赖管理。已针对青龙 v2.21.0 修复首批接口差异，验证范围见 [接口适配记录](docs/API-002.md)；仍需 Android 真机验收。

## 下载 APK

首次安装：打开 [最新正式版](https://github.com/iuyaa/qinglong_app/releases/latest)，直接下载 `qinglong-android.apk`，无需 GitHub 登录。

从 3.0.4 起，可在 App「关于软件 → App 更新」中检查版本、下载并校验 APK，再打开 Android 系统安装界面。首次需要允许本 App 安装更新；授权后返回点击安装。使用同一签名覆盖升级，账号配置保留。检查/下载失败可重试或打开发布页，需要能访问 GitHub 的网络。

[GitHub Actions](https://github.com/iuyaa/qinglong_app/actions/workflows/android.yml) 也保留构建产物 14 天，作为备用下载（需要登录 GitHub）。

- 新包名：`io.github.iuyaa.qinglong`，可与原 APK 同时安装，账号配置独立。
- Android 5.0 及以上是当前构建配置的最低要求；实际手机兼容性待验证。
- 使用本仓库专用签名，同一签名的后续构建可覆盖升级。
- 当前版本为 3.0.4，版本代码使用 Actions 构建号。

## 云端构建

代码推送到 `main` 或手动运行工作流时，GitHub 托管的 Ubuntu runner 自动安装 Java/Flutter、解析锁定依赖、执行回归测试、构建并验签 APK。main 成功构建后发布 APK、校验文件和更新清单；PR 只检查，不发布。

本机无需安装 Flutter、Android Studio 或模拟器。首次基线固定使用 Flutter 3.3.10、Java 11 和上游锁文件，后续工具链升级应单独验证。

所需 Actions Secrets（只保存于 GitHub Secrets，禁止提交到代码）：

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

工作流缺少签名配置时失败。PR 仅测试和编译 debug，不读取签名密钥。Actions 不连接任何真实青龙面板。

## 当前改动和验证范围

- 独立包名、独立签名和 GitHub Actions 构建链路。
- 关闭共享 HTTP 客户端的请求内容日志，移除接受任意 HTTPS 证书的逻辑。
- 保留旧版布局及主要业务流程，反馈、下载入口改为本仓库。
- 已通过浏览器验证 v2.21.0 隔离任务的创建、编辑、运行、日志、禁用和删除；用户反馈 3.0.2 真机任务、脚本、日志页面目视正常，完整真机操作验收仍待验证。
- 3.0.3 修复登录失败保留原会话、两步验证、登录过期及多面板请求/缓存隔离，见 [登录与会话验证](docs/AUTH-003.md)。
- 3.0.4 增加 App 内更新、离线编辑器资源、未保存返回保护、多账号排序及批量确认，见 [本轮改动与集中测试清单](docs/MAINTENANCE-004.md)。
- 继承的账号本地存储等实现尚未进行完整安全审计，详见 [数据说明](docs/DATA.md)。

## 来源

导入自 [LinxiDev/qinglong-app](https://github.com/LinxiDev/qinglong-app/tree/d1b6150a464e849df9c89f863a5e21b6183500f4)，保留 [AGPL-3.0 许可证](LICENSE)及原有版权声明。原作者与各衍生项目的贡献见 [来源与选型](docs/UPSTREAM.md)。本仓库不代表青龙官方或原客户端作者。
