import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'storage/firebase_seed_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
