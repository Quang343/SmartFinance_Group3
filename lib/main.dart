import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'storage/firebase_seed_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher: $error\n$stack\n');
    return true;
  };
  
  // Load variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Cấu hình tường minh Offline Persistence (Đồng bộ ngoại tuyến)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Seed Firebase Auth & Firestore data (Admin, Revenue, Expense)
  await FirebaseSeedService.seedDefaultUsers();

  runApp(
    const ProviderScope(
      child: SmartFinanceApp(),
    ),
  );
}
