import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
          children: <Widget>[
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_page.png',
              fit: BoxFit.cover, // 이미지가 화면을 채우도록 설정
            ),
          ),
          // 이미지 위에 버튼
          Positioned(
            bottom: 50, // 버튼의 위치를 이미지 위에 설정
            left: 50,   // 버튼의 위치 설정
            child: ElevatedButton(
              onPressed: () {
                print("버튼 클릭됨");
              },
              child: Text('시작하기'),
            ),
          ),
        ],
      ),
    );
  }
}

