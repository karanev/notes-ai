import 'package:flutter/material.dart';

// Model for list items used within the AddEditNoteScreen
class ListItem {
  String text;
  bool isCompleted;
  TextEditingController controller;
  FocusNode focusNode;
  final int creationOrder; // To preserve original relative order

  ListItem({
    required this.text,
    this.isCompleted = false,
    required this.creationOrder,
  })
      : controller = TextEditingController(text: text),
        focusNode = FocusNode();

  Map<String, dynamic> toJson() => {'text': text, 'isCompleted': isCompleted};

  factory ListItem.fromJson(Map<String, dynamic> json, int creationOrder) => ListItem(
      text: json['text'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      creationOrder: creationOrder);

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}