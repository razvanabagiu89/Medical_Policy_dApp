import 'metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_and_registration.dart';
import 'user_model.dart';
import 'user_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // starting point of MetaMaskProvider and UserProvider that will be further passed to all the widgets
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(
            create: (context) => MetaMaskProvider()..start()),
      ],
      child: MaterialApp(
        title: 'My App',
        home: LoginAndRegistration(),
      ),
    );
  }
}