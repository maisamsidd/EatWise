import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart'; // For haptic feedback
// Assuming ChatModel.dart contains the ChatMessage class
// import 'package:eat_wise/Model/ChatModel.dart';

// Define ChatMessage class for clarity (replace with your actual ChatModel.dart)
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage(this.text, this.isUser, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

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
  bool _isTyping = false; // For send button animation

  // Animation Controller for background and send button
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;

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

    // Simulate bot typing
    await Future.delayed(Duration(milliseconds: 500));
    final reply = await generateGeminiResponse(fullPrompt);

    setState(() {
      _messages.add(ChatMessage(reply, false));
      _isLoading = false;
    });

    _controller.clear();
    HapticFeedback.lightImpact(); // Add haptic feedback
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
    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.trim().isNotEmpty;
      });
    });

    // Background animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10), // Slower for subtlety
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.blue.shade300,
      end: Colors.green.shade300,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Send button animation
    _sendButtonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _sendButtonScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _sendButtonController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sendButtonController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Colors.blueAccent;
    final Color softGreen = Colors.green.shade100;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "EatWise Chat",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            fontFamily: 'Roboto', // Modern font
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Show info or settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Chatbot for nutrition guidance")),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Gradient background with blur
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade200,
                        _colorAnimation.value!,
                        Colors.teal.shade200,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
          // Main content
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              _buildInputArea(primaryBlue, softGreen),
            ],
          ),
        ],
      ),
    );
  }

  // Typing indicator widget
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Bot is typing",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Message bubble widget
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.green.shade200,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isUser ? Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser)
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue.shade700,
                      child: Icon(Icons.restaurant_menu,
                          size: 16, color: Colors.white),
                    ),
                  ),
                Flexible(
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input area widget
  Widget _buildInputArea(Color primaryBlue, Color softGreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                cursorColor: Colors.blueAccent,
                cursorWidth: 2.0,
                cursorHeight: 20.0,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  suffixIcon: _isTyping
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      _controller.clear();
                    },
                  )
                      : null,
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    sendMessage(text);
                  }
                },
              ),
            ),
          ),
          SizedBox(width: 12),
          AnimatedBuilder(
            animation: _sendButtonScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _sendButtonScale.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isTyping ? primaryBlue : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _isTyping
                        ? () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        sendMessage(text);
                        _sendButtonController.forward().then((_) =>
                            _sendButtonController.reverse());
                      }
                    }
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}