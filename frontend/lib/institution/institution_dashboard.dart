import 'package:flutter/material.dart';
import 'package:frontend/utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import '../common/input_field.dart';
import '../common/password_field.dart';
import '../common/gradient_button.dart';
import 'show_employees.dart';

class InstitutionDashboard extends StatefulWidget {
  @override
  _InstitutionDashboardState createState() => _InstitutionDashboardState();
}

class _InstitutionDashboardState extends State<InstitutionDashboard> {
  final TextEditingController addEmployeeUsernameController =
      TextEditingController();
  final TextEditingController removeEmployeeUsernameController =
      TextEditingController();
  final TextEditingController employeeFullNameController =
      TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

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

  Future<void> removeEmployee(BuildContext context) async {
    final String removeEmployeeUsername = removeEmployeeUsernameController.text;
    if (removeEmployeeUsername.isEmpty) {
      showDialogCustom(
          context, "Username can't be empty. Please enter valid values.");
      return;
    }
    final userModel = context.read<UserProvider>();
    final id = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/$id/employee/remove';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'username': removeEmployeeUsername,
      }),
    );

    if (response.statusCode == 200) {
      showDialogCustom(context, 'Employee removed successfully');
    } else {
      showDialogCustom(
          context, 'Error removing employee\nPlease try again later');
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
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 15),
              const Text(
                'Institution Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
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
                buttonText: 'Add employee',
              ),
              const SizedBox(height: 20),
              InputField(
                labelText: 'Enter employee username',
                controller: removeEmployeeUsernameController,
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await removeEmployee(context);
                },
                buttonText: 'Remove employee',
              ),
              const SizedBox(height: 20),
              PasswordField(
                labelText: 'Enter old password',
                controller: oldPasswordController,
              ),
              const SizedBox(height: 15),
              PasswordField(
                labelText: 'Enter new password',
                controller: newPasswordController,
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await changePassword(
                      context, oldPasswordController, newPasswordController);
                },
                buttonText: 'Change your password',
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return ShowEmployees();
                    },
                  );
                },
                buttonText: 'Show all employees',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
