import 'package:hive/hive.dart';

/// Represents a single loan / EMI commitment.
///
/// We store the [firstDueDate] (the very first EMI date) and derive the
/// next-due date from `firstDueDate + emisPaid months`. This keeps the
/// model immutable to time — no daily mutation needed.
class Loan {
  Loan({
    required this.id,
    required this.lender,
    required this.emiAmount,
    required this.totalEmis,
    required this.emisPaid,
    required this.firstDueDate,
    this.notes,
    this.accentIndex = 0,
    DateTime? createdAt,
    this.archived = false,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String lender;
  double emiAmount;
  int totalEmis;
  int emisPaid;
  DateTime firstDueDate;
  String? notes;
  int accentIndex;
  DateTime createdAt;
  bool archived;

  // ---- Derived ----

  int get emisRemaining => (totalEmis - emisPaid).clamp(0, totalEmis);

  double get totalAmount => emiAmount * totalEmis;
  double get paidAmount => emiAmount * emisPaid;
  double get remainingAmount => emiAmount * emisRemaining;

  double get progress =>
      totalEmis == 0 ? 0 : (emisPaid / totalEmis).clamp(0.0, 1.0);

  bool get isClosed => emisPaid >= totalEmis;

  /// The date of the next pending EMI (or null if closed).
  DateTime? get nextDueDate {
    if (isClosed) return null;
    return _addMonths(firstDueDate, emisPaid);
  }

  /// The date the loan will close if every EMI is paid on time.
  DateTime get closureDate => _addMonths(firstDueDate, totalEmis - 1);

  Loan copyWith({
    String? lender,
    double? emiAmount,
    int? totalEmis,
    int? emisPaid,
    DateTime? firstDueDate,
    String? notes,
    int? accentIndex,
    bool? archived,
  }) {
    return Loan(
      id: id,
      lender: lender ?? this.lender,
      emiAmount: emiAmount ?? this.emiAmount,
      totalEmis: totalEmis ?? this.totalEmis,
      emisPaid: emisPaid ?? this.emisPaid,
      firstDueDate: firstDueDate ?? this.firstDueDate,
      notes: notes ?? this.notes,
      accentIndex: accentIndex ?? this.accentIndex,
      createdAt: createdAt,
      archived: archived ?? this.archived,
    );
  }
}

DateTime _addMonths(DateTime base, int months) {
  final year = base.year + ((base.month - 1 + months) ~/ 12);
  final month = ((base.month - 1 + months) % 12) + 1;
  final day = base.day;
  // Clamp the day to the last day of the target month.
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}

// -------------------- Hive adapter (manual) --------------------

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 1;

  @override
  Loan read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String,
      lender: fields[1] as String,
      emiAmount: (fields[2] as num).toDouble(),
      totalEmis: fields[3] as int,
      emisPaid: fields[4] as int,
      firstDueDate: fields[5] as DateTime,
      notes: fields[6] as String?,
      accentIndex: fields[7] as int? ?? 0,
      createdAt: fields[8] as DateTime?,
      archived: fields[9] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lender)
      ..writeByte(2)
      ..write(obj.emiAmount)
      ..writeByte(3)
      ..write(obj.totalEmis)
      ..writeByte(4)
      ..write(obj.emisPaid)
      ..writeByte(5)
      ..write(obj.firstDueDate)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.accentIndex)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.archived);
  }
}
