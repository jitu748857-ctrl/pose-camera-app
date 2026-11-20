import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const PoseCameraApp());
}

class PoseCameraApp extends StatelessWidget {
  const PoseCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose Camera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  int _cameraIndex = 0;
  File? _poseImage;
  double _opacity = 0.45;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _startCamera(_cameraIndex);
  }

  Future<void> _startCamera(int index) async {
    await _controller?.dispose();
    final controller = CameraController(
      cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    await controller.initialize();
    if (mounted) setState(() {});
  }

  void _switchCamera() {
    _cameraIndex = (_cameraIndex + 1) % cameras.length;
    _startCamera(_cameraIndex);
  }

  Future<void> _pickPose() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _poseImage = File(picked.path));
    }
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final file = await controller.takePicture();
    await Gal.putImage(file.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo saved to gallery')),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          if (_poseImage != null)
            IgnorePointer(
              child: Opacity(
                opacity: _opacity,
                child: Image.file(_poseImage!, fit: BoxFit.contain),
              ),
            ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, size: 30),
                  onPressed: _pickPose,
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, size: 30),
                  onPressed: _switchCamera,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Slider(
                  value: _opacity,
                  min: 0.1,
                  max: 0.9,
                  onChanged: (v) => setState(() => _opacity = v),
                ),
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
