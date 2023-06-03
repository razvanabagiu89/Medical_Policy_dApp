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

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedUserType = 'patient';

  Future<void> _sendDataToBackend(BuildContext context) async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    var passwordHash = sha256.convert(utf8.encode(password)).toString();

    var response;
    if (username == 'admin') {
      response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': passwordHash,
        }),
      );
    } else {
      response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/login'),
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
          print("Patient login successful");
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => Dashboard()));
        } else if (_selectedUserType == 'institution') {
          print("Institution login successful");
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => InstitutionDashboard()));
        } else if (_selectedUserType == 'employee') {
          print("Employee login successful");
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const EmployeeDashboard()));
        }
      }
    } else {
      print("Login failed");
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
                      color: Colors.green,
                    ),
                  ),
                  GradientButton(
                    onPressed: () =>
                        context.read<MetaMaskProvider>().disconnect(),
                    buttonText: "Disconnect",
                  ),
                ],
              );
            } else if (provider.isConnected && !provider.isInOperatingChain) {
              connectButton = GradientButton(
                onPressed: () {}, // no action needed if wrong chain
                buttonText:
                    'Wrong chain. Please connect to ${MetaMaskProvider.operatingChain}',
              );
            } else if (provider.isEnabled) {
              connectButton = GradientButton(
                onPressed: () => context.read<MetaMaskProvider>().connect(),
                buttonText: "Connect",
              );
            } else {
              connectButton = GradientButton(
                onPressed: () {}, // no action needed if not supported browser
                buttonText: 'Please use a Web3 supported browser.',
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
                      controller: _usernameController,
                      labelText: 'Username',
                    ),
                    const SizedBox(height: 15),
                    PasswordField(
                      controller: _passwordController,
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
