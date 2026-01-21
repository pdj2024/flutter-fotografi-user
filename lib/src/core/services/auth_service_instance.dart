import 'package:mpjnew/src/features/auth/services/auth_service.dart';

/// ============================================
/// 🔐 GLOBAL AUTHSERVICE INSTANCE
/// ============================================
/// This is the ONLY place where we create the global instance
/// All files should import THIS file, not auth_service.dart
/// ============================================

final AuthService authService = AuthService();