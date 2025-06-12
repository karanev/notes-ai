import 'package:flutter/material.dart';
import '../services/database.dart';
import '../repositories/note_repository.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note; // Null if we are adding, has a value if we are editing
  final NoteRepository repository; // This is required for the screen to function

  const AddEditNoteScreen({
    Key? key,
    required this.repository,
    this.note,
  }) : super(key: key);

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _currentStatus;

  final List<String> _statuses = ['todo', 'in_progress', 'done'];
  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _currentStatus = widget.note?.status ?? 'todo';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    // First, validate the form. If it's not valid, do nothing.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Use the repository to perform the action.
    // The UI doesn't know or care how the repository saves the data.
    if (_isEditing) {
      // Use `copyWith` to create an updated instance of the note
      final updatedNote = widget.note!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        status: _currentStatus,
      );
      await widget.repository.updateNote(updatedNote);
    } else {
      await widget.repository.addNote(
        title: _titleController.text,
        content: _contentController.text,
        status: _currentStatus,
      );
    }

    // After saving, pop the screen to return to the list
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'Add Note'),
        actions: [
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Text Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Content Text Field
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: _currentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _statuses.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status.replaceAll('_', ' ').toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentStatus = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}