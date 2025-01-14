import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import '../common/gradient_button.dart';
import '../common/input_field.dart';

class AddInstitution extends StatefulWidget {
  @override
  AddInstitutionState createState() => AddInstitutionState();
}

class AddInstitutionState extends State<AddInstitution> {
  final TextEditingController addInstitutionUsernameController =
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
                labelText: 'Enter institution username',
                controller: addInstitutionUsernameController,
              ),
              const SizedBox(height: 15),
              InputField(
                labelText: 'Enter institution CIF',
                controller: institutionCIFController,
              ),
              const SizedBox(height: 15),
              GradientButton(
                onPressed: () async {
                  await addInstitution(context);
                },
                buttonText: 'Add',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
