import 'dart:convert';
import 'package:eat_wise/Model/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatScreen extends StatefulWidget {
  final String initialMessage;

  ChatScreen({super.key, required this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;

  // Animation Controller and Animation for background color change
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  Future<void> sendMessage(String userInput) async {
    const topicInstruction =
        "You are a helpful assistant who only talks briefly about Dish guidance according to health conditions, "
        "main ingredients categorization (Green, Yellow, Red for safe, moderate, caution respectively). "
        "If not related to dishes, health or nutrition, reply 'I'm only trained to talk about fitness and nutrition.'";

    final fullPrompt = "$topicInstruction\n\nUser: $userInput";

    setState(() {
      _messages.add(ChatMessage(userInput, true));
      _isLoading = true;
    });

    final reply = await generateGeminiResponse(fullPrompt);

    setState(() {
      _messages.add(ChatMessage(reply, false));
      _isLoading = false;
    });

    _controller.clear();
  }

  Future<String> generateGeminiResponse(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final text = decoded['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } else {
      print("❌ Error: ${response.statusCode}");
      print("💬 Body: ${response.body}");
      return 'Something went wrong. Please try again.';
    }
  }

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
        "👋 Welcome to EatWise Chatbot! How can I assist you today?", false));
    _controller.text = widget.initialMessage;

    // Initialize AnimationController and ColorTween for background animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);  // Repeat with reverse

    _colorAnimation = ColorTween(
      begin: Colors.blue.shade700,
      end: Colors.lightGreen,
    ).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }


  @override
  void dispose() {
    _animationController.dispose();  // Dispose of the animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Colors.blueAccent;
    final Color softGreen = Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Row(
          children: [
            const Text(
              "Hello",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Colors.white),
            ),
          ],
        ),
        elevation: 3, // Remove shadow
        toolbarHeight: 100,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade300, _colorAnimation.value!],
                      stops: [0.0, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
          // Main content on top of the background
          Column(
            children: [
              // Add space for the app bar
              //SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: message.isUser ? primaryBlue : Colors.green.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: message.isUser
                                ? Radius.circular(16)
                                : Radius.zero,
                            bottomRight: message.isUser
                                ? Radius.zero
                                : Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            )
                          ],
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          cursorColor: Colors.green,
                          cursorWidth: 2.0, // Default is 2.0
                          cursorHeight: 18.0,
                          cursorRadius: Radius.circular(2.0),
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),

                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          final text = _controller.text.trim();
                          if (text.isNotEmpty) {
                            sendMessage(text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}