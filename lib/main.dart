import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqflite_logger.dart';
import 'package:talker/talker.dart';
import 'package:talker_sqflite_logger/talker_sqflite_logger.dart';

class TalkerObserverImp implements TalkerObserver {
  TalkerObserverImp();

  @override
  void onError(TalkerError err) {
    developer.log(
      err.generateTextMessage(),
      time: err.time,
      level: Level.SEVERE.value,
      name: err.title ?? err.displayMessage,
      error: err.error,
      stackTrace: err.stackTrace,
    );
  }

  @override
  void onException(TalkerException err) {
    developer.log(
      err.generateTextMessage(),
      time: err.time,
      level: Level.SHOUT.value,
      name: err.title ?? err.displayMessage,
      error: err.error,
      stackTrace: err.stackTrace,
    );
  }

  @override
  void onLog(TalkerData log) {
    // developer.log(
    //   log.generateTextMessage(),
    //   time: log.time,
    //   level: Level.INFO.value,
    //   name: log.title ?? log.displayMessage,
    // );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Talker _talker;

  @override
  void initState() {
    super.initState();

    _talker = Talker(
      logger: TalkerLogger(
        output: (message) => developer.log(message),
      ),
      observer: TalkerObserverImp(),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: MyHomePage(
          talker: _talker,
        ),
        debugShowCheckedModeBanner: false,
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required Talker talker,
  }) : _talker = talker;

  final Talker _talker;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Database _db;
  late TalkerSqfliteDatabaseFactory _factory;

  Future<String> get _path async => join(await getDatabasesPath(), 'demo.db');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Talker Sqflite Logger'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton(
                onPressed: _button01onPressed,
                child: const Text('Open, close and delete database'),
              ),
              const SizedBox(
                height: 8.0,
              ),
              FilledButton(
                onPressed: _button02onPressed,
                child: const Text('SQL Queries'),
              ),
              const SizedBox(
                height: 8.0,
              ),
              FilledButton(
                onPressed: _button03onPressed,
                child: const Text('Batch Queries'),
              ),
              const SizedBox(
                height: 8.0,
              ),
              FilledButton(
                onPressed: _button04onPressed,
                child: const Text('Filter SQL Queries'),
              ),
              const SizedBox(
                height: 8.0,
              ),
              FilledButton(
                onPressed: _button05onPressed,
                child: const Text('Filter Batch Queries'),
              ),
              const SizedBox(
                height: 8.0,
              ),
              FilledButton(
                onPressed: _button06onPressed,
                child: const Text('Invokes'),
              ),
            ],
          ),
        ),
      );

  Future<void> _createDatabase({
    TalkerSqfliteLoggerSettings? settings,
    SqfliteDatabaseFactoryLoggerType? type,
    OpenDatabaseOptions? options,
  }) async {
    _factory = TalkerSqfliteDatabaseFactory(
      talker: widget._talker,
      settings: settings,
    );

    _db = await _factory.openDatabase(
      path: await _path,
      options: options,
      type: type,
    );
  }

  Future<void> _closeDatabase() async {
    await _db.close();
  }

  Future<void> _deleteDatabase() async {
    await _factory.deleteDatabase(await _path);
  }

  Future<void> _button01onPressed() async {
    try {
      await _createDatabase(
        settings: const TalkerSqfliteLoggerSettings(
          printSqlEvents: false,
          printDatabaseOpenEvents: true,
          printOpenDatabaseOptions: true,
          printDatabaseCloseEvents: true,
          printDatabaseDeleteEvents: true,
        ),
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) {
            db.execute(
              'CREATE TABLE Test '
              '(id INTEGER PRIMARY KEY, '
              'name TEXT, '
              'value INTEGER, '
              'num REAL)',
            );
          },
        ),
      );
      await _closeDatabase();
      await _deleteDatabase();
    } catch (error, stackTrace) {
      widget._talker.handle(
        error,
        stackTrace,
        "Error on clicking in the button 'Open, close and delete database'",
      );
    }
  }

  Future<void> _button02onPressed() async {
    try {
      await _createDatabase(
        settings: const TalkerSqfliteLoggerSettings(
          printSqlResults: true,
        ),
      );
      await _db.transaction((txn) async {
        await txn.execute(
          'CREATE TABLE Test '
          '(id INTEGER PRIMARY KEY, '
          'name TEXT, '
          'value INTEGER, '
          'num REAL)',
        );
        await txn.insert(
          'Test',
          {
            'name': 'some name',
            'value': 1234,
            'num': 456.789,
          },
        );
        await txn.update(
          'Test',
          {
            'name': 'updated name',
            'value': '9876',
          },
          where: 'name = ?',
          whereArgs: [
            'some name',
          ],
        );
      });

      await _db.query('Test');

      await _closeDatabase();
      await _deleteDatabase();
    } catch (error, stackTrace) {
      widget._talker.handle(
        error,
        stackTrace,
        "Error on clicking in the button 'SQL Queries'",
      );
    }
  }

  Future<void> _button03onPressed() async {
    try {
      await _createDatabase(
        settings: const TalkerSqfliteLoggerSettings(
          printSqlEvents: false,
        ),
      );

      final batch = _db.batch()
        ..execute(
          'CREATE TABLE Test '
          '(id INTEGER PRIMARY KEY, '
          'name TEXT, '
          'value INTEGER, '
          'num REAL)',
        )
        ..rawInsert(
          'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)',
        )
        ..rawUpdate(
          'UPDATE Test SET name = ?, value = ? WHERE name = ?',
          ['updated name', '9876', 'some name'],
        );

      await batch.commit();

      await _closeDatabase();
      await _deleteDatabase();
    } catch (error, stackTrace) {
      widget._talker.handle(
        error,
        stackTrace,
        "Error on clicking in the button 'Batch Queries'",
      );
    }
  }

  Future<void> _button04onPressed() async {
    try {
      await _createDatabase(
        settings: TalkerSqfliteLoggerSettings(
          sqlEventFilter: (event) => event.sql.contains('UPDATE'),
        ),
      );

      await _db.execute(
        'CREATE TABLE Test '
        '(id INTEGER PRIMARY KEY, '
        'name TEXT, '
        'value INTEGER, '
        'num REAL)',
      );
      await _db.rawInsert(
        'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)',
      );
      await _db.query('Test');
      await _db.rawUpdate(
        'UPDATE Test SET name = ?, value = ? WHERE name = ?',
        ['updated name', '9876', 'some name'],
      );
      await _db.rawQuery('SELECT * FROM Test');

      await _closeDatabase();
      await _deleteDatabase();
    } catch (error, stackTrace) {
      widget._talker.handle(
        error,
        stackTrace,
        "Error on clicking in the button 'Filter SQL Queries'",
      );
    }
  }

  Future<void> _button05onPressed() async {
    try {
      await _createDatabase(
        settings: TalkerSqfliteLoggerSettings(
          printSqlEvents: false,
          sqlBatchEventFilter: (operations) => operations
              .map(
                (operation) => operation.sql.contains('INSERT INTO'),
              )
              .toList(),
        ),
      );

      final batch = _db.batch()
        ..execute(
          'CREATE TABLE Test '
          '(id INTEGER PRIMARY KEY, '
          'name TEXT, '
          'value INTEGER, '
          'num REAL)',
        )
        ..rawInsert(
          'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)',
        )
        ..rawUpdate(
          'UPDATE Test SET name = ?, value = ? WHERE name = ?',
          ['updated name', '9876', 'some name'],
        );

      await batch.commit();

      await _closeDatabase();
      await _deleteDatabase();
    } catch (error, stackTrace) {
      widget._talker.handle(
        error,
        stackTrace,
        "Error on clicking in the button 'Filter Batch Queries'",
      );
    }
  }

  Future<void> _button06onPressed() async {
    try {
      await _createDatabase(
        settings: const TalkerSqfliteLoggerSettings(
          printSqlResults: true,
        ),
        type: SqfliteDatabaseFactoryLoggerType.invoke,
      );

      await _db.transaction((txn) async {
        await txn.execute(
          'CREATE TABLE Test '
          '(id INTEGER PRIMARY KEY, '
          'name TEXT, '
          'value INTEGER, '
          'num REAL)',
        );
        await txn.rawInsert(
          'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)',
        );
        await txn.rawUpdate(
          'UPDATE Test SET name = ?, value = ? WHERE name = ?',
          ['updated name', '9876', 'some name'],
        );
      });

      await _db.query('Test');

      await _closeDatabase();
      await _deleteDatabase();
    } catch (error, stackTrace) {
      widget._talker.handle(
        error,
        stackTrace,
        "Error on clicking in the button 'Invokes'",
      );
    }
  }
}
