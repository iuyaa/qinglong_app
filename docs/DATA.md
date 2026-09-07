# 当前版本的数据说明

本 App 是青龙面板客户端。使用时将连接你填写的面板地址，向该面板发送登录凭据及你发起的管理请求。

当前版本沿用上游的本地账号保存机制，使用 SharedPreferences 等本地存储；尚未完成迁移至 Android Keystore 保护的存储或全面安全审计。

共享 HTTP 客户端已移除请求内容日志及接受任意 HTTPS 证书的回调。其他历史代码、外部编辑器 CDN、分享和外链行为仍待完整审查。此说明不是“绝不访问第三方”的承诺。

GitHub Actions 仅构建源码，不需要面板地址、账号密码或面板 API 密钥。请勿将这些内容提交到仓库或 Actions 配置。

问题反馈与源码：https://github.com/iuyaa/qinglong_app
