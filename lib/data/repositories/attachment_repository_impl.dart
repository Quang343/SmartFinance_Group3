import '../../domain/entities/attachment_entity.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../datasources/local_attachment_datasource.dart';
import '../mappers/attachment_mapper.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final LocalAttachmentDataSource _dataSource;

  AttachmentRepositoryImpl(this._dataSource);

  @override
  Future<List<AttachmentEntity>> getByOwnerId(String ownerId) async {
    final models = await _dataSource.getByOwnerId(ownerId);
    return models.map(AttachmentMapper.toEntity).toList();
  }

  @override
  Future<AttachmentEntity?> getById(String id) async {
    final model = await _dataSource.getByUid(id);
    return model != null ? AttachmentMapper.toEntity(model) : null;
  }

  @override
  Future<void> create(AttachmentEntity attachment) async {
    final model = AttachmentMapper.toIsarModel(attachment);
    await _dataSource.create(model);
  }

  @override
  Future<void> delete(String id) async {
    await _dataSource.delete(id);
  }
}
