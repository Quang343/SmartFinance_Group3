import 'package:flutter/material.dart';

class TransactionFormScreen extends StatelessWidget {
  const TransactionFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: const Center(
        child: Text('Transaction Form Placeholder'),
      ),
    );
  }
}
