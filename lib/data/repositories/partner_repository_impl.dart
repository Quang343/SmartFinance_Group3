import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/partner_entity.dart';
import '../models/partner_model.dart';
import 'partner_repository.dart';

class PartnerRepositoryImpl implements PartnerRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'partners';

  PartnerRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<PartnerEntity>> getPartners(String company) {
    if (company.isEmpty) return Stream.value([]);
    return _firestore
        .collection(_collection)
        .where('company', isEqualTo: company)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PartnerModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<PartnerEntity?> getByTaxCode(String taxCode, String company) async {
    final cleanTax = taxCode.trim();
    if (cleanTax.isEmpty) return null;
    Query query = _firestore.collection(_collection).where('taxCode', isEqualTo: cleanTax);
    if (company.isNotEmpty) {
      query = query.where('company', isEqualTo: company);
    }
    final snapshot = await query.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return PartnerModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  @override
  Future<PartnerEntity> createPartner(PartnerEntity partner) async {
    final docId = partner.id.isNotEmpty ? partner.id : const Uuid().v4();
    final model = PartnerModel(
      id: docId,
      name: partner.name,
      taxCode: partner.taxCode,
      address: partner.address,
      phone: partner.phone,
      bankName: partner.bankName,
      bankAccount: partner.bankAccount,
      createdByUid: partner.createdByUid,
      company: partner.company,
      createdAt: partner.createdAt,
      updatedAt: partner.updatedAt,
    );
    await _firestore.collection(_collection).doc(docId).set(model.toJson());
    return PartnerModel.fromJson(model.toJson(), docId);
  }

  @override
  Future<void> updatePartner(PartnerEntity partner) async {
    final model = PartnerModel(
      id: partner.id,
      name: partner.name,
      taxCode: partner.taxCode,
      address: partner.address,
      phone: partner.phone,
      bankName: partner.bankName,
      bankAccount: partner.bankAccount,
      createdByUid: partner.createdByUid,
      company: partner.company,
      createdAt: partner.createdAt,
      updatedAt: DateTime.now(),
    );
    await _firestore.collection(_collection).doc(partner.id).update(model.toJson());
  }

  @override
  Future<void> deletePartner(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
