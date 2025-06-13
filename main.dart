import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(MyApp());
}

class Task {
  final int? id;
  final String title;
  final bool isDone;
  final String date;

  Task({this.id, required this.title, required this.isDone, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone ? 1 : 0,
      'date': date,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'] == 1,
      date: map['date'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        isDone INTEGER,
        date TEXT
      )
    ''');
  }

  Future<void> insertTask(Task task) async {
    final db = await instance.database;
    await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasksByDate(String date) async {
    final db = await instance.database;
    final result = await db.query('tasks', where: 'date = ?', whereArgs: [date]);
    return result.map((e) => Task.fromMap(e)).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await instance.database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<Map<String, List<Task>>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    Map<String, List<Task>> data = {};
    for (var row in result) {
      final task = Task.fromMap(row);
      data.putIfAbsent(task.date, () => []).add(task);
    }
    return data;
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Map<DateTime, List<Task>> _tasks;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Task> _selectedTasks = [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final allTasks = await DatabaseHelper.instance.getAllTasks();
    setState(() {
      _tasks = {};
      allTasks.forEach((dateStr, tasks) {
        final date = DateTime.parse(dateStr);
        _tasks[date] = tasks;
      });
      _selectedTasks = _tasks[_selectedDay] ?? [];
    });
  }

  Future<void> _addTask(String title) async {
    final task = Task(title: title, isDone: false, date: _selectedDay.toIso8601String().split("T")[0]);
    await DatabaseHelper.instance.insertTask(task);
    _controller.clear();
    await _loadTasks();
  }

  Future<void> _toggleTask(Task task) async {
    final updated = Task(id: task.id, title: task.title, isDone: !task.isDone, date: task.date);
    await DatabaseHelper.instance.updateTask(updated);
    await _loadTasks();
  }

  Color _getDayColor(DateTime day) {
    final tasks = _tasks[day] ?? [];
    if (tasks.isEmpty) return Colors.transparent;
    final completed = tasks.where((t) => t.isDone).length;
    final ratio = completed / tasks.length;
    return Color.lerp(Colors.green[100], Colors.green[900], ratio)!;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Todo Calendar')),
        body: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final color = _getDayColor(day);
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text('${day.day}'),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedTasks = _tasks[_selectedDay] ?? [];
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'New task')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTask(_controller.text),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedTasks.length,
                itemBuilder: (context, index) {
                  final task = _selectedTasks[index];
                  return ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                        color: task.isDone ? Colors.grey : Colors.black,
                      ),
                    ),
                    trailing: Checkbox(
                      value: task.isDone,
                      onChanged: (_) => _toggleTask(task),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
