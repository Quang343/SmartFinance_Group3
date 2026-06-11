import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/local_invoice_datasource.dart';
import '../mappers/invoice_mapper.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final LocalInvoiceDataSource _dataSource;

  InvoiceRepositoryImpl(this._dataSource);

  @override
  Future<List<InvoiceEntity>> getAll() async {
    final models = await _dataSource.getAll();
    return models.map(InvoiceMapper.toEntity).toList();
  }

  @override
  Future<List<InvoiceEntity>> getByOcrStatus(OcrStatus status) async {
    final models = await _dataSource.getByOcrStatus(status.name);
    return models.map(InvoiceMapper.toEntity).toList();
  }

  @override
  Future<InvoiceEntity?> getById(String id) async {
    final model = await _dataSource.getByUid(id);
    return model != null ? InvoiceMapper.toEntity(model) : null;
  }

  @override
  Future<void> create(InvoiceEntity invoice) async {
    final model = InvoiceMapper.toIsarModel(invoice);
    await _dataSource.create(model);
  }

  @override
  Future<void> update(InvoiceEntity invoice) async {
    final model = InvoiceMapper.toIsarModel(invoice);
    await _dataSource.update(model);
  }

  @override
  Future<void> delete(String id) async {
    await _dataSource.delete(id);
  }
}
