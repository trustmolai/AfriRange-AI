import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewScreen extends StatefulWidget {
  final Function(XFile file) onPhotoCaptured;

  const CameraPreviewScreen({super.key, required this.onPhotoCaptured});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final file = await _controller!.takePicture();
      widget.onPhotoCaptured(file);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Camera access denied or unavailable.', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Center target plant'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          
          // Outer overlay bounds framing guide
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Green border guide line
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'FIT PLANT INSIDE FRAME',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.black45),
                  ),
                ),
              ),
            ),
          ),

          // Capture Control Action Bar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2E7D32), width: 6),
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                          )
                        : null,
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
