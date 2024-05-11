import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isWorking = false;
  String result = "";
  late CameraController cameraController;
  CameraImage? cameraImage;

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/dict.txt",
      );
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await cameraController.initialize();
      if (mounted) {
        cameraController.startImageStream((imageFromStream) {
          if (!isWorking) {
            setState(() {
              isWorking = true;
              cameraImage = imageFromStream;
              runModelOnStreamFrames();
            });
          }
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  runModelOnStreamFrames() async {
    try {
      if (cameraImage != null) {
        var recognition = await Tflite.runModelOnFrame(
          bytesList: cameraImage!.planes.map((plane) {
            return plane.bytes!;
          }).toList(),
          imageHeight: cameraImage!.height,
          imageWidth: cameraImage!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true,
        );
        // Process the recognition results
        result = "";
        recognition!.forEach((response) {
          result +=
              response["label"] + " " + (response["confidence"] as double).toStringAsFixed(2) + "\n";
        });
        setState(() {
          result;
        });
        isWorking = false;
      }
    } catch (e) {
      print("Error running model: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Image detection")),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: IconButton(
          onPressed: () {
            initCamera();
          },
          icon: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }
}
