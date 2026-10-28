
import 'package:flutter/material.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> employeeData;

  const EmployeeDetailsScreen({
    super.key,
    required this.employeeData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 60,
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Registration Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...employeeData.entries.map(
                (entry) => Card(
              child: ListTile(
                title: Text(
                  entry.key
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                ),
                subtitle: Text(
                  entry.value == null ||
                      entry.value.toString().isEmpty
                      ? 'Not provided'
                      : entry.value.toString(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Form'),
          ),
        ],
      ),
    );
  }
}
