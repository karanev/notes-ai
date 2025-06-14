import 'package:flutter/material.dart';
import '../../services/nlp_service/nlp_models.dart'; // For NlpResult
import '../../repositories/note_repository.dart';
import '../add_edit_note_screen.dart';

class NlpResultDialog extends StatelessWidget {
  final NlpResult nlpResult;
  final NoteRepository noteRepository;

  const NlpResultDialog({
    Key? key,
    required this.nlpResult,
    required this.noteRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (nlpResult.notes.isNotEmpty) {
      return AlertDialog(
        title: Text(nlpResult.message.split('\n\n').first),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: nlpResult.notes.length,
                  itemBuilder: (BuildContext context, int index) {
                    final note = nlpResult.notes[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.only(right: 16.0), // Remove only left padding, keep 16.0 right padding
                      title: Text(note.title),
                      onTap: () {
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddEditNoteScreen(
                              repository: noteRepository,
                              note: note,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: const Text("Message"),
        content: Text(nlpResult.message),
        actions: [
          TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop()),
        ],
      );
    }
  }
}