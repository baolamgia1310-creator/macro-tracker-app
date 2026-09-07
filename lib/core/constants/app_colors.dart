import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 1. Màu thương hiệu chủ đạo
  static const Color lime = Color(0xFFC6F235);
  static const Color limeDark = Color(0xFF88B806);

  // 2. Chế độ Tối (Dark Theme)
  static const Color darkBg = Color(0xFF0F1216);
  static const Color darkCard = Color(0xFF1B2028);
  static const Color darkBorder = Color(0xFF2A313D);
  static const Color darkText = Color(0xFFF9FAFB);
  static const Color darkSubtext = Color(0xFF94A3B8);

  // 3. Chế độ Sáng (Light Theme)
  static const Color lightBg = Color(0xFFF4F6F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightSubtext = Color(0xFF64748B);

  // 4. BIẾN CŨ GIỮ NGUYÊN ĐỂ KHÔNG BỊ LỖI CÁC FILE TRƯỚC ĐÓ
  static const Color greySubtext = Color(0xFF94A3B8);

  // 5. Màu chỉ số dinh dưỡng (Macros)
  static const Color protein = Color(0xFF06B6D4);
  static const Color carbs = Color(0xFFF59E0B);
  static const Color fat = Color(0xFFEF4444);

  // 6. Màu biểu đồ
  static const Color chartLine = Color(0xFF0284C7);
}