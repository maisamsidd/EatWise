import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:animate_gradient/animate_gradient.dart';

class Output extends StatefulWidget {
  final String userId;
  final String profileId;
  final Map<String, bool> healthConditions;
  final List<String> dishes;

  const Output({
    super.key,
    required this.userId,
    required this.profileId,
    required this.healthConditions,
    required this.dishes,
  });

  @override
  State<Output> createState() => _OutputState();
}

class _OutputState extends State<Output> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _analyses = [];
  List<dynamic> _filteredAnalyses = [];
  Map<String, dynamic>? _profileInfo;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expandedCards = {};
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  // Color Palette
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _warningColor = const Color(0xFFFFC107);
  final Color _dangerColor = const Color(0xFFF44336);
  final Color _cardBackground = const Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
    _searchController.addListener(_filterAnalyses);
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.post(
        Uri.parse("https://a423-34-143-164-249.ngrok-free.app/ids"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "profile_id": widget.profileId,
        }),
      ).timeout(const Duration(seconds: 240));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _analyses = responseData['analyses'] ?? [];
          _profileInfo = responseData['profile_info'];
          _isLoading = false;
        });
        _sortAnalyses();
        _filterAnalyses();
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load recommendations');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showErrorSnackbar();
    }
  }

  void _sortAnalyses() {
    _analyses.sort((a, b) {
      final order = {'green': 0, 'yellow': 1, 'red': 2};
      final aOrder = order[a['recommendation'].toLowerCase()] ?? 3;
      final bOrder = order[b['recommendation'].toLowerCase()] ?? 3;
      return aOrder.compareTo(bOrder);
    });
  }

  void _filterAnalyses() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredAnalyses = List.from(_analyses);
      } else {
        _filteredAnalyses = _analyses.where((analysis) {
          final dishName = (analysis['dish'] ?? '').toString().toLowerCase();
          final alternative = (analysis['alternative'] ?? '').toString().toLowerCase();
          return dishName.contains(query) || alternative.contains(query);
        }).toList();
      }
    });
  }

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_errorMessage),
        backgroundColor: _dangerColor,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _fetchRecommendations,
        ),
      ),
    );
  }

  Color _getCardColor(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'green':
        return _successColor.withOpacity(0.3);
      case 'red':
        return _dangerColor.withOpacity(0.3);
      default:
        return _warningColor.withOpacity(0.3);
    }
  }

  Color _getBorderColor(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'green':
        return _successColor;
      case 'red':
        return _dangerColor;
      default:
        return _warningColor;
    }
  }

  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    final cardColor = _getCardColor(analysis['recommendation']);
    final borderColor = _getBorderColor(analysis['recommendation']);
    final textColor = Colors.grey.shade800;
    final isExpanded = _expandedCards[analysis['dish']] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedCards[analysis['dish']] = !isExpanded;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          analysis['dish'] ?? 'Unknown Dish',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Text(
                          analysis['recommendation'].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: isExpanded
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        analysis['explanation'] ?? 'No explanation provided',
                        style: TextStyle(
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                      if (analysis['recommendation'] != 'Green') ...[
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: textColor, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Suggestion: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              TextSpan(text: analysis['alternative'] ?? 'No suggestion'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade700.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search dishes (e.g., biryani, veg, chicken)',
                    prefixIcon: Icon(Icons.search, color: _primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.lightBlueAccent.withOpacity(0.2),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(color: Colors.black87),
                  onChanged: (value) {
                    _filterAnalyses();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Veg'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Non-Veg'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Spicy'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sweet'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return AnimatedScale(
      scale: _searchQuery == label.toLowerCase() ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(label),
        selected: _searchQuery == label.toLowerCase(),
        onSelected: (bool selected) {
          setState(() {
            _searchController.text = selected ? label : '';
            _filterAnalyses();
          });
        },
        backgroundColor: Colors.white.withOpacity(0.2),
        selectedColor: _primaryColor.withOpacity(0.4),
        checkmarkColor: _primaryColor,
        labelStyle: TextStyle(
          color: _searchQuery == label.toLowerCase()
              ? _primaryColor
              : Colors.grey.shade700,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: _searchQuery == label.toLowerCase()
                ? _primaryColor
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Dishes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchRecommendations,
            color: _primaryColor,
            child: _filteredAnalyses.isEmpty
                ? Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No dishes available'
                    : 'No dishes found for "$_searchQuery"',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredAnalyses.length,
              itemBuilder: (context, index) {
                return _buildAnalysisCard(_filteredAnalyses[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
          const SizedBox(height: 20),
          const Text('Analyzing your dishes...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 50,
            color: _dangerColor,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            onPressed: _fetchRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recommendation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
          tooltip: 'Back to Home',
        ),
        actions: [
        ],
      ),
      body: AnimateGradient(
        primaryColors: [
          _cardBackground,
          _primaryColor.withOpacity(0.4),
        ],
        secondaryColors: [
          _primaryColor.withOpacity(0.4),
          _cardBackground,
        ],
        child: _isLoading
            ? _buildLoadingIndicator()
            : _hasError
            ? _buildErrorState()
            : _buildContent(),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () {
            _fabController.forward().then((_) => _fabController.reverse());
            _fetchRecommendations();
          },
          backgroundColor: _primaryColor,
          child: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
        ),
      ),
    );
  }
}