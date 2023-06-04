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
import '../institution/employee_dashboard.dart';
import 'package:crypto/crypto.dart';
import '../common/input_field.dart';
import '../common/password_field.dart';
import '../common/dropdown.dart';
import '../common/gradient_button.dart';
import '../utils.dart';

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

    var response;
    if (username == 'admin') {
      response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': passwordHash,
        }),
      );
    } else {
      response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': passwordHash,
          'type': _selectedUserType,
        }),
      );
    }

    if (response.statusCode == 200) {
      if (username == 'admin') {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => AdminDashboard()));
      } else {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        String id = jsonResponse['id'].toString();

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(
            UserModel(id: id, username: username, userType: _selectedUserType));

        if (_selectedUserType == 'patient') {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => Dashboard()));
        } else if (_selectedUserType == 'institution') {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => InstitutionDashboard()));
        } else if (_selectedUserType == 'employee') {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const EmployeeDashboard()));
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
            late final Widget connectButton;
            bool isPatient = _selectedUserType == 'patient';
            bool showConnectButton =
                !provider.isConnected || !provider.isInOperatingChain;

            if (provider.isConnected && provider.isInOperatingChain) {
              connectButton = Column(
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
                    onPressed: () =>
                        context.read<MetaMaskProvider>().disconnect(),
                    buttonText: "Disconnect",
                  ),
                ],
              );
            } else if (provider.isConnected && !provider.isInOperatingChain) {
              connectButton = Column(
                children: [
                  const Text(
                    'Wrong chain. Please connect to ${MetaMaskProvider.operatingChain}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color.fromARGB(255, 255, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GradientButton(
                    onPressed: () => context.read<MetaMaskProvider>().connect(),
                    buttonText: "Connect",
                  ),
                ],
              );
            } else if (provider.isEnabled) {
              connectButton = GradientButton(
                onPressed: () => context.read<MetaMaskProvider>().connect(),
                buttonText: "Connect",
              );
            } else {
              connectButton = Column(
                children: [
                  const Text(
                    'Please use a Web3 supported browser.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color.fromARGB(255, 255, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GradientButton(
                    onPressed: () => context.read<MetaMaskProvider>().connect(),
                    buttonText: "Connect",
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    const SizedBox(height: 20),
                    const SizedBox(height: 15),
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 50,
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
                    const SizedBox(height: 20),
                    if (isPatient && showConnectButton) connectButton,
                    if (!showConnectButton) connectButton,
                    const SizedBox(height: 20),
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
