package com.example.sika_app

import android.app.Activity
import android.content.ClipData
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Sauvegarde de la bibliothèque dans un fichier, et déménagement de l'ancienne app
 * (`com.example.sika_app`) vers la nouvelle (`io.github.cianusdev.youplay`).
 *
 * Le même code tourne dans les deux apps : l'identifiant installé décide du rôle.
 * - l'ancienne envoie sa bibliothèque à la nouvelle (fichier partagé via FileProvider) ;
 * - la nouvelle n'accepte que des données venant de l'ancienne signée avec la même clé ;
 * - les sons téléchargés appartiennent à l'ancienne app (Android 11+) : la nouvelle les
 *   « reprend » en les recopiant, après une seule confirmation Android pour supprimer les originaux.
 */
class LibraryTransfer(private val activity: Activity) {
    companion object {
        const val LEGACY_ID = "com.example.sika_app"
        const val NEW_ID = "io.github.cianusdev.youplay"
        const val ACTION_IMPORT = "io.github.cianusdev.youplay.IMPORT_LIBRARY"
        const val EXTRA_REQUEST = "youplay.transferTo"
        private const val REQ_SAVE = 7301
        private const val REQ_OPEN = 7302
        private const val REQ_ADOPT = 7303
    }

    private val pm get() = activity.packageManager
    private val own get() = activity.packageName
    private val other get() = if (own == LEGACY_ID) NEW_ID else LEGACY_ID

    private var pendingImport: String? = null
    private var pendingRequest = false
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
                        "isLegacy" to (own == LEGACY_ID),
                        "isNew" to (own == NEW_ID),
                        "otherReady" to otherReady(),
                        "sdk" to Build.VERSION.SDK_INT,
                    ),
                )
                "save" -> save(call.argument<String>("name")!!, call.argument<String>("content")!!, result)
                "open" -> open(result)
                "takeImport" -> result.success(pendingImport.also { pendingImport = null })
                "takeRequest" -> result.success(pendingRequest.also { pendingRequest = false })
                "send" -> result.success(send(call.argument<String>("content")!!))
                "request" -> result.success(launchOther { putExtra(EXTRA_REQUEST, own) })
                // Toujours l'ancienne app, qu'on soit l'une ou l'autre : Android demande confirmation.
                "uninstallLegacy" -> {
                    val ok = installed(LEGACY_ID)
                    if (ok) activity.startActivity(Intent(Intent.ACTION_DELETE, Uri.parse("package:$LEGACY_ID")))
                    result.success(ok)
                }
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

    // --- Déménagement ---------------------------------------------------------------------------

    private fun installed(pkg: String) = try {
        pm.getPackageInfo(pkg, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    /** Même clé de signature : seule une vraie YouPlay peut envoyer ou recevoir la bibliothèque. */
    private fun sameSigner(pkg: String) = pm.checkSignatures(pkg, own) == PackageManager.SIGNATURE_MATCH

    /** L'autre app est installée, signée par nous, et sait faire le transfert. */
    private fun otherReady(): Boolean {
        if (own != LEGACY_ID && own != NEW_ID) return false
        if (!installed(other) || !sameSigner(other)) return false
        return try {
            (pm.getApplicationInfo(other, PackageManager.GET_META_DATA).metaData?.getInt("youplay.transfer", 0) ?: 0) >= 1
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    /** Ouvre l'autre app ; [intent] null = son écran d'accueil (intent du lanceur). */
    private fun launchOther(intent: Intent? = null, configure: Intent.() -> Unit = {}): Boolean {
        if (!otherReady()) return false
        val launch = pm.getLaunchIntentForPackage(other) ?: return false
        val target = intent?.apply { component = launch.component } ?: launch
        target.configure()
        target.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        activity.startActivity(target)
        return true
    }

    /** Ancienne app → nouvelle : la bibliothèque passe par un fichier lisible une seule fois. */
    private fun send(content: String): Boolean {
        if (own != LEGACY_ID) return false
        val dir = File(activity.cacheDir, "transfer").apply { mkdirs() }
        val file = File(dir, "library.json").apply { writeText(content) }
        val uri = FileProvider.getUriForFile(activity, "$own.updates", file)
        // Fichier en ClipData (pas en data) : l'intent correspond ainsi au filtre IMPORT_LIBRARY
        // déclaré par la nouvelle app, exigé par Android 14+ même pour un intent explicite.
        return launchOther(Intent(ACTION_IMPORT)) {
            clipData = ClipData.newRawUri(null, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    /** Appelé au lancement et à chaque nouvel intent. */
    fun handleIntent(intent: Intent?) {
        intent ?: return
        if (own == LEGACY_ID && intent.getStringExtra(EXTRA_REQUEST) == NEW_ID && otherReady()) {
            pendingRequest = true
            intent.removeExtra(EXTRA_REQUEST)
        }
        if (own == NEW_ID && intent.action == ACTION_IMPORT) {
            val uri = intent.clipData?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.uri
            // L'autorité « com.example.sika_app.updates » est unique sur le téléphone : si l'ancienne
            // app est installée et signée par nous, le fichier vient forcément d'elle.
            if (uri != null && uri.authority == "$LEGACY_ID.updates" && installed(LEGACY_ID) && sameSigner(LEGACY_ID)) {
                pendingImport = try {
                    activity.contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
                } catch (_: Exception) {
                    null
                }
            }
            intent.action = Intent.ACTION_MAIN
            intent.clipData = null
        }
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

    private fun adopt(paths: List<String>, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return result.success(0)
        val files = mutableListOf<Pair<File, File>>()
        val uris = mutableListOf<Uri>()
        val table = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        for (path in paths) {
            val original = File(path)
            if (!original.exists()) continue
            val (id, owner) = activity.contentResolver.query(
                table,
                arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.OWNER_PACKAGE_NAME),
                "${MediaStore.MediaColumns.DATA}=?",
                arrayOf(path),
                null,
            )?.use { c -> if (c.moveToFirst()) c.getLong(0) to c.getString(1) else null } ?: continue
            if (owner == own) continue
            val copy = File(original.parentFile, ".${original.name}.youplay.m4a")
            try {
                original.copyTo(copy, overwrite = true)
            } catch (_: Exception) {
                copy.delete()
                break // plus de place : les sons restants restent lisibles, simplement pas déplaçables
            }
            files += original to copy
            uris += ContentUris.withAppendedId(table, id)
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
