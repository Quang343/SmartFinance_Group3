import re

with open(r'd:\Github Repositories\SmartFinance_Group3\lib\features\invoices\presentation\invoice_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SMARTFINANCE JSC',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFF00D09E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc',
                                          style: TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                        const Text(
                                          'MST: 0123456789',
                                          style: TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isIncoming ? 'HÓA ĐƠN ĐẦU VÀO' : 'HÓA ĐƠN BÁN RA',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Số: \', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        Text('Ngày: \', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey.shade300, thickness: 1),
                              const SizedBox(height: 16),

                              // Seller & Buyer
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('ĐƠN VỊ BÁN HÀNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                        const SizedBox(height: 8),
                                        Text(invoice.sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                        if (invoice.sellerTaxCode != null && invoice.sellerTaxCode!.isNotEmpty)
                                          Text('MST: \', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        if (invoice.sellerAddress != null && invoice.sellerAddress!.isNotEmpty)
                                          Text('Đ/c: \', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('KHÁCH HÀNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                        const SizedBox(height: 8),
                                        Text(invoice.buyerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                        if (invoice.buyerTaxCode != null && invoice.buyerTaxCode!.isNotEmpty)
                                          Text('MST: \', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        if (invoice.buyerAddress != null && invoice.buyerAddress!.isNotEmpty)
                                          Text('Đ/c: \', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Table
                              if (invoice.items.isNotEmpty) ...[
                                Container(
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                                  child: Column(
                                    children: [
                                      // Header
                                      Container(
                                        color: Colors.grey.shade100,
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        child: Row(
                                          children: const [
                                            Expanded(flex: 4, child: Text('Tên dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
                                            Expanded(flex: 1, child: Text('ĐVT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
                                            Expanded(flex: 1, child: Text('SL', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
                                            Expanded(flex: 2, child: Text('Thành tiền', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
                                          ],
                                        ),
                                      ),
                                      // Rows
                                      ...invoice.items.map((item) => Container(
                                        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 4, child: Text(item.itemName, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                                            Expanded(flex: 1, child: Text(item.unit, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                                            Expanded(flex: 1, child: Text(formatQuantity(item.quantity), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                                            Expanded(flex: 2, child: Text(currencyFormatter.format(item.totalAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                                          ],
                                        ),
                                      )).toList(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Summary
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Cộng tiền hàng: \', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      const SizedBox(height: 4),
                                      Text('Thuế GTGT (\%): \', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      const SizedBox(height: 8),
                                      Text('TỔNG CỘNG: \', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (hasTransaction) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _shareScreenshot(context),
                                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                                label: const Text('Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00D09E),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _saveScreenshot(context),
                                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                                label: const Text('Chụp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Image View Section'''

start_idx = content.find('              : SingleChildScrollView(')
end_str = '                      // Image View Section'
end_idx = content.find(end_str)

if start_idx != -1 and end_idx != -1:
    new_content = content[:start_idx] + replacement + content[end_idx:]
    with open(r'd:\Github Repositories\SmartFinance_Group3\lib\features\invoices\presentation\invoice_detail_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Replaced successfully")
else:
    print("Could not find boundaries")
    print(start_idx, end_idx)
