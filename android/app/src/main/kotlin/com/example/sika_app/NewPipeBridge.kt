package com.example.sika_app

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import okhttp3.OkHttpClient
import okhttp3.RequestBody.Companion.toRequestBody
import org.schabi.newpipe.extractor.Image
import org.schabi.newpipe.extractor.channel.ChannelInfoItem
import org.schabi.newpipe.extractor.stream.StreamType
import org.schabi.newpipe.extractor.InfoItem
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.ReCaptchaException
import org.schabi.newpipe.extractor.localization.ContentCountry
import org.schabi.newpipe.extractor.localization.Localization
import org.schabi.newpipe.extractor.playlist.PlaylistInfo
import org.schabi.newpipe.extractor.playlist.PlaylistInfoItem
import org.schabi.newpipe.extractor.search.SearchInfo
import org.schabi.newpipe.extractor.services.youtube.linkHandler.YoutubeSearchQueryHandlerFactory
import org.schabi.newpipe.extractor.stream.AudioStream
import org.schabi.newpipe.extractor.stream.DeliveryMethod
import org.schabi.newpipe.extractor.stream.StreamInfo
import org.schabi.newpipe.extractor.stream.StreamInfoItem
import org.schabi.newpipe.extractor.MediaFormat
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/** Downloader HTTP minimal pour NewPipeExtractor (calqué sur celui de NewPipe). */
private class OkDownloader : Downloader() {
    private val client = OkHttpClient.Builder().readTimeout(30, TimeUnit.SECONDS).build()

    override fun execute(request: Request): Response {
        val body = request.dataToSend()?.toRequestBody()
        val builder = okhttp3.Request.Builder()
            .method(request.httpMethod(), body)
            .url(request.url())
            .addHeader("User-Agent", USER_AGENT)
        request.headers().forEach { (name, values) ->
            builder.removeHeader(name)
            values.forEach { builder.addHeader(name, it) }
        }
        client.newCall(builder.build()).execute().use { res ->
            if (res.code == 429) throw ReCaptchaException("reCaptcha demandé", request.url())
            return Response(res.code, res.message, res.headers.toMultimap(), res.body?.string(), res.request.url.toString())
        }
    }

    companion object {
        const val USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0"
    }
}

/**
 * Canal "sika/newpipe" : recherche YouTube Music, albums, flux audio, titres liés.
 * Toutes les opérations réseau tournent hors du thread UI.
 */
object NewPipeBridge {
    private val pool = Executors.newFixedThreadPool(3)
    private val main = Handler(Looper.getMainLooper())
    private val yt get() = ServiceList.YouTube
    @Volatile private var ready = false

    private fun ensureInit() {
        if (ready) return
        synchronized(this) {
            if (!ready) {
                NewPipe.init(OkDownloader(), Localization("fr", "FR"), ContentCountry("FR"))
                ready = true
            }
        }
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "sika/newpipe").setMethodCallHandler { call, result ->
            pool.execute {
                try {
                    ensureInit()
                    val value = handle(call)
                    main.post { result.success(value) }
                } catch (e: NotImplementedError) {
                    main.post { result.notImplemented() }
                } catch (e: Throwable) {
                    main.post { result.error("newpipe", e.message ?: e.javaClass.simpleName, null) }
                }
            }
        }
    }

    private fun handle(call: MethodCall): Any? = when (call.method) {
        "searchSongs" -> searchSongs(call.argument<String>("query")!!)["songs"]
        "searchTop" -> searchSongs(call.argument<String>("query")!!)
        "searchArtists" -> searchArtists(call.argument<String>("query")!!)
        "suggestions" -> yt.suggestionExtractor.suggestionList(call.argument<String>("query")!!).take(8)
        "searchVideos" -> search(call.argument<String>("query")!!, YoutubeSearchQueryHandlerFactory.VIDEOS)
        "searchAlbums" -> searchAlbums(call.argument<String>("query")!!)
        "playlist" -> playlist(call.argument<String>("url")!!)
        "audioStream" -> audioStream(call.argument<String>("id")!!)
        "related" -> related(call.argument<String>("id")!!)
        else -> throw NotImplementedError()
    }

    // ------------------------------------------------------------------------
    // Recherche « intelligente »
    // ------------------------------------------------------------------------

    /**
     * Titres : YouTube Music d'abord ; s'il ne renvoie rien (cas actuel de l'extracteur v0.26.5),
     * on prend 2 pages de vidéos, on écarte le bruit (reprises, réactions, karaoké…),
     * on dédoublonne (clip / audio / paroles du même titre) et on trie par pertinence.
     * Renvoie {songs, suggestion (« Vouliez-vous dire »), corrected}.
     */
    private fun searchSongs(query: String): Map<String, Any?> {
        val music = runCatching { search(query, YoutubeSearchQueryHandlerFactory.MUSIC_SONGS) }.getOrDefault(emptyList())
        if (music.isNotEmpty()) return mapOf("songs" to music, "suggestion" to null, "corrected" to false)

        val handler = yt.searchQHFactory.fromQuery(query, listOf(YoutubeSearchQueryHandlerFactory.VIDEOS), "")
        val info = SearchInfo.getInfo(yt, handler)
        val raw = info.relatedItems.toMutableList()
        if (info.hasNextPage()) {
            runCatching { raw += SearchInfo.getMoreItems(yt, handler, info.nextPage).items }
        }
        val q = tokens(query)
        val best = LinkedHashMap<String, Pair<Double, Map<String, Any?>>>()
        raw.filterIsInstance<StreamInfoItem>().forEachIndexed { index, it ->
            val dur = it.duration
            if (dur !in 60L..900L || it.isShortFormContent) return@forEachIndexed
            if (it.streamType != StreamType.VIDEO_STREAM) return@forEachIndexed
            val song = asSong(item(it)!!)
            val score = scoreSong(q, it, song, index)
            if (score <= -50) return@forEachIndexed
            val key = norm(song["artist"] as String) + "|" + norm(song["title"] as String)
            if ((best[key]?.first ?: Double.NEGATIVE_INFINITY) < score) best[key] = score to song
        }
        val songs = best.values.sortedByDescending { it.first }.map { it.second }.take(30)
        return mapOf(
            "songs" to songs,
            "suggestion" to info.searchSuggestion?.takeIf { it.isNotBlank() },
            "corrected" to info.isCorrectedSearch,
        )
    }

    private val penalties = listOf(
        "cover", "reprise", "reaction", "réaction", "react", "karaoke", "karaoké", "instrumental",
        "remix", "live", "en live", "acoustic", "acoustique", "nightcore", "slowed", "sped up",
        "speed up", "8d", "1 hour", "1h", "loop", "tuto", "tutorial", "parodie", "parody",
        "interview", "making of", "behind the scenes", "teaser", "trailer", "extrait", "snippet",
    )
    private val officialMarks = listOf("official audio", "audio officiel", "clip officiel", "official video", "official music video", "visualizer")

    private fun scoreSong(q: List<String>, item: StreamInfoItem, song: Map<String, Any?>, index: Int): Double {
        val title = norm(item.name ?: "")
        val uploader = item.uploaderName ?: ""
        val haystack = "$title ${norm(uploader)} ${norm(song["artist"] as String)}"
        var score = 0.0
        // Couverture de la requête : mots de la recherche présents dans titre + artiste.
        if (q.isNotEmpty()) score += 45.0 * q.count { w -> haystack.contains(w) } / q.size
        // Sources officielles.
        if (uploader.endsWith(" - Topic")) score += 25
        if (item.isUploaderVerified) score += 15
        if (officialMarks.any { mark -> title.contains(norm(mark)) }) score += 10
        // Popularité (échelle logarithmique) et ordre proposé par YouTube.
        if (item.viewCount > 0) score += 3.0 * kotlin.math.log10(item.viewCount.toDouble())
        score += (40 - index).coerceAtLeast(0) * 0.4
        // Versions non désirées, sauf si la recherche les demande.
        for (p in penalties) {
            val np = norm(p)
            val inTitle = Regex("""(^|\s)${Regex.escape(np)}(\s|$)""").containsMatchIn(title)
            if (inTitle && q.none { w -> np.contains(w) }) score -= 30
        }
        if (title.contains("lyrics") || title.contains("paroles")) score -= 4
        return score
    }

    /** Chaînes d'artistes (avec photo), triées par pertinence. */
    private fun searchArtists(query: String): List<Map<String, Any?>> {
        val handler = yt.searchQHFactory.fromQuery(query, listOf(YoutubeSearchQueryHandlerFactory.CHANNELS), "")
        val nq = norm(query)
        return SearchInfo.getInfo(yt, handler).relatedItems
            .filterIsInstance<ChannelInfoItem>()
            .map { c ->
                val name = cleanArtist(c.name ?: "")
                val nn = norm(name)
                var score = 0.0
                if (nn == nq) score += 60 else if (nn.startsWith(nq) || nq.startsWith(nn)) score += 35 else if (nn.contains(nq)) score += 15
                if (c.isVerified) score += 25
                if (c.subscriberCount > 0) score += 4.0 * kotlin.math.log10(c.subscriberCount.toDouble())
                score to mapOf(
                    "name" to name,
                    "url" to c.url,
                    "thumbnail" to best(c.thumbnails),
                    "subscribers" to c.subscriberCount,
                    "verified" to c.isVerified,
                    "exact" to (nn == nq),
                )
            }
            .filter { it.first > 10 }
            .sortedByDescending { it.first }
            .map { it.second }
            .distinctBy { norm(it["name"] as String) }
            .take(6)
    }

    /** Minuscules, sans accents ni ponctuation. */
    private fun norm(s: String): String = java.text.Normalizer.normalize(s.lowercase(), java.text.Normalizer.Form.NFD)
        .replace(Regex("""\p{M}+"""), "")
        .replace(Regex("""[^a-z0-9]+"""), " ")
        .trim()

    private fun tokens(s: String) = norm(s).split(" ").filter { it.length >= 2 }

    private fun searchAlbums(query: String): List<Map<String, Any?>> {
        val music = runCatching { search(query, YoutubeSearchQueryHandlerFactory.MUSIC_ALBUMS) }.getOrDefault(emptyList())
        if (music.isNotEmpty()) return music
        return runCatching { search(query, YoutubeSearchQueryHandlerFactory.PLAYLISTS) }.getOrDefault(emptyList())
            .filter { it["type"] == "playlist" }
    }

    private val noise = Regex(
        """\s*[(\[](?:[^)\]]*(?:clip|official|officiel|video|vidéo|audio|lyrics?|paroles|visuali[sz]er|hd|4k|prod)[^)\]]*)[)\]]""",
        RegexOption.IGNORE_CASE,
    )
    private val trailingNoise = Regex("""\s*[|/]\s*(?:clip|official|lyrics?|paroles|audio).*$""", RegexOption.IGNORE_CASE)

    /** "DAMSO - Impardonnable (Clip Officiel)" -> artiste "DAMSO", titre "Impardonnable". */
    private fun asSong(m: Map<String, Any?>): Map<String, Any?> {
        var title = (m["title"] as? String ?: "").replace(noise, "").replace(trailingNoise, "").trim()
        var artist = m["artist"] as? String ?: ""
        val dash = Regex("""\s+[-–—|]\s+""").find(title)
        if (dash != null) {
            artist = title.substring(0, dash.range.first).trim()
            title = title.substring(dash.range.last + 1).trim()
        }
        return m + mapOf("title" to title.ifEmpty { m["title"] }, "artist" to artist)
    }

    private fun search(query: String, filter: String): List<Map<String, Any?>> {
        val handler = yt.searchQHFactory.fromQuery(query, listOf(filter), "")
        return SearchInfo.getInfo(yt, handler).relatedItems.mapNotNull(::item)
    }

    private fun playlist(url: String): Map<String, Any?> {
        val info = PlaylistInfo.getInfo(yt, url)
        return mapOf(
            "name" to info.name,
            "uploader" to info.uploaderName,
            "thumbnail" to best(info.thumbnails),
            "items" to info.relatedItems.mapNotNull(::item),
        )
    }

    private fun related(id: String): List<Map<String, Any?>> =
        StreamInfo.getInfo(yt, watchUrl(id)).relatedItems.mapNotNull(::item)

    /** Meilleur flux audio progressif (M4A de préférence : lu partout par ExoPlayer). */
    private fun audioStream(id: String): Map<String, Any?> {
        val info = StreamInfo.getInfo(yt, watchUrl(id))
        val streams = info.audioStreams.filter { it.isUrl && it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP }
        val pick: AudioStream = streams
            .sortedWith(compareByDescending<AudioStream> { it.format == MediaFormat.M4A }.thenByDescending { it.averageBitrate })
            .firstOrNull() ?: throw IllegalStateException("Aucun flux audio disponible")
        return mapOf(
            "url" to pick.content,
            "mime" to (pick.format?.mimeType ?: "audio/mp4"),
            "bitrate" to pick.averageBitrate,
            "duration" to info.duration,
            "userAgent" to OkDownloader.USER_AGENT,
        )
    }

    private fun item(i: InfoItem): Map<String, Any?>? = when (i) {
        is StreamInfoItem -> mapOf(
            "type" to "stream",
            "id" to videoId(i.url),
            "url" to i.url,
            "title" to i.name,
            "artist" to cleanArtist(i.uploaderName),
            "artistUrl" to i.uploaderUrl,
            "duration" to i.duration,
            "thumbnail" to best(i.thumbnails),
        )
        is PlaylistInfoItem -> mapOf(
            "type" to "playlist",
            "url" to i.url,
            "title" to i.name,
            "artist" to cleanArtist(i.uploaderName),
            "count" to i.streamCount,
            "thumbnail" to best(i.thumbnails),
        )
        else -> null
    }

    /** "DamsoVEVO" → "Damso", "Tiakola - Topic" → "Tiakola", "Gims Officiel" → "Gims". */
    private fun cleanArtist(s: String?) = (s ?: "")
        .removeSuffix(" - Topic")
        .replace(Regex("""VEVO$"""), "")
        .replace(Regex("""\s+(official|officiel|music|musique)$""", RegexOption.IGNORE_CASE), "")
        .trim()

    private fun best(images: List<Image>): String? {
        val url = images.maxByOrNull { it.height }?.url ?: return null
        // Miniatures YouTube Music : demander une taille carrée plus grande.
        return url.replace(Regex("=w\\d+-h\\d+"), "=w544-h544").replace(Regex("=s\\d+-"), "=s240-")
    }

    private fun watchUrl(id: String) = "https://www.youtube.com/watch?v=$id"

    private fun videoId(url: String): String =
        Regex("[?&]v=([A-Za-z0-9_-]{11})").find(url)?.groupValues?.get(1) ?: url.substringAfterLast('/')
}
