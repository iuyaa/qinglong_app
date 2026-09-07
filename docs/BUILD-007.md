# 项目频道入口 007

日期：2026-09-07。工作目录已迁移到 `M:\qinglong_app`。

用户提供并确认项目 Telegram 频道 `https://t.me/qinglong_app`。

- GitHub 仓库 About 的 homepage 已设置为频道地址，并通过 API 回读确认。
- README 增加项目仓库、发布列表、Telegram 更新公告频道；移除过时的固定当前版本文案。
- App「关于软件」的分组名改为「项目链接」，新增 Telegram 频道行，显示 `@qinglong_app · 更新公告`。复用现有 `_launchURL` 和 `openProjectUrl`，失败时沿用现有提示。
- 版本升级为 3.0.7，构建代码使用运行号；没有新增依赖或业务写操作。

构建提交：`fc33c83400f3a4ae4e08c75d4c6e7c05eefed695`。

验证：`git diff --check` PASS；[GitHub Actions 14](https://github.com/iuyaa/qinglong_app/actions/runs/34115281594) SUCCESS。`flutter test` 12 项通过；`flutter build apk --release --build-name=3.0.7 --build-number=14` 及签名检查 PASS。

`python reference/verify-build-14.py 14 ff248fa9f5035394ad2fae329219d91a37b127e687a614f8323c9d8bd04e4e93` PASS：Artifact ZIP、APK 完整性、公开资产/更新清单 SHA256、包名和版本匹配，原签名一致，图标资源仍正确。

[正式发布 3.0.7+14](https://github.com/iuyaa/qinglong_app/releases/tag/v3.0.7%2B14)，已设 latest。匿名读取更新清单成功。

成品：`artifacts/build-14/qinglong-android.apk`，27,737,090 字节；SHA256：`9c38d351b15eabc1cc5da2f98617947387782ec33687103609aaab0cf67e6778`。

手机上点击频道、未安装 Telegram 时的浏览器接管、覆盖安装：NOT_RUN。本次没有向 Telegram 发送消息，也未连接或操作真实青龙面板。
