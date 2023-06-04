import 'package:flutter/material.dart';
import 'package:frontend/utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../common/gradient_button.dart';
import '../common/input_field.dart';
import 'compare_institutions.dart';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../common/pallete.dart';
import '../common/change_password.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController addInstitutionUsernameController =
      TextEditingController();
  final TextEditingController removeInstitutionUsernameController =
      TextEditingController();
  final TextEditingController institutionCIFController =
      TextEditingController();

  Future<void> addInstitution(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final String addInstitutionUsername = addInstitutionUsernameController.text;
    final String institutionCIF = institutionCIFController.text;
    if (addInstitutionUsername.isEmpty || institutionCIF.isEmpty) {
      showDialogCustom(context,
          "Username or CIF can't be empty. Please enter valid credentials.");
      return;
    }
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/institution/add';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'username': addInstitutionUsername,
        'CIF': institutionCIF,
      }),
    );

    if (response.statusCode == 201) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String institutionPassword = jsonResponse['password'].toString();
      showDialogCustom(context,
          'Institution password ${institutionPassword}\nDo not share it with anyone!');
    } else {
      showDialogCustom(
          context, 'Error creating institution\nPlease try again later');
    }
  }

  Future<void> removeInstitution(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final String removeInstitutionUsername =
        removeInstitutionUsernameController.text;
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:8000/api/institution/remove';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'username': removeInstitutionUsername,
      }),
    );

    if (response.statusCode == 200) {
      showDialogCustom(context, 'Institution removed successfully');
    } else {
      showDialogCustom(context, "Error removing institution: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.read<UserProvider>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text(
                          'Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Pallete.whiteColor,
                          ),
                        ),
                        backgroundColor: Pallete.backgroundColor,
                        contentTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Pallete.whiteColor,
                        ),
                        content: SingleChildScrollView(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SelectableText(
                                    'User ID: ${userModel.getUserID()}'),
                                SelectableText(
                                    'Username: ${userModel.getUsername()}'),
                                SelectableText(
                                    'User Type: ${userModel.getUserType()}'),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 15),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 15),
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter institution username',
                controller: addInstitutionUsernameController,
              ),
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter institution CIF',
                controller: institutionCIFController,
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await addInstitution(context);
                },
                buttonText: 'Add Institution',
              ),
              const SizedBox(height: 20),
              InputField(
                labelText: 'Enter institution username',
                controller: removeInstitutionUsernameController,
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await removeInstitution(context);
                },
                buttonText: 'Remove Institution',
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return CompareInstitutions();
                    },
                  );
                },
                buttonText: 'Show all institutions',
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return ChangePassword();
                    },
                  );
                },
                buttonText: 'Change password',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
