import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String noteTitle;
  final VoidCallback onConfirmDelete;

  const DeleteConfirmationDialog({
    Key? key,
    required this.noteTitle,
    required this.onConfirmDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Note?'),
      content: Text('Are you sure you want to delete "$noteTitle"?'),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
          onPressed: () {
            onConfirmDelete();
            Navigator.of(context).pop(); // Close the dialog after confirming
          },
        ),
      ],
    );
  }
}