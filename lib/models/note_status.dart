import 'package:flutter/material.dart';

class NoteStatus {
  static const String done = 'done';
  static const String inProgress = 'inProgress';
  static const String todo = 'todo';

  static Color getColor(String status) {
    switch (status) {
      case done:
        return Colors.green;
      case inProgress:
        return Colors.blue;
      case todo:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static String displayText(String status) {
    switch (status) {
      case done:
        return 'DONE';
      case inProgress:
        return 'IN PROGRESS';
      case todo:
        return 'TODO';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }
}
