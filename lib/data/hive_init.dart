import 'package:hive_flutter/hive_flutter.dart';

import 'models/loan.dart';
import 'models/payment.dart';

class HiveInit {
  HiveInit._();

  static const loansBox = 'loans';
  static const paymentsBox = 'payments';

  static Future<void> ensureReady() async {
    await Hive.initFlutter('freedom_v1');

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LoanAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PaymentAdapter());
    }

    await Hive.openBox<Loan>(loansBox);
    await Hive.openBox<Payment>(paymentsBox);
  }

  static Box<Loan> get loans => Hive.box<Loan>(loansBox);
  static Box<Payment> get payments => Hive.box<Payment>(paymentsBox);
}
