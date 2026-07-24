import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/domain/entities/partner_entity.dart';
import 'package:smart_finance/domain/entities/invoice_item_entity.dart';
import 'package:smart_finance/core/widgets/scale_on_tap.dart';
import 'package:smart_finance/data/repositories/storage_repository.dart';
import 'package:smart_finance/core/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:smart_finance/core/sync/sync_item.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import '../providers/invoice_provider.dart';
class _ItemFormState {
  final TextEditingController nameController;
  final TextEditingController unitController;
  final TextEditingController quantityController;
  final TextEditingController priceController;

  _ItemFormState({String name = '', String unit = 'Lần', int quantity = 1, int price = 0})
      : nameController = TextEditingController(text: name),
        unitController = TextEditingController(text: unit),
        quantityController = TextEditingController(text: quantity.toString()),
        priceController = TextEditingController(text: price > 0 ? price.toString() : '');

  int get amount => (int.tryParse(quantityController.text) ?? 0) * (int.tryParse(priceController.text) ?? 0);

  void dispose() {
    nameController.dispose();
    unitController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  final InvoiceType invoiceType;
  final String? invoiceId;
  final String? scannedImagePath;
  final String? scannedSellerName;
  final String? scannedTaxCode;
  final int? scannedSubtotal;
  final int? scannedVatRate;
  final int? scannedTotalAmount;

  const InvoiceCreateScreen({
    super.key,
    this.invoiceType = InvoiceType.outgoing,
    this.invoiceId,
    this.scannedImagePath,
    this.scannedSellerName,
    this.scannedTaxCode,
    this.scannedSubtotal,
    this.scannedVatRate,
    this.scannedTotalAmount,
  });

  @override
  ConsumerState<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partnerContactNameController = TextEditingController();
  final _partnerNameController = TextEditingController();
  final _partnerTaxCodeController = TextEditingController();
  final _partnerAddressController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  
  final _sellerNameController = TextEditingController();
  final _sellerTaxCodeController = TextEditingController();
  final _sellerAddressController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _sellerBankNameController = TextEditingController();
  final _sellerBankAccountController = TextEditingController();

  String _paymentMethod = 'TM';
  
  final List<_ItemFormState> _items = [_ItemFormState()];
  final _vatRateController = TextEditingController(text: '10');

  final _formNumberController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  bool _isLoadingFormatInfo = false;

  int get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  int get _vatRate => int.tryParse(_vatRateController.text) ?? 0;
  int get _vatAmount => (_subtotal * _vatRate / 100).round();
  int get _totalAmount => _subtotal + _vatAmount;

  bool _isSaving = false;
  bool _saveToPartner = false;
  InvoiceEntity? _existingInvoice;


  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    
    final myCompanyName = user?.company ?? '';
    final myTaxCode = user?.taxCode ?? '';
    final myAddress = user?.address ?? '';
    final myPhone = user?.phone ?? '';
    final myBankName = user?.bankName ?? '';
    final myBankAccount = user?.bankAccount ?? '';

    if (widget.invoiceId != null) {
      _loadExistingInvoice();
    } else {
      if (widget.invoiceType == InvoiceType.outgoing) {
        _sellerNameController.text = myCompanyName;
        _sellerTaxCodeController.text = myTaxCode;
        _sellerAddressController.text = myAddress;
        _sellerPhoneController.text = myPhone;
        _sellerBankNameController.text = myBankName;
        _sellerBankAccountController.text = myBankAccount;
      } else {
        _partnerNameController.text = myCompanyName;
        _partnerTaxCodeController.text = myTaxCode;
        _partnerAddressController.text = myAddress;
        _bankNameController.text = myBankName;
        _bankAccountController.text = myBankAccount;
        
        _sellerNameController.text = widget.scannedSellerName ?? '';
        _sellerTaxCodeController.text = widget.scannedTaxCode ?? '';
        if (widget.scannedVatRate != null) {
          _vatRateController.text = widget.scannedVatRate.toString();
        }
        
        if (widget.invoiceType == InvoiceType.incoming) {
          _sellerNameController.text = widget.scannedSellerName ?? '';
          _sellerTaxCodeController.text = widget.scannedTaxCode ?? '';
          int subtotalVal = widget.scannedSubtotal ?? 0;
          _vatRateController.text = (widget.scannedVatRate ?? 0).toString();
          if (subtotalVal > 0) {
            _items.clear();
            _items.add(_ItemFormState(name: 'Hàng hóa / Dịch vụ (OCR)', unit: 'Gói', quantity: 1, price: subtotalVal));
          }
        }
      }

      _loadOutgoingInvoiceFormat();
    }
  }

  Future<void> _loadExistingInvoice() async {
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final queueService = ref.read(syncQueueServiceProvider);

      InvoiceEntity? invoice = await repo.getById(widget.invoiceId!);

      // Kiểm tra hàng đợi để lấy bản nháp offline mới nhất
      final syncItem = queueService.queue.firstWhereOrNull((e) => e.entityId == widget.invoiceId);
      if (syncItem != null && syncItem.payload.isNotEmpty) {
        invoice = InvoiceModel.fromJson(syncItem.payload);
      }

      if (invoice != null) {
        _existingInvoice = invoice;
        _formNumberController.text = invoice.formNumber ?? '';
        _serialNumberController.text = invoice.serialNumber ?? '';
        
        final parts = invoice.invoiceNumber.split('-');
        _invoiceNumberController.text = parts.isNotEmpty ? parts.last : invoice.invoiceNumber;
        
        _sellerNameController.text = invoice.sellerName;
        _sellerTaxCodeController.text = invoice.sellerTaxCode;
        _sellerAddressController.text = invoice.sellerAddress ?? '';
        _sellerPhoneController.text = invoice.sellerPhone ?? '';
        _sellerBankNameController.text = invoice.sellerBankName ?? '';
        _sellerBankAccountController.text = invoice.sellerBankAccount ?? '';

        _partnerContactNameController.text = invoice.buyerContactName ?? '';
        _partnerNameController.text = invoice.buyerName;
        _partnerTaxCodeController.text = invoice.buyerTaxCode;
        _partnerAddressController.text = invoice.buyerAddress ?? '';
        _bankNameController.text = invoice.buyerBankName ?? '';
        _bankAccountController.text = invoice.buyerBankAccount ?? '';

        _paymentMethod = invoice.paymentMethod ?? 'TM';
        _vatRateController.text = invoice.vatRate.toString();

        _items.clear();
        if (invoice.items.isNotEmpty) {
          for (var item in invoice.items) {
            _items.add(_ItemFormState(
              name: item.itemName,
              unit: item.unit,
              quantity: item.quantity.toInt(),
              price: item.unitPrice,
            ));
          }
        } else {
          _items.add(_ItemFormState());
        }
        
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading existing invoice: $e');
    }
  }

  Future<void> _loadOutgoingInvoiceFormat() async {
    if (widget.invoiceType != InvoiceType.outgoing) return;
    setState(() => _isLoadingFormatInfo = true);
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final nextId = await repo.getNextSequentialId(InvoiceType.outgoing);
      final yearSuffix = DateTime.now().year.toString().substring(2);
      
      _formNumberController.text = '01GTKT0/001';
      _serialNumberController.text = 'AA/${yearSuffix}E';
      _invoiceNumberController.text = nextId.toString().padLeft(8, '0');
    } catch (e) {
      debugPrint('Error loading next sequential ID: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFormatInfo = false);
    }
  }

  @override
  void dispose() {
    _partnerContactNameController.dispose();
    _partnerNameController.dispose();
    _partnerTaxCodeController.dispose();
    _partnerAddressController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _sellerNameController.dispose();
    _sellerTaxCodeController.dispose();
    _sellerAddressController.dispose();
    _sellerPhoneController.dispose();
    _sellerBankNameController.dispose();
    _sellerBankAccountController.dispose();
    _vatRateController.dispose();
    _formNumberController.dispose();
    _serialNumberController.dispose();
    _invoiceNumberController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _saveInvoice() async {
    if (_isSaving) return;
    
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng thêm ít nhất 1 dịch vụ')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final repo = ref.read(invoiceRepositoryProvider);
        final storageRepo = ref.read(storageRepositoryProvider);
        final newInvoiceId = _existingInvoice?.id ?? const Uuid().v4();
        
        String? finalImagePath;
        
        if (widget.invoiceType == InvoiceType.incoming && widget.scannedImagePath != null) {
          if (!widget.scannedImagePath!.startsWith('http')) {
             try {
             if (kIsWeb) {
              final response = await http.get(Uri.parse(widget.scannedImagePath!));
              if (response.statusCode == 200) {
                final uploadedUrl = await storageRepo.uploadInvoiceImage(newInvoiceId, webFile: response.bodyBytes, fileName: 'invoice.png');
                if (uploadedUrl != null) {
                  finalImagePath = uploadedUrl;
                }
              }
            } else {
              final uploadedUrl = await storageRepo.uploadInvoiceImage(newInvoiceId, file: File(widget.scannedImagePath!));
              if (uploadedUrl != null) {
                finalImagePath = uploadedUrl;
              }
            } } catch (e) {
               debugPrint('Lỗi upload ảnh (Có thể do đang Offline): $e');
               finalImagePath = widget.scannedImagePath; // Lưu tạm đường dẫn local
             }
          } else {
             finalImagePath = widget.scannedImagePath;
          }
        } else if (_existingInvoice != null) {
          finalImagePath = _existingInvoice!.imagePath;
        }
      
        final invoiceItems = _items.map((item) {
          final itemId = const Uuid().v4();
          return InvoiceItemEntity(
            id: itemId,
            itemCode: itemId.substring(0, 8).toUpperCase(),
            itemName: item.nameController.text,
            unit: item.unitController.text,
            quantity: double.tryParse(item.quantityController.text) ?? 0.0,
            unitPrice: int.tryParse(item.priceController.text) ?? 0,
            totalAmount: item.amount,
          );
        }).toList();

        String formNum = _formNumberController.text.trim();
        String serialNum = _serialNumberController.text.trim();
        String seqNum = _invoiceNumberController.text.trim();
        String sellerTax = _sellerTaxCodeController.text.trim();
        
        String generatedInvoiceNumber;
        if (widget.invoiceType == InvoiceType.outgoing) {
           generatedInvoiceNumber = 'INV-$formNum-$serialNum-$seqNum';
        } else {
           generatedInvoiceNumber = 'OCR-INV-$sellerTax-$formNum-$serialNum-$seqNum';
        }

        // Check if invoice already exists
        if (_existingInvoice == null || _existingInvoice!.invoiceNumber != generatedInvoiceNumber) {
          final isExists = await repo.checkInvoiceExists(sellerTax, formNum, serialNum, generatedInvoiceNumber);
          if (isExists) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hóa đơn $generatedInvoiceNumber đã tồn tại, vui lòng sửa lại thông tin'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() => _isSaving = false);
            }
            return;
          }
        }

        final newInvoice = InvoiceEntity(
          id: newInvoiceId,
          invoiceNumber: generatedInvoiceNumber,
          formNumber: formNum,
          serialNumber: serialNum,
          sellerName: _sellerNameController.text,
          sellerTaxCode: _sellerTaxCodeController.text,
          sellerAddress: _sellerAddressController.text,
          sellerPhone: _sellerPhoneController.text,
          sellerBankName: _sellerBankNameController.text.isNotEmpty ? _sellerBankNameController.text : null,
          sellerBankAccount: _sellerBankAccountController.text.isNotEmpty ? _sellerBankAccountController.text : null,
          buyerContactName: _partnerContactNameController.text.isNotEmpty ? _partnerContactNameController.text : null,
          buyerName: _partnerNameController.text,
          buyerTaxCode: _partnerTaxCodeController.text,
          buyerAddress: _partnerAddressController.text.isNotEmpty ? _partnerAddressController.text : null,
          buyerBankName: _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
          buyerBankAccount: _bankAccountController.text.isNotEmpty ? _bankAccountController.text : null,
          paymentMethod: _paymentMethod,
          items: invoiceItems,
          subtotal: _subtotal,
          vatRate: _vatRate,
          vatAmount: _vatAmount,
          totalAmount: _totalAmount,
          ocrStatus: _existingInvoice?.ocrStatus ?? OcrStatus.extracted,
          transactionStatus: _existingInvoice?.transactionStatus ?? InvoiceTransactionStatus.notCreated,
          ocrConfidence: _existingInvoice?.ocrConfidence ?? 1.0,
          type: widget.invoiceType,
          issuedDate: DateTime.now(), // Cập nhật lại ngày xuất? Có thể giữ nguyên
          createdAt: _existingInvoice?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          imagePath: finalImagePath,
        );

        final newInvoiceModel = InvoiceModel(
          id: newInvoice.id,
          invoiceNumber: newInvoice.invoiceNumber,
          formNumber: newInvoice.formNumber,
          serialNumber: newInvoice.serialNumber,
          sellerName: newInvoice.sellerName,
          sellerTaxCode: newInvoice.sellerTaxCode,
          sellerAddress: newInvoice.sellerAddress,
          sellerPhone: newInvoice.sellerPhone,
          sellerBankName: newInvoice.sellerBankName,
          sellerBankAccount: newInvoice.sellerBankAccount,
          buyerContactName: newInvoice.buyerContactName,
          buyerName: newInvoice.buyerName,
          buyerTaxCode: newInvoice.buyerTaxCode,
          buyerAddress: newInvoice.buyerAddress,
          buyerBankName: newInvoice.buyerBankName,
          buyerBankAccount: newInvoice.buyerBankAccount,
          paymentMethod: newInvoice.paymentMethod,
          items: newInvoice.items,
          subtotal: newInvoice.subtotal,
          vatRate: newInvoice.vatRate,
          vatAmount: newInvoice.vatAmount,
          totalAmount: newInvoice.totalAmount,
          ocrStatus: newInvoice.ocrStatus,
          transactionStatus: newInvoice.transactionStatus,
          ocrConfidence: newInvoice.ocrConfidence,
          type: newInvoice.type,
          issuedDate: newInvoice.issuedDate,
          createdAt: newInvoice.createdAt,
          updatedAt: newInvoice.updatedAt,
          imagePath: newInvoice.imagePath,
          status: newInvoice.status,
        );

        final queueService = ref.read(syncQueueServiceProvider);
        
        final syncItem = SyncItem(
          id: const Uuid().v4(),
          collection: 'invoices',
          action: _existingInvoice != null ? SyncAction.update : SyncAction.create,
          entityId: newInvoiceId,
          payload: newInvoiceModel.toJson(),
        );

        bool isOfflineSuccess = false;

        if (widget.invoiceType == InvoiceType.outgoing) {
           await queueService.enqueue(syncItem);
        }

        try {
          if (_existingInvoice != null) {
            await repo.update(newInvoice).timeout(const Duration(seconds: 3));
          } else {
            await repo.create(newInvoice).timeout(const Duration(seconds: 3));
          }
          if (widget.invoiceType == InvoiceType.outgoing) {
             await queueService.removeItem(syncItem.id);
          }
        } on TimeoutException {
          if (widget.invoiceType == InvoiceType.incoming) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yêu cầu kết nối mạng để lưu hóa đơn đầu vào (Cần để upload ảnh scan)'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() => _isSaving = false);
            }
            return;
          } else {
            isOfflineSuccess = true;
          }
        } catch (e) {
          if (widget.invoiceType == InvoiceType.outgoing) {
             await queueService.markAsError(syncItem.id, e.toString());
          }
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
             setState(() => _isSaving = false);
          }
          return;
        }

        if (_saveToPartner) {
          final partnerRepo = ref.read(partnerRepositoryProvider);
          final user = ref.read(currentUserProvider);
          if (user != null) {
            final isOutgoing = widget.invoiceType == InvoiceType.outgoing;
            final name = (isOutgoing ? _partnerNameController.text : _sellerNameController.text).trim();
            final taxCode = (isOutgoing ? _partnerTaxCodeController.text : _sellerTaxCodeController.text).trim();
            final address = (isOutgoing ? _partnerAddressController.text : _sellerAddressController.text).trim();
            final phone = isOutgoing ? '' : _sellerPhoneController.text.trim();
            final bankName = (isOutgoing ? _bankNameController.text : _sellerBankNameController.text).trim();
            final bankAccount = (isOutgoing ? _bankAccountController.text : _sellerBankAccountController.text).trim();

            if (name.isNotEmpty || taxCode.isNotEmpty) {
              try {
                PartnerEntity? existingPartner;
                if (taxCode.isNotEmpty) {
                  existingPartner = await partnerRepo.getByTaxCode(taxCode, user.company);
                }

                if (existingPartner != null) {
                  final updatedPartner = PartnerEntity(
                    id: existingPartner.id,
                    name: name.isNotEmpty ? name : existingPartner.name,
                    taxCode: taxCode.isNotEmpty ? taxCode : existingPartner.taxCode,
                    address: address.isNotEmpty ? address : existingPartner.address,
                    phone: phone.isNotEmpty ? phone : existingPartner.phone,
                    bankName: bankName.isNotEmpty ? bankName : existingPartner.bankName,
                    bankAccount: bankAccount.isNotEmpty ? bankAccount : existingPartner.bankAccount,
                    createdByUid: existingPartner.createdByUid,
                    company: existingPartner.company,
                    createdAt: existingPartner.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  await partnerRepo.updatePartner(updatedPartner);
                } else {
                  final newPartner = PartnerEntity(
                    id: const Uuid().v4(),
                    name: name,
                    taxCode: taxCode,
                    address: address,
                    phone: phone,
                    bankName: bankName,
                    bankAccount: bankAccount,
                    createdByUid: user.id,
                    company: user.company,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await partnerRepo.createPartner(newPartner);
                }
              } catch (e) {
                debugPrint('Error saving/updating partner: $e');
              }
            }
          }
        }

        // Refresh lists
        ref.invalidate(allInvoicesProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOfflineSuccess
                    ? 'Đã lưu ngoại tuyến (Sẽ đồng bộ khi có mạng)'
                    : (widget.invoiceType == InvoiceType.outgoing ? 'Hóa đơn đã được tạo thành công!' : 'Hóa đơn đã được lưu thành công!')
              ),
              backgroundColor: isOfflineSuccess ? Colors.orange : Colors.green,
            ),
          );
          if (widget.invoiceType == InvoiceType.outgoing) {
            context.go('/invoices/outgoing');
          } else {
            context.go('/invoices/incoming');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Có lỗi xảy ra: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  void _showPartnerSelectionDialog(bool isBuyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryColor = const Color(0xFF00D09E);
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF060E0A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Chọn đối tác từ danh bạ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final partnersAsync = ref.watch(partnerStreamProvider);
                        return partnersAsync.when(
                          data: (partners) {
                            if (partners.isEmpty) {
                              return const Center(child: Text('Danh bạ trống', style: TextStyle(color: Colors.grey)));
                            }
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: partners.length,
                              itemBuilder: (context, index) {
                                final p = partners[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                                    child: Icon(Icons.business, color: primaryColor),
                                  ),
                                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('MST: ${p.taxCode}'),
                                  onTap: () {
                                    setState(() {
                                      if (isBuyer) {
                                        _partnerNameController.text = p.name;
                                        _partnerTaxCodeController.text = p.taxCode;
                                        _partnerAddressController.text = p.address ?? '';
                                        _bankNameController.text = p.bankName ?? '';
                                        _bankAccountController.text = p.bankAccount ?? '';
                                      } else {
                                        _sellerNameController.text = p.name;
                                        _sellerTaxCodeController.text = p.taxCode;
                                        _sellerAddressController.text = p.address ?? '';
                                        _sellerPhoneController.text = p.phone ?? '';
                                        _sellerBankNameController.text = p.bankName ?? '';
                                        _sellerBankAccountController.text = p.bankAccount ?? '';
                                      }
                                      _saveToPartner = false; // Đã chọn từ danh bạ thì không cần lưu mới
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                          loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
                          error: (err, stack) => Center(child: Text('Lỗi: $err')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addSampleData(String type) {
    setState(() {
      if (widget.invoiceType == InvoiceType.outgoing) {
        if (type == 'it') {
          _partnerContactNameController.text = 'Trần Văn IT';
          _partnerNameController.text = 'CTY TNHH Công Nghệ Tương Lai';
          _partnerTaxCodeController.text = '0123456789';
          _partnerAddressController.text = '456 Đường Sáng Tạo, Quận 3, TP. HCM';
          _vatRateController.text = '10';
          final oldItems = List.of(_items);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var item in oldItems) { item.dispose(); }
          });
          _items.clear();
          _items.add(_ItemFormState(name: 'Phát triển phần mềm', unit: 'Gói', quantity: 1, price: 15000000));
          _items.add(_ItemFormState(name: 'Bảo trì hệ thống tháng 7', unit: 'Tháng', quantity: 1, price: 5000000));
        } else if (type == 'consulting') {
          _partnerContactNameController.text = 'Lê Văn Tư Vấn';
          _partnerNameController.text = 'Tập Đoàn Tư Vấn Global';
          _partnerTaxCodeController.text = '1122334455';
          _partnerAddressController.text = '88 Đường Hội Nhập, Quận 1, TP. HCM';
          _vatRateController.text = '10';
          _items.clear();
          _items.add(_ItemFormState(name: 'Dịch vụ tư vấn chiến lược', unit: 'Gói', quantity: 1, price: 20000000));
        } else if (type == 'furniture') {
          _partnerContactNameController.text = 'Nguyễn Thị Nội Thất';
          _partnerNameController.text = 'Nội Thất Sang Trọng';
          _partnerTaxCodeController.text = '0987654321';
          _partnerAddressController.text = '100 Đường Tương Lai, Quận 7, TP. HCM';
          _vatRateController.text = '8';
          final oldItems = List.of(_items);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var item in oldItems) { item.dispose(); }
          });
          _items.clear();
          _items.add(_ItemFormState(name: 'Bàn làm việc gỗ sồi', unit: 'Cái', quantity: 5, price: 5000000));
          _items.add(_ItemFormState(name: 'Ghế xoay văn phòng', unit: 'Cái', quantity: 5, price: 1200000));
        } else if (type == 'shipping') {
          _partnerContactNameController.text = 'Trần Văn Vận Tải';
          _partnerNameController.text = 'Giao Hàng Nhanh Chóng';
          _partnerTaxCodeController.text = '0369852147';
          _partnerAddressController.text = '12 Đường Vận Tải, Quận 4, TP. HCM';
          _vatRateController.text = '10';
          final oldItems = List.of(_items);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var item in oldItems) { item.dispose(); }
          });
          _items.clear();
          _items.add(_ItemFormState(name: 'Dịch vụ vận chuyển Bắc Nam', unit: 'Chuyến', quantity: 2, price: 2750000));
        }
      } else {
        // Hóa đơn đầu vào (Incoming): MOCK DATA điền vào phần NGƯỜI BÁN
        if (type == 'it') {
          _sellerNameController.text = 'CTY TNHH Công Nghệ Tương Lai';
          _sellerTaxCodeController.text = '0123456789';
          _sellerAddressController.text = '456 Đường Sáng Tạo, Quận 3, TP. HCM';
          _vatRateController.text = '10';
          final oldItems = List.of(_items);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var item in oldItems) { item.dispose(); }
          });
          _items.clear();
          _items.add(_ItemFormState(name: 'Phát triển phần mềm', unit: 'Gói', quantity: 1, price: 15000000));
          _items.add(_ItemFormState(name: 'Bảo trì hệ thống tháng 7', unit: 'Tháng', quantity: 1, price: 5000000));
        } else if (type == 'consulting') {
          _sellerNameController.text = 'Tập Đoàn Tư Vấn Global';
          _sellerTaxCodeController.text = '1122334455';
          _sellerAddressController.text = '88 Đường Hội Nhập, Quận 1, TP. HCM';
          _vatRateController.text = '10';
          _items.clear();
          _items.add(_ItemFormState(name: 'Dịch vụ tư vấn chiến lược', unit: 'Gói', quantity: 1, price: 20000000));
        } else if (type == 'furniture') {
          _sellerNameController.text = 'Nội Thất Sang Trọng';
          _sellerTaxCodeController.text = '0987654321';
          _sellerAddressController.text = '100 Đường Tương Lai, Quận 7, TP. HCM';
          _vatRateController.text = '8';
          final oldItems = List.of(_items);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var item in oldItems) { item.dispose(); }
          });
          _items.clear();
          _items.add(_ItemFormState(name: 'Bàn làm việc gỗ sồi', unit: 'Cái', quantity: 5, price: 5000000));
          _items.add(_ItemFormState(name: 'Ghế xoay văn phòng', unit: 'Cái', quantity: 5, price: 1200000));
        } else if (type == 'shipping') {
          _sellerNameController.text = 'Giao Hàng Nhanh Chóng';
          _sellerTaxCodeController.text = '0369852147';
          _sellerAddressController.text = '12 Đường Vận Tải, Quận 4, TP. HCM';
          _vatRateController.text = '10';
          final oldItems = List.of(_items);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var item in oldItems) { item.dispose(); }
          });
          _items.clear();
          _items.add(_ItemFormState(name: 'Dịch vụ vận chuyển Bắc Nam', unit: 'Chuyến', quantity: 2, price: 2750000));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen early to cache data for offline use
    ref.watch(partnerStreamProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00D09E);
    final inputFillColor = isDark ? const Color(0xFF0F1E15) : Colors.grey.shade50;
    final inputBorderColor = isDark ? const Color(0xFF1E382B) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: Center(
          child: ScaleOnTap(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/invoices/outgoing');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D281E) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1E382B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF060E0A), size: 18),
            ),
          ),
        ),
        title: Text(
          widget.invoiceId != null ? 'Chỉnh sửa hóa đơn' : (widget.invoiceType == InvoiceType.outgoing ? 'Tạo hóa đơn bán ra' : 'Hóa đơn đầu vào (OCR)'),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.flash_on_rounded, color: primaryColor),
            tooltip: 'Điền dữ liệu mẫu',
            color: isDark ? const Color(0xFF0F1E15) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: _addSampleData,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'it',
                child: Row(children: [Icon(Icons.computer, size: 20, color: Color(0xFF00D09E)), SizedBox(width: 8), Text('Dịch vụ IT')]),
              ),
              const PopupMenuItem(
                value: 'furniture',
                child: Row(children: [Icon(Icons.chair, size: 20, color: Color(0xFF00D09E)), SizedBox(width: 8), Text('Nội thất')]),
              ),
              const PopupMenuItem(
                value: 'shipping',
                child: Row(children: [Icon(Icons.local_shipping, size: 20, color: Color(0xFF00D09E)), SizedBox(width: 8), Text('Vận chuyển')]),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (widget.invoiceType == InvoiceType.incoming && widget.scannedImagePath != null) ...[
              const Text('ẢNH HÓA ĐƠN ĐÃ QUÉT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.scannedImagePath != null
                    ? (widget.scannedImagePath!.startsWith('http') || kIsWeb
                        ? Image.network(widget.scannedImagePath!, height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Image.file(File(widget.scannedImagePath!), height: 200, width: double.infinity, fit: BoxFit.cover))
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],

            // Thông tin hóa đơn mẫu
            if (_isLoadingFormatInfo) 
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
            else if (widget.invoiceType == InvoiceType.outgoing)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text('THÔNG TIN HÓA ĐƠN (Đã điền tự động)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 16),
                  iconColor: primaryColor,
                  collapsedIconColor: Colors.grey,
                  children: _buildInvoiceFormatFields(isDark, inputFillColor, inputBorderColor, isOutgoing: true),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('THÔNG TIN HÓA ĐƠN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ..._buildInvoiceFormatFields(isDark, inputFillColor, inputBorderColor, isOutgoing: false),
                  const SizedBox(height: 24),
                ],
              ),

            // Đơn vị bán
            widget.invoiceType == InvoiceType.outgoing
              ? Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text('THÔNG TIN ĐƠN VỊ BÁN (Đã điền tự động)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 16),
                    iconColor: primaryColor,
                    collapsedIconColor: Colors.grey,
                    children: _buildSellerFields(isDark, primaryColor, inputFillColor, inputBorderColor),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('THÔNG TIN ĐƠN VỊ BÁN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        TextButton.icon(
                          onPressed: () => _showPartnerSelectionDialog(false),
                          icon: const Icon(Icons.contacts, size: 16),
                          label: const Text('Chọn từ danh bạ', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ..._buildSellerFields(isDark, primaryColor, inputFillColor, inputBorderColor),
                  ],
                ),
            const SizedBox(height: 24),

            // Thông tin Khách hàng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('THÔNG TIN NGƯỜI MUA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                if (widget.invoiceType == InvoiceType.outgoing)
                  TextButton.icon(
                    onPressed: () => _showPartnerSelectionDialog(true),
                    icon: const Icon(Icons.contacts, size: 16),
                    label: const Text('Chọn từ danh bạ', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _partnerContactNameController,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: _buildInputDeco('Họ tên người mua hàng', Icons.person_outline, isDark, primaryColor, inputFillColor, inputBorderColor),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _partnerNameController,
              readOnly: widget.invoiceType == InvoiceType.incoming,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: _buildInputDeco('Tên đơn vị', Icons.business_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
              validator: (value) => value == null || value.isEmpty ? 'Nhập tên đối tác' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _partnerTaxCodeController,
              readOnly: widget.invoiceType == InvoiceType.incoming,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: _buildInputDeco('Mã số thuế', Icons.credit_card_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
              validator: (value) => value == null || value.isEmpty ? 'Nhập mã số thuế' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _partnerAddressController,
              readOnly: widget.invoiceType == InvoiceType.incoming,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: _buildInputDeco('Địa chỉ', Icons.location_on_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
            ),
            const SizedBox(height: 12),
            if (widget.invoiceType == InvoiceType.outgoing)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('Lưu đối tác này vào danh bạ', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
                value: _saveToPartner,
                activeColor: primaryColor,
                onChanged: (val) {
                  if (val != null) setState(() => _saveToPartner = val);
                },
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: _buildInputDeco('Hình thức thanh toán', Icons.payment_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
              dropdownColor: isDark ? const Color(0xFF0F1E15) : Colors.white,
              items: const [
                DropdownMenuItem(value: 'TM', child: Text('Tiền mặt (TM)')),
                DropdownMenuItem(value: 'CK', child: Text('Chuyển khoản (CK)')),
                DropdownMenuItem(value: 'TM/CK', child: Text('TM/CK')),
              ],
              onChanged: widget.invoiceType == InvoiceType.incoming ? null : (val) {
                if (val != null) setState(() => _paymentMethod = val);
              },
            ),
            if (_paymentMethod == 'CK' || _paymentMethod == 'TM/CK') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                readOnly: widget.invoiceType == InvoiceType.incoming,
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                decoration: _buildInputDeco('Ngân hàng gì?', Icons.account_balance_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
                validator: (value) => _paymentMethod != 'TM' && (value == null || value.isEmpty) ? 'Nhập tên ngân hàng' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankAccountController,
                readOnly: widget.invoiceType == InvoiceType.incoming,
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                decoration: _buildInputDeco('Số tài khoản', Icons.numbers_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
                validator: (value) => _paymentMethod != 'TM' && (value == null || value.isEmpty) ? 'Nhập số tài khoản' : null,
              ),
            ],
            
            const SizedBox(height: 32),
            const Text('CHI TIẾT DỊCH VỤ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index == _items.length - 1 ? 0 : 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A1811) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF1E382B) : Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Dịch vụ #${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                          if (_items.length > 1)
                            InkWell(
                              onTap: () {
                                final itemToRemove = item;
                                setState(() {
                                  _items.removeAt(index);
                                });
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  itemToRemove.dispose();
                                });
                              },
                              child: const Icon(Icons.close, color: Colors.red, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: item.nameController,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        decoration: _buildInputDeco('Tên sản phẩm/dịch vụ', Icons.inventory_2_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
                        validator: (value) => value == null || value.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: item.unitController,
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                              decoration: _buildInputDeco('ĐVT', null, isDark, primaryColor, inputFillColor, inputBorderColor),
                              validator: (value) => value == null || value.isEmpty ? 'Bắt buộc' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: item.quantityController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                              decoration: _buildInputDeco('Số lượng', null, isDark, primaryColor, inputFillColor, inputBorderColor),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Bắt buộc';
                                final numVal = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                                if (numVal == null || numVal <= 0) return 'Không hợp lệ';
                                if (numVal > 99999999) return 'Quá lớn';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: item.priceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        decoration: _buildInputDeco('Đơn giá (VND)', Icons.attach_money_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Bắt buộc';
                          final numVal = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                          if (numVal == null || numVal <= 0) return 'Không hợp lệ';
                          if (numVal > 999999999999999) return 'Quá lớn';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      if (item.amount > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Thành tiền:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('${item.amount} VND', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _items.add(_ItemFormState());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm dịch vụ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('TỔNG KẾT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _vatRateController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: _buildInputDeco('Thuế suất VAT (%)', Icons.percent_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
              validator: (value) => value == null || int.tryParse(value) == null ? 'Nhập phần trăm thuế' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),
            
            // Calc summary card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1E15) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E382B) : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cộng tiền hàng:', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                        Text('${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(_subtotal).trim()} VND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Thuế VAT:', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                        Text('${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(_vatAmount).trim()} VND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            'Tổng tiền thanh toán:', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(_totalAmount).trim()} VND', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF00D09E)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ScaleOnTap(
              onTap: _saveInvoice,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.invoiceId != null ? 'Cập nhật' : (widget.invoiceType == InvoiceType.outgoing ? 'Lưu & Phát hành' : 'Lưu hóa đơn'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF060E0A)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
  List<Widget> _buildInvoiceFormatFields(bool isDark, Color inputFillColor, Color inputBorderColor, {required bool isOutgoing}) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return [
      TextFormField(
        controller: _formNumberController,
        readOnly: isOutgoing,
        style: TextStyle(fontSize: 15, color: textColor),
        decoration: _buildInputDeco('Mẫu số', Icons.description_outlined, isDark, const Color(0xFF00D09E), inputFillColor, inputBorderColor),
        validator: (value) => value == null || value.trim().isEmpty ? 'Nhập mẫu số' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _serialNumberController,
        readOnly: isOutgoing,
        style: TextStyle(fontSize: 15, color: textColor),
        decoration: _buildInputDeco('Ký hiệu', Icons.tag_outlined, isDark, const Color(0xFF00D09E), inputFillColor, inputBorderColor),
        validator: (value) => value == null || value.trim().isEmpty ? 'Nhập ký hiệu' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _invoiceNumberController,
        readOnly: isOutgoing,
        keyboardType: isOutgoing ? TextInputType.none : TextInputType.number,
        style: TextStyle(fontSize: 15, color: textColor),
        decoration: _buildInputDeco('Số hóa đơn', Icons.numbers_outlined, isDark, const Color(0xFF00D09E), inputFillColor, inputBorderColor),
        validator: (value) => value == null || value.trim().isEmpty ? 'Nhập số hóa đơn' : null,
      ),
    ];
  }

  List<Widget> _buildSellerFields(bool isDark, Color primaryColor, Color inputFillColor, Color inputBorderColor) {
    return [
      TextFormField(
        controller: _sellerNameController,
        readOnly: widget.invoiceType == InvoiceType.outgoing,
        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
        decoration: _buildInputDeco('Tên đơn vị bán', Icons.storefront_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
        validator: (value) => value == null || value.isEmpty ? 'Bắt buộc' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _sellerTaxCodeController,
        readOnly: widget.invoiceType == InvoiceType.outgoing,
        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
        decoration: _buildInputDeco('Mã số thuế', Icons.credit_card_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _sellerAddressController,
        readOnly: widget.invoiceType == InvoiceType.outgoing,
        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
        decoration: _buildInputDeco('Địa chỉ', Icons.location_on_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _sellerPhoneController,
        readOnly: widget.invoiceType == InvoiceType.outgoing,
        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
        decoration: _buildInputDeco('Số điện thoại', Icons.phone_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _sellerBankNameController,
              readOnly: widget.invoiceType == InvoiceType.outgoing,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: _buildInputDeco('Ngân hàng', Icons.account_balance_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _sellerBankAccountController,
              readOnly: widget.invoiceType == InvoiceType.outgoing,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: _buildInputDeco('Số tài khoản', Icons.numbers_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (widget.invoiceType == InvoiceType.incoming)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text('Lưu nhà cung cấp này vào danh bạ', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
          value: _saveToPartner,
          activeColor: primaryColor,
          onChanged: (val) {
            if (val != null) setState(() => _saveToPartner = val);
          },
        ),
    ];
  }

  InputDecoration _buildInputDeco(String label, IconData? icon, bool isDark, Color primaryColor, Color inputFillColor, Color inputBorderColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
      filled: true,
      fillColor: inputFillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: inputBorderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }
}
