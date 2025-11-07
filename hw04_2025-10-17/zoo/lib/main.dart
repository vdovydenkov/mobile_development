import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const ZooApp());
}

// Основное приложение
class ZooApp extends StatelessWidget {
  const ZooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ZooSimulation(),
    );
  }
}

// Виджет, где идёт симуляция
class ZooSimulation extends StatefulWidget {
  const ZooSimulation({super.key});

  @override
  State<ZooSimulation> createState() => _ZooSimulationState();
}

class _ZooSimulationState extends State<ZooSimulation> {
  final Zoo _zoo = Zoo();
  Timer? _timer;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _zoo.populate(); // Заселить животных
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _log += '\n${_zoo.simulateStep()}';
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Симуляция зоопарка')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Text(_log.isEmpty ? 'Инициализация...' : _log),
      ),
    );
  }
}

// ЛОГИКА ЗООПАРКА
abstract class Animal {
  String name;
  int age = 0;
  bool alive = true;
  bool sick = false;
  final Random _rnd = Random();

  Animal(this.name);

  // Базовые действия
  void eat() => _log('$name ест');
  void drink() => _log('$name пьёт');
  void walk() => _log('$name гуляет');
  void play() => _log('$name играет');

  void getSick() {
    if (!sick && _rnd.nextBool()) {
      sick = true;
      _log('$name заболел');
    }
  }

  void recover() {
    if (sick && _rnd.nextInt(3) == 0) {
      sick = false;
      _log('$name выздоровел');
    }
  }

  void die() {
    alive = false;
    _log('$name умер');
  }

  Animal reproduce(); // потомство

  String simulate() {
    if (!alive) return '$name уже мёртв';

    age++;

    // Возможность умереть от старости
    if (age > 10 && _rnd.nextInt(10) < 2) {
      die();
      return '$name умер от старости';
    }

    // Если животное больно — шанс выздороветь или умереть
    if (sick) {
      if (_rnd.nextInt(10) < 2) {
        die();
        return '$name умер от болезни';
      } else if (_rnd.nextInt(10) < 4) {
        recover();
        return '$name выздоровел';
      } else {
        return '$name болеет';
      }
    }

    // Случайное действие
    final actionIndex = _rnd.nextInt(6);
    switch (actionIndex) {
      case 0:
        eat();
        break;
      case 1:
        drink();
        break;
      case 2:
        walk();
        break;
      case 3:
        play();
        break;
      case 4:
        getSick();
        if (sick) return '$name заболел';
        break;
      case 5:
        // шанс размножения
        if (_rnd.nextInt(8) == 0) {
          final baby = reproduce();
          return '${baby.name} родился от $name';
        }
        break;
    }

    return '$name жив и бодр (возраст $age)';
  }

  void _log(String text) {
    debugPrint(text);
  }
}

// Конкретные классы животных
class Lion extends Animal {
  Lion(String name) : super(name);
  @override
  Lion reproduce() => Lion('Львёнок_${Random().nextInt(1000)}');
}

class Elephant extends Animal {
  Elephant(String name) : super(name);
  @override
  Elephant reproduce() => Elephant('Слонёнок_${Random().nextInt(1000)}');
}

class Monkey extends Animal {
  Monkey(String name) : super(name);
  @override
  Monkey reproduce() => Monkey('Обезьянка_${Random().nextInt(1000)}');
}

class Zebra extends Animal {
  Zebra(String name) : super(name);
  @override
  Zebra reproduce() => Zebra('Зебрёнок_${Random().nextInt(1000)}');
}

class Giraffe extends Animal {
  Giraffe(String name) : super(name);
  @override
  Giraffe reproduce() => Giraffe('Жирафёнок_${Random().nextInt(1000)}');
}

// Зоопарк
class Zoo {
  final List<Animal> animals = [];
  final Random _rnd = Random();

  void populate() {
    // Случайное количество животных каждого вида
    final types = [Lion, Elephant, Monkey, Zebra, Giraffe];

    for (var type in types) {
      final count = 2 + _rnd.nextInt(3);
      for (int i = 0; i < count; i++) {
        animals.add(_createAnimal(type));
      }
    }
  }

  Animal _createAnimal(Type type) {
    switch (type) {
      case Lion:
        return Lion('Лев_${_rnd.nextInt(1000)}');
      case Elephant:
        return Elephant('Слон_${_rnd.nextInt(1000)}');
      case Monkey:
        return Monkey('Обезьяна_${_rnd.nextInt(1000)}');
      case Zebra:
        return Zebra('Зебра_${_rnd.nextInt(1000)}');
      case Giraffe:
        return Giraffe('Жираф_${_rnd.nextInt(1000)}');
      default:
        throw Exception('Неизвестный тип животного');
    }
  }

  String simulateStep() {
    if (animals.isEmpty) return 'В зоопарке никого не осталось.';

    final aliveAnimals = animals.where((a) => a.alive).toList();
    if (aliveAnimals.isEmpty) return 'Все животные умерли.';

    final animal = aliveAnimals[_rnd.nextInt(aliveAnimals.length)];
    final result = animal.simulate();

    // Добавляем потомство
    if (result.contains('родился')) {
      final newAnimal = animal.reproduce();
      animals.add(newAnimal);
    }

    // Убираем мёртвых
    animals.removeWhere((a) => !a.alive);

    return result;
  }
}
