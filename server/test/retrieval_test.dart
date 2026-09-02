import 'package:ethpos_assistant_server/src/models/product_dto.dart';
import 'package:ethpos_assistant_server/src/retrieval.dart';
import 'package:test/test.dart';

ProductDto _product({
  required String id,
  required String name,
  String category = 'Accessories',
  String description = '',
  double price = 9.99,
  int currentStock = 10,
  List<String> compatibleTags = const [],
}) {
  return ProductDto(
    id: id,
    name: name,
    price: price,
    currency: 'USD',
    currentStock: currentStock,
    category: category,
    description: description,
    locationCode: 'A-1-B1',
    compatibleTags: compatibleTags,
  );
}

void main() {
  group('Retrieval.tokenize', () {
    test('lowercases, strips punctuation, drops stopwords', () {
      final tokens = Retrieval.tokenize('Do you have a case for the iPhone 12?');
      expect(tokens, containsAll(['case', 'iphone', '12']));
      expect(tokens, isNot(contains('have'))); // stopword
      expect(tokens, isNot(contains('the')));
      expect(tokens, isNot(contains('for')));
    });
  });

  group('Retrieval.extractFitmentTarget', () {
    test('extracts target from "for X" phrasing', () {
      expect(Retrieval.extractFitmentTarget('do you have a case for iphone 12'), 'iphone 12');
    });

    test('extracts target from "fits X" phrasing', () {
      expect(Retrieval.extractFitmentTarget('does this charger fit samsung s21'), 'samsung s21');
    });

    test('extracts target from "compatible with X" phrasing', () {
      expect(Retrieval.extractFitmentTarget('is this compatible with iphone 13'), 'iphone 13');
    });

    test('returns null when no fitment phrase present', () {
      expect(Retrieval.extractFitmentTarget('what is the price of milk'), isNull);
    });
  });

  group('Retrieval.search', () {
    final milk = _product(id: '1', name: 'Full Cream Milk 1L', category: 'Dairy', description: 'Fresh milk');
    final case12 = _product(
      id: '2',
      name: 'Slim Case',
      description: 'Protective phone case',
      compatibleTags: ['iPhone 12', 'iPhone 13'],
    );
    final case14 = _product(
      id: '3',
      name: 'Rugged Case',
      description: 'Heavy duty phone case',
      compatibleTags: ['iPhone 14'],
      currentStock: 0,
    );
    final charger = _product(
      id: '4',
      name: 'USB-C Charger 20W',
      description: 'Fast charger',
      compatibleTags: ['iPhone 12', 'iPhone 13', 'Samsung S21'],
    );
    final catalog = [milk, case12, case14, charger];

    test('unrelated query returns no candidates', () {
      final results = Retrieval.search('do you sell bread', catalog);
      expect(results, isEmpty);
    });

    test('plain name match finds the product', () {
      final results = Retrieval.search('how much is the milk', catalog);
      expect(results.map((r) => r.product.id), contains('1'));
    });

    test('fitment query ranks tagged accessories above plain matches', () {
      final results = Retrieval.search('do you have a case for iphone 12', catalog);
      expect(results, isNotEmpty);
      expect(results.first.product.id, '2'); // case12 — exact tag match
    });

    test('fitment query surfaces out-of-stock compatible items too', () {
      final results = Retrieval.search('case for iphone 14', catalog);
      expect(results.map((r) => r.product.id), contains('3'));
      expect(results.first.product.currentStock, 0);
    });

    test('cross-category interchangeable accessories both surface for a shared fitment tag', () {
      final results = Retrieval.search('what fits my iphone 12', catalog);
      final ids = results.map((r) => r.product.id).toSet();
      expect(ids, containsAll(['2', '4'])); // case and charger both tagged for iPhone 12
    });

    test('respects the limit parameter', () {
      final bigCatalog = List.generate(
        20,
        (i) => _product(id: 'p$i', name: 'Widget $i', description: 'a generic widget'),
      );
      final results = Retrieval.search('widget', bigCatalog, limit: 5);
      expect(results.length, 5);
    });
  });
}
