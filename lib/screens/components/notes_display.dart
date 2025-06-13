import 'package:flutter/material.dart';
import '../../repositories/note_repository.dart';
import '../../services/database.dart' show Note;
import '../../models/note_status.dart';

class NotesDisplay extends StatelessWidget {
  final NoteRepository noteRepository;
  final Widget Function(Note) buildNoteSubtitle;
  final void Function(Note) onNoteTap;
  final void Function(Note) onNoteLongPress;

  const NotesDisplay({
    Key? key,
    required this.noteRepository,
    required this.buildNoteSubtitle,
    required this.onNoteTap,
    required this.onNoteLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: noteRepository.watchAllNotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notes = snapshot.data ?? [];

        if (notes.isEmpty) {
          return const Center(
            child: Text(
              'No notes yet. Tap the "+" to add one!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: buildNoteSubtitle(note),
                trailing: Text(
                  NoteStatus.displayText(note.status),
                  style: TextStyle(
                    color: NoteStatus.getColor(note.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => onNoteTap(note),
                onLongPress: () => onNoteLongPress(note),
              ),
            );
          },
        );
      },
    );
  }
}