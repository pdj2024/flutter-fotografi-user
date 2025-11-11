import '../../pages/providers/auth_service_fotografi.dart';
import 'api_client.dart';

final AuthService authService = AuthService(); // pastikan ini hanya dibuat 1x
final ApiClient apiClient = ApiClient(authService); // inject authService
