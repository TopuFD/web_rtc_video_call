
// ============= calling_controller.dart (Updated) =============
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_call/service/socet_service.dart';
class CallingController extends GetxController {
  Rxn<rtc.MediaStream> localStream = Rxn<rtc.MediaStream>();
  Rxn<rtc.MediaStream> remoteStream = Rxn<rtc.MediaStream>();

  RxBool isCallStarted = false.obs;
  RxBool isRemoteConnected = false.obs;

  final rtc.RTCVideoRenderer localRenderer = rtc.RTCVideoRenderer();
  final rtc.RTCVideoRenderer remoteRenderer = rtc.RTCVideoRenderer();

  String roomId = "test-room-123";

@override
Future<void> onInit() async {
  super.onInit();
  log("🚀 Initializing CallingController...");
  
  await requestPermissions();
  await initRenderers();
  await initLocalMedia();
  
  // ✅ Connect to socket with room
  await SocketService.connectSocket(room: roomId);
  
  // ⏳ Wait a bit for socket to connect
  await Future.delayed(Duration(milliseconds: 500));
  
  log("✅ Socket connected for room: $roomId");

  // ✅ Set callback for remote stream
  SocketService.onRemoteStream = (stream) {
    log("🎉 === REMOTE STREAM CALLBACK FIRED ===");
    log("Remote stream tracks: ${stream.getTracks().length}");
    
    remoteStream.value = stream;
    remoteRenderer.srcObject = stream;
    isRemoteConnected.value = true;
    
    log("✅ Remote stream set to UI");
  };

  ever(localStream, (stream) {
    if (stream != null) {
      localRenderer.srcObject = stream;
      log("✅ Local stream set to renderer");
    }
  });
}

  Future<void> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    log("📷 Camera: $cameraStatus | 🎤 Microphone: $micStatus");
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    log("✅ Renderers initialized");
  }

  Future<void> initLocalMedia() async {
    try {
      log("🎥 Requesting local media...");
      
      final mediaConstraints = {
        "audio": true,
        "video": {
          "facingMode": "user",
          "width": {"ideal": 640},
          "height": {"ideal": 480},
          "frameRate": {"ideal": 30},
        }
      };

      final stream = await rtc.navigator.mediaDevices.getUserMedia(mediaConstraints);

      localStream.value = stream;
      localRenderer.srcObject = stream;
      SocketService.setLocalStream(stream);

      log("✅ Local media initialized");
      log("  📹 Video tracks: ${stream.getVideoTracks().length}");
      log("  🎤 Audio tracks: ${stream.getAudioTracks().length}");
    } catch (e) {
      log("❌ Failed to initialize local media: $e");
    }
  }

  Future<void> startCall() async {
  log("📞 Starting call...");
  isCallStarted.value = true;

  // Optionally call only if you are the first device
  
  }

  void endCall() {
    log("📞 Ending call from controller...");
    SocketService.endCall();
    isCallStarted.value = false;
    isRemoteConnected.value = false;
    remoteStream.value = null;
    remoteRenderer.srcObject = null;
  }

  @override
  void onClose() {
    log("🧹 Cleaning up CallingController...");
    localRenderer.dispose();
    remoteRenderer.dispose();
    localStream.value?.dispose();
    super.onClose();
  }
}