# 图标替换 006

日期：2026-09-07。用户确认已生成的白底绿龙预览，并授权替换 App 图标。

## 改动

- `branding/qinglong-icon.png` 保留确认的 1254×1254 原图及其提示词；来源和导出方法见 `branding/README.md`。
- `scripts/export-icon.ps1` 使用 Windows System.Drawing 导出 512×512 App 内标志及五档 48/72/96/144/192 像素桌面图标，不重新生成图案或调用收费 API。
- Android 8+ 增加自适应图标，白色背景和 432×432 前景，按 68% 缩放保留安全空间。绿圈相对画布略微偏心，按实际像素确认最远前景距离中心 129.97px，小于 132px 安全半径。
- 登录页、账号入口和关于软件均复用 `assets/images/ql.png`，随资源替换统一；同名白底/启动源图也同步。
- 移除旧的 flutter_icons 配置，避免后续误生成覆盖安全留白。版本变为 3.0.6；账号、接口与业务逻辑未变更。

## 验证

- 本地读取已导出 PNG：五档尺寸 PASS，432×432 自适应前景 PASS，源文件与确认预览字节一致。
- 初次 70% 缩放的安全圆检查失败（133.41px > 132px），调整为 68% 后通过。第 12 次构建被后续提交取消，以第 13 次结果为准。
- 构建提交：`1a4d510cfff2a536aa686ef3bbebcb705b1aa645`。
- [GitHub Actions 13](https://github.com/iuyaa/qinglong_app/actions/runs/34108378687)：SUCCESS，`flutter test` 12 项 PASS，锁文件未变；`flutter build apk --release --build-name=3.0.6 --build-number=13` 和 `apksigner verify --verbose --print-certs` PASS。
- `python reference/verify-build-13.py 13 3b75bb03cd384c2f14e439f33fd556ca8fdc9548f57e24c36cdda547a137b983`：PASS。检查 ZIP/APK 完整性、公开清单与资产 SHA256、包名/版本、前版签名；成品内三张 App 标志字节一致，五档图标和自适应前景像素与导出文件一致，自适应 XML 已打包。
- 匿名 API 资产请求本次返回 HTTP 403；随后公开 browser_download_url 下载 `update.json` 返回成功，元数据与 APK 匹配。不能将本地通路成功当作手机网络可用性证明。
- Android 真机桌面缓存刷新、各厂商图标裁切、安装与页面展示：NOT_RUN。
- 完整 `flutter analyze` / Android lint：NOT_RUN。真实面板本轮未连接、未操作。

正式发布：[3.0.6+13](https://github.com/iuyaa/qinglong_app/releases/tag/v3.0.6%2B13)，非草稿/非预发布，已设 latest。

成品：`artifacts/build-13/qinglong-android.apk`，27,735,343 字节。

APK SHA256：`127c975b61cea46ff2390162a8f6e3f83ef2b1a4276e8ca7f55328655a998470`。

签名证书 SHA256：`076dbcb13c02831c52f78abcf9fbe0460ee522bc78763970ae487ad402fa7c12`，与前版一致。
