package work.newtab.qinglong

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import java.security.MessageDigest

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "io.github.iuyaa.qinglong/update")
            .setMethodCallHandler { call, result ->
                if (call.method != "verify" && call.method != "install") {
                    result.notImplemented()
                } else {
                    // Hashing the APK must not block Flutter's UI thread.
                    Thread {
                        try {
                            val file = File(call.argument<String>("path") ?: "").canonicalFile
                            require(file == File(cacheDir, "updates/qinglong-update.apk").canonicalFile && file.isFile)
                            val digest = MessageDigest.getInstance("SHA-256")
                            file.inputStream().use { input ->
                                val buffer = ByteArray(65536)
                                while (true) {
                                    val count = input.read(buffer)
                                    if (count < 0) break
                                    digest.update(buffer, 0, count)
                                }
                            }
                            require(digest.digest().joinToString("") { "%02x".format(it) } == call.argument<String>("sha256"))
                            @Suppress("DEPRECATION")
                            val archive = packageManager.getPackageArchiveInfo(file.path, PackageManager.GET_SIGNATURES)
                                ?: throw IllegalArgumentException()
                            @Suppress("DEPRECATION")
                            val installed = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                            require(archive.packageName == packageName)
                            @Suppress("DEPRECATION")
                            val nextCode = if (Build.VERSION.SDK_INT >= 28) archive.longVersionCode else archive.versionCode.toLong()
                            @Suppress("DEPRECATION")
                            val currentCode = if (Build.VERSION.SDK_INT >= 28) installed.longVersionCode else installed.versionCode.toLong()
                            require(nextCode > currentCode && nextCode == call.argument<Number>("code")?.toLong())
                            @Suppress("DEPRECATION")
                            val newSignatures = archive.signatures?.map { it.toCharsString() }?.toSet()
                            @Suppress("DEPRECATION")
                            val oldSignatures = installed.signatures?.map { it.toCharsString() }?.toSet()
                            require(!newSignatures.isNullOrEmpty() && newSignatures == oldSignatures)
                            runOnUiThread {
                                try {
                                    if (call.method == "verify") result.success("verified")
                                    else if (Build.VERSION.SDK_INT >= 26 && !packageManager.canRequestPackageInstalls()) {
                                        startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                                        result.success("permission")
                                    } else {
                                        val uri = FileProvider.getUriForFile(this, "$packageName.updates", file)
                                        startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/vnd.android.package-archive")
                                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                                        result.success("opened")
                                    }
                                } catch (_: Exception) { result.error("INSTALL_FAILED", "无法打开安装界面", null) }
                            }
                        } catch (_: Exception) {
                            runOnUiThread { result.error("INVALID_UPDATE", "安装包校验失败", null) }
                        }
                    }.start()
                }
            }
    }
}
