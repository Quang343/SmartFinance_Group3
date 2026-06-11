import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'storage/isar_database.dart';
import 'storage/isar_seed_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarDatabase.open();
  await IsarSeedService.seedIfNeeded();

  runApp(
    const ProviderScope(
      child: SmartFinanceApp(),
    ),
  );
}
