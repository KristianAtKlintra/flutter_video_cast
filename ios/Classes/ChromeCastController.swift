//
//  ChromeCastController.swift
//  flutter_video_cast
//
//  Created by Alessio Valentini on 07/08/2020.
//

import Flutter
import GoogleCast

class ChromeCastController: NSObject, FlutterPlatformView {

    // MARK: - Internal properties

    private let channel: FlutterMethodChannel
    private let chromeCastButton: GCKUICastButton
    private let sessionManager = GCKCastContext.sharedInstance().sessionManager

    // MARK: - Init

    init(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        registrar: FlutterPluginRegistrar
    ) {
        self.channel = FlutterMethodChannel(name: "flutter_video_cast/chromeCast_\(viewId)", binaryMessenger: registrar.messenger())
        self.chromeCastButton = GCKUICastButton(frame: frame)
        super.init()
        self.configure(arguments: args)
    }

    func view() -> UIView {
        return chromeCastButton
    }

    private func configure(arguments args: Any?) {
        setTint(arguments: args)
        setMethodCallHandler()
    }

    // MARK: - Styling

    private func setTint(arguments args: Any?) {
        guard
            let args = args as? [String: Any],
            let red = args["red"] as? CGFloat,
            let green = args["green"] as? CGFloat,
            let blue = args["blue"] as? CGFloat,
            let alpha = args["alpha"] as? Int else {
                print("Invalid color")
                return
        }
        chromeCastButton.tintColor = UIColor(
            red: red / 255,
            green: green / 255,
            blue: blue / 255,
            alpha: CGFloat(alpha) / 255
        )
    }

    // MARK: - Flutter methods handling

    private func setMethodCallHandler() {
        channel.setMethodCallHandler { call, result in
            self.onMethodCall(call: call, result: result)
        }
    }

    private func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
        case "chromeCast#wait":
            result(nil)
            break
        case "chromeCast#loadMedia":
            loadMedia(args: call.arguments)
            result(nil)
            break
        case "chromeCast#loadMediaQueue":
            loadMediaQueue(args: call.arguments)
            result(nil)
            break
        case "chromeCast#play":
            play()
            result(nil)
            break
        case "chromeCast#pause":
            pause()
            result(nil)
            break
        case "chromeCast#seek":
            seek(args: call.arguments)
            result(nil)
            break
        case "chromeCast#stop":
            stop()
            result(nil)
            break
        case "chromeCast#isConnected":
            result(isConnected())
            break
        case "chromeCast#isPlaying":
            result(isPlaying())
            break
        case "chromeCast#addSessionListener":
            addSessionListener()
            result(nil)
            break
        case "chromeCast#removeSessionListener":
            removeSessionListener()
            result(nil)
            break
        case "chromeCast#position":
            result(position())
            break
        case "chromeCast#presentDefaultExpandedMediaControls":
            presentDefaultExpandedMediaControls()
            result(nil)
            break
        case "chromeCast#duration":
            result(duration())
            break
        case "chromeCast#metadata":
            result(metadata())
            break
        default:
            result(nil)
            break
        }
    }

    private func loadMedia(args: Any?) {
        guard
            let args = args as? [String: Any],
            let mediaInformation = getMediaInformation(from: args) else {
                return
        }
                
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.loadMedia(mediaInformation) {
            request.delegate = self
        }
    }
    
    private func loadMediaQueue(args: Any?){
        guard
            let args = args as? [String: Any],
            let queue = args["mediaitems"] as? [[String: Any]]
        else {
                print("Invalid URL")
                return
        }
        
        var queueItems: [GCKMediaQueueItem] = []
        for item in queue {
            guard let mediaInformation = getMediaInformation(from: item) else {
                continue
            }
            let builder = GCKMediaQueueItemBuilder.init()
            builder.mediaInformation = mediaInformation
            builder.autoplay = true
            builder.preloadTime = 8.0
            let newItem = builder.build()
            queueItems.append(newItem)
        }
        
        let rb = GCKMediaLoadRequestDataBuilder()
        let qb = GCKMediaQueueDataBuilder.init(queueType: GCKMediaQueueType.videoPlayList)
        qb.items = queueItems
        qb.startIndex = 0
        qb.name = "Kvf Vit"
        qb.repeatMode = GCKMediaRepeatMode.off
        
        rb.queueData = qb.build()
        
        sessionManager.currentCastSession?.remoteMediaClient?.loadMedia(with: rb.build())
    }
    
    private func getMediaInformation(from: [String: Any]) -> GCKMediaInformation?{
        guard
            let url = from["url"] as? String,
            let mediaUrl = URL(string: url)  else {
                print("Invalid URL")
                return nil
        }
        let metadata = GCKMediaMetadata()
        if from.keys.contains("Title") {
            metadata.setString(from["Title"] as! String, forKey: kGCKMetadataKeyTitle)
        }
        if from.keys.contains("Subtitle") {
            metadata.setString(from["Subtitle"] as! String, forKey: kGCKMetadataKeySubtitle)
        }
        if from.keys.contains("Image") {
            metadata.addImage(GCKImage(url: URL(string: from["Image"] as! String)!, width: 960, height: 720))
        }

        for k in from.keys {
            if k.starts(with: "KVF_") {
                metadata.setString(from[k] as! String, forKey: k)
            }
        }

        let mediaInformationBuilder = GCKMediaInformationBuilder(contentURL: mediaUrl)
        mediaInformationBuilder.metadata = metadata
        let mediaInformation = mediaInformationBuilder.build()
        return mediaInformation;
    }

    private func play() {
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.play() {
            request.delegate = self
        }
    }

    private func pause() {
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.pause() {
            request.delegate = self
        }
    }

    private func seek(args: Any?) {
        guard
            let args = args as? [String: Any],
            let relative = args["relative"] as? Bool,
            let interval = args["interval"] as? Double else {
                return
        }
        let seekOptions = GCKMediaSeekOptions()
        seekOptions.relative = relative
        seekOptions.interval = interval
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.seek(with: seekOptions) {
            request.delegate = self
        }
    }

    private func stop() {
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.stop() {
            request.delegate = self
        }
    }

    private func isConnected() -> Bool {
        return sessionManager.currentCastSession?.remoteMediaClient?.connected ?? false
    }

    private func isPlaying() -> Bool {
        return sessionManager.currentCastSession?.remoteMediaClient?.mediaStatus?.playerState == GCKMediaPlayerState.playing
    }

    private func addSessionListener() {
        sessionManager.add(self)
    }

    private func removeSessionListener() {
        sessionManager.remove(self)
    }

    private func position() -> Int {        
        return Int(sessionManager.currentCastSession?.remoteMediaClient?.approximateStreamPosition() ?? 0) * 1000
    }

    private func presentDefaultExpandedMediaControls() {
        return GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()
    }

    private func duration() -> Int {
        let dur = sessionManager.currentCastSession?.remoteMediaClient?.mediaStatus?.mediaInformation?.streamDuration;
        return dur == TimeInterval.infinity ? 0 : Int(dur ?? 0) * 1000
    }

    private func metadata() -> String? {
        guard let metadata = sessionManager.currentCastSession?.remoteMediaClient?.mediaStatus?.mediaInformation?.metadata else {
            return nil;
        }
        var dict = [String: String]()
        dict[kGCKMetadataKeyTitle] = metadata.string(forKey: kGCKMetadataKeyTitle)
        dict[kGCKMetadataKeySubtitle] = metadata.string(forKey: kGCKMetadataKeySubtitle)
        dict["Image"] = metadata.string(forKey: "Image")
        
        for k in metadata.allKeys() {
            if(k.starts(with: "KVF_")){
                dict[k] = metadata.string(forKey: k)
            }
        }
        
        return GCKJSONUtils.writeJSON(dict)
    }

}

// MARK: - GCKSessionManagerListener

extension ChromeCastController: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        channel.invokeMethod("chromeCast#didStartSession", arguments: nil)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        channel.invokeMethod("chromeCast#didEndSession", arguments: nil)
    }
}

// MARK: - GCKRequestDelegate

extension ChromeCastController: GCKRequestDelegate {
    func requestDidComplete(_ request: GCKRequest) {
        channel.invokeMethod("chromeCast#requestDidComplete", arguments: nil)
    }

    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        channel.invokeMethod("chromeCast#requestDidFail", arguments: ["error" : error.localizedDescription])
    }
}
