import 'package:flutter/material.dart';
import 'ocr_verify_constants.dart';

class ValidationBanner extends StatelessWidget {
  final List<String> errors;

  const ValidationBanner({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: child,
        ),
      ),
      child: errors.isEmpty
          ? const SizedBox.shrink(key: ValueKey('empty_banner'))
          : Semantics(
              key: const ValueKey('error_banner'),
              container: true,
              label: 'Cảnh báo dữ liệu',
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: OcrVerifyDimens.spacingMedium),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(OcrVerifyDimens.cardRadius),
                  border: Border.all(color: Theme.of(context).colorScheme.error),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Cảnh báo dữ liệu',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OcrVerifyDimens.spacingSmall),
                    ...errors.map((err) => Padding(
                          padding: const EdgeInsets.only(left: 28.0, bottom: 4.0),
                          child: Text(
                            '• $err',
                            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13),
                          ),
                        )),
                  ],
                ),
              ),
            ),
    );
  }
}
