import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/core/providers/auth_provider.dart';
import 'package:smart_finance/domain/entities/partner_entity.dart';
import 'package:smart_finance/core/widgets/app_dialogs.dart';
import 'package:smart_finance/core/widgets/scale_on_tap.dart';

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
  final _searchController = TextEditingController();

  String? _editingId;
  String _searchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    _taxCodeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _searchController.dispose();
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
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = const Color(0xFF00D09E);
        final inputFillColor = isDark ? const Color(0xFF060E0A) : Colors.grey.shade50;
        final inputBorderColor = isDark ? const Color(0xFF1E382B) : Colors.grey.shade300;

        InputDecoration buildInputDecoration(String label, {IconData? icon}) {
          return InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
            prefixIcon: icon != null ? Icon(icon, size: 20, color: primaryColor) : null,
            filled: true,
            fillColor: inputFillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          );
        }

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F1E15) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Text(
            _editingId == null ? 'Thêm Đối Tác Mới' : 'Cập Nhật Đối Tác',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: buildInputDecoration('Tên đối tác *', icon: Icons.business_rounded),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên đối tác' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _taxCodeController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: buildInputDecoration('Mã số thuế *', icon: Icons.receipt_rounded),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập MST' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    keyboardType: TextInputType.phone,
                    decoration: buildInputDecoration('Số điện thoại', icon: Icons.phone_rounded),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: buildInputDecoration('Địa chỉ', icon: Icons.location_on_rounded),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bankNameController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: buildInputDecoration('Ngân hàng', icon: Icons.account_balance_rounded),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _bankAccountController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: buildInputDecoration('Số tài khoản', icon: Icons.credit_card_rounded),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Hủy', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700)),
            ),
            ScaleOnTap(
              onTap: _savePartner,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Lưu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF060E0A),
                  ),
                ),
              ),
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
            const SnackBar(
              content: Text('Đã lưu thông tin đối tác thành công!'),
              backgroundColor: Color(0xFF00D09E),
            ),
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
    AppDialogs.showConfirmDialog(
      context: context,
      title: 'Xác nhận xóa đối tác',
      message: 'Bạn có chắc chắn muốn xóa đối tác "${partner.name}" khỏi danh bạ?',
      icon: Icons.delete_outline_rounded,
      color: Colors.redAccent,
      confirmText: 'Xóa đối tác',
      onConfirm: () async {
        final repository = ref.read(partnerRepositoryProvider);
        await repository.deletePartner(partner.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa đối tác thành công!'),
              backgroundColor: Color(0xFF00D09E),
            ),
          );
        }
      },
    );
  }

  Widget _buildPartnerCard(PartnerEntity p, bool isDark, bool isMobile) {
    final primaryColor = const Color(0xFF00D09E);
    final initialLetter = p.name.isNotEmpty ? p.name.trim()[0].toUpperCase() : 'P';
    bool isHovered = false;

    Widget cardContent = StatefulBuilder(
      builder: (context, setStateCard) {
        return MouseRegion(
          onEnter: (_) => setStateCard(() => isHovered = true),
          onExit: (_) => setStateCard(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: isHovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
            decoration: BoxDecoration(
              color: isHovered
                  ? (isDark ? const Color(0xFF13281C) : Colors.white)
                  : (isDark ? const Color(0xFF0F1E15) : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered
                    ? primaryColor.withValues(alpha: 0.6)
                    : (isDark ? const Color(0xFF1E382B) : Colors.grey.shade200),
                width: isHovered ? 2.0 : 1.5,
              ),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initialLetter,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'MST: ${p.taxCode}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      if (p.phone != null && p.phone!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_rounded, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                            const SizedBox(width: 3),
                            Text(
                              p.phone!,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if ((p.bankName != null && p.bankName!.isNotEmpty) ||
                      (p.bankAccount != null && p.bankAccount!.isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.account_balance_rounded, size: 13, color: isDark ? Colors.white38 : Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${p.bankName ?? ""} ${p.bankAccount != null ? "(${p.bankAccount})" : ""}'.trim(),
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (p.address != null && p.address!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 13, color: isDark ? Colors.white38 : Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.address!,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!isMobile) ...[
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                onPressed: () => _showFormDialog(partner: p),
                tooltip: 'Sửa đối tác',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () => _confirmDelete(p),
                tooltip: 'Xóa đối tác',
              ),
            ],
          ],
        ),
      ),
    ),
  );
},
);

    if (isMobile) {
      cardContent = Slidable(
        key: ValueKey(p.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => _showFormDialog(partner: p),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'Sửa',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            SlidableAction(
              onPressed: (context) => _confirmDelete(p),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              label: 'Xóa',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
          ],
        ),
        child: cardContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: cardContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsyncValue = ref.watch(partnerStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final primaryColor = const Color(0xFF00D09E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF00D09E),
              Color(0xFF34D399),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Danh bạ Đối tác',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ScaleOnTap(
              onTap: () => _showFormDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Color(0xFF060E0A), size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Thêm đối tác',
                      style: TextStyle(
                        color: Color(0xFF060E0A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, MST, SĐT, ngân hàng...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF0F1E15) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF1E382B) : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: partnersAsyncValue.when(
              data: (partners) {
                final filtered = partners.where((p) {
                  if (_searchQuery.isEmpty) return true;
                  final nameMatch = p.name.toLowerCase().contains(_searchQuery);
                  final taxMatch = p.taxCode.toLowerCase().contains(_searchQuery);
                  final phoneMatch = p.phone?.toLowerCase().contains(_searchQuery) ?? false;
                  final bankMatch = p.bankName?.toLowerCase().contains(_searchQuery) ?? false;
                  final accMatch = p.bankAccount?.toLowerCase().contains(_searchQuery) ?? false;
                  return nameMatch || taxMatch || phoneMatch || bankMatch || accMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_center_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Không tìm thấy đối tác phù hợp'
                              : 'Chưa có đối tác nào trong danh bạ',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildPartnerCard(filtered[index], isDark, isMobile);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D09E)),
              ),
              error: (error, stack) => Center(
                child: Text('Lỗi tải dữ liệu: $error', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
