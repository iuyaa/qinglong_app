# 构建验收记录 001

- 日期：2026-09-07
- 仓库：https://github.com/iuyaa/qinglong_app （public，fork=false）
- 构建提交：`d16824888cf37203a2ef53139385a59a428dcd05`
- Actions：https://github.com/iuyaa/qinglong_app/actions/runs/34085192644
- 产物：`qinglong-android-1`，Artifact ID `10005095299`

## 已执行验证

| 命令/检查 | 结果 |
| --- | --- |
| `flutter pub get` 与 `git diff --exit-code -- pubspec.lock` | PASS，锁文件未变化 |
| `flutter test test/http_test.dart` | PASS，1 个测试，覆盖日志文本、401、502 和非 JSON 响应 |
| `flutter build apk --release --build-name=3.0.1 --build-number=1` | PASS，25.3 MB |
| `apksigner verify --verbose --print-certs` | PASS，v1/v2 签名通过，RSA 3072 |
| 下载后 SHA256 对照与 Python `ZipFile.testzip()` | PASS，文件与云端校验值一致，ZIP 完整 |
| Apktool 解码成品 Manifest/版本 | PASS，包名 `io.github.iuyaa.qinglong`，版本 3.0.1+1，minSdk 21、targetSdk 33 |
| 已暂存文件凭据特征检查 | PASS；参考 APK、研究资料及签名备份未加入 Git |
| `git diff --cached --check`（首次导入） | 5 处上游空白警告，保留原样；不是代码验证失败 |

签名证书 SHA256：`076dbcb13c02831c52f78abcf9fbe0460ee522bc78763970ae487ad402fa7c12`。

本地文件：`artifacts/build-1/qinglong-android.apk`，26,522,067 字节。

APK SHA256：`6c2902f2f41f1f986c996e0c2fd09146eb940b3652d823ed89cb6abd4cd48677`。

## 验证限制

- 完整 `flutter analyze`：NOT_RUN。
- Android 真机启动、页面点击与实际登录：NOT_RUN。
- 当前青龙面板的接口兼容性与任务执行：NOT_RUN，未操作真实面板。
- 继承功能与本地账号存储的全面审计：NOT_RUN。
- 工具链仍为上游旧版，现代 Android/应用商店要求需要另行升级验证。
- 验签日志含旧依赖 META-INF 条目在 v1 下未保护的警告；命令整体通过，v2 验证通过。未声称日志零警告。

签名密钥另存于本地忽略目录 `.private/`，需要独立私密备份，不上传 GitHub 代码或产物。
