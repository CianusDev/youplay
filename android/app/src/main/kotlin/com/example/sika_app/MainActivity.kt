package com.example.sika_app

import android.media.MediaScannerConnection
import android.os.Environment
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity : nécessaire pour la lecture en arrière-plan.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        NewPipeBridge.register(messenger)

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
                    val path = call.argument<String>("path")!!
                    val mime = if (path.endsWith(".png")) "image/png" else "audio/mp4"
                    MediaScannerConnection.scanFile(applicationContext, arrayOf(path), arrayOf(mime), null)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
