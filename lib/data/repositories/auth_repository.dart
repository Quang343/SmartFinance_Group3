import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../storage/isar_database.dart';
import '../local/isar_models/isar_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(IsarDatabase.instance);
});

class AuthRepository {
  final Isar _isar;

  AuthRepository(this._isar);

  Future<IsarUser?> login(String identifier, String password) async {
    // Cho phép đăng nhập bằng cả email đầy đủ hoặc chỉ username (phần trước @)
    final user = await _isar.isarUsers
        .filter()
        .emailEqualTo(identifier)
        .or()
        .emailStartsWith('$identifier@')
        .findFirst();

    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  Future<void> register(IsarUser user) async {
    final existing = await _isar.isarUsers.filter().emailEqualTo(user.email).findFirst();
    if (existing != null) {
      throw Exception('Email này đã được sử dụng');
    }

    await _isar.writeTxn(() async {
      await _isar.isarUsers.put(user);
    });
  }
}
