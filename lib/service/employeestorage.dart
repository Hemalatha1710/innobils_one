
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeStorageService {
  static const String _storageKey = 'employee_records';

  static Future<void> saveEmployee(
      Map<String, dynamic> employee,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final existingRecords =
        prefs.getStringList(_storageKey) ?? [];

    existingRecords.add(jsonEncode(employee));

    await prefs.setStringList(
      _storageKey,
      existingRecords,
    );
  }

  static Future<List<Map<String, dynamic>>>
  getEmployees() async {
    final prefs = await SharedPreferences.getInstance();

    final records = prefs.getStringList(_storageKey) ?? [];

    return records.map((record) {
      return Map<String, dynamic>.from(
        jsonDecode(record) as Map,
      );
    }).toList();
  }
}
