import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/core/constants/route_names.dart';
import 'package:smart_finance/core/services/image_acquisition_service.dart';
import 'package:smart_finance/core/widgets/capture_option_card.dart';

class InvoiceCaptureScreen extends StatefulWidget {
  final ImageAcquisitionService? imageAcquisitionService;

  const InvoiceCaptureScreen({
    super.key,
    this.imageAcquisitionService,
  });

  @override
  State<InvoiceCaptureScreen> createState() => _InvoiceCaptureScreenState();
}

class _InvoiceCaptureScreenState extends State<InvoiceCaptureScreen> {
  late final ImageAcquisitionService _imageAcquisitionService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageAcquisitionService = widget.imageAcquisitionService ?? ImageAcquisitionService();
  }

  Future<void> _handleCapture(ImageAcquisitionSource source) async {
    setState(() => _isLoading = true);

    try {
      final File? file = await _imageAcquisitionService.pick(source);
      
      if (!mounted) return;
      
      if (file != null) {
        // Use push to keep CaptureScreen in stack for easy retaking
        context.pushNamed(RouteNames.invoiceScan, extra: file);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      // You can add more specific error code checks here (e.g., camera_access_denied)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hệ thống: ${e.message}')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi không xác định: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét hóa đơn'),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeaderInstruction(),
                  const SizedBox(height: 32),
                  
                  // Responsive Layout for Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CaptureOptionCard(
                              icon: Icons.camera_alt,
                              title: 'Chụp ảnh',
                              description: 'Sử dụng Camera',
                              enabled: !_isLoading,
                              onTap: () => _handleCapture(ImageAcquisitionSource.camera),
                            ),
                            const SizedBox(height: 16),
                            CaptureOptionCard(
                              icon: Icons.photo_library,
                              title: 'Thư viện',
                              description: 'Chọn ảnh có sẵn',
                              enabled: !_isLoading,
                              onTap: () => _handleCapture(ImageAcquisitionSource.gallery),
                            ),
                          ],
                        );
                      } else {
                        // Desktop/Tablet: Center the row and constrain max width
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CaptureOptionCard(
                                    icon: Icons.camera_alt,
                                    title: 'Chụp ảnh',
                                    description: 'Sử dụng Camera',
                                    enabled: !_isLoading,
                                    onTap: () => _handleCapture(ImageAcquisitionSource.camera),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CaptureOptionCard(
                                    icon: Icons.photo_library,
                                    title: 'Thư viện',
                                    description: 'Chọn ảnh có sẵn',
                                    enabled: !_isLoading,
                                    onTap: () => _handleCapture(ImageAcquisitionSource.gallery),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 48),
                  const _CaptureTipsSection(),
                ],
              ),
            ),
          ),
          
          // Full-body loading overlay to prevent layout jump
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderInstruction extends StatelessWidget {
  const _HeaderInstruction();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Vui lòng chọn nguồn ảnh để tiếp tục',
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }
}

class _CaptureTipsSection extends StatelessWidget {
  const _CaptureTipsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mẹo chụp ảnh để OCR chính xác nhất:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const _TipRow(text: 'Đặt hóa đơn trên mặt phẳng.'),
            const _TipRow(text: 'Đảm bảo đủ ánh sáng.'),
            const _TipRow(text: 'Chụp rõ 4 góc hóa đơn.'),
            const _TipRow(text: 'Tránh ảnh bị mờ hoặc chói sáng.'),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;

  const _TipRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
