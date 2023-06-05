import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import '../common/gradient_button.dart';
import '../common/input_field.dart';

class AddEmployee extends StatefulWidget {
  @override
  AddEmployeeState createState() => AddEmployeeState();
}

class AddEmployeeState extends State<AddEmployee> {
  final TextEditingController addEmployeeUsernameController =
      TextEditingController();
  final TextEditingController employeeFullNameController =
      TextEditingController();

  Future<void> addEmployee(BuildContext context) async {
    final String addEmployeeUsername = addEmployeeUsernameController.text;
    final String employeeFullName = employeeFullNameController.text;
    if (addEmployeeUsername.isEmpty || employeeFullName.isEmpty) {
      showDialogCustom(context,
          "Username or name can't be empty. Please enter valid values.");
      return;
    }
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/$id/employee/add';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'username': addEmployeeUsername,
        'full_name': employeeFullName,
        'institution_username': userModel.getUsername(),
      }),
    );

    if (response.statusCode == 201) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String employeePassword = jsonResponse['password'].toString();
      showDialogCustom(context,
          'Employee password: ${employeePassword}\nDo not share it with anyone!');
    } else {
      showDialogCustom(
          context, 'Error creating employee\nPlease try again later');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter employee username',
                controller: addEmployeeUsernameController,
              ),
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter employee name',
                controller: employeeFullNameController,
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await addEmployee(context);
                },
                buttonText: 'Remove',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
