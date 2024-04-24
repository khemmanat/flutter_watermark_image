import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String imageCard = "assets/card.png";

  // base64 image file with watermark
  String base64Image = "";

  ui.Image? idCardImage, watermarkImage;

  Future<ui.Image?> loadCardImage() async {
    ui.Image? idCardImageRes;
    final ByteData data = await rootBundle.load(imageCard);
    final Uint8List bytes = data.buffer.asUint8List();
    idCardImageRes = await decodeImageFromList(bytes);
    return idCardImageRes;
  }

  Future<ui.Image?> loadWatermarkImage() async {
    ui.Image? watermarkImageRes;
    final ByteData data =
        await rootBundle.load("assets/watermarks/watermark.jpg");
    final Uint8List bytes = data.buffer.asUint8List();
    watermarkImageRes = await decodeImageFromList(bytes);
    return watermarkImageRes;
  }

  // prepare images
  Future<void> prepareImages() async {
    idCardImage = await loadCardImage();
    watermarkImage = await loadWatermarkImage();

    if (idCardImage == null && watermarkImage == null) {
      throw Exception("Failed to load images");
    }
  }

  Future<Uint8List> loadAndDisplayWatermarkedImage() async {
    final watermarkedImage =
        await applyWatermark(idCardImage!, watermarkImage!);

    final byteData =
        await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> applyWatermark(ui.Image idCard, ui.Image watermark) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final width = idCard.width.toDouble();
    final height = idCard.height.toDouble();

    final watermarkX = width - watermark.width;
    final watermarkY = height - watermark.height;
    const alpha = 128;

    final paint = Paint()
      ..color = Color.fromARGB(alpha.toInt(), 0, 0, 0)
      ..blendMode = BlendMode.overlay;

    canvas.drawImage(idCard, Offset.zero, Paint());
    canvas.drawImageRect(
        watermark,
        Rect.fromLTWH(watermarkX, watermarkY, watermark.width.toDouble(),
            watermark.height.toDouble()),
        Rect.fromLTWH(watermarkX, watermarkY, watermark.width.toDouble(),
            watermark.height.toDouble()),
        paint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Watermark Image"),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Image.asset(imageCard),
            if (base64Image.isNotEmpty)
              Image.memory(
                base64Decode(base64Image),
              ),
            ElevatedButton(
              onPressed: () {
                prepareImages().then((_) {
                  loadAndDisplayWatermarkedImage().then((watermarkedImage) {
                    setState(() {
                      base64Image = base64Encode(watermarkedImage);
                    });
                  });
                });
              },
              child: const Text("Add Watermark"),
            ),
          ],
        ),
      ),
    );
  }

  // For usage later
  // get base64 image file from given image
  Future<String> getBase64Image(String imagePath) async {
    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();
    return base64Encode(bytes);
  }
}
