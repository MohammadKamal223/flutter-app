import 'dart:ffi'; // Dart FFI for native calls
import 'dart:io';
import 'package:ffi/ffi.dart';

// Define a class to handle Vosk API calls
class VoskService {
  late DynamicLibrary _voskLib;

  Future<void> initVosk() async {
    try {
      // Load the vosk.dll from your Windows build
      _voskLib = DynamicLibrary.open("windows/libs/vosk.dll");

      // Ensure Vosk is initialized
      final Pointer<NativeFunction<Void Function()>> initFunc =
          _voskLib.lookup("vosk_init");
      initFunc.asFunction<void Function()>()();

      print("✅ Vosk Initialized Successfully on Windows!");
    } catch (e) {
      print("❌ Error loading Vosk on Windows: $e");
    }
  }
}
