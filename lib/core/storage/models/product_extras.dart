import 'package:hive/hive.dart';

part 'product_extras.g.dart';

/// Electronics-specific attributes, kept beside [LocalProduct] rather than on
/// it so typeId 0 needs no migration. Keyed in the box by productId.
@HiveType(typeId: 22)
class ProductExtras extends HiveObject {
  @HiveField(0)
  final String productId;

  /// Requires a serial/IMEI to be captured before payment.
  @HiveField(1)
  final bool serialised;

  /// 0 = no warranty offered.
  @HiveField(2)
  final int warrantyMonths;

  /// Services (repairs, fitting) hold no stock and skip bin logic.
  @HiveField(3)
  final bool isService;

  /// Shown as a quick-add button on the till.
  @HiveField(4)
  final bool quickAdd;

  ProductExtras({
    required this.productId,
    this.serialised = false,
    this.warrantyMonths = 0,
    this.isService = false,
    this.quickAdd = false,
  });

  ProductExtras copyWith({
    bool? serialised,
    int? warrantyMonths,
    bool? isService,
    bool? quickAdd,
  }) =>
      ProductExtras(
        productId: productId,
        serialised: serialised ?? this.serialised,
        warrantyMonths: warrantyMonths ?? this.warrantyMonths,
        isService: isService ?? this.isService,
        quickAdd: quickAdd ?? this.quickAdd,
      );
}
