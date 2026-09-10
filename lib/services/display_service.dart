import 'dart:io';
import 'package:flutter_displaymode/flutter_displaymode.dart';

class DisplayService {
  // Đóng gói logic mở khóa tần số quét màn hình (120Hz/90Hz/60Hz)
  Future<void> optimizeRefreshRate() async {
    if (!Platform.isAndroid) return;

    try {
      // Cấp quyền kích hoạt tần số quét tối đa của phần cứng
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {
      // Bỏ qua lỗi trên các thiết bị không hỗ trợ API này
    }
  }
}