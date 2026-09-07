# qinglong-app — 青龙面板客户端

> 基于 **Flutter** 开发的青龙面板第三方移动客户端，支持 Android / iOS 双端，可在手机上完整管理青龙面板的任务、订阅、环境变量、脚本、依赖、配置、日志等核心功能。

| 项目性质 | 上游依赖 | 维护者 |
|:---:|:---:|:---:|
| 客户端 App（非服务端） | [whyour/qinglong](https://github.com/whyour/qinglong) | yanyu |

---

## 功能特性

### 账号与登录

- **多账号管理**：支持同时添加多个青龙面板账号，账号间数据与会话完全隔离，一键切换
- **账号密码登录**：对接常规 `/api/*` 接口
- **OpenAPI 登录**：使用 `client_id / client_secret` 对接 `/open/*` 接口（部分功能需在面板侧分配对应 scope 权限）

### 核心管理功能

| 模块 | 功能说明 |
|---|---|
| **定时任务** | 查看、搜索、启停、置顶、手动运行、编辑任务 |
| **订阅管理** | 订阅列表、运行/停止、启用/禁用、日志查看 |
| **环境变量** | 增删改查、批量操作、启用/禁用、搜索、排序移动 |
| **配置文件** | 文件列表、内容查看、在线编辑与保存 |
| **脚本管理** | 目录浏览、查看、在线编辑、上传/新增/删除 |
| **依赖管理** | 依赖列表、安装/卸载/重装、查看安装日志 |
| **日志中心** | 任务运行日志、登录日志（OpenAPI 模式下可能受限） |
| **系统信息** | 面板版本、系统状态等信息展示 |
| **应用管理** | 应用列表与搜索、新增/编辑/删除应用、重置 Secret |

### 其他

- 主题切换（亮色 / 暗色）
- 文字缩放与基础显示设置
- 内置二维码扫描快速登录
- 代码编辑器（基于 CodeMirror）
- iCloud 数据同步支持（iOS）
- 应用内购与赞助页面

---

## 接口说明

本项目对接青龙面板两套接口体系：

```
常规登录  →  /api/*
OpenAPI   →  /open/*
```

> 使用 OpenAPI（`client_id/client_secret`）登录时，若接口返回 `401` 或 `404`，通常是面板侧未为该应用分配对应权限（scope），请在面板「应用管理」中检查并授权。

---

## 代码结构

```
lib/
├── main.dart                  # 应用入口，多账号容器与全局初始化
├── base/                      # 基础设施层
│   ├── http/                  # HTTP 封装、Token 拦截器、接口定义
│   ├── theme.dart             # 主题配置
│   ├── routes.dart            # 路由管理
│   └── ...                    # 通用 UI 组件、ViewModel 基类等
└── module/                    # 业务模块
    ├── home/                  # 首页 & 系统信息
    ├── task/                  # 定时任务
    ├── subscribe/             # 订阅管理
    ├── env/                   # 环境变量
    ├── config/                # 配置文件
    ├── others/                # 脚本、依赖、日志、关于等
    ├── appkey/                # 应用管理（Apps / AppKeys）
    ├── login/                 # 登录页面
    ├── code_editor/           # 内置代码编辑器
    └── ...                    # 设置、订阅、推送、扫描等页面
```

---

## 快速开始

### 环境要求

- Flutter SDK（版本要求见 `pubspec.yaml`）
- Android Studio / Xcode（对应平台构建工具）

### 运行

```bash
# 获取依赖
flutter pub get

# 连接设备后运行
flutter run
```

### 构建发布包

```bash
# Android APK
flutter build apk --release

# iOS（需 macOS + Xcode）
flutter build ios --release
```

---

## 致谢

- 青龙面板：[whyour/qinglong](https://github.com/whyour/qinglong)
- 原项目参考：[ayoulx/qinglong-app](https://github.com/ayoulx/qinglong-app)




