package com.example.sika_app

import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * Sauvegarde de la bibliothèque dans un fichier, et passage de l'ancienne app
 * (`com.example.sika_app`, signée avec une clé de debug) à la nouvelle (`io.github.cianusdev.youplay`).
 *
 * Les deux apps n'ont pas la même clé : la bibliothèque passe par un fichier (Exporter dans
 * l'ancienne, Restaurer dans la nouvelle). Les sons téléchargés appartiennent à l'ancienne app
 * (Android 11+) : la nouvelle les « reprend » en les recopiant, après une seule confirmation
 * Android pour supprimer les originaux.
 */
class LibraryTransfer(private val activity: Activity) {
    companion object {
        const val LEGACY_ID = "com.example.sika_app"

        /** Certificat (public) de l'ancienne YouPlay : on ne propose pas de désinstaller une autre app. */
        private const val LEGACY_CERT_SHA256 = "104fae1ca60c5904feda9a30d272517d82b89b7b86fe36834f9580178fef5c55"
        private const val REQ_SAVE = 7301
        private const val REQ_OPEN = 7302
        private const val REQ_ADOPT = 7303
    }

    private val pm get() = activity.packageManager
    private val own get() = activity.packageName

    private var saveResult: MethodChannel.Result? = null
    private var saveContent: String? = null
    private var openResult: MethodChannel.Result? = null
    private var adoptResult: MethodChannel.Result? = null
    private var adoptFiles: List<Pair<File, File>> = emptyList()

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "youplay/backup").setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> result.success(
                    mapOf(
                        "packageName" to own,
                        "legacyInstalled" to (own != LEGACY_ID && legacyInstalled()),
                        "sdk" to Build.VERSION.SDK_INT,
                    ),
                )
                "save" -> save(call.argument<String>("name")!!, call.argument<String>("content")!!, result)
                "open" -> open(result)
                // Ouvre l'ancienne YouPlay (pour y exporter la bibliothèque).
                "openLegacy" -> {
                    val intent = if (legacyInstalled()) pm.getLaunchIntentForPackage(LEGACY_ID) else null
                    intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)?.let { activity.startActivity(it) }
                    result.success(intent != null)
                }
                // Android demande confirmation.
                "uninstallLegacy" -> {
                    val ok = legacyInstalled()
                    if (ok) activity.startActivity(Intent(Intent.ACTION_DELETE, Uri.parse("package:$LEGACY_ID")))
                    result.success(ok)
                }
                "foreign" -> result.success(foreign(call.argument<List<String>>("paths")!!).size)
                "adopt" -> adopt(call.argument<List<String>>("paths")!!, result)
                "restart" -> {
                    // Les préférences Flutter sont écrites en différé (apply) : on force l'écriture avant de quitter.
                    activity.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit().commit()
                    pm.getLaunchIntentForPackage(own)?.let {
                        it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                        activity.startActivity(it)
                    }
                    result.success(null)
                    Runtime.getRuntime().exit(0)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** L'ancienne YouPlay est installée, et c'est bien la nôtre (même certificat). */
    @Suppress("DEPRECATION")
    private fun legacyInstalled(): Boolean = try {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            pm.getPackageInfo(LEGACY_ID, PackageManager.GET_SIGNING_CERTIFICATES).signingInfo?.apkContentsSigners
        } else {
            pm.getPackageInfo(LEGACY_ID, PackageManager.GET_SIGNATURES).signatures
        }
        signatures.orEmpty().any { sig ->
            MessageDigest.getInstance("SHA-256").digest(sig.toByteArray()).joinToString("") { "%02x".format(it) } == LEGACY_CERT_SHA256
        }
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    // --- Fichier de sauvegarde ------------------------------------------------------------------

    private fun save(name: String, content: String, result: MethodChannel.Result) {
        saveResult?.success(null)
        saveResult = result
        saveContent = content
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(Intent.EXTRA_TITLE, name)
        }
        activity.startActivityForResult(intent, REQ_SAVE)
    }

    private fun open(result: MethodChannel.Result) {
        openResult?.success(null)
        openResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            // Certains gestionnaires de fichiers étiquettent mal le JSON : on laisse tout choisir.
            type = "*/*"
        }
        activity.startActivityForResult(intent, REQ_OPEN)
    }

    // --- Reprise des sons téléchargés par l'ancienne app ----------------------------------------

    /** Sons présents mais appartenant à une autre app (Android 11+) : id MediaStore par fichier. */
    private fun foreign(paths: List<String>): List<Pair<File, Long>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return emptyList()
        val out = mutableListOf<Pair<File, Long>>()
        for (path in paths) {
            val file = File(path)
            if (!file.exists()) continue
            val (id, owner) = activity.contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.OWNER_PACKAGE_NAME),
                "${MediaStore.MediaColumns.DATA}=?",
                arrayOf(path),
                null,
            )?.use { c -> if (c.moveToFirst()) c.getLong(0) to c.getString(1) else null } ?: continue
            if (owner != own) out += file to id
        }
        return out
    }

    private fun adopt(paths: List<String>, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return result.success(0)
        val files = mutableListOf<Pair<File, File>>()
        val uris = mutableListOf<Uri>()
        for ((original, id) in foreign(paths)) {
            val copy = File(original.parentFile, ".${original.name}.youplay.m4a")
            try {
                original.copyTo(copy, overwrite = true)
            } catch (_: Exception) {
                copy.delete()
                break // plus de place : les sons restants restent lisibles, simplement pas déplaçables
            }
            files += original to copy
            uris += ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
        }
        if (uris.isEmpty()) return result.success(0)
        adoptResult = result
        adoptFiles = files
        val request = MediaStore.createDeleteRequest(activity.contentResolver, uris)
        activity.startIntentSenderForResult(request.intentSender, REQ_ADOPT, null, 0, 0, 0)
    }

    private fun finishAdopt(ok: Boolean) {
        var count = 0
        for ((original, copy) in adoptFiles) {
            if (ok && !original.exists() && copy.renameTo(original)) {
                count++
                MediaStoreScan.scan(activity, original.path)
            } else {
                copy.delete()
            }
        }
        adoptFiles = emptyList()
        adoptResult?.success(if (ok) count else -1)
        adoptResult = null
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            REQ_SAVE -> {
                val uri = data?.data
                val ok = resultCode == Activity.RESULT_OK && uri != null && try {
                    activity.contentResolver.openOutputStream(uri, "wt")?.use { it.write(saveContent!!.toByteArray()) } != null
                } catch (_: Exception) {
                    false
                }
                saveResult?.success(if (resultCode == Activity.RESULT_OK) ok else null)
                saveResult = null
                saveContent = null
            }
            REQ_OPEN -> {
                val uri = data?.data
                val text = if (resultCode == Activity.RESULT_OK && uri != null) {
                    try {
                        activity.contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
                    } catch (_: Exception) {
                        ""
                    }
                } else {
                    null
                }
                openResult?.success(text)
                openResult = null
            }
            REQ_ADOPT -> finishAdopt(resultCode == Activity.RESULT_OK)
            else -> return false
        }
        return true
    }
}
