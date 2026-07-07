import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CategoryRepositoryImpl(this._firestore, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';
  CollectionReference get _collection => _firestore.collection('users').doc(_userId).collection('categories');

  @override
  Future<List<CategoryEntity>> getAll() async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CategoryEntity>> getActive() async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection.where('isActive', isEqualTo: true).get();
    return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CategoryEntity>> getByType(TransactionType type) async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection.where('type', isEqualTo: type.name).where('isActive', isEqualTo: true).get();
    return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<CategoryEntity?> getById(String id) async {
    if (_userId.isEmpty) return null;
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return CategoryModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> create(CategoryEntity category) async {
    if (_userId.isEmpty) return;
    final model = CategoryModel(
      id: category.id,
      name: category.name,
      type: category.type,
      iconCode: category.iconCode,
      colorHex: category.colorHex,
      isDefault: category.isDefault,
      isActive: category.isActive,
      orderIndex: category.orderIndex,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
    await _collection.doc(category.id).set(model.toJson());
  }

  @override
  Future<void> update(CategoryEntity category) async {
    if (_userId.isEmpty) return;
    final model = CategoryModel(
      id: category.id,
      name: category.name,
      type: category.type,
      iconCode: category.iconCode,
      colorHex: category.colorHex,
      isDefault: category.isDefault,
      isActive: category.isActive,
      orderIndex: category.orderIndex,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
    await _collection.doc(category.id).update(model.toJson());
  }

  @override
  Future<void> deactivate(String id) async {
    if (_userId.isEmpty) return;
    await _collection.doc(id).update({
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> delete(String id) async {
    if (_userId.isEmpty) return;
    await _collection.doc(id).delete();
  }
}
