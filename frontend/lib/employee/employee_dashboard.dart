import 'package:flutter/material.dart';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import 'show_documents.dart';
import '../common/gradient_button.dart';
import '../common/pallete.dart';
import '../common/change_password.dart';
import 'request_access.dart';

class EmployeeDashboard extends StatelessWidget {
  late Future<List<String>> futureMedicalHashes;

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
                'Employee Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return RequestAccess();
                    },
                  );
                },
                buttonText: 'Request Access',
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () async {
                  final userModel = context.read<UserProvider>();
                  String employeeId = userModel.getUserID();
                  futureMedicalHashes =
                      fetchMedicalHashes(userModel, employeeId);
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return ShowDocuments(
                          futureMedicalHashes: futureMedicalHashes);
                    },
                  );
                },
                buttonText: 'Show Documents',
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
