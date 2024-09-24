import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  String? _analysisResult; // 분석 결과를 저장할 변수

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
      await _uploadImageAndAnalyze(_image!); // 사진을 찍고 분석 요청
    }
  }

  // OpenAI API로 사진을 보내고 분석 결과 받기
  Future<void> _uploadImageAndAnalyze(File imageFile) async {

    // 파일을 multipart 형식으로 전송
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/chat/completions'), // OpenAI API 이미지 엔드포인트
    );

    // 요청 헤더에 API 키 추가
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.headers['Content-Type'] = 'multipart/form-data';

    // 파일 추가
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    // 요청 보내기
    var response = await request.send();

    // 응답 처리
    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);
      var decodedData = jsonDecode(responseData.body);
      setState(() {
        _analysisResult = decodedData.toString(); // 분석 결과를 저장
      });
    } else {
      setState(() {
        _analysisResult = '분석 실패: ${response.statusCode}';
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
              child: Text('분석 결과: $_analysisResult'),
            ),
        ],
      ),
    );
  }
}
