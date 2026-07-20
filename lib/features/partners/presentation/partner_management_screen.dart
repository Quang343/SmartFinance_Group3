import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/core/providers/auth_provider.dart';
import 'package:smart_finance/domain/entities/partner_entity.dart';

class PartnerManagementScreen extends ConsumerStatefulWidget {
  const PartnerManagementScreen({super.key});

  @override
  ConsumerState<PartnerManagementScreen> createState() => _PartnerManagementScreenState();
}

class _PartnerManagementScreenState extends ConsumerState<PartnerManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();

  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    _taxCodeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  void _showFormDialog({PartnerEntity? partner}) {
    if (partner != null) {
      _editingId = partner.id;
      _nameController.text = partner.name;
      _taxCodeController.text = partner.taxCode;
      _addressController.text = partner.address ?? '';
      _phoneController.text = partner.phone ?? '';
      _bankNameController.text = partner.bankName ?? '';
      _bankAccountController.text = partner.bankAccount ?? '';
    } else {
      _editingId = null;
      _nameController.clear();
      _taxCodeController.clear();
      _addressController.clear();
      _phoneController.clear();
      _bankNameController.clear();
      _bankAccountController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_editingId == null ? 'Thêm Đối Tác' : 'Sửa Đối Tác'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tên đối tác *'),
                    validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                  ),
                  TextFormField(
                    controller: _taxCodeController,
                    decoration: const InputDecoration(labelText: 'Mã số thuế *'),
                    validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Địa chỉ'),
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  ),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(labelText: 'Ngân hàng'),
                  ),
                  TextFormField(
                    controller: _bankAccountController,
                    decoration: const InputDecoration(labelText: 'Số tài khoản'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: _savePartner,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D09E), foregroundColor: Colors.white),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _savePartner() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      
      final repository = ref.read(partnerRepositoryProvider);
      final partner = PartnerEntity(
        id: _editingId ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        taxCode: _taxCodeController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        bankName: _bankNameController.text.trim(),
        bankAccount: _bankAccountController.text.trim(),
        createdByUid: user.id,
        company: user.company,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (_editingId == null) {
          await repository.createPartner(partner);
        } else {
          await repository.updatePartner(partner);
        }
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu thành công'), backgroundColor: Color(0xFF00D09E)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _confirmDelete(PartnerEntity partner) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa đối tác "${partner.name}"?'),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final repository = ref.read(partnerRepositoryProvider);
                await repository.deletePartner(partner.id);
                if (mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa thành công'), backgroundColor: Color(0xFF00D09E)),
                  );
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsyncValue = ref.watch(partnerStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh bạ Đối tác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFF00D09E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: partnersAsyncValue.when(
        data: (partners) {
          if (partners.isEmpty) {
            return const Center(
              child: Text('Chưa có đối tác nào.', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final p = partners[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('MST: ${p.taxCode}\nSĐT: ${p.phone ?? "N/A"}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFormDialog(partner: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(p),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00D09E))),
        error: (error, stack) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }
}
