import 'package:flutter/material.dart';

class NlpQueryInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAskQuestion;

  const NlpQueryInput({
    Key? key,
    required this.controller,
    required this.onAskQuestion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Ask Nara...',
          hintText: 'e.g., How many finished tasks?',
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: onAskQuestion,
          ),
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => onAskQuestion(),
      ),
    );
  }
}