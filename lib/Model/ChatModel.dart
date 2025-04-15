import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage(
    this.text,
    this.isUser,
  );
}
