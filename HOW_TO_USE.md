
arch -x86_64 pod install

## GitHub Actions 构建与发布

当前自动化流程只负责 Android APK。

### 日常构建

推送代码或提交 Pull Request 后，会自动运行 `Android 日常构建`：

```bash
git add .
git commit -m "fix: 修复问题"
git push origin main
```

构建完成后，在 GitHub 仓库中打开：

```text
Actions -> Android 日常构建 -> Artifacts -> android-release-apk
```

下载后可得到：

```text
app-release.apk
```

### 正式发布

推荐使用版本标签发布，这是最常见、最清晰的 GitHub Actions 发布方式：

```bash
git tag v1.0.0
git push origin v1.0.0
```

推送 `v*` 标签后，会自动运行 `Android 正式发布`，并创建 GitHub Release：

```text
Releases -> v1.0.0 -> qinglong_app-1.0.0.apk
```

### 手动发布

也可以在 GitHub 页面手动发布：

```text
Actions -> Android 正式发布 -> Run workflow
```

`version` 可填写：

```text
1.0.0
v1.0.0
auto
```

填写 `auto` 时，会读取最新的 `v*` 标签，并自动递增 Patch 版本。例如当前最新是 `v1.0.0`，则自动发布 `v1.0.1`。

### Android 签名配置

如需生成正式签名 APK，在 GitHub 仓库中打开：

```text
Settings -> Secrets and variables -> Actions -> New repository secret
```

配置以下密钥：

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

Windows PowerShell 生成 `ANDROID_KEYSTORE_BASE64`：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release.keystore")) | Set-Clipboard
```

macOS 生成 `ANDROID_KEYSTORE_BASE64`：

```bash
base64 -i release.keystore | pbcopy
```

如果没有配置签名密钥，流程仍会完成构建，但会使用兜底签名，适合测试，不建议作为正式分发包。

使用它替代pod install

用于生成app的图标

flutter pub run flutter_launcher_icons:main
生成原生的启动页面

flutter pub run flutter_native_splash:create
修改app名称

flutter pub run flutter_app_name

生成json.jc.dart文件
flutter pub run build_runner build --delete-conflicting-outputs

sudo arch -x86_64 gem install ffi
# go to ios folder then run
arch -x86_64 pod install
