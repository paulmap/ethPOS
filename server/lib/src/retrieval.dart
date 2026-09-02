import 'models/product_dto.dart';

/// A scored candidate product returned by [Retrieval.search].
class ScoredProduct {
  final ProductDto product;
  final int score;

  ScoredProduct(this.product, this.score);
}

/// Deterministic keyword-based retrieval — no embeddings/vector search.
/// Given the 8GB RAM budget on the target VPS has to also hold the Ollama
/// model itself, this deliberately avoids an embeddings pipeline. Candidate
/// selection is fully decided here; the LLM's only job is writing prose from
/// the context it's given, which is far more reliable for a small (3B-class)
/// instruct model than asking it to also emit structured references.
class Retrieval {
  static const _stopwords = {
    'a', 'an', 'the', 'is', 'are', 'do', 'does', 'i', 'you', 'we', 'have',
    'has', 'of', 'for', 'to', 'in', 'on', 'at', 'and', 'or', 'my', 'me',
    'it', 'this', 'that', 'want', 'need', 'please', 'can', 'could',
  };

  static final _fitmentPhrase = RegExp(
    r'\b(?:for|fits|fit|compatible with|works with)\s+([a-z0-9 ]{2,30})',
    caseSensitive: false,
  );

  /// Tokenizes [question] into lowercase words, stripping punctuation and
  /// dropping stopwords.
  static List<String> tokenize(String question) {
    final cleaned = question.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    return cleaned
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_stopwords.contains(t))
        .toList();
  }

  /// Extracts the fitment target from phrasing like "for iPhone 12",
  /// "fits iPhone 12", "compatible with iPhone 12" — or null if no such
  /// phrase is present.
  static String? extractFitmentTarget(String question) {
    final match = _fitmentPhrase.firstMatch(question);
    return match?.group(1)?.trim();
  }

  /// Scores and ranks [catalog] against [question], returning the top
  /// [limit] candidates with score > 0.
  static List<ScoredProduct> search(String question, List<ProductDto> catalog, {int limit = 8}) {
    final tokens = tokenize(question);
    final fitmentTarget = extractFitmentTarget(question)?.toLowerCase();

    final scored = <ScoredProduct>[];
    for (final product in catalog) {
      final blob = product.searchBlob;
      var score = 0;

      for (final token in tokens) {
        if (blob.contains(token)) score += 1;
      }

      for (final tag in product.compatibleTags) {
        final tagLower = tag.toLowerCase();
        for (final token in tokens) {
          if (tagLower.contains(token)) score += 3;
        }
        if (fitmentTarget != null &&
            (tagLower.contains(fitmentTarget) || fitmentTarget.contains(tagLower))) {
          score += 5;
        }
      }

      if (score > 0) scored.add(ScoredProduct(product, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).toList();
  }
}
