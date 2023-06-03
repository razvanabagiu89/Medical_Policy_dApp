import 'metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_signup_screen/auth_page.dart';
import 'user_provider.dart';
import 'utils.dart';
import 'common/pallete.dart';

void main() {
  runApp(MyApp());
  WidgetsBinding.instance?.addPostFrameCallback((_) {
    parseYamlFile();
  });
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
        title: 'Medd dApp',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Pallete.backgroundColor,
        ),
        home: AuthPage(),
      ),
    );
  }
}
