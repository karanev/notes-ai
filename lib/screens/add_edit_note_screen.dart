import 'package:flutter/material.dart';
import '../services/database.dart' show Note, NoteType; // Import NoteType
import '../repositories/note_repository.dart';
import '../models/note_status.dart';
import '../models/list_item_model.dart'; // Import the new ListItem model
import 'dart:convert'; // For JSON operations
import 'components/add_edit_note/note_content_input_widget.dart'; // New component

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
  int _nextListItemCreationOrder = 0;

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
              .map((item) => ListItem.fromJson(
                  item as Map<String, dynamic>, _nextListItemCreationOrder++))
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
        _listItems.add(ListItem(
          text: _newListItemController.text.trim(),
          creationOrder: _nextListItemCreationOrder++,
        ));
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
                // Use the new component
                NoteContentInputWidget(
                  currentNoteType: _currentNoteType,
                  contentController: _contentController,
                  listItems: _listItems,
                  newListItemController: _newListItemController,
                  onAddListItem: _addListItem,
                  onRemoveListItem: _removeListItem,
                  onListItemCompletedChanged: (item, newValue) { // Callback for checkbox change
                    setState(() {
                      item.isCompleted = newValue ?? false;
                    });
                  },
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
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}