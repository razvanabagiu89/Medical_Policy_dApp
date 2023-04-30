// login_and_registration.dart

import 'package:flutter/material.dart';
import 'login.dart';
import 'registration.dart';

class LoginAndRegistration extends StatelessWidget {
  const LoginAndRegistration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login and Registration'),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Login(),
                SizedBox(height: 20),
                Registration(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
