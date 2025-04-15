import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Output extends StatefulWidget {
  final List<String> dishes;
  final Map<String, bool> healthConditions;

  const Output({
    super.key,
    required this.dishes,
    required this.healthConditions,
  });

  @override
  State<Output> createState() => _OutputState();
}

class _OutputState extends State<Output> {
  List<Map<String, dynamic>> recommendations = [];
  bool isLoading = true;
  String errorMessage = "";
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

  Future<void> fetchRecommendations() async {
    const url = "https://5f2c-35-192-188-193.ngrok-free.app/recommend"; // Your API

    try {
      final response = await http
          .post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": "current_user",
          "dishes": widget.dishes,
          "health_conditions": widget.healthConditions,
        }),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint("📌 API Response: ${response.body}"); // Debugging line

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Fix: Ensure "recommendations" is always a list
        List<Map<String, dynamic>> parsedRecommendations = [];
        if (jsonResponse.containsKey("recommendations") &&
            jsonResponse["recommendations"] != null) {
          parsedRecommendations = List<Map<String, dynamic>>.from(
              jsonResponse["recommendations"] ?? []);
        }

        setState(() {
          recommendations = parsedRecommendations;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Error: ${response.statusCode}\n${response.body}";
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

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    final source = recommendation['source'] ?? 'llm';
    final dishName = recommendation['dish'] ?? 'Unknown dish';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dishName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    source.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: source == 'dataset'
                      ? Colors.blue[100]
                      : Colors.purple[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (source == 'dataset')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recommendation['recommendation'] != null)
                    Text(
                      recommendation['recommendation'],
                      style: TextStyle(
                        color: _getRecommendationColor(recommendation['recommendation']),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (recommendation['reasons'] != null)
                    ...List<Widget>.from((recommendation['reasons'] as List?)
                        ?.map((reason) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text("• $reason"),
                    )) ??
                        []),
                  const SizedBox(height: 8),
                  if (recommendation['ingredients'] != null)
                    Wrap(
                      spacing: 4,
                      children: List<Widget>.from((recommendation['ingredients'] as List?)
                          ?.map((ing) => Chip(
                        label: Text(ing),
                        backgroundColor: Colors.grey[200],
                      )) ??
                          []),
                    ),
                ],
              )
            else if (recommendation['analysis'] != null)
              Text(
                recommendation['analysis'],
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRecommendationColor(String recommendation) {
    if (recommendation.contains('Good')) return Colors.green;
    if (recommendation.contains('Moderate')) return Colors.orange;
    if (recommendation.contains('Poor')) return Colors.red;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dish Recommendations"),
        actions: [
          if (!isLoading && !hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchRecommendations,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchRecommendations,
                child: const Text("Try Again"),
              ),
            ],
          ),
        ),
      )
          : recommendations.isEmpty
          ? const Center(
        child: Text(
          "No recommendations available",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          return _buildRecommendationItem(recommendations[index]);
        },
      ),
    );
  }
}
