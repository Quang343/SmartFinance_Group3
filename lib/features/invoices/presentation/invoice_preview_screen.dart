import 'package:flutter/material.dart';

class InvoicePreviewScreen extends StatelessWidget {
  const InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Preview')),
      body: const Center(
        child: Text('Invoice Preview Placeholder'),
      ),
    );
  }
}
