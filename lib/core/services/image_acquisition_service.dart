import 'dart:io';
import 'package:image_picker/image_picker.dart';

enum ImageAcquisitionSource {
  camera,
  gallery,
  // TODO: documentScanner,
  // TODO: pdfImport,
  // TODO: cloudDrive,
}

class ImageAcquisitionService {
  final ImagePicker _picker;
  
  ImageAcquisitionService({ImagePicker? picker}) 
      : _picker = picker ?? ImagePicker();

  Future<File?> pick(ImageAcquisitionSource source) async {
    XFile? pickedFile;
    
    switch (source) {
      case ImageAcquisitionSource.camera:
        pickedFile = await _picker.pickImage(source: ImageSource.camera);
        break;
      case ImageAcquisitionSource.gallery:
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
        break;
    }

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    
    return null;
  }
}
