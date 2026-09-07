# 更新检查与仓库入口修正 005

日期：2026-09-07。构建提交：`93c248ad7db50762c03ff85b8055da8cbc60c1ae`。

## 问题与改动

用户反馈 App 更新检查失败、发布页无法打开。复查公开 latest API，原 3.0.4+10 为正式发布，APK、SHA256SUMS.txt、update.json 均存在。匿名请求两个更新清单下载端点均返回 HTTP 200；GitHub 网页首次连接超时，随后仓库首页恢复 HTTP 200，latest 返回 302 指向已发布标签。因此不是缺少 Release，手机端具体失败步骤仍未复现。

- `about_page.dart`：入口改名为「项目仓库 / 下载」，仍指向自有仓库；统一使用外部浏览器，处理启动返回 false 和异常。
- `app_update_page.dart`：发布入口直接打开 releases 列表；提供打开及复制仓库地址。清单请求网络失败后，使用 GitHub 官方资产 API 重试；资产 ID 必须为正整数，API 地址由代码构造，保留原有地址、版本、大小、哈希和安装签名校验。
- 更新检查显示失败步骤，区分 HTTP 404、403/429、超时和元数据异常，避免统一提示掩盖原因。不输出异常原文或面板凭据。
- 工作流版本升级为 3.0.5，更新发布说明；没有新增依赖或本地安装开发工具。

## 验证

- `git diff HEAD^ HEAD --check`：PASS。
- [GitHub Actions 11](https://github.com/iuyaa/qinglong_app/actions/runs/34102165014)：SUCCESS。`flutter test` 12 项 PASS，包含超时回退、拒绝外部地址/非法资产 ID 和错误分类；锁文件未变化。
- `flutter build apk --release --build-name=3.0.5 --build-number=11`、`apksigner verify --verbose --print-certs`：PASS。签名证书 SHA256 与前版一致：`076dbcb13c02831c52f78abcf9fbe0460ee522bc78763970ae487ad402fa7c12`。
- [正式 Release 3.0.5+11](https://github.com/iuyaa/qinglong_app/releases/tag/v3.0.5%2B11)：非草稿、非预发布，已标记 latest，三个资产完整。
- 匿名读取官方 API 资产端点的 `update.json`：HTTP 200，版本、包名、大小、SHA256、APK 地址均与成品匹配。
- `python reference/verify-build-11.py 11 47e1f78d637f568a029d4c225a7bb7fd120ee7f0deacf5a6b8fec42c8088e51e`：PASS，ZIP/APK 完整性、云端 Artifact digest、公开 APK digest、清单、包名/版本和签名记录一致，更新权限/Provider 及离线编辑器资源存在。
- 手机网络下的更新检查、浏览器启动、APK 下载及系统覆盖安装：NOT_RUN。需要用户安装新包后重试；不保证绕过 GitHub 网络访问限制。
- 真实青龙面板：本轮未连接、未操作。

成品：`artifacts/build-11/qinglong-android.apk`，26,876,500 字节；SHA256：`a7249b20b010a5c49b631e7ea67340eaf3fc9b0d29b0b4a62bbb6d0ee2408d82`。

完整 `flutter analyze` / Android lint：NOT_RUN；继承工具链的 lint 加载告警仍需后续处理，构建通过不代表完整 lint 验收。
