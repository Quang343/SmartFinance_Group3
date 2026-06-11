import 'package:flutter/material.dart';

class InvoiceScanScreen extends StatelessWidget {
  const InvoiceScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Invoice')),
      body: const Center(
        child: Text('Invoice Scan Placeholder'),
      ),
    );
  }
}
