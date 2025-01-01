import 'package:uuid/uuid.dart';

class Meal {
  final String id;
  final String name;
  final int calories;
  final DateTime consumptionDateTime;
  final String userEmail;

  Meal({
    String? id,
    required this.name,
    required this.calories,
    required this.consumptionDateTime,
    required this.userEmail,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'consumptionDateTime': consumptionDateTime.toIso8601String(),
      'userEmail': userEmail,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      consumptionDateTime: DateTime.parse(map['consumptionDateTime']),
      userEmail: map['userEmail'],
    );
  }
}
