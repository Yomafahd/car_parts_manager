import 'package:flutter/material.dart';
import 'competitors_tab.dart';

class CompetitorsScreen extends StatelessWidget {
  const CompetitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنافسون في مصر'),
      ),
      body: const CompetitorsTab(),
    );
  }
}
