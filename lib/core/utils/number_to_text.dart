class NumberToText {
  static const List<String> _chuSo = [
    "không", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín"
  ];
  static const List<String> _tien = [
    "", "nghìn", "triệu", "tỷ", "nghìn tỷ", "triệu tỷ"
  ];

  static String _doc3so(int so) {
    int tram = (so / 100).floor();
    int chuc = ((so % 100) / 10).floor();
    int donVi = so % 10;
    String ketQua = "";

    if (tram == 0 && chuc == 0 && donVi == 0) return "";
    
    if (tram != 0) {
      ketQua += "${_chuSo[tram]} trăm ";
      if (chuc == 0 && donVi != 0) ketQua += "linh ";
    }
    
    if (chuc != 0 && chuc != 1) {
      ketQua += "${_chuSo[chuc]} mươi ";
      if (chuc == 0 && donVi != 0) ketQua += "linh ";
    }
    
    if (chuc == 1) ketQua += "mười ";
    
    switch (donVi) {
      case 1:
        if (chuc > 1) {
          ketQua += "mốt ";
        } else {
          ketQua += "${_chuSo[donVi]} ";
        }
        break;
      case 5:
        if (chuc == 0) {
          ketQua += "${_chuSo[donVi]} ";
        } else {
          ketQua += "lăm ";
        }
        break;
      default:
        if (donVi != 0) {
          ketQua += "${_chuSo[donVi]} ";
        }
        break;
    }
    return ketQua;
  }

  static String convert(int so) {
    if (so == 0) return "Không đồng";
    if (so < 0) return "Số âm";
    
    int lan = 0;
    int i = 0;
    String ketQua = "";
    List<int> viTri = List.filled(6, 0);

    int tempSo = so;
    while (tempSo > 0) {
      viTri[lan] = tempSo % 1000;
      tempSo = (tempSo / 1000).floor();
      lan++;
    }
    
    for (i = lan - 1; i >= 0; i--) {
      if (viTri[i] != 0) {
        ketQua += _doc3so(viTri[i]) + _tien[i] + " ";
      }
    }
    
    ketQua = ketQua.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (ketQua.isNotEmpty) {
      ketQua = ketQua[0].toUpperCase() + ketQua.substring(1) + " đồng";
    }
    return ketQua;
  }
}
