import 'package:flutter/material.dart';

class Items extends StatelessWidget {
  const Items(
    this.text,
    {super.key});

    final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text, style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.normal
      ),
    );
  }
}