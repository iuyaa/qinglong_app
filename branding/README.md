# Android 图标

`qinglong-icon.png` 是用户于 2026-09-07 确认替换的 AxonHub 预览原图（1254×1254），保留原文件，不重绘。提示词在 `qinglong-icon-prompt.txt`，PNG 亦保留提示词。后端报告质量 low，未报告图像模型。

参考青龙面板[原仓库](https://github.com/whyour/qinglong) README 的[标志](https://user-images.githubusercontent.com/22700758/191449379-f9f56204-0e31-4a16-be5a-331f52696a73.png)，仅用于本项目客户端标识。

在 Windows 仓库根目录运行 `powershell -NoProfile -File scripts/export-icon.ps1`，确定性导出已提交的 App 内图片、五档旧版桌面图标和自适应图标前景，不调用图像 API。自适应前景使用 432×432 画布和 68% 原图缩放，保留白底；整个绿圈位于 Android 66/108 安全圆内。旧版图标 48/72/96/144/192 像素，App 内标志 512×512。

Android 8 起使用 `mipmap-anydpi-v26/ic_launcher.xml` 的白色背景与前景；较早系统回退到 PNG。Manifest 保持 `@mipmap/ic_launcher`。不再使用旧的 flutter_icons 配置，以免重新生成时丢失安全留白。
