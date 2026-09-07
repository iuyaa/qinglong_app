# 源码来源与选型

检查日期：2026-09-07。时间以默认分支最新提交为准，不用 GitHub `updated_at` 判断代码是否更新。

| 候选仓库 | 默认分支提交日期 | 判断 |
| --- | --- | --- |
| [lffw001/qinglong_app](https://github.com/lffw001/qinglong_app) | 2023-06-08 | AGPL-3.0，旧版同源，Flutter/Dart 2 工具链 |
| [ayoulx/qinglong-app](https://github.com/ayoulx/qinglong-app) | 2025-07-22 | AGPL-3.0，同源延续版本 |
| [a417039669/qinglong_app](https://github.com/a417039669/qinglong_app) | 2022-04-25 | AGPL-3.0，较早版本，包含预编译 APK |
| [nzmd/qinglong_app](https://github.com/nzmd/qinglong_app) | 2022-01-26 | Apache-2.0，版本更早 |
| [LinxiDev/qinglong-app](https://github.com/LinxiDev/qinglong-app) | 2026-05-13 | **选用**：旧版业务改动小，准确提交存在成功 Android 构建记录 |
| [Frrostless/qinglong-app](https://github.com/Frrostless/qinglong-app) | 2026-06-10 | AGPL-3.0，Dart 3 及界面重做，未查到 Actions 构建记录 |
| [zhengsh2822/qinglong_app_glass](https://github.com/zhengsh2822/qinglong_app_glass) | 2026-09-06 | AGPL-3.0，持续更新，加入玻璃效果组件；查到 iOS 构建证据，不能当作 Android 证据 |

重点克隆检查了 lffw001、LinxiDev、Frrostless 和 glass 四个项目；其余通过 GitHub 仓库元数据、文件清单和提交信息比较。并非对所有候选做了完整代码审计。

## 导入基线

- 源仓库：https://github.com/LinxiDev/qinglong-app
- 分支：`main`
- 提交：`d1b6150a464e849df9c89f863a5e21b6183500f4`
- [该提交成功的 Android 构建](https://github.com/LinxiDev/qinglong-app/actions/runs/25785637994)
- LinxiDev 相对 lffw001 当前快照的 `lib/` 差异仅在 `api.dart`、`url.dart`、`about_page.dart` 三个文件，共 6 行新增、5 行删除。
- 其近期其他提交的失败来自 Dart >=3.10 要求与 Flutter 3.3.10 自带 Dart 2.18.6 不匹配；这不是默认分支基线的同一提交。失败记录：https://github.com/LinxiDev/qinglong-app/actions/runs/34008183279

通过源码快照创建新的 Git 历史，未创建 GitHub Fork 关系。继承 LICENSE 和原代码声明，当前修改由本仓库提交历史记录。旧 APK 仅作为本地参考，没有上传到仓库。

原 README 保存在 [UPSTREAM_README.md](UPSTREAM_README.md)。LinxiDev 致谢 ayoulx/qinglong-app；lffw001 README 指向历史 qinglongapp/qinglong_app。进一步完整谱系未验证。感谢各原作者及 [whyour/qinglong](https://github.com/whyour/qinglong)。

## 继承代码的边界

源码中的会员/赞助文案、iCloud、iOS 商店等历史内容并不代表本维护版提供相关服务。保留 iOS 源文件用于记录来源，但当前只构建 Android。未声称该源码就是用户提供的 2.7.2 APK 的精确可复现源码。
