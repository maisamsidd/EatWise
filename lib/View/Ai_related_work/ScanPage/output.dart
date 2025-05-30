import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:get/get.dart';
import 'package:eat_wise/Controllers/theme_controller.dart';
import 'package:eat_wise/View/HomePage/userProfile.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/Utils/Apis_utils.dart';

class Output extends StatefulWidget {
  final String userId;
  final String profileId;
  final Map<String, bool> healthConditions;
  final List<String> dishes;
  final List<dynamic>? savedAnalyses;

  const Output({
    super.key,
    required this.userId,
    required this.profileId,
    required this.healthConditions,
    required this.dishes,
    this.savedAnalyses,
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

  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _warningColor = const Color(0xFFFFC107);
  final Color _dangerColor = const Color(0xFFF44336);
  final Color _cardBackground = const Color(0xFFFAFAFA);

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    if (widget.savedAnalyses != null) {
      setState(() {
        _analyses = widget.savedAnalyses!;
        _filteredAnalyses = List.from(_analyses);
        _isLoading = false;
      });
      _sortAnalyses();
    } else {
      _fetchRecommendations();
    }
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

  Future<void> _saveToFirestore(List<dynamic> analyses) async {
    try {
      final scanData = {
        'userId': widget.userId,
        'profileId': widget.profileId,
        'dishes': widget.dishes,
        'analyses': analyses,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await ApisUtils.users
          .doc(widget.userId)
          .collection('scans')
          .add(scanData);
    } catch (e) {
      print('Error saving to Firestore: $e');
    }
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.post(
        Uri.parse("https://c3ec-34-82-46-113.ngrok-free.app/ids"),
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
        await _saveToFirestore(_analyses);
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
    final textColor = themeController.isDarkMode.value ? Colors.grey.shade200 : Colors.grey.shade800;
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
            color: Colors.black.withOpacity(themeController.isDarkMode.value ? 0.3 : 0.1),
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
            color: Colors.black.withOpacity(themeController.isDarkMode.value ? 0.3 : 0.1),
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
                  style: TextStyle(
                    color: themeController.isDarkMode.value ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search dishes (e.g., biryani, veg, chicken)',
                    hintStyle: TextStyle(
                      color: themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[600],
                    ),
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
        label: Text(
          label,
          style: TextStyle(
            color: _searchQuery == label.toLowerCase()
                ? _primaryColor
                : (themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
        selected: _searchQuery == label.toLowerCase(),
        onSelected: (bool selected) {
          setState(() {
            _searchController.text = selected ? label : '';
            _filterAnalyses();
          });
        },
        backgroundColor: themeController.isDarkMode.value ? Colors.grey[800] : Colors.white.withOpacity(0.2),
        selectedColor: _primaryColor.withOpacity(0.4),
        checkmarkColor: _primaryColor,
        shape: StadiumBorder(
          side: BorderSide(
            color: _searchQuery == label.toLowerCase()
                ? _primaryColor
                : (themeController.isDarkMode.value ? Colors.grey[600]! : Colors.grey[300]!),
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
              color: themeController.isDarkMode.value ? Colors.grey[200] : Colors.grey[800],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchRecommendations,
            color: _primaryColor,
            backgroundColor: themeController.isDarkMode.value ? Colors.grey[800] : Colors.white,
            child: _filteredAnalyses.isEmpty
                ? Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No dishes available'
                    : 'No dishes found for "$_searchQuery"',
                style: TextStyle(
                  color: themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[600],
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
          Lottie.asset(
            'assets/animations/load.json',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing your dishes...',
            style: TextStyle(
              color: themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[800],
            ),
          ),
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
                color: themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[700],
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      appBar: AppBar(
        title: Text(
          'Recommendation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Get.back();
          },
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            color: Colors.white,
            onPressed: () {
              Get.to(() => const SettingsPage());
            },
            tooltip: 'Go to Profile',
          ),
        ],
      ),
      body: _isLoading
          ? AnimateGradient(
        primaryColors: [
          themeController.isDarkMode.value ? Colors.grey[900]! : _cardBackground,
          _primaryColor.withOpacity(0.4),
        ],
        secondaryColors: [
          _primaryColor.withOpacity(0.4),
          themeController.isDarkMode.value ? Colors.grey[900]! : _cardBackground,
        ],
        child: _buildLoadingIndicator(),
      )
          : Container(
        color: themeController.isDarkMode.value ? Colors.grey[900] : _cardBackground,
        child: _hasError ? _buildErrorState() : _buildContent(),
      ),
      floatingActionButton: widget.savedAnalyses == null
          ? ScaleTransition(
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
      )
          : null,
    ));
  }
}