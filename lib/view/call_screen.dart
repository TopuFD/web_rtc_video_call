
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../controller/calling_controller.dart';

class CallScreen extends StatelessWidget {
  CallScreen({Key? key}) : super(key: key);
  final CallingController callCtrl = Get.put(CallingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            Obx(() {
              if (callCtrl.isRemoteConnected.value && 
                  callCtrl.remoteStream.value != null) {
                return RTCVideoView(
                  callCtrl.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: false,
                );
              }
              
              // Waiting state
              return Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ Show loading indicator
                      if (callCtrl.isCallStarted.value)
                        CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        callCtrl.isCallStarted.value
                            ? "Connecting..."
                            : "Press call button to start",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 40),
                      // ✅ Debug info
                      Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDebugRow(
                              "Local Stream",
                              callCtrl.localStream.value != null ? "✅" : "❌",
                            ),
                            _buildDebugRow(
                              "Remote Stream",
                              callCtrl.remoteStream.value != null ? "✅" : "❌",
                            ),
                            _buildDebugRow(
                              "Call Started",
                              callCtrl.isCallStarted.value ? "✅" : "❌",
                            ),
                            _buildDebugRow(
                              "Room ID",
                              callCtrl.roomId,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Local video (small preview in corner)
            Positioned(
              right: 16,
              top: 16,
              width: 120,
              height: 160,
              child: Obx(() {
                if (callCtrl.localStream.value == null) {
                  return SizedBox.shrink();
                }
                
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: RTCVideoView(
                      callCtrl.localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                );
              }),
            ),

            // ✅ Connection status indicator
            Positioned(
              top: 16,
              left: 16,
              child: Obx(() {
                if (!callCtrl.isCallStarted.value) {
                  return SizedBox.shrink();
                }
                
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: callCtrl.isRemoteConnected.value
                        ? Colors.green
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        callCtrl.isRemoteConnected.value
                            ? "Connected"
                            : "Connecting...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            // Control buttons (bottom)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Obx(() {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Start/Join Call Button
                    if (!callCtrl.isCallStarted.value)
                      _buildCallButton(
                        icon: Icons.video_call,
                        color: Colors.green,
                        onPressed: () async {
                          log("📞 Call button pressed");
                          await callCtrl.startCall();
                        },
                        label: "Start Call",
                      ),
                    
                    SizedBox(width: 20),
                    
                    // End Call Button
                    if (callCtrl.isCallStarted.value)
                      _buildCallButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        onPressed: () {
                          log("📴 End call button pressed");
                          callCtrl.endCall();
                        },
                        label: "End Call",
                      ),
                    
                    // ✅ Toggle Camera/Audio buttons (if call started)
                    if (callCtrl.isCallStarted.value) ...[
                      SizedBox(width: 20),
                      _buildSmallButton(
                        icon: Icons.cameraswitch,
                        onPressed: () {
                          // TODO: Implement camera switch
                          log("🔄 Switch camera");
                        },
                      ),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Helper: Debug row widget
  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Helper: Main call button
  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          backgroundColor: color,
          onPressed: onPressed,
          heroTag: label,
          child: Icon(icon, size: 32),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ✅ Helper: Small action button
  Widget _buildSmallButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
// call_screen.dart
