import 'package:flutter/material.dart';
import 'package:notes/screens/note_list_screen.dart';
import 'package:notes/services/database.dart';
import 'package:notes/repositories/note_repository.dart';
import 'package:notes/services/nlp_service/nlp_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate dependencies here
    final AppDatabase database = AppDatabase();
    final NoteRepository noteRepository = NoteRepository(database);
    final NlpService nlpService = NlpService();

    return MaterialApp(
      title: 'NaraNotes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: NoteListScreen(
        noteRepository: noteRepository,
        nlpService: nlpService,
      ),
    );
  }
}