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

  @override
  Future<List<CategoryEntity>> getAll() async {
    if (_uid.isEmpty) return [];
    final snapshot = await _scopeQuery(_collection).get();
    return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CategoryEntity>> getActive() async {
    if (_uid.isEmpty) return [];
    final snapshot = await _scopeQuery(_collection).where('isActive', isEqualTo: true).get();
    return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CategoryEntity>> getByType(TransactionType type) async {
    if (_uid.isEmpty) return [];
    final snapshot = await _scopeQuery(_collection).where('type', isEqualTo: type.name).where('isActive', isEqualTo: true).get();
    return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<CategoryEntity?> getById(String id) async {
    if (_uid.isEmpty) return null;
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return CategoryModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> _checkNameUniqueness(String name, String type, String excludeId) async {
    if (_uid.isEmpty) return;
    final trimmedName = name.trim().toLowerCase();
    final snapshot = await _scopeQuery(_collection).where('type', isEqualTo: type).get();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final existingId = data['id'] as String? ?? doc.id;
      if (existingId == excludeId) continue;
      final existingName = (data['name'] as String? ?? '').trim().toLowerCase();
      if (existingName == trimmedName) {
        throw Exception('Tên danh mục "${name.trim()}" đã tồn tại trong hệ thống!');
      }
    }
  }

  @override
  Future<void> create(CategoryEntity category) async {
    if (_uid.isEmpty) return;
    await _checkNameUniqueness(category.name, category.type, category.id);
    final model = CategoryModel(
      id: category.id,
      name: category.name.trim(),
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
    await _checkNameUniqueness(category.name, category.type, category.id);
    final model = CategoryModel(
      id: category.id,
      name: category.name.trim(),
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
    await _collection.doc(category.id).update(model.toJson());
  }

  @override
  Future<void> deactivate(String id) async {
    if (_uid.isEmpty) return;
    await _collection.doc(id).update({
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> delete(String id) async {
    if (_uid.isEmpty) return;
    await _collection.doc(id).delete();
  }
}
