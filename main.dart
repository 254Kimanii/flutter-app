import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo_app/home.dart';

void main() async {
  await Hive.initFlutter();
  var box = await Hive.openBox('mytasks');
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}