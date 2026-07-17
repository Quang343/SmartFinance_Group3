import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/attachment_entity.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../models/attachment_model.dart';
import '../models/user_model.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserModel? _currentUser;

  AttachmentRepositoryImpl(this._firestore, this._auth, this._currentUser);

  String get _uid => _currentUser?.id ?? _auth.currentUser?.uid ?? '';
  String get _company => _currentUser?.company ?? '';
  String get _role => _currentUser?.role ?? '';
  CollectionReference get _collection => _firestore.collection('attachments');

  @override
  Future<List<AttachmentEntity>> getByOwnerId(String ownerId) async {
    if (_uid.isEmpty) return [];
    Query query = _collection.where('ownerId', isEqualTo: ownerId);
    if (_role == 'financeManager') {
      query = query.where('company', isEqualTo: _company);
    } else {
      query = query.where('createdByUid', isEqualTo: _uid);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => AttachmentModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<AttachmentEntity?> getById(String id) async {
    if (_uid.isEmpty) return null;
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return AttachmentModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> create(AttachmentEntity attachment) async {
    if (_uid.isEmpty) return;
    final model = AttachmentModel(
      id: attachment.id,
      ownerId: attachment.ownerId,
      ownerType: attachment.ownerType,
      filePath: attachment.filePath,
      createdAt: attachment.createdAt,
      fileName: attachment.fileName,
      mimeType: attachment.mimeType,
      createdByUid: _uid,
      company: _company,
    );
    await _collection.doc(attachment.id).set(model.toJson());
  }

  @override
  Future<void> delete(String id) async {
    if (_uid.isEmpty) return;
    await _collection.doc(id).delete();
  }
}
