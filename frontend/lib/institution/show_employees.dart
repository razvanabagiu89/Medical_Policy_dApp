import 'package:flutter/material.dart';
import 'package:frontend/common/pallete.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShowEmployees extends StatefulWidget {
  @override
  _ShowEmployeesState createState() => _ShowEmployeesState();
}

class _ShowEmployeesState extends State<ShowEmployees> {
  List<dynamic>? employees;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    var response =
        await http.get(Uri.parse('http://localhost:8000/get_employees'));

    if (response.statusCode == 200) {
      employees = jsonDecode(response.body);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      body: (employees == null)
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(15.0),
              itemCount: employees!.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
              itemBuilder: (context, index) {
                var employee = employees![index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 10.0),
                  leading: Text(
                    '[USERNAME]: ${employee['username']}\n[FULL NAME]: ${employee['full_name']}\nID: ${employee['ID']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Pallete.whiteColor,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
