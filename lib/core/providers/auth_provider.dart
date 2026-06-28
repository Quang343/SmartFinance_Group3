import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_models/isar_user.dart';

final currentUserProvider = StateProvider<IsarUser?>((ref) => null);
