import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_provider.dart';
import 'package:provider/provider.dart';

class InstitutionDashboard extends StatefulWidget {
  @override
  _InstitutionDashboardState createState() => _InstitutionDashboardState();
}

class _InstitutionDashboardState extends State<InstitutionDashboard> {
  final GlobalKey<FormState> _addEmployeeFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _removeEmployeeFormKey = GlobalKey<FormState>();
  String addEmployeeUsername = '';
  String removeEmployeeUsername = '';
  String employeeFullName = '';

  Future<void> addEmployee(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:5000/api/$id/employee/add';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'username': addEmployeeUsername,
        'full_name': employeeFullName,
      }),
    );

    if (response.statusCode == 201) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String employeePassword = jsonResponse['password'].toString();
      print(employeePassword);
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> removeEmployee(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:5000/api/$id/employee/remove';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'username': removeEmployeeUsername,
      }),
    );

    if (response.statusCode == 200) {
      print('Employee removed successfully');
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Institution Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Add Employee', style: TextStyle(fontSize: 18)),
            Form(
              key: _addEmployeeFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter employee username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid username';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        addEmployeeUsername = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter employee full name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid full name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        employeeFullName = value;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_addEmployeeFormKey.currentState!.validate()) {
                          await addEmployee(context);
                          print(
                              'Adding employee: $addEmployeeUsername, $employeeFullName');
                        }
                      },
                      child: Text('Add Employee'),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            Text('Remove Employee', style: TextStyle(fontSize: 18)),
            Form(
              key: _removeEmployeeFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter employee username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid username';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        removeEmployeeUsername = value;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_removeEmployeeFormKey.currentState!.validate()) {
                          await removeEmployee(context);
                          print('Removing employee: $removeEmployeeUsername');
                        }
                      },
                      child: Text('Remove Employee'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
