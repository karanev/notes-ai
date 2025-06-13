import 'package:flutter/material.dart';
import '../services/database.dart' show Note, NoteType; // Import NoteType
import '../repositories/note_repository.dart';
import '../models/note_status.dart';
import 'dart:convert'; // For JSON operations

// Model for list items used within this screen
class ListItem {
  String text;
  bool isCompleted;
  TextEditingController controller;
  FocusNode focusNode;

  ListItem({required this.text, this.isCompleted = false})
      : controller = TextEditingController(text: text),
        focusNode = FocusNode();

  Map<String, dynamic> toJson() => {'text': text, 'isCompleted': isCompleted};

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
      text: json['text'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false);

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

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
  late NoteType _currentNoteType;
  List<ListItem> _listItems = [];
  final TextEditingController _newListItemController = TextEditingController();

  final List<String> _statuses = [
    NoteStatus.todo,
    NoteStatus.inProgress,
    NoteStatus.done,
  ];
  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _currentStatus = widget.note?.status ?? NoteStatus.todo;
    _currentNoteType = widget.note?.noteType ?? NoteType.text;

    if (_isEditing) {
      if (widget.note!.noteType == NoteType.list) {
        try {
          final List<dynamic> decodedItems = jsonDecode(widget.note!.content);
          _listItems = decodedItems
              .map((item) => ListItem.fromJson(item as Map<String, dynamic>))
              .toList();
          _contentController = TextEditingController(); // Not used for list type
        } catch (e) {
          // If content is not valid JSON for a list, treat as text
          _currentNoteType = NoteType.text;
          _contentController = TextEditingController(text: widget.note!.content);
          _listItems = [];
        }
      } else {
        _contentController = TextEditingController(text: widget.note!.content);
      }
    } else {
      // For new notes, initialize based on the default _currentNoteType
      _contentController = TextEditingController();
      if (_currentNoteType == NoteType.list) _listItems = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _newListItemController.dispose();
    for (var item in _listItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _saveNote() async {
    // First, validate the form. If it's not valid, do nothing.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String contentToSave;
    if (_currentNoteType == NoteType.list) {
      // Ensure item texts are updated from their controllers
      for (var item in _listItems) {
        item.text = item.controller.text;
      }
      contentToSave = jsonEncode(_listItems.map((item) => item.toJson()).toList());
    } else {
      contentToSave = _contentController.text;
    }

    if (_isEditing) {
      final updatedNote = widget.note!.copyWith(
        title: _titleController.text,
        content: contentToSave,
        status: _currentStatus,
        noteType: _currentNoteType,
      );
      await widget.repository.updateNote(updatedNote);
    } else {
      await widget.repository.addNote(
        title: _titleController.text,
        content: contentToSave,
        status: _currentStatus,
        noteType: _currentNoteType,
      );
    }

    // After saving, pop the screen to return to the list
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _addListItem() {
    if (_newListItemController.text.trim().isNotEmpty) {
      setState(() {
        // New items are always added as not completed, so they will appear at the top
        // or among other uncompleted items after sorting.
        // If you want them strictly at the top of uncompleted,
        // you might need to adjust sorting or insert at a specific index.
        // For now, just adding and relying on the sort in build.
        _listItems.add(ListItem(text: _newListItemController.text.trim()));
        _newListItemController.clear();
        // Optionally, request focus for the newly added item's text field
        // Future.delayed(Duration(milliseconds: 50), () => FocusScope.of(context).requestFocus(_listItems.last.focusNode));
      });
    }
  }

  void _removeListItem(int index) {
    _listItems[index].dispose();
    setState(() {
      _listItems.removeAt(index);
      // No need to re-sort here, build will handle it.
    });  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'Add Note'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Note Type Selector
                DropdownButtonFormField<NoteType>(
                  value: _currentNoteType,
                  decoration: const InputDecoration(
                    labelText: 'Note Type',
                    border: OutlineInputBorder(),
                  ),
                  items: NoteType.values.map((NoteType type) {
                    return DropdownMenuItem<NoteType>(
                      value: type,
                      child: Text(type.toString().split('.').last.capitalize()),
                    );
                  }).toList(),
                  onChanged: (NoteType? newValue) {
                    if (newValue != null) {
                      setState(() => _currentNoteType = newValue);
                    }
                  },
                ),
                const SizedBox(height: 16),
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
                _buildContentInput(), // Dynamic content input based on type
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
                      child: Text(NoteStatus.displayText(status)),
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: _saveNote,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentInput() {
    if (_currentNoteType == NoteType.list) {
      // Sort list items: incomplete first, then completed
      _listItems.sort((a, b) {
        if (a.isCompleted == b.isCompleted) return 0; // Keep original order if same status
        return a.isCompleted ? 1 : -1; // Incomplete items first
      });


      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('List Items:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_listItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text('No items yet. Add one below!')),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // To be used inside SingleChildScrollView
            itemCount: _listItems.length,
            itemBuilder: (context, index) {
              final item = _listItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.only(left:8.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: item.isCompleted,
                        onChanged: (bool? value) {
                          setState(() {
                            item.isCompleted = value ?? false;
                            // Re-sorting will happen on next build implicitly due to setState
                          });
                        },
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: item.controller,
                          focusNode: item.focusNode,
                          decoration: InputDecoration(
                            hintText: 'List item ${index + 1}',
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            decoration: item.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                          onChanged: (text) => item.text = text, // Keep item.text in sync
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _removeListItem(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newListItemController,
            decoration: InputDecoration(
              labelText: 'Add new item',
              suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _addListItem),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addListItem(),
          ),
        ],
      );
    } else {
      // Text Note
      return TextFormField(
        controller: _contentController,
        decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder(), alignLabelWithHint: true),
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
      );
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}