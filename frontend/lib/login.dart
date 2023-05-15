import 'metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard.dart';
import 'user_model.dart';
import 'user_provider.dart';
import 'admin_dashboard.dart';
import 'institution_dashboard.dart';
import 'doctor_dashboard.dart';
import 'package:crypto/crypto.dart';

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
        userProvider.setUser(UserModel(id: id));

        if (_selectedUserType == 'patient') {
          print("Patient login successful");
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => Dashboard()));
        } else if (_selectedUserType == 'institution') {
          print("Institution login successful");
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => InstitutionDashboard()));
        } else if (_selectedUserType == 'doctor') {
          print("Doctor login successful");
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => DoctorDashboard()));
        }
      }
    } else {
      print("Login failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Consumer<MetaMaskProvider>(
        builder: (context, provider, child) {
          late final Widget connectText;
          if (provider.isConnected && provider.isInOperatingChain) {
            connectText = Text(
              'Connected to ${provider.currentAddress}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            );
          } else if (provider.isConnected && !provider.isInOperatingChain) {
            connectText = const Text(
              'Wrong chain. Please connect to ${MetaMaskProvider.operatingChain}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color.fromARGB(255, 15, 15, 15)),
            );
          } else {
            connectText = const Text(
              'Please connect to MetaMask',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            );
          }
          late final Widget connectButton;
          bool isPatient = _selectedUserType == 'patient';
          bool showConnectButton =
              !provider.isConnected || !provider.isInOperatingChain;

          if (provider.isConnected && provider.isInOperatingChain) {
            connectButton = Text(
              'Connected to ${provider.currentAddress}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            );
          } else if (provider.isConnected && !provider.isInOperatingChain) {
            connectButton = const Text(
              'Wrong chain. Please connect to ${MetaMaskProvider.operatingChain}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color.fromARGB(255, 15, 15, 15)),
            );
          } else if (provider.isEnabled) {
            connectButton = ElevatedButton(
              onPressed: () => context.read<MetaMaskProvider>().connect(),
              child: const Text(
                "Connect",
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            );
          } else {
            connectButton = const Text(
              'Please use a Web3 supported browser.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              DropdownButton<String>(
                value: _selectedUserType,
                items: <String>['institution', 'doctor', 'patient']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUserType = newValue!;
                  });
                },
              ),
              connectText,
              if (isPatient && showConnectButton) connectButton,
              ElevatedButton(
                onPressed: () => _sendDataToBackend(context),
                child: Text('Login'),
              ),
            ],
          );
        },
      ),
    );
  }
}
