import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'hive_init.dart';
import 'models/loan.dart';
import 'models/payment.dart';

class LoanRepository {
  LoanRepository();

  static const _uuid = Uuid();

  Box<Loan> get _loans => HiveInit.loans;
  Box<Payment> get _payments => HiveInit.payments;

  Stream<BoxEvent> watchLoans() => _loans.watch();

  List<Loan> all({bool includeArchived = false}) {
    final values = _loans.values.toList();
    if (!includeArchived) values.removeWhere((l) => l.archived);
    return values;
  }

  Loan? byId(String id) => _loans.get(id);

  Future<Loan> create({
    required String lender,
    required double emiAmount,
    required int totalEmis,
    required DateTime firstDueDate,
    int emisPaid = 0,
    String? notes,
    int accentIndex = 0,
  }) async {
    final loan = Loan(
      id: _uuid.v4(),
      lender: lender.trim(),
      emiAmount: emiAmount,
      totalEmis: totalEmis,
      emisPaid: emisPaid,
      firstDueDate: firstDueDate,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      accentIndex: accentIndex,
    );
    await _loans.put(loan.id, loan);
    return loan;
  }

  Future<void> update(Loan loan) async => _loans.put(loan.id, loan);

  Future<void> delete(String id) async {
    await _loans.delete(id);
    final relatedKeys = _payments.values
        .where((p) => p.loanId == id)
        .map((p) => p.id)
        .toList();
    await _payments.deleteAll(relatedKeys);
  }

  Future<void> markPaid(Loan loan,
      {DateTime? on, bool isExtra = false}) async {
    if (loan.emisPaid >= loan.totalEmis) return;
    // Write the payment first so any UI listening to the loans box sees the
    // new history immediately on its rebuild.
    final payment = Payment(
      id: _uuid.v4(),
      loanId: loan.id,
      amount: loan.emiAmount,
      paidOn: on ?? DateTime.now(),
      isExtra: isExtra,
    );
    await _payments.put(payment.id, payment);
    final updated = loan.copyWith(emisPaid: loan.emisPaid + 1);
    await _loans.put(updated.id, updated);
  }

  Future<void> undoLastPayment(Loan loan) async {
    final payments = _payments.values
        .where((p) => p.loanId == loan.id)
        .toList()
      ..sort((a, b) => b.paidOn.compareTo(a.paidOn));
    if (payments.isEmpty) return;
    await _payments.delete(payments.first.id);
    if (loan.emisPaid > 0) {
      final updated = loan.copyWith(emisPaid: loan.emisPaid - 1);
      await _loans.put(updated.id, updated);
    }
  }

  List<Payment> paymentsFor(String loanId) {
    return _payments.values.where((p) => p.loanId == loanId).toList()
      ..sort((a, b) => b.paidOn.compareTo(a.paidOn));
  }
}
