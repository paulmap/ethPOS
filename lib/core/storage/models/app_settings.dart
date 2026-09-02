import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4)
class AppSettings extends HiveObject {
  @HiveField(0)
  final String baseCurrency;

  @HiveField(1)
  final Map<String, double> exchangeRates;

  @HiveField(2, defaultValue: 'Alpha Systems')
  final String? businessName;

  @HiveField(3, defaultValue: 'Hilte City')
  final String? city;

  @HiveField(4, defaultValue: 'India')
  final String? country;

  @HiveField(5, defaultValue: 'alpha@gmail.com')
  final String? email;

  @HiveField(6, defaultValue: '+1812993345')
  final String? contactNumber;

  @HiveField(7, defaultValue: 'RCPT')
  final String? receiptPrefix;

  @HiveField(8, defaultValue: 1)
  final int? receiptStartNumber;

  @HiveField(9, defaultValue: 'INV')
  final String? invoicePrefix;

  @HiveField(10, defaultValue: 1)
  final int? invoiceStartNumber;

  @HiveField(11, defaultValue: 'PO')
  final String? poPrefix;

  @HiveField(12, defaultValue: 1)
  final int? poStartNumber;

  @HiveField(13, defaultValue: 'Thank you for your business!')
  final String? receiptTagline;

  @HiveField(14)
  final List<String>? taxCategories;

  @HiveField(15, defaultValue: '1234')
  final String? adminPin;

  @HiveField(16, defaultValue: 100)
  final int? minPointsForRedemption;

  @HiveField(17)
  final String? assistantBaseUrl;

  @HiveField(18)
  final String? assistantApiKey;

  @HiveField(19, defaultValue: false)
  final bool? assistantEnabled;

  AppSettings({
    this.baseCurrency = 'USD',
    this.exchangeRates = const {
      'USD': 1.0,
      'ZWL': 2500.0,
      'ZAR': 19.0,
      'BP': 0.8,
    },
    this.businessName = 'Alpha Systems',
    this.city = 'Hilte City',
    this.country = 'India',
    this.email = 'alpha@gmail.com',
    this.contactNumber = '+1812993345',
    this.receiptPrefix = 'RCPT',
    this.receiptStartNumber = 1,
    this.invoicePrefix = 'INV',
    this.invoiceStartNumber = 1,
    this.poPrefix = 'PO',
    this.poStartNumber = 1,
    this.receiptTagline = 'Thank you for your business!',
    this.taxCategories = const ['Tax Exempt', 'Standard Rate (15%)', 'Zero Rated'],
    this.adminPin = '1234',
    this.minPointsForRedemption = 100,
    this.assistantBaseUrl,
    this.assistantApiKey,
    this.assistantEnabled = false,
  });

  // Helper getters
  String get effectiveBusinessName => businessName ?? 'Alpha Systems';
  String get effectiveCity => city ?? 'Hilte City';
  String get effectiveCountry => country ?? 'India';
  String get effectiveEmail => email ?? 'alpha@gmail.com';
  String get effectiveContactNumber => contactNumber ?? '+1812993345';
  String get effectiveReceiptPrefix => receiptPrefix ?? 'RCPT';
  int get effectiveReceiptStartNumber => receiptStartNumber ?? 1;
  String get effectiveInvoicePrefix => invoicePrefix ?? 'INV';
  int get effectiveInvoiceStartNumber => invoiceStartNumber ?? 1;
  String get effectivePoPrefix => poPrefix ?? 'PO';
  int get effectivePoStartNumber => poStartNumber ?? 1;
  String get effectiveReceiptTagline => receiptTagline ?? 'Thank you for your business!';
  List<String> get effectiveTaxCategories => taxCategories ?? const ['Tax Exempt', 'Standard Rate (15%)', 'Zero Rated'];
  int get effectiveMinPointsForRedemption => minPointsForRedemption ?? 100;
  String get effectiveAssistantBaseUrl => assistantBaseUrl ?? '';
  String get effectiveAssistantApiKey => assistantApiKey ?? '';
  bool get effectiveAssistantEnabled => assistantEnabled ?? false;

  AppSettings copyWith({
    String? baseCurrency,
    Map<String, double>? exchangeRates,
    String? businessName,
    String? city,
    String? country,
    String? email,
    String? contactNumber,
    String? receiptPrefix,
    int? receiptStartNumber,
    String? invoicePrefix,
    int? invoiceStartNumber,
    String? poPrefix,
    int? poStartNumber,
    String? receiptTagline,
    List<String>? taxCategories,
    String? adminPin,
    int? minPointsForRedemption,
    String? assistantBaseUrl,
    String? assistantApiKey,
    bool? assistantEnabled,
  }) {
    return AppSettings(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      businessName: businessName ?? this.businessName,
      city: city ?? this.city,
      country: country ?? this.country,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      receiptStartNumber: receiptStartNumber ?? this.receiptStartNumber,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceStartNumber: invoiceStartNumber ?? this.invoiceStartNumber,
      poPrefix: poPrefix ?? this.poPrefix,
      poStartNumber: poStartNumber ?? this.poStartNumber,
      receiptTagline: receiptTagline ?? this.receiptTagline,
      taxCategories: taxCategories ?? this.taxCategories,
      adminPin: adminPin ?? this.adminPin,
      minPointsForRedemption: minPointsForRedemption ?? this.minPointsForRedemption,
      assistantBaseUrl: assistantBaseUrl ?? this.assistantBaseUrl,
      assistantApiKey: assistantApiKey ?? this.assistantApiKey,
      assistantEnabled: assistantEnabled ?? this.assistantEnabled,
    );
  }
}
