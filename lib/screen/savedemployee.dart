
import 'package:flutter/material.dart';

import '../service/employeestorage.dart';


class SavedEmployeesScreen extends StatefulWidget {
  const SavedEmployeesScreen({super.key});

  @override
  State<SavedEmployeesScreen> createState() =>
      _SavedEmployeesScreenState();
}

class _SavedEmployeesScreenState
    extends State<SavedEmployeesScreen> {
  late Future<List<Map<String, dynamic>>> employees;

  @override
  void initState() {
    super.initState();
    loadEmployees();
  }

  void loadEmployees() {
    employees = EmployeeStorageService.getEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(loadEmployees);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: employees,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load saved records'),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return const Center(
              child: Text(
                'No employees saved yet.\nSubmit the form first.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final employee = records[index];

              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    employee['full_name']?.toString().isNotEmpty ==
                        true
                        ? employee['full_name'].toString()
                        : 'Employee ${index + 1}',
                  ),
                  subtitle: Text(
                    employee['email']?.toString() ?? '',
                  ),
                  children: employee.entries.map((entry) {
                    return ListTile(
                      title: Text(
                        entry.key.replaceAll('_', ' '),
                      ),
                      subtitle: Text(
                        entry.value?.toString() ?? 'Not provided',
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
