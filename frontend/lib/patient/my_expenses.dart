import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyExpenses extends StatefulWidget {
  @override
  _MyExpensesState createState() => _MyExpensesState();
}

class _MyExpensesState extends State<MyExpenses> {
  List<dynamic> expenses = [];
  double totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    // Replace with your Flask backend URL
    final response =
        await http.get(Uri.parse('http://localhost:8000/api/expenses'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        expenses = data['expenses'];
        totalExpenses = data['total'];
      });
    } else {
      print('Failed to fetch expenses');
    }
  }

  Future<void> addExpense(String type, String description, double cost) async {
    // Replace with your Flask backend URL
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/expenses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'description': description,
        'cost': cost,
      }),
    );

    if (response.statusCode == 201) {
      fetchExpenses();
    } else {
      print('Failed to add expense');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController costController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Expenses List
            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return ListTile(
                    title: Text(expense['description']),
                    subtitle: Text('Type: ${expense['type']}'),
                    trailing: Text('\$${expense['cost'].toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Total Expenses
            Text(
              'Total Expenses: \$${totalExpenses.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Add Expense Form
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Expense Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Expense Cost',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      addExpense(
                        'Request',
                        descriptionController.text,
                        double.tryParse(costController.text) ?? 0.0,
                      );
                      descriptionController.clear();
                      costController.clear();
                    },
                    child: const Text('Request Expense'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      addExpense(
                        'Import',
                        descriptionController.text,
                        double.tryParse(costController.text) ?? 0.0,
                      );
                      descriptionController.clear();
                      costController.clear();
                    },
                    child: const Text('Import Expense'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
