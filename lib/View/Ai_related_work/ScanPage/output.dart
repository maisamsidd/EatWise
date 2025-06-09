import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Added for explicit timeout handling

class Output extends StatefulWidget {
  final List<String> dishes;
  final Map<String, bool> healthConditions;
  final String userId;
  final String profileId;

  const Output({
    super.key,
    required this.dishes,
    required this.healthConditions,
    required this.userId,
    required this.profileId,
  });

  @override
  State<Output> createState() => _OutputState();
}

class _OutputState extends State<Output> {
  String recommendationText = "Loading recommendations...";
  List<String> matchedDishes = [];
  bool isLoading = true;
  String errorMessage = "";
  bool hasError = false;
  final Color primaryColor = Colors.blue.shade700;
  final Color secondaryColor = Colors.blue.shade100;
  final Color textColor = Colors.white;
  bool isRetrying = false;
  int retryCount = 0;
  final int maxRetries = 2;

  // Search functionality
  TextEditingController searchController = TextEditingController();
  List<String> filteredDishes = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchRecommendations() async {
    // API endpoint - consider moving this to a configuration file
    const apiUrl = "https://fc70-34-125-96-33.ngrok-free.app/recommend";
    // Fallback endpoint for when the main one times out
    const fallbackUrl =
        "https://fc70-34-125-96-33.ngrok-free.app/recommend/default";

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = "";
      isRetrying = retryCount > 0;
    });

    try {
      // Use a shorter timeout for faster feedback
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "ngrok-skip-browser-warning": "true"
            },
            body: jsonEncode({
              "user_id": widget.userId,
              "profile_id": widget.profileId,
            }),
          )
          .timeout(
              const Duration(seconds: 15)); // Reduced timeout to 15 seconds

      debugPrint("API Response: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          recommendationText = responseBody["recommendation"] ??
              "No specific recommendation available. Please check your scanned dishes and health conditions.";
          matchedDishes =
              List<String>.from(responseBody["matched_dishes"] ?? []);
          isLoading = false;
          retryCount = 0; // Reset retry count on success
        });
      } else {
        throw Exception(
            "API Error: ${response.statusCode}\n${responseBody["error"] ?? "Unknown error"}");
      }
    } on TimeoutException {
      debugPrint("Main API request timed out, trying fallback URL");

      // Try the fallback endpoint with default recommendations
      try {
        final fallbackResponse = await http.get(
          Uri.parse(fallbackUrl),
          headers: {
            "Accept": "application/json",
            "ngrok-skip-browser-warning": "true"
          },
        ).timeout(const Duration(seconds: 10));

        if (fallbackResponse.statusCode == 200) {
          final fallbackData = jsonDecode(fallbackResponse.body);
          setState(() {
            recommendationText = fallbackData["recommendation"] ??
                "Based on your profile, we recommend balanced meals with lean proteins and vegetables.";
            matchedDishes =
                List<String>.from(fallbackData["matched_dishes"] ?? []);
            isLoading = false;

            // Add a note that this is a fallback recommendation
            if (!recommendationText.contains("(Fallback)")) {
              recommendationText =
                  "$recommendationText\n\n(Fallback recommendation due to server timeout)";
            }
          });
        } else {
          throw Exception("Fallback API failed");
        }
      } catch (fallbackError) {
        // Both main and fallback failed, handle this case
        handleError(
            "Connection timed out. The server might be busy. Please try again later.");
      }
    } catch (e) {
      handleError("Connection error: ${e.toString()}");
    }
  }

  void handleError(String message) {
    // Implement exponential backoff for retries
    if (retryCount < maxRetries) {
      setState(() {
        retryCount++;
        errorMessage = "$message\n\nRetrying ($retryCount/$maxRetries)...";
        hasError = true;
      });

      // Wait longer between each retry
      Future.delayed(Duration(seconds: retryCount * 2)).then((_) {
        fetchRecommendations();
      });
    } else {
      // Max retries reached, show error
      setState(() {
        errorMessage =
            "$message\n\nMax retries reached. Please try again later.";
        hasError = true;
        isLoading = false;
      });

      // Provide generic recommendations in case of failure
      setState(() {
        recommendationText =
            """Based on general health guidelines, we recommend:

1. Focus on balanced meals with lean proteins and plenty of vegetables
2. Stay hydrated by drinking water throughout the day
3. Limit processed foods and added sugars
4. Consider portion sizes appropriate for your needs

(Generic recommendation due to connection issues)""";

        // Add some sample dish matches as a fallback
        matchedDishes = [
          "Grilled Chicken Salad",
          "Steamed Vegetables",
          "Baked Fish"
        ];
        hasError = false;
      });
    }
  }

  void filterDishes(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      filteredDishes = matchedDishes.where((dish) {
        return dish.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget _buildHealthConditionChips() {
    final activeConditions = widget.healthConditions.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (activeConditions.isEmpty) {
      return Chip(
        label: const Text("No health restrictions"),
        backgroundColor: Colors.green,
        labelStyle: const TextStyle(color: Colors.white),
        avatar: const Icon(Icons.check, color: Colors.white),
      );
    }

    return Wrap(
      spacing: 8,
      children: activeConditions.map((condition) {
        return Chip(
          label: Text(
            condition.replaceAllMapped(
              RegExp(r'^.| .'),
              (match) => match.group(0)!.toUpperCase(),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange[700],
          avatar: const Icon(Icons.health_and_safety,
              size: 18, color: Colors.white),
        );
      }).toList(),
    );
  }

  Widget _buildDishChip(String dish) {
    return Chip(
      label: Text(dish),
      backgroundColor: secondaryColor,
      side: BorderSide(color: primaryColor),
    );
  }

  Widget _buildMatchedDishes() {
    final dishesToShow = isSearching ? filteredDishes : matchedDishes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search recommended dishes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        filterDishes('');
                      },
                    )
                  : null,
            ),
            onChanged: filterDishes,
          ),
        ),
        Text(
          isSearching ? "Search Results" : "Recommended Dishes",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (dishesToShow.isEmpty)
          Text(
            isSearching
                ? "No matching dishes found"
                : "No dishes recommended yet",
            style: const TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dishesToShow.map((dish) => _buildDishChip(dish)).toList(),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  "Recommendation",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              recommendationText,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            _buildMatchedDishes(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            isRetrying
                ? "Retrying... ($retryCount/$maxRetries)"
                : "Analyzing your dishes...",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: primaryColor,
                ),
          ),
          if (isRetrying) ...[
            const SizedBox(height: 10),
            Text(
              "The server might be busy. Please wait...",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              "Oops! Something went wrong",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  retryCount = 0; // Reset retry count before retrying
                  fetchRecommendations();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Food Recommendation"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? _buildLoadingScreen()
            : hasError
                ? _buildErrorScreen()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHealthConditionChips(),
                        const SizedBox(height: 20),
                        _buildRecommendationCard(),
                      ],
                    ),
                  ),
      ),
    );
  }
}
