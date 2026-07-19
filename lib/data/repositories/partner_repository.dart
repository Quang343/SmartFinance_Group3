import '../../domain/entities/partner_entity.dart';

abstract class PartnerRepository {
  Stream<List<PartnerEntity>> getPartners(String company);
  Future<PartnerEntity> createPartner(PartnerEntity partner);
  Future<void> updatePartner(PartnerEntity partner);
  Future<void> deletePartner(String id);
}
