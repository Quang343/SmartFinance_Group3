import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

enum DocumentPayloadType { file, network, memory, pdf }

class DocumentPayload {
  final DocumentPayloadType type;
  final Object data;

  const DocumentPayload.file(File file)
      : type = DocumentPayloadType.file,
        data = file;

  const DocumentPayload.network(String url)
      : type = DocumentPayloadType.network,
        data = url;

  const DocumentPayload.memory(Uint8List bytes)
      : type = DocumentPayloadType.memory,
        data = bytes;
}

class DocumentViewer extends StatelessWidget {
  final DocumentPayload payload;

  const DocumentViewer({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    // Gesture Layer is provided by InteractiveViewer
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      boundaryMargin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      panEnabled: true,
      scaleEnabled: true,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: Document Surface
            _DocumentSurface(payload: payload),
            
            // Layer 2: Overlay Layer (Empty for Phase 4)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  // Reserved for OCR bounding boxes, annotations, highlights
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentSurface extends StatelessWidget {
  final DocumentPayload payload;

  const _DocumentSurface({required this.payload});

  @override
  Widget build(BuildContext context) {
    switch (payload.type) {
      case DocumentPayloadType.file:
        final file = payload.data as File;
        return kIsWeb 
            ? Image.network(file.path, fit: BoxFit.contain)
            : Image.file(file, fit: BoxFit.contain);
      case DocumentPayloadType.network:
        return Image.network(payload.data as String, fit: BoxFit.contain);
      case DocumentPayloadType.memory:
        return Image.memory(payload.data as Uint8List, fit: BoxFit.contain);
      case DocumentPayloadType.pdf:
        return const Center(child: Text('PDF rendering not yet implemented'));
    }
  }
}
