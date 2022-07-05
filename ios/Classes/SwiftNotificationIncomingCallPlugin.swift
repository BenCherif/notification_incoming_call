import Flutter
import UIKit
import CallKit
import AVFoundation

@available(iOS 10.0, *)
public class SwiftNotificationIncomingCallPlugin: NSObject, FlutterPlugin, CXProviderDelegate {
    
    
    static let actionCallIncoming = "co.strolink.notification_incoming_call.actionCallIncoming"
    static let actionCallStart = "co.strolink.notification_incoming_call.actionCallStart"
    static let actionCallAccept = "co.strolink.notification_incoming_call.actionCallAccept"
    static let actionCallDecline = "co.strolink.notification_incoming_call.actionCallDecline"
    static let actionCallEnded = "co.strolink.notification_incoming_call.actionCallEnded"
    static let actionCallTimeout = "co.strolink.notification_incoming_call.actionCallTimeout"
    
    static let actionCallToggleHold = "co.strolink.notification_incoming_call.actionCallToggleHold"
    static let actionCallToggleMute = "co.strolink.notification_incoming_call.actionCallToggleMute"
    static let actionCallToggleDmtf = "co.strolink.notification_incoming_call.actionCallToggleDmtf"
    static let actionCallToggleGroup = "co.strolink.notification_incoming_call.actionCallToggleGroup"
    static let actionCallToggleAudioSession = "co.strolink.notification_incoming_call.actionCallToggleAudioSession"
    
    public static var sharedInstance: SwiftNotificationIncomingCallPlugin? = nil
    
    private var channel: FlutterMethodChannel? = nil
    private var eventChannel: FlutterEventChannel? = nil
    private var callManager: CallManager? = nil
    
    private var eventCallbackHandler: EventCallbackHandler?
    private var sharedProvider: CXProvider? = nil
    
    private var outgoingCall : Call?
    private var answerCall : Call?
    
    private var data: Data?
    
    private func sendEvent(_ event: String, _ body: [String : Any?]?) {
        eventCallbackHandler?.send(event, body ?? [:] as [String : Any?])
    }
    
    public static func sharePluginWithRegister(with registrar: FlutterPluginRegistrar) -> SwiftNotificationIncomingCallPlugin {
        if(sharedInstance == nil){
            sharedInstance = SwiftNotificationIncomingCallPlugin()
        }
        sharedInstance!.channel = FlutterMethodChannel(name: "notification_incoming_call", binaryMessenger: registrar.messenger())
        sharedInstance!.eventChannel = FlutterEventChannel(name: "notification_incoming_call_events", binaryMessenger: registrar.messenger())
        sharedInstance!.callManager = CallManager()
        sharedInstance!.eventCallbackHandler = EventCallbackHandler()
        sharedInstance!.eventChannel?.setStreamHandler(sharedInstance!.eventCallbackHandler as? FlutterStreamHandler & NSObjectProtocol)
        return sharedInstance!
    }
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = sharePluginWithRegister(with: registrar)
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "showCallkitIncoming":
            guard let args = call.arguments else {
                result("OK")
                return
            }
            if let getArgs = args as? [String: Any] {
                self.data = Data(args: getArgs)
                showCallkitIncoming(self.data!, fromPushKit: false)
            }
            result("OK")
            break
        case "startCall":
            guard let args = call.arguments else {
                result("OK")
                return
            }
            if let getArgs = args as? [String: Any] {
                self.data = Data(args: getArgs)
                self.startCall(self.data!)
            }
            result("OK")
            break
        case "endCall":
            guard let args = call.arguments else {
                result("OK")
                return
            }
            if let getArgs = args as? [String: Any] {
                self.data = Data(args: getArgs)
                self.endCall(self.data!)
            }
            result("OK")
            break
        case "activeCalls":
            result(self.callManager?.activeCalls())
            break;
        case "endAllCalls":
            self.callManager?.endCallAlls()
            result("OK")
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    
    public func showCallkitIncoming(_ data: Data, fromPushKit: Bool) {
        
        self.endCallNotExist(data)
        
        var handle: CXHandle?
        handle = CXHandle(type: self.getHandleType(data.handleType), value: data.handle)
        
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = handle
        callUpdate.supportsDTMF = data.supportsDTMF
        callUpdate.supportsHolding = data.supportsHolding
        callUpdate.supportsGrouping = data.supportsGrouping
        callUpdate.supportsUngrouping = data.supportsUngrouping
        callUpdate.hasVideo = data.type > 0 ? true : false
        callUpdate.localizedCallerName = data.nameCaller
        
        initCallkitProvider(data)
        
        let uuid = UUID(uuidString: data.uuid)
        
        configurAudioSession()
        self.sharedProvider?.reportNewIncomingCall(with: uuid!, update: callUpdate) { error in
            if(error == nil) {
                self.configurAudioSession()
                let call = Call(uuid: uuid!)
                call.handle = data.handle
                self.callManager?.addCall(call)
                self.sendEvent(SwiftNotificationIncomingCallPlugin.actionCallIncoming, data.toJSON())
            }
        }
    }
    
    
    public func startCall(_ data: Data) {
        initCallkitProvider(data)
        self.callManager?.startCall(data)
    }
    
    public func endCall(_ data: Data) {
        let call = Call(uuid: UUID(uuidString: data.uuid)!)
        self.callManager?.endCall(call: call)
    }
    
    
    public func saveEndCall(_ uuid: String, _ reason: Int) {
        switch reason {
        case 1:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.failed)
            break
        case 2, 6:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.remoteEnded)
            break
        case 3:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.unanswered)
            break
        case 4:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.answeredElsewhere)
            break
        case 5:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.declinedElsewhere)
            break
        default:
            break
        }
    }
    
    
    func endCallNotExist(_ data: Data) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(data.duration)) {
            let call = self.callManager?.callWithUUID(uuid: UUID(uuidString: data.uuid)!)
            if (call != nil && self.answerCall == nil && self.outgoingCall == nil) {
                self.callEndTimeout(data)
            }
        }
    }
    
    
    
    func callEndTimeout(_ data: Data) {
        self.saveEndCall(data.uuid, 3)
        sendEvent(SwiftNotificationIncomingCallPlugin.actionCallTimeout, data.toJSON())
    }
    
    func getHandleType(_ handleType: String?) -> CXHandle.HandleType {
        var typeDefault = CXHandle.HandleType.generic
        switch handleType {
        case "number":
            typeDefault = CXHandle.HandleType.phoneNumber
            break
        case "email":
            typeDefault = CXHandle.HandleType.emailAddress
        default:
            typeDefault = CXHandle.HandleType.generic
        }
        return typeDefault
    }
    
    func initCallkitProvider(_ data: Data) {
        if(self.sharedProvider == nil){
            self.sharedProvider = CXProvider(configuration: createConfiguration(data))
            self.sharedProvider?.setDelegate(self, queue: nil)
        }
    }
    
    func createConfiguration(_ data: Data) -> CXProviderConfiguration {
        let configuration = CXProviderConfiguration(localizedName: data.appName)
        configuration.supportsVideo = data.supportsVideo
        configuration.maximumCallGroups = data.maximumCallGroups
        configuration.maximumCallsPerCallGroup = data.maximumCallsPerCallGroup
        
        configuration.supportedHandleTypes = [
            CXHandle.HandleType.generic,
            CXHandle.HandleType.emailAddress,
            CXHandle.HandleType.phoneNumber
        ]
        if #available(iOS 11.0, *) {
            configuration.includesCallsInRecents = data.includesCallsInRecents
        }
        if !data.iconName.isEmpty {
            if let image = UIImage(named: data.iconName) {
                configuration.iconTemplateImageData = image.pngData()
            } else {
                print("Unable to load icon \(data.iconName).");
            }
        }
        if !data.ringtonePath.isEmpty {
            configuration.ringtoneSound = data.ringtonePath
        }
        return configuration
    }
    
    
    
    func senddefaultAudioInterruptionNofificationToStartAudioResource(){
        var userInfo : [AnyHashable : Any] = [:]
        let intrepEndeRaw = AVAudioSession.InterruptionType.ended.rawValue
        userInfo[AVAudioSessionInterruptionTypeKey] = intrepEndeRaw
        userInfo[AVAudioSessionInterruptionOptionKey] = AVAudioSession.InterruptionOptions.shouldResume.rawValue
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: self, userInfo: userInfo)
    }
    
    func configurAudioSession(){
        let session = AVAudioSession.sharedInstance()
        do{
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.allowBluetooth)
            try session.setMode(self.getAudioSessionMode(data?.audioSessionMode))
            try session.setActive(data?.audioSessionActive ?? true)
            try session.setPreferredSampleRate(data?.audioSessionPreferredSampleRate ?? 44100.0)
            try session.setPreferredIOBufferDuration(data?.audioSessionPreferredIOBufferDuration ?? 0.005)
        }catch{
            print(error)
        }
    }
    
    func getAudioSessionMode(_ audioSessionMode: String?) -> AVAudioSession.Mode {
        var mode = AVAudioSession.Mode.default
        switch audioSessionMode {
        case "gameChat":
            mode = AVAudioSession.Mode.gameChat
            break
        case "measurement":
            mode = AVAudioSession.Mode.measurement
            break
        case "moviePlayback":
            mode = AVAudioSession.Mode.moviePlayback
            break
        case "spokenAudio":
            mode = AVAudioSession.Mode.spokenAudio
            break
        case "videoChat":
            mode = AVAudioSession.Mode.videoChat
            break
        case "videoRecording":
            mode = AVAudioSession.Mode.videoRecording
            break
        case "voiceChat":
            mode = AVAudioSession.Mode.voiceChat
            break
        case "voicePrompt":
            if #available(iOS 12.0, *) {
                mode = AVAudioSession.Mode.voicePrompt
            } else {
                // Fallback on earlier versions
            }
            break
        default:
            mode = AVAudioSession.Mode.default
        }
        return mode
    }
    
    
    
    
    
    
    
    public func providerDidReset(_ provider: CXProvider) {
        if(self.callManager == nil){ return }
        for call in self.callManager!.calls{
            call.endCall()
        }
        self.callManager?.removeAllCalls()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        let call = Call(uuid: action.callUUID, isOutGoing: true)
        call.handle = action.handle.value
        configurAudioSession()
        call.hasStartedConnectDidChange = { [weak self] in
            self?.sharedProvider?.reportOutgoingCall(with: call.uuid, startedConnectingAt: call.connectData)
        }
        call.hasConnectDidChange = { [weak self] in
            self?.sharedProvider?.reportOutgoingCall(with: call.uuid, startedConnectingAt: call.connectedData)
        }
        self.outgoingCall = call;
        self.sendEvent(SwiftNotificationIncomingCallPlugin.actionCallStart, self.data?.toJSON())
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = self.callManager?.callWithUUID(uuid: action.callUUID) else{
            action.fail()
            return
        }
        configurAudioSession()
        self.answerCall = call
        sendEvent(SwiftNotificationIncomingCallPlugin.actionCallAccept, self.data?.toJSON())
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let call = self.callManager?.callWithUUID(uuid: action.callUUID) else {
            if(self.answerCall == nil && self.outgoingCall == nil){
                sendEvent(SwiftNotificationIncomingCallPlugin.actionCallTimeout, self.data?.toJSON())
            }else {
                sendEvent(SwiftNotificationIncomingCallPlugin.actionCallEnded, self.data?.toJSON())
            }
            action.fail()
            return
        }
        call.endCall()
        self.callManager?.removeCall(call)
        sendEvent(SwiftNotificationIncomingCallPlugin.actionCallEnded, self.data?.toJSON())
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = self.callManager?.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        call.isOnHold = action.isOnHold
        call.isMuted = action.isOnHold
        self.callManager?.setHold(call: call, onHold: action.isOnHold)
        self.sendEvent(SwiftNotificationIncomingCallPlugin.actionCallToggleHold, [ "id": action.callUUID.uuidString, "isOnHold": action.isOnHold ])
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let call = self.callManager?.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        call.isMuted = action.isMuted
        self.sendEvent(SwiftNotificationIncomingCallPlugin.actionCallToggleMute, [ "id": action.callUUID.uuidString, "isMuted": action.isMuted ])
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        guard (self.callManager?.callWithUUID(uuid: action.callUUID)) != nil else {
            action.fail()
            return
        }
        //call.isMuted = action.isMuted
        self.sendEvent(SwiftNotificationIncomingCallPlugin.actionCallToggleGroup, [ "id": action.callUUID.uuidString, "callUUIDToGroupWith" : action.callUUIDToGroupWith?.uuidString])
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        guard (self.callManager?.callWithUUID(uuid: action.callUUID)) != nil else {
            action.fail()
            return
        }
        //call.isMuted = action.isMuted
        self.sendEvent(SwiftNotificationIncomingCallPlugin.actionCallToggleDmtf, [ "id": action.callUUID.uuidString, "digits": action.digits, "type": action.type ])
        action.fulfill()
    }
    
    
    public func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        sendEvent(SwiftNotificationIncomingCallPlugin.actionCallTimeout, self.data?.toJSON())
    }
    
    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        if(self.answerCall?.hasConnected ?? false){
            senddefaultAudioInterruptionNofificationToStartAudioResource()
            return
        }
        if(self.outgoingCall?.hasConnected ?? false){
            senddefaultAudioInterruptionNofificationToStartAudioResource()
            return
        }
        self.outgoingCall?.startCall(withAudioSession: audioSession) {success in
            if success {
                self.callManager?.addCall(self.outgoingCall!)
                self.outgoingCall?.startAudio()
            }
        }
        self.answerCall?.ansCall(withAudioSession: audioSession) { success in
            if success{
                self.answerCall?.startAudio()
            }
        }
        senddefaultAudioInterruptionNofificationToStartAudioResource()
        configurAudioSession()
        self.sendEvent(SwiftNotificationIncomingCallPlugin.actionCallToggleAudioSession, [ "isActivate": true ])
    }
    
    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        if self.outgoingCall?.isOnHold ?? false || self.answerCall?.isOnHold ?? false{
            print("Call is on hold")
            return
        }
        self.outgoingCall?.endCall()
        if(self.outgoingCall != nil){
            self.outgoingCall = nil
        }
        self.answerCall?.endCall()
        if(self.answerCall != nil){
            self.answerCall = nil
        }
        self.callManager?.removeAllCalls()
        self.sendEvent(SwiftNotificationIncomingCallPlugin.actionCallToggleAudioSession, [ "isActivate": false ])
    }
    
    
}

class EventCallbackHandler: FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    
    public func send(_ event: String, _ body: [String: Any?]) {
        let data: [String : Any] = [
            "event": event,
            "body": body
        ]
        eventSink?(data)
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
