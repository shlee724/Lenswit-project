import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  await dotenv.load(fileName: ".env");    // 2번코드
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
    _analysisResult = "분석중...";
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);  // 카메라를 열어서 사진 찍기
    if (photo != null) {
      setState(() {
        _image = File(photo.path);  // 찍은 사진을 저장
      });
      await _analyzeImage(); // 사진을 찍고 분석 요청
    }
  }

  Future<String> analyzeImage(String base64Image) async {
    final apiKey = dotenv.env['OPENAI_API_KEY']; // OpenAI API 키 입력
    final apiUrl = 'https://api.openai.com/v1/chat/completions';
    print("base64Image:" + base64Image);

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey'
      },
      body: json.encode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text',
               'text': '이 콘택트 렌즈가 뒤집혔는지 정상인지 알려줘. 정상일 가능성이 더 높다면'
                   '"정상입니다!" 라고 말하고, 뒤집혔을 가능성이 더 높다면 "뒤집혔습니다" 라고 말해'
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'}
              }
            ]
          }
        ],
        'max_tokens': 1000
      }),
    );
    // 응답을 UTF-8로 디코딩하여 처리
    final decodedBody = utf8.decode(response.bodyBytes);

    final responseMap = {
      'Status Code': response.statusCode,
      'Body': response.body,
      'Body Bytes': response.bodyBytes,
      'Headers': response.headers,
      'Content Length': response.contentLength,
      'Reason Phrase': response.reasonPhrase,
      'Request': response.request.toString(),
      'Persistent Connection': response.persistentConnection,
      'Is Redirect': response.isRedirect
    };

    print(responseMap);
    if (response.statusCode == 200) {
      final data = jsonDecode(decodedBody);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to analyze image: ${response.statusCode}');
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    final bytes = await _image!.readAsBytes();
    final base64Image = base64Encode(bytes);

    try {
      final result = await analyzeImage(base64Image);
      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      setState(() {
        _analysisResult = 'Error: $e';
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
              'assets/images/main_page.jpg',
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
              top: MediaQuery.of(context).size.height * 0.6, // 화면의 정중앙보다 약간 아래로 설정
              left: 50,
              right: 50,
              child: Text(
                '분석 결과: $_analysisResult',
                style: TextStyle(
                  color: Colors.white, // 텍스트 색상을 하얗게 설정
                  fontSize: 24, // 기존보다 글자 크기를 크게 설정
                ),
                textAlign: TextAlign.center, // 텍스트를 중앙 정렬
              ),
            ),
        ],
      ),
    );
  }
}
