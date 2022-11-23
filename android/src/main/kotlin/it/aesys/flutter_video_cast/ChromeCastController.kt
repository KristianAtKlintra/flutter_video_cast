package it.aesys.flutter_video_cast

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.ContextThemeWrapper
import androidx.mediarouter.app.MediaRouteButton
import com.google.android.gms.cast.*
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.Session
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.framework.media.widget.ExpandedControllerActivity
import com.google.android.gms.common.api.PendingResult
import com.google.android.gms.common.api.Status
import com.google.android.gms.common.images.WebImage
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.json.JSONObject

class ChromeCastController(
    messenger: BinaryMessenger,
    viewId: Int,
    context: Context?
) : PlatformView, MethodChannel.MethodCallHandler, SessionManagerListener<Session>, PendingResult.StatusListener {
    private val channel = MethodChannel(messenger, "flutter_video_cast/chromeCast_$viewId")
    private val chromeCastButton = MediaRouteButton(ContextThemeWrapper(context, R.style.Theme_AppCompat_NoActionBar))
    private val sessionManager = CastContext.getSharedInstance()?.sessionManager
    private val context = context

    init {
        CastButtonFactory.setUpMediaRouteButton(context, chromeCastButton)
        channel.setMethodCallHandler(this)
    }

    private fun loadMedia(args: Any?) {
        if (args is Map<*, *>) {
            val url = args["url"] as? String

            val meta = MediaMetadata(MediaMetadata.MEDIA_TYPE_GENERIC)
            meta.putString(MediaMetadata.KEY_TITLE, args["title"] as? String)
            meta.putString(MediaMetadata.KEY_ARTIST, args["artist"] as? String)
            (args["image-url"] as? String).let{imageUrl ->
                meta.addImage(WebImage(Uri.parse(imageUrl)))
            }

            val media = MediaInfo.Builder(url).setMetadata(meta).build()
            val options = MediaLoadOptions.Builder().build()
            val request = sessionManager?.currentCastSession?.remoteMediaClient?.load(media, options)
            request?.addStatusListener(this)
        }
    }

    private fun play() {
        val request = sessionManager?.currentCastSession?.remoteMediaClient?.play()
        request?.addStatusListener(this)
    }

    private fun pause() {
        val request = sessionManager?.currentCastSession?.remoteMediaClient?.pause()
        request?.addStatusListener(this)
    }

    private fun seek(args: Any?) {
        if (args is Map<*, *>) {
            val relative = (args["relative"] as? Boolean) ?: false
            var interval = args["interval"] as? Double
            interval = interval?.times(1000)
            if (relative) {
                interval = interval?.plus(sessionManager?.currentCastSession?.remoteMediaClient?.mediaStatus?.streamPosition ?: 0)
            }
            val request = sessionManager?.currentCastSession?.remoteMediaClient?.seek(interval?.toLong() ?: 0)
            request?.addStatusListener(this)
        }
    }

    private fun setVolume(args: Any?) {
        if (args is Map<*, *>) {
            val volume = args["volume"] as? Double
            val request = sessionManager?.currentCastSession?.remoteMediaClient?.setStreamVolume(volume ?: 0.0)
            request?.addStatusListener(this)
        }
    }

    private fun getVolume() = sessionManager?.currentCastSession?.volume ?: 0.0

    private fun stop() {
        val request = sessionManager?.currentCastSession?.remoteMediaClient?.stop()
        request?.addStatusListener(this)
    }

    private fun isPlaying() = sessionManager?.currentCastSession?.remoteMediaClient?.isPlaying ?: false

    private fun isConnected() = sessionManager?.currentCastSession?.isConnected ?: false

    private fun endSession() = sessionManager?.endCurrentSession(true)

    private fun position() = sessionManager?.currentCastSession?.remoteMediaClient?.approximateStreamPosition ?: 0

    private fun duration() = sessionManager?.currentCastSession?.remoteMediaClient?.mediaInfo?.streamDuration ?: 0

    private fun addSessionListener() {
        sessionManager?.addSessionManagerListener(this)
    }

    private fun removeSessionListener() {
        sessionManager?.removeSessionManagerListener(this)
    }

    override fun getView() = chromeCastButton

    override fun dispose() {

    }

    // Flutter methods handling

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when(call.method) {
            "chromeCast#wait" -> result.success(null)
            "chromeCast#loadMedia" -> {
                loadMedia(call.arguments)
                result.success(null)
            }
            "chromeCast#loadMediaQueue" -> {
                loadMediaQueue(call.arguments)
                result.success(null)
            }
            "chromeCast#play" -> {
                play()
                result.success(null)
            }
            "chromeCast#pause" -> {
                pause()
                result.success(null)
            }
            "chromeCast#seek" -> {
                seek(call.arguments)
                result.success(null)
            }
            "chromeCast#setVolume" -> {
                setVolume(call.arguments)
                result.success(null)
            }
            "chromeCast#getVolume" -> result.success(getVolume())
            "chromeCast#stop" -> {
                stop()
                result.success(null)
            }
            "chromeCast#isPlaying" -> result.success(isPlaying())
            "chromeCast#isConnected" -> result.success(isConnected())
            "chromeCast#endSession" -> {
                endSession()
                result.success(null)
            }
            "chromeCast#position" -> result.success(position())
            "chromeCast#duration" -> result.success(duration())
            "chromeCast#addSessionListener" -> {
                addSessionListener()
                result.success(null)
            }
            "chromeCast#removeSessionListener" -> {
                removeSessionListener()
                result.success(null)
            }
            "chromeCast#removeSessionListener" -> {
                removeSessionListener()
                result.success(null)
            }
            "chromeCast#position" -> {
                result.success(position())
            }

            "chromeCast#presentDefaultExpandedMediaControls" -> {
                presentDefaultExpandedMediaControls()
                result.success(null)
            }

            "chromeCast#duration" -> {
                result.success(duration())
            }

            "chromeCast#metadata" -> {
                result.success(metadata())
            }
        }
    }

    private fun presentDefaultExpandedMediaControls() {
        var packageName = this.context?.applicationContext?.packageName
        var activityName= "ExpandedControlsActivity"
        var intent = Intent().apply {
            action = packageName + "." + activityName
            type = "text/plain"
        }
        this.context?.startActivity(intent)
    }

    private fun metadata() : String? {
        var metadata = sessionManager?.currentCastSession?.remoteMediaClient?.mediaStatus?.mediaInfo?.metadata
        if( metadata == null ) {
            return null
        }
        var dict = mutableMapOf<String, String?>()
        dict[MediaMetadata.KEY_TITLE] = metadata.getString(MediaMetadata.KEY_TITLE)
        dict[MediaMetadata.KEY_SUBTITLE] = metadata.getString(MediaMetadata.KEY_SUBTITLE)
        dict["Image"] = metadata.getString("Image")

        for( k in metadata.keySet()) {
            if( k.startsWith("KVF_")){
                dict[k] = metadata.getString(k)
            }
        }
        return JSONObject(dict).toString()
    }

    private fun loadMediaQueue(args: Any?){
        var args = args as? Map<String, Any?>
        var queue = args?.get("mediaitems") as? List<Map<String, Any?>>
        if(queue == null){
            Log.d("ChromeCastController", "Invalid queue")
            return
        }

        var queueItems = mutableListOf<MediaQueueItem>()

        for(item in queue) {
            var mediaInfo = getMediaInformation(item)
            val queueItem: MediaQueueItem = MediaQueueItem.Builder(mediaInfo)
                .setAutoplay(true)
                .setPreloadTime(8.0)
                .build()
            queueItems.add(queueItem)
        }
        sessionManager?.currentCastSession?.remoteMediaClient?.queueLoad(
            queueItems.toTypedArray(), //Items
            0, //StartIndex
            MediaStatus.REPEAT_MODE_REPEAT_OFF, //Repeat off
            0, //playPosition
            null //Custom Data
        )
    }

    private fun getMediaInformation(from: Map<String, Any?>): MediaInfo? {

        var url = from["url"] as? String
        var mediaUrl = Uri.parse(url)

        if(mediaUrl == null){
            Log.d("ChromeCastController", "Invalid URL")
            return null
        }

        var metadata = MediaMetadata()
        if( from.containsKey("Title") ){
            metadata.putString(MediaMetadata.KEY_TITLE, from["Title"] as? String)
        }
        if( from.containsKey("Subtitle") ){
            metadata.putString(MediaMetadata.KEY_SUBTITLE, from["Subtitle"] as? String)
        }
        if( from.containsKey("Image") ){
            metadata.addImage(WebImage(mediaUrl))
        }

        for( k in from.keys ) {
            if (k.startsWith("KVF_")) {
                metadata.putString(k, from[k] as? String)
            }
        }

        return MediaInfo.Builder(url).setMetadata(metadata).build()
    }

    // SessionManagerListener

    override fun onSessionStarted(p0: Session?, p1: String?) {
        channel.invokeMethod("chromeCast#didStartSession", null)
    }

    override fun onSessionEnded(p0: Session?, p1: Int) {
        channel.invokeMethod("chromeCast#didEndSession", null)
    }

    override fun onSessionResuming(p0: Session?, p1: String?) {

    }

    override fun onSessionResumed(p0: Session?, p1: Boolean) {

    }

    override fun onSessionResumeFailed(p0: Session?, p1: Int) {

    }

    override fun onSessionSuspended(p0: Session?, p1: Int) {

    }

    override fun onSessionStarting(p0: Session?) {

    }

    override fun onSessionEnding(p0: Session?) {

    }

    override fun onSessionStartFailed(p0: Session?, p1: Int) {

    }

    // PendingResult.StatusListener

    override fun onComplete(status: Status?) {
        if (status?.isSuccess == true) {
            channel.invokeMethod("chromeCast#requestDidComplete", null)
        }
    }
}
