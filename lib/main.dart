import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  File? _image;  // 찍은 사진을 저장할 변수
  final ImagePicker _picker = ImagePicker();  // ImagePicker 인스턴스 생성

  @override
  void initState() {
    super.initState();
    _requestCameraPermission(); // 앱 시작 시 권한 요청
  }

  // 카메라 권한 요청 함수
  Future<void> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();

    if (status.isGranted) {
      print("카메라 권한이 허용되었습니다.");
    } else if (status.isDenied) {
      print("카메라 권한이 거부되었습니다.");
    } else if (status.isPermanentlyDenied) {
      print("카메라 권한이 영구적으로 거부되었습니다. 설정에서 권한을 변경해야 합니다.");
      openAppSettings(); // 설정 페이지로 이동하여 권한 변경
    }
  }

  // 카메라 열어서 사진 찍기
  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);  // 카메라를 열어서 사진 찍기
    if (photo != null) {
      setState(() {
        _image = File(photo.path);  // 찍은 사진을 저장
      });
    }
  }

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
          Align(
            alignment: Alignment.bottomCenter, // 하단 중앙 정렬
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50), // 하단에서 약간의 여백
              child: ElevatedButton(
                onPressed: _takePicture, // 버튼 클릭 시 카메라 실행
                child: Text('시작합니다'), // 버튼 텍스트
              ),
            ),
          ),
          // 찍은 사진 표시
          if (_image != null)
            Positioned(
              top: 100,
              left: 50,
              right: 50,
              child: Image.file(_image!),  // 찍은 사진을 화면에 표시
            ),
        ],
      ),
    );
  }
}
