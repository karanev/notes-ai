// lib/services/database.dart

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert'; // For JSON encoding/decoding

part 'database.g.dart';

// Enum for NoteType
enum NoteType { text, list }

// Helper to convert NoteType enum to String and vice-versa for database storage
class NoteTypeConverter extends TypeConverter<NoteType, String> {
  const NoteTypeConverter();
  @override
  NoteType fromSql(String fromDb) {
    return NoteType.values.firstWhere((e) => e.toString() == fromDb, orElse: () => NoteType.text);
  }

  @override
  String toSql(NoteType value) {
    return value.toString();
  }
}

// Model for individual list items (will be stored as JSON in Note.content for list types)
// This class is not directly part of the database schema but used for structuring list content.
// For simplicity in this example, its toJson/fromJson is manual.
// In a more complex app, you might use json_serializable.

@DataClassName('Note')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get content => text().named('body')();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get noteType => text().map(const NoteTypeConverter()).withDefault(Constant(NoteType.text.toString()))();
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(
          e ??
              driftDatabase(
                name: 'todo-app',
                native: const DriftNativeOptions(
                  databaseDirectory: getApplicationSupportDirectory,
                ),
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                  onResult: (result) {
                    if (result.missingFeatures.isNotEmpty) {
                      debugPrint(
                        'Using ${result.chosenImplementation} due to unsupported '
                        'browser features: ${result.missingFeatures}',
                      );
                    }
                  },
                ),
              ),
        );

  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 2; // Incremented schema version

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(notes, notes.noteType);
      }
    },
  );

  Stream<List<Note>> watchAllNotes() {
    return (select(notes)..orderBy([
          (n) => OrderingTerm(expression: n.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<List<Note>> getAllNotes() {
    return (select(notes)..orderBy([
          (n) => OrderingTerm(expression: n.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<int> insertNote(NotesCompanion note) => into(notes).insert(note);
  Future<bool> updateNote(NotesCompanion note) => update(notes).replace(note);
  Future<int> deleteNote(int id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();

  Future<int> countUnfinishedTasks() {
    final query = selectOnly(notes)..where(notes.status.equals('todo'));
    query.addColumns([countAll()]);
    return query.map((row) => row.read(countAll())!).getSingle();
  }
}
