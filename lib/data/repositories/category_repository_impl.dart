import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserModel? _currentUser;

  CategoryRepositoryImpl(this._firestore, this._auth, this._currentUser);

  String get _uid => _currentUser?.id ?? _auth.currentUser?.uid ?? '';
  String get _company => _currentUser?.company ?? '';
  String get _role => _currentUser?.role ?? '';
  CollectionReference get _collection => _firestore.collection('categories');

  Query _scopeQuery(Query query) {
    if (_role == 'financeManager') {
      return query.where('company', isEqualTo: _company);
    }
    return query.where('createdByUid', isEqualTo: _uid);
  }

  Future<QuerySnapshot> _getWithCacheFallback(Query query) async {
    try {
      return await query.get().timeout(
        const Duration(seconds: 3),
        onTimeout: () => query.get(const GetOptions(source: Source.cache)),
      );
    } catch (e) {
      return await query.get(const GetOptions(source: Source.cache));
    }
  }

  @override
  Future<List<CategoryEntity>> getAll() async {
    if (_uid.isEmpty) return [];
    final snapshot = await _getWithCacheFallback(_scopeQuery(_collection));
    final list = snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<List<CategoryEntity>> getActive() async {
    if (_uid.isEmpty) return [];
    final snapshot = await _getWithCacheFallback(_scopeQuery(_collection).where('isActive', isEqualTo: true));
    final list = snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<List<CategoryEntity>> getByType(TransactionType type) async {
    if (_uid.isEmpty) return [];
    final snapshot = await _getWithCacheFallback(_scopeQuery(_collection).where('type', isEqualTo: type.name).where('isActive', isEqualTo: true));
    final list = snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<CategoryEntity?> getById(String id) async {
    if (_uid.isEmpty) return null;
    try {
      final doc = await _collection.doc(id).get().timeout(
        const Duration(seconds: 3),
        onTimeout: () => _collection.doc(id).get(const GetOptions(source: Source.cache)),
      );
      if (doc.exists) {
        return CategoryModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      try {
        final doc = await _collection.doc(id).get(const GetOptions(source: Source.cache));
        if (doc.exists) {
          return CategoryModel.fromJson(doc.data() as Map<String, dynamic>);
        }
      } catch (_) {}
    }
    return null;
  }

  String _validateAndNormalizeName(String name) {
    if (name.trim().isEmpty) {
      throw Exception('Tên danh mục không được để trống.');
    }
    final normalized = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length > 100) {
      throw Exception('Tên danh mục vượt quá độ dài cho phép.');
    }
    final alphanumeric = normalized.replaceAll(RegExp(r'[^a-zA-Z0-9\p{L}]', unicode: true), '');
    if (alphanumeric.isEmpty) {
      throw Exception('Tên danh mục không hợp lệ.');
    }
    return normalized;
  }

  Future<void> _checkNameUniqueness(String normalizedName, String type, String excludeId) async {
    if (_uid.isEmpty) return;
    final lowerName = normalizedName.toLowerCase();
    final snapshot = await _scopeQuery(_collection).where('type', isEqualTo: type).get();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final existingId = data['id'] as String? ?? doc.id;
      if (existingId == excludeId) continue;
      final existingName = (data['name'] as String? ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
      if (existingName == lowerName) {
        throw Exception('Tên danh mục "$normalizedName" đã tồn tại trong hệ thống!');
      }
    }
  }

  @override
  Future<void> create(CategoryEntity category) async {
    if (_uid.isEmpty) return;
    final normalizedName = _validateAndNormalizeName(category.name);
    await _checkNameUniqueness(normalizedName, category.type, category.id);
    final model = CategoryModel(
      id: category.id,
      name: normalizedName,
      type: category.type,
      iconCode: category.iconCode,
      colorHex: category.colorHex,
      isDefault: category.isDefault,
      isActive: category.isActive,
      orderIndex: category.orderIndex,
      createdByUid: _uid,
      company: _company,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
    await _collection.doc(category.id).set(model.toJson());
  }

  @override
  Future<void> update(CategoryEntity category) async {
    if (_uid.isEmpty) return;
    final normalizedName = _validateAndNormalizeName(category.name);
    await _checkNameUniqueness(normalizedName, category.type, category.id);
    final model = CategoryModel(
      id: category.id,
      name: normalizedName,
      type: category.type,
      iconCode: category.iconCode,
      colorHex: category.colorHex,
      isDefault: category.isDefault,
      isActive: category.isActive,
      orderIndex: category.orderIndex,
      createdByUid: category.createdByUid.isNotEmpty ? category.createdByUid : _uid,
      company: category.company.isNotEmpty ? category.company : _company,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
    try {
      await _collection.doc(category.id).update(model.toJson());
    } catch (e) {
      if (e is FirebaseException && e.code == 'not-found') throw Exception('Không tìm thấy danh mục.');
      rethrow;
    }
  }

  @override
  Future<void> updateOrder(List<CategoryEntity> categories) async {
    if (_uid.isEmpty) return;
    final batch = _firestore.batch();
    for (final cat in categories) {
      final docRef = _collection.doc(cat.id);
      batch.update(docRef, {
        'orderIndex': cat.orderIndex,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> deactivate(String id) async {
    if (_uid.isEmpty) return;
    try {
      await _collection.doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') throw Exception('Không tìm thấy danh mục.');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    if (_uid.isEmpty) return;
    try {
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') throw Exception('Không tìm thấy danh mục.');
      rethrow;
    }
  }
}
