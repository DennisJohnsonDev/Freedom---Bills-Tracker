import 'package:hive/hive.dart';

class Payment {
  Payment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paidOn,
    this.isExtra = false,
  });

  final String id;
  final String loanId;
  final double amount;
  final DateTime paidOn;
  final bool isExtra;
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 2;

  @override
  Payment read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as String,
      loanId: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      paidOn: fields[3] as DateTime,
      isExtra: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.loanId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.paidOn)
      ..writeByte(4)
      ..write(obj.isExtra);
  }
}
