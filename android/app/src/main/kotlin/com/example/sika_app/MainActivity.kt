package com.example.sika_app

import android.content.Intent
import android.media.AudioManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// AudioServiceActivity : nécessaire pour la lecture en arrière-plan.
class MainActivity : AudioServiceActivity() {
    private val transfer by lazy { LibraryTransfer(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        NewPipeBridge.register(messenger)
        transfer.register(messenger)

        // Stockage public : dossier Music et indexation par la médiathèque Android.
        MethodChannel(messenger, "youplay/media").setMethodCallHandler { call, result ->
            when (call.method) {
                "musicDir" -> result.success(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC).absolutePath,
                )
                "picturesDir" -> result.success(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES).absolutePath,
                )
                "scan" -> {
                    MediaStoreScan.scan(this, call.argument<String>("path")!!)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Mises à jour : version installée, ABI du téléphone, ouverture de l'installateur Android.
        MethodChannel(messenger, "youplay/update").setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> {
                    val info = packageManager.getPackageInfo(packageName, 0)
                    val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode else @Suppress("DEPRECATION") info.versionCode.toLong()
                    result.success(mapOf("versionCode" to code, "versionName" to info.versionName, "abis" to Build.SUPPORTED_ABIS.toList(), "packageName" to packageName))
                }
                "install" -> {
                    val file = File(call.argument<String>("path")!!)
                    val uri = FileProvider.getUriForFile(this, "$packageName.updates", file)
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Appel en cours (sonnerie, GSM, VoIP) : sert à reprendre la musique à la fin d'un appel sur MIUI.
        MethodChannel(messenger, "youplay/audio").setMethodCallHandler { call, result ->
            when (call.method) {
                "inCall" -> {
                    val am = getSystemService(AUDIO_SERVICE) as AudioManager
                    result.success(am.mode != AudioManager.MODE_NORMAL)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Résultats des sélecteurs de fichiers et de la confirmation de suppression Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!transfer.onActivityResult(requestCode, resultCode, data)) {
            @Suppress("DEPRECATION")
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}

/** Signale un fichier à la médiathèque Android (apps musique, explorateur). */
object MediaStoreScan {
    fun scan(context: android.content.Context, path: String) {
        val mime = if (path.endsWith(".png")) "image/png" else "audio/mp4"
        MediaScannerConnection.scanFile(context.applicationContext, arrayOf(path), arrayOf(mime), null)
    }
}
