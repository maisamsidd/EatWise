import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    const url = "https://5711-146-148-56-55.ngrok-free.app/recommend";

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "ngrok-skip-browser-warning": "true"
        },
        body: jsonEncode({
          "user_id": widget.userId,
          "profile_id": widget.profileId,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint("API Response: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          recommendationText = responseBody["recommendation"] ??
              "No specific recommendation available. Please check your scanned dishes and health conditions.";
          matchedDishes = List<String>.from(responseBody["matched_dishes"] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = responseBody["error"] ??
              "Error: ${response.statusCode}\n${response.body}";
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection error: ${e.toString()}";
        hasError = true;
        isLoading = false;
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
          avatar: const Icon(Icons.health_and_safety, size: 18, color: Colors.white),
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
            isSearching ? "No matching dishes found" : "No dishes recommended yet",
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
            "Analyzing your dishes...",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: primaryColor,
            ),
          ),
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
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: fetchRecommendations,
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
        title: Text(
          "Dish Recommendations",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: primaryColor,
        actions: [
          if (!isLoading && !hasError)
            IconButton(
              icon: Icon(Icons.refresh, color: textColor),
              onPressed: fetchRecommendations,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.1), Colors.white],
            stops: const [0.1, 0.1],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Health Profile",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildHealthConditionChips(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                _buildLoadingScreen()
              else if (hasError)
                _buildErrorScreen()
              else
                _buildRecommendationCard(),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Scanned Dishes",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.dishes.map((dish) {
                          return Chip(
                            label: Text(dish),
                            backgroundColor: secondaryColor,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}