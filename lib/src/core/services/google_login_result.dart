
import 'package:mpjnew/src/core/constants/login_status.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';

class GoogleLoginResult {
  final GoogleLoginStatus status;
  final CustomerModel? customer;

  GoogleLoginResult(this.status, {this.customer});
}