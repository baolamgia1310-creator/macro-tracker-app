enum AuthStatus {
  loading,          // Đang đọc token khởi động
  unauthenticated,  // Chưa đăng nhập
  unverified,       // Đã đăng ký nhưng chưa bấm link email
  needsPassword,    // Đăng nhập Google nhưng chưa tạo mật khẩu
  needsOnboarding,  // Đã xác thực nhưng chưa tính BMR/TDEE
  authenticated,    // Đã hoàn tất mọi bước, vào màn hình chính
}