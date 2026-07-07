import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/attachment_entity.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../models/attachment_model.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AttachmentRepositoryImpl(this._firestore, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';
  CollectionReference get _collection => _firestore.collection('users').doc(_userId).collection('attachments');

  @override
  Future<List<AttachmentEntity>> getByOwnerId(String ownerId) async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection.where('ownerId', isEqualTo: ownerId).get();
    return snapshot.docs.map((doc) => AttachmentModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<AttachmentEntity?> getById(String id) async {
    if (_userId.isEmpty) return null;
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return AttachmentModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> create(AttachmentEntity attachment) async {
    if (_userId.isEmpty) return;
    final model = AttachmentModel(
      id: attachment.id,
      ownerId: attachment.ownerId,
      ownerType: attachment.ownerType,
      filePath: attachment.filePath,
      createdAt: attachment.createdAt,
      fileName: attachment.fileName,
      mimeType: attachment.mimeType,
    );
    await _collection.doc(attachment.id).set(model.toJson());
  }

  @override
  Future<void> delete(String id) async {
    if (_userId.isEmpty) return;
    await _collection.doc(id).delete();
  }
}
