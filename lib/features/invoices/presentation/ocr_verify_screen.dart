import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/document_viewer/document_viewer.dart';
import 'providers/ocr_verify_provider.dart';
import 'providers/ocr_verify_state.dart';

import 'widgets/ocr_verify/header_section.dart';
import 'widgets/ocr_verify/line_items_section.dart';
import 'widgets/ocr_verify/summary_section.dart';
import 'widgets/ocr_verify/footer_section.dart';
import 'widgets/ocr_verify/validation_banner.dart';
import 'widgets/ocr_verify/ocr_verify_constants.dart';

class OcrVerifyScreen extends ConsumerStatefulWidget {
  final File? file;

  const OcrVerifyScreen({super.key, this.file});

  @override
  ConsumerState<OcrVerifyScreen> createState() => _OcrVerifyScreenState();
}

class _OcrVerifyScreenState extends ConsumerState<OcrVerifyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.file != null) {
        ref.read(ocrVerifyProvider.notifier).processImage(widget.file!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ocrVerifyProvider, (previous, next) {
      if (next.status == OcrStatus.success && next.savedInvoiceId != null) {
        context.go('/invoices/incoming/${next.savedInvoiceId}');
      }
      if (next.status == OcrStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    });

    final status = ref.watch(ocrVerifyProvider.select((s) => s.status));
    final isLoading = status == OcrStatus.scanning || status == OcrStatus.saving;
    
    final documentPayload = widget.file != null 
        ? DocumentPayload.file(widget.file!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra Hóa đơn'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/invoices/incoming');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= OcrVerifyDimens.desktopBreakpoint;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: documentPayload != null 
                          ? _ScannerOverlay(
                              isScanning: status == OcrStatus.scanning,
                              child: DocumentViewer(payload: documentPayload),
                            )
                          : const Center(child: Text('Không có ảnh')),
                    ),
                    const VerticalDivider(width: 1),
                    const Expanded(
                      flex: 1,
                      child: _DraftFormAdapter(),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 250, // Fixed height for document viewer on mobile
                      child: documentPayload != null 
                          ? _ScannerOverlay(
                              isScanning: status == OcrStatus.scanning,
                              child: DocumentViewer(payload: documentPayload),
                            )
                          : const Center(child: Text('Không có ảnh')),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))
                          ],
                        ),
                        child: const _DraftFormAdapter(),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: status == OcrStatus.scanning 
                  ? Colors.black.withOpacity(0.4) 
                  : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == OcrStatus.saving)
                        const CircularProgressIndicator(),
                      if (status == OcrStatus.scanning)
                        Icon(Icons.document_scanner, size: 48, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        status == OcrStatus.scanning ? 'Đang phân tích OCR...' : 'Đang lưu...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: status == OcrStatus.scanning ? Colors.white : null,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DraftFormAdapter extends ConsumerWidget {
  final ScrollController? scrollController;

  const _DraftFormAdapter({this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(ocrVerifyProvider.select((s) => s.status));
    
    // We only need to check if draft is null to show "Chưa có dữ liệu"
    // Using select to avoid rebuilding the entire form when draft fields change.
    final hasDraft = ref.watch(ocrVerifyProvider.select((s) => s.draft != null));

    if (!hasDraft) {
      if (status == OcrStatus.scanning) {
        return const SizedBox.shrink(); // Handled by overlay
      }
      return const Center(child: Text('Chưa có dữ liệu.'));
    }

    return _FormPane(
      scrollController: scrollController,
      onSave: () {
        // Ensure any active focus is removed so fields dispatch their latest state
        FocusScope.of(context).unfocus();
        
        // Wait for the focus change to propagate and state to update synchronously
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(ocrVerifyProvider.notifier).saveInvoice();
        });
      },
    );
  }
}

// Pure UI Layout
class _FormPane extends ConsumerWidget {
  final ScrollController? scrollController;
  final VoidCallback onSave;

  const _FormPane({
    this.scrollController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only the general errors to rebuild the banner
    final validation = ref.watch(ocrVerifyProvider.select((s) => s.validation));
    final List<String> generalErrors = [
      if (validation.mathWarning != null) validation.mathWarning!,
      ...validation.missingFields.map((f) => 'Thiếu thông tin: $f')
    ];

    return Column(
      children: [
        if (scrollController != null)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: OcrVerifyDimens.spacingSmall),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(OcrVerifyDimens.spacingMedium),
            children: [
              ValidationBanner(errors: generalErrors),
              const HeaderSection(),
              const SizedBox(height: OcrVerifyDimens.spacingLarge),
              const LineItemsSection(),
              const SizedBox(height: OcrVerifyDimens.spacingLarge),
              const SummarySection(),
              // Extra space for footer
              const SizedBox(height: OcrVerifyDimens.footerSpacer),
            ],
          ),
        ),
        FooterSection(onSave: onSave),
      ],
    );
  }
}

class _ScannerOverlay extends StatefulWidget {
  final Widget child;
  final bool isScanning;

  const _ScannerOverlay({required this.child, required this.isScanning});

  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_ScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _controller.repeat(reverse: true);
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isScanning)
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Positioned(
                            top: _controller.value * (constraints.maxHeight - 4),
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

