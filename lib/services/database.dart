// lib/services/database.dart

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

part 'database.g.dart';

@DataClassName('Note')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get content => text().named('body')();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
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
  int get schemaVersion => 1;

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
