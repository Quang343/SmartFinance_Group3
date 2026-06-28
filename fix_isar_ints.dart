import 'dart:io';

void main() {
  final targetDir = Directory('lib/data/local/isar_models');
  if (!targetDir.existsSync()) {
    print('Directory not found');
    return;
  }

  final files = targetDir.listSync().whereType<File>().where((file) => file.path.endsWith('.g.dart'));
  
  final maxSafeInteger = BigInt.parse('9007199254740991');
  final minSafeInteger = BigInt.parse('-9007199254740991');

  final pattern = RegExp(r'(?<![\w\.])(-?\d{16,})(?![\w\.])');

  for (final file in files) {
    final content = file.readAsStringSync();
    
    final newContent = content.replaceAllMapped(pattern, (match) {
      final numStr = match.group(1)!;
      final numBigInt = BigInt.tryParse(numStr);
      if (numBigInt != null && (numBigInt > maxSafeInteger || numBigInt < minSafeInteger)) {
        // Find JS safe integer
        final numDouble = double.tryParse(numStr);
        if (numDouble != null) {
          // dart:core double.toInt() might clamp to 64-bit integer, but we want the exact double representation
          // Double parsed from string will lose precision in exactly the same way JS does.
          // Wait, double in Dart web is the same as double in Dart native? Yes, IEEE 754 64-bit float.
          // So formatting it back to string as an exact integer (with zero decimal places)
          // `toStringAsFixed(0)` should give the rounded value.
          final rounded = numDouble.toStringAsFixed(0);
          return match.group(0)!.replaceFirst(numStr, rounded);
        }
      }
      return match.group(0)!;
    });

    if (content != newContent) {
      file.writeAsStringSync(newContent);
      print('Fixed ${file.path}');
    } else {
      print('No changes in ${file.path}');
    }
  }
}
