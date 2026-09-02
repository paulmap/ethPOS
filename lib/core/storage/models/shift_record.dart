import 'package:hive/hive.dart';

part 'shift_record.g.dart';

/// One till session: who opened it, the float in, and the cash-up out.
@HiveType(typeId: 23)
class ShiftRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffId;

  @HiveField(2)
  final String staffName;

  @HiveField(3)
  final DateTime openedAt;

  @HiveField(4)
  final double openingFloat;

  @HiveField(5)
  final DateTime? closedAt;

  /// Cash physically counted at close, in USD.
  @HiveField(6)
  final double? countedCash;

  @HiveField(7)
  final double? countedCashZwl;

  /// System totals confirmed at close.
  @HiveField(8)
  final double? mobileMoneyTotal;

  @HiveField(9)
  final double? cardTotal;

  /// Cash sales the system expected, used for the variance.
  @HiveField(10)
  final double? expectedCash;

  @HiveField(11)
  final String? closingNote;

  /// Supervisor sign-off, applied later than the assistant's count.
  @HiveField(12)
  final String? signedOffBy;

  ShiftRecord({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.openedAt,
    required this.openingFloat,
    this.closedAt,
    this.countedCash,
    this.countedCashZwl,
    this.mobileMoneyTotal,
    this.cardTotal,
    this.expectedCash,
    this.closingNote,
    this.signedOffBy,
  });

  bool get isOpen => closedAt == null;

  /// Positive = over, negative = short. The assistant sees this figure; the
  /// pattern across shifts is supervisor-only (see AiAction log).
  double? get variance => (countedCash == null || expectedCash == null)
      ? null
      : double.parse(
          (countedCash! - (expectedCash! + openingFloat)).toStringAsFixed(2));

  ShiftRecord copyWith({
    DateTime? closedAt,
    double? countedCash,
    double? countedCashZwl,
    double? mobileMoneyTotal,
    double? cardTotal,
    double? expectedCash,
    String? closingNote,
    String? signedOffBy,
  }) =>
      ShiftRecord(
        id: id,
        staffId: staffId,
        staffName: staffName,
        openedAt: openedAt,
        openingFloat: openingFloat,
        closedAt: closedAt ?? this.closedAt,
        countedCash: countedCash ?? this.countedCash,
        countedCashZwl: countedCashZwl ?? this.countedCashZwl,
        mobileMoneyTotal: mobileMoneyTotal ?? this.mobileMoneyTotal,
        cardTotal: cardTotal ?? this.cardTotal,
        expectedCash: expectedCash ?? this.expectedCash,
        closingNote: closingNote ?? this.closingNote,
        signedOffBy: signedOffBy ?? this.signedOffBy,
      );
}
