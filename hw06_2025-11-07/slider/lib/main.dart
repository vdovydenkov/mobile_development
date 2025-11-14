import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const NumberGameApp());
}

class NumberGameApp extends StatelessWidget {
  const NumberGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const NumberGameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NumberGameScreen extends StatefulWidget {
  const NumberGameScreen({super.key});

  @override
  State<NumberGameScreen> createState() => _NumberGameScreenState();
}

class _NumberGameScreenState extends State<NumberGameScreen> {
  bool gameStarted = false;
  int targetNumber = 0;          // X
  double sliderValue = 50;       // Y
  int attempts = 0;
  int totalScore = 0;

  final Random rnd = Random();

  void startGame() {
    setState(() {
      gameStarted = true;
      attempts = 0;
      totalScore = 0;
      newRound();
    });
  }

  void endGame() {
    setState(() {
      gameStarted = false;
    });
  }

  void newRound() {
    targetNumber = rnd.nextInt(100) + 1;
    sliderValue = targetNumber.toDouble();
  }

  void handleTouch(double newValue) {
    if (!gameStarted) return;

    sliderValue = newValue;

    // Фиксируем попытку
    attempts++;

    // Расчёт очков: максимум 100, чем меньше разница — тем больше
    int diff = (targetNumber - sliderValue.round()).abs();
    int score = max(0, 100 - diff);
    totalScore += score;

    if (attempts >= 3) {
      showResult();
    } else {
      newRound();
    }

    setState(() {});
  }

  void showResult() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Результат"),
        content: Text("Ваши очки: $totalScore"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              endGame();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Игра: угадай число"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                gameStarted
                    ? "Число: $targetNumber"
                    : "Нажмите 'Начать игру'",
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 40),

              // Слайдер (виден только во время игры)
              if (gameStarted)
                Slider(
                  value: sliderValue,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: sliderValue.round().toString(),
                  onChanged: (v) {
                    handleTouch(v);
                  },
                ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {
                  if (gameStarted) {
                    endGame();
                  } else {
                    startGame();
                  }
                },
                child: Text(gameStarted ? "Закончить игру" : "Начать игру"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
