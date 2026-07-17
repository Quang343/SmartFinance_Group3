import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'storage/firebase_seed_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (details) {
    File('dart_crash.log').writeAsStringSync('FlutterError: ${details.exceptionAsString()}\n${details.stack.toString()}\n', mode: FileMode.append);
    FlutterError.presentError(details);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    File('dart_crash.log').writeAsStringSync('PlatformDispatcher: $error\n$stack\n', mode: FileMode.append);
    return true;
  };
  
  // Load variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
  // Seed Firebase Auth & Firestore data (Admin, Revenue, Expense)
  await FirebaseSeedService.seedDefaultUsers();

  runApp(
    const ProviderScope(
      child: SmartFinanceApp(),
    ),
  );
}
