import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'vosk_service.dart';

class SpeechService {
  late VoskService _voskService;
  Pointer<Void>? _model;
  Pointer<Void>? _recognizer;

  SpeechService() {
    _voskService = VoskService();
  }

  Future<void> initVosk() async {
    if (!Platform.isWindows) return; // Only run on Windows

    await _voskService.initVosk(); // Ensure Vosk is loaded

    try {
      final DynamicLibrary voskLib = DynamicLibrary.open("windows/libs/vosk.dll");

      // Load Vosk Model
      final Pointer<Utf8> modelPath = "assets/vosk-model-small-en-us-0.15".toNativeUtf8();
      final modelFunc = voskLib.lookupFunction<Pointer<Void> Function(Pointer<Utf8>), Pointer<Void> Function(Pointer<Utf8>)>("vosk_model_new");
      _model = modelFunc(modelPath);

      // Create Recognizer
      final recognizerFunc = voskLib.lookupFunction<Pointer<Void> Function(Pointer<Void>, Double), Pointer<Void> Function(Pointer<Void>, double)>("vosk_recognizer_new");
      _recognizer = recognizerFunc(_model!, 16000);

      print("✅ Vosk Speech Recognition Initialized!");
    } catch (e) {
      print("❌ Error initializing Vosk SpeechService: $e");
    }
  }

  Future<String> recognizeAudio(String audioFilePath) async {
    if (!Platform.isWindows || _recognizer == null) return "❌ Vosk not initialized";

    try {
      final DynamicLibrary voskLib = DynamicLibrary.open("windows/libs/vosk.dll");

      // Load audio file as input
      final Pointer<Utf8> audioPath = audioFilePath.toNativeUtf8();
      final acceptWaveformFunc = voskLib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>), int Function(Pointer<Void>, Pointer<Utf8>)>("vosk_recognizer_accept_waveform");
      final int result = acceptWaveformFunc(_recognizer!, audioPath);

      // Get final text result
      if (result == 1) {
        final finalResultFunc = voskLib.lookupFunction<Pointer<Utf8> Function(Pointer<Void>), Pointer<Utf8> Function(Pointer<Void>)>("vosk_recognizer_final_result");
        return finalResultFunc(_recognizer!).toDartString();
      } else {
        return "❌ Speech not recognized.";
      }
    } catch (e) {
      return "❌ Error recognizing audio: $e";
    }
  }

  void dispose() {
    if (!Platform.isWindows) return;
    
    final DynamicLibrary voskLib = DynamicLibrary.open("windows/libs/vosk.dll");

    if (_recognizer != null) {
      final recognizerFreeFunc = voskLib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>("vosk_recognizer_free");
      recognizerFreeFunc(_recognizer!);
    }

    if (_model != null) {
      final modelFreeFunc = voskLib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>("vosk_model_free");
      modelFreeFunc(_model!);
    }

    print("✅ Vosk SpeechService disposed!");
  }
}
