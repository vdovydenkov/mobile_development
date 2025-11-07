import 'package:flutter/material.dart';

void main() {
  runApp(const Incrementator());
}

class Incrementator extends StatelessWidget {
  const Incrementator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Incrementator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainScreen(title: 'Incrementator'),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});
  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _limit = 7;
  int _counter = 0;

  void _incrementCounter() {
    if (_counter < _limit) {
      setState(() {
        _counter++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Лимит достигнут')),
      );
    }
  }

  void _reset() {
    setState(() {
      _counter = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Счетчик сброшен')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Нажато:'),
            Text(
              '$_counter / $_limit',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Добавить',
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _reset,
            tooltip: 'Сбросить',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
