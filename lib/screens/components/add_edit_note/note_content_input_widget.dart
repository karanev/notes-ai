import 'package:flutter/material.dart';
import '../../../services/database.dart' show NoteType;
import '../../../models/list_item_model.dart';

class NoteContentInputWidget extends StatelessWidget {
  final NoteType currentNoteType;
  final TextEditingController contentController;
  final List<ListItem> listItems;
  final TextEditingController newListItemController;
  final VoidCallback onAddListItem;
  final void Function(int index) onRemoveListItem;
  final void Function(ListItem item, bool? newValue) onListItemCompletedChanged;

  const NoteContentInputWidget({
    Key? key,
    required this.currentNoteType,
    required this.contentController,
    required this.listItems,
    required this.newListItemController,
    required this.onAddListItem,
    required this.onRemoveListItem,
    required this.onListItemCompletedChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentNoteType == NoteType.list) {
      // Sort list items before rendering
      final sortedListItems = List<ListItem>.from(listItems);
      sortedListItems.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.creationOrder.compareTo(b.creationOrder);
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('List Items:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (sortedListItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text('No items yet. Add one below!')),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedListItems.length,
            itemBuilder: (context, index) {
              final item = sortedListItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: item.isCompleted,
                        onChanged: (bool? value) {
                          onListItemCompletedChanged(item, value);
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
                        onPressed: () => onRemoveListItem(listItems.indexOf(item)), // Use original list index for removal
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: newListItemController,
            decoration: InputDecoration(
              labelText: 'Add new item',
              suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: onAddListItem),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => onAddListItem(),
          ),
        ],
      );
    } else {
      // Text Note
      return TextFormField(
        controller: contentController,
        decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder(), alignLabelWithHint: true),
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
      );
    }
  }
}