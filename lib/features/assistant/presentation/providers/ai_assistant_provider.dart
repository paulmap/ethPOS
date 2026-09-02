import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/storage/models/local_product.dart';

class ReferencedProduct {
  final String id;
  final String name;
  final double price;
  final String currency;
  final int currentStock;
  final String locationCode;

  ReferencedProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.currentStock,
    required this.locationCode,
  });

  factory ReferencedProduct.fromJson(Map<String, dynamic> json) {
    return ReferencedProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
      locationCode: json['locationCode'] as String? ?? 'Unassigned',
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<ReferencedProduct> referencedProducts;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.referencedProducts = const [],
    this.isError = false,
  });
}

/// Talks to the self-hosted AI assistant backend (see /server). Kept
/// decoupled from InventoryProvider/AppSettings via constructors -- callers
/// pass baseUrl/apiKey at call time, matching how other providers in this
/// app avoid cross-provider coupling.
class AiAssistantProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Dio _client(String baseUrl, String apiKey) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      // A small model on a modest VPS can genuinely take several seconds.
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Authorization': 'Bearer $apiKey'},
    ));
  }

  Future<void> sendQuestion(String question, {required String baseUrl, required String apiKey}) async {
    _messages.add(ChatMessage(text: question, isUser: true));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client(baseUrl, apiKey).post('/v1/query', data: {'question': question});
      final data = response.data as Map<String, dynamic>;
      final referenced = (data['referencedProducts'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ReferencedProduct.fromJson)
          .toList();
      _messages.add(ChatMessage(
        text: data['answer'] as String? ?? '(no answer)',
        isUser: false,
        referencedProducts: referenced,
      ));
    } on DioException catch (e) {
      _messages.add(ChatMessage(text: _describeError(e), isUser: false, isError: true));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> syncCatalog(List<LocalProduct> products, {required String baseUrl, required String apiKey}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _client(baseUrl, apiKey).post('/v1/sync', data: {
        'products': products
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'barcode': p.barcode,
                  'price': p.price,
                  'currency': p.effectiveCurrency,
                  'currentStock': p.currentStock,
                  'category': p.effectiveCategory,
                  'description': p.effectiveDescription,
                  'locationCode': p.locationCode,
                  'compatibleTags': p.effectiveCompatibleTags,
                })
            .toList(),
      });
      return true;
    } on DioException catch (e) {
      _errorMessage = _describeError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _describeError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return "Can't reach the AI assistant server. Check the backend URL and your connection.";
      case DioExceptionType.receiveTimeout:
        return 'The assistant took too long to respond. Please try again.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          return 'Unauthorized — check the API key in Settings.';
        }
        return 'The assistant server returned an error (${e.response?.statusCode}).';
      default:
        return 'Something went wrong talking to the assistant server.';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
