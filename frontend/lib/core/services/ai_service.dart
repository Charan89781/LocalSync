class AIService {
  // Mock AI Recommendation Engine
  static Future<List<String>> getRecommendedCategories(
      String userInterests) async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Safety', 'Events', 'Marketplace'];
  }

  // Mock AI Spam Detection
  static Future<bool> isSpam(String content) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final spamKeywords = ['winner', 'prize', 'click here', 'free money'];
    return spamKeywords
        .any((keyword) => content.toLowerCase().contains(keyword));
  }

  // Mock AI Complaint Classification
  static Future<String> classifyComplaint(String description) async {
    await Future.delayed(const Duration(seconds: 1));
    if (description.contains('water') || description.contains('pipe')) {
      return 'Infrastructure';
    }
    if (description.contains('noise') || description.contains('loud')) {
      return 'Noise';
    }
    if (description.contains('trash') || description.contains('garbage')) {
      return 'Sanitation';
    }
    return 'General';
  }

  // Mock AI Sentiment Analysis for Community Health
  static Future<double> analyzeCommunitySentiment() async {
    // Returns a score between 0.0 and 1.0
    return 0.85;
  }
}
