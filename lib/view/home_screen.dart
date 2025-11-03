import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:video_call/view/call_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        centerTitle: true,
        title: Text("pakna", style: TextStyle(color: Colors.white)),
      ),
      body: SizedBox(
        width: Get.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () {
              Get.to(CallScreen());
            }, child: Text("Call Screen")),
          ],
        ),
      ),
    );
  }
}
