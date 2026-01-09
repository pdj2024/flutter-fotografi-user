import '../../features/auth/services/auth_service.dart';
import 'api_client.dart';

final AuthService authService = AuthService(); // pastikan ini hanya dibuat 1x
final ApiClient apiClient = ApiClient(); // inject authService
