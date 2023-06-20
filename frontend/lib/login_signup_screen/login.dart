import 'package:frontend/common/pallete.dart';
import '../metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../patient/patient_dashboard.dart';
import '../user_model.dart';
import '../user_provider.dart';
import '../admin/admin_dashboard.dart';
import '../institution/institution_dashboard.dart';
import '../employee/employee_dashboard.dart';
import 'package:crypto/crypto.dart';
import '../common/input_field.dart';
import '../common/password_field.dart';
import '../common/dropdown.dart';
import '../common/gradient_button.dart';
import '../utils.dart';
import '../common/custom_icon_button.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String _selectedUserType = 'patient';

  Future<void> _sendDataToBackend(BuildContext context) async {
    final String username = usernameController.text;
    final String password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      showDialogCustom(context,
          "Username or password can't be empty. Please enter valid credentials.");
      return;
    }
    var passwordHash = sha256.convert(utf8.encode(password)).toString();
    http.Response response;
    if (username == 'admin') {
      response = await http.post(
        Uri.parse('https://localhost:8000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': passwordHash,
        }),
      );
    } else {
      response = await http.post(
        Uri.parse('https://localhost:8000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': passwordHash,
          'type': _selectedUserType,
        }),
      );
    }

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String id = jsonResponse['id'].toString();
      final String token = jsonResponse['access_token'];
      if (username == 'admin') {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(UserModel(
            id: id, username: username, userType: 'admin', token: token));
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => AdminDashboard()));
      } else {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        String id = jsonResponse['id'].toString();

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(UserModel(
            id: id,
            username: username,
            userType: _selectedUserType,
            token: token));

        if (_selectedUserType == 'patient') {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => PatientDashboard()));
        } else if (_selectedUserType == 'institution') {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => InstitutionDashboard()));
        } else if (_selectedUserType == 'employee') {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => EmployeeDashboard()));
        }
      }
    } else {
      showDialogCustom(
          context, "Login failed. Please check your username or password.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Consumer<MetaMaskProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 800,
                        height: 120,
                      ),
                    ),
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 35,
                      ),
                    ),
                    const SizedBox(height: 15),
                    InputField(
                      controller: usernameController,
                      labelText: 'Username',
                    ),
                    const SizedBox(height: 15),
                    PasswordField(
                      controller: passwordController,
                      labelText: 'Password',
                    ),
                    const SizedBox(height: 15),
                    InputDropdown(
                      value: _selectedUserType,
                      items: <String>['institution', 'employee', 'patient'],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedUserType = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    provider.isConnected
                        ? Column(
                            children: [
                              Text(
                                'Connected to ${provider.currentAddress}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Pallete.gradient3,
                                ),
                              ),
                              const SizedBox(height: 15),
                              GradientButton(
                                onPressed: () => context
                                    .read<MetaMaskProvider>()
                                    .disconnect(),
                                buttonText: "Disconnect",
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconButton(
                                imagePath: 'assets/images/metamask.png',
                                onPressed: () =>
                                    context.read<MetaMaskProvider>().connect(),
                              ),
                              const SizedBox(width: 20),
                              CustomIconButton(
                                imagePath: 'assets/images/walletconnect.png',
                                onPressed: () => connectWalletConnect(),
                              ),
                            ],
                          ),
                    const SizedBox(height: 15),
                    GradientButton(
                      onPressed: () => _sendDataToBackend(context),
                      buttonText: 'Login',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
