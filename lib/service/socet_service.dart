
import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SocketService {
  static late io.Socket socket;
  static RTCPeerConnection? peerConnection;
  static MediaStream? localStream;
  static MediaStream? remoteStream;
  static Function(MediaStream)? onRemoteStream;
  static String? roomId;

  static const Map<String, dynamic> config = {
    "iceServers": [
      {"urls": "stun:stun.l.google.com:19302"},
      {"urls": "stun:stun1.l.google.com:19302"},
      {"urls": "stun:stun2.l.google.com:19302"},
      // Add TURN if needed
    ],
  };

  static Future<void> connectSocket({String? room}) async {
    roomId = room;

    socket = io.io(
      "http://10.10.10.37:3000",
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setReconnectionDelay(1000)
          .build(),
    );

    socket.onConnect((_) async {
      log("✅ Socket connected: ${socket.id}");
      if (roomId != null) socket.emit('join', roomId);
      initListeners();
    });

    socket.onConnectError((e) => log("❌ Socket connect error: $e"));
    socket.onDisconnect((_) => log("❌ Socket disconnected"));

    socket.onAny((event, data) => log("📡 Event: $event | Data: $data"));

    socket.connect();
  }

  static void setLocalStream(MediaStream stream) {
    localStream = stream;
    log("✅ Local stream set with ${stream.getTracks().length} tracks");
  }
  //======================================================================peer connection instance
  static Future<void> createPeerConnectionInstance() async {
    if (peerConnection != null) return;

    peerConnection = await createPeerConnection(config);

    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        peerConnection?.addTrack(track, localStream!);
        log("🎥 Added local track: ${track.kind}");
      }
    }

    peerConnection?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onRemoteStream?.call(remoteStream!);
        log("✅ Remote stream received");
      }
    };

    peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        socket.emit('candidate', {
          "candidate": candidate.candidate,
          "sdpMid": candidate.sdpMid,
          "sdpMLineIndex": candidate.sdpMLineIndex,
          "room": roomId
        });
      }
    };
  }

  static void initListeners() {


    //========================================================room ready
    socket.on('ready', (_) async {
      log("✅ Room ready, creating offer...");
      await createOffer();
    });


    //===========================================================offer

    socket.on("offer", (data) async {
      await createPeerConnectionInstance();
      await peerConnection?.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type']));
      var answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);
      socket.emit('answer', {...answer.toMap(), 'room': roomId});
      log("✅ Answer sent");
    });
    //===========================================================answer

    socket.on("answer", (data) async {
      await peerConnection?.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type']));
      log("✅ Remote description set (answer)");
    });


    //=====================================================candidate

    socket.on("candidate", (data) async {
      try {
        await peerConnection?.addCandidate(RTCIceCandidate(
            data['candidate'], data['sdpMid'], data['sdpMLineIndex']));
        log("✅ ICE candidate added");
      } catch (e) {
        log("❌ Error adding ICE candidate: $e");
      }
    });
  }

//=======================================================create offer
  static Future<void> createOffer() async {
    await createPeerConnectionInstance();
    var offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    socket.emit('offer', {...offer.toMap(), 'room': roomId});
    log("✅ Offer sent");
  }

  static void endCall() {
    localStream?.dispose();
    remoteStream?.dispose();
    peerConnection?.close();
    peerConnection = null;
    remoteStream = null;
    socket.emit('leave', roomId);
    log("📞 Call ended");
  }
}
