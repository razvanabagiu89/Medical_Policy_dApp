import '../metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_mr.dart';
import 'grant.dart';
import 'revoke.dart';
import 'show_access.dart';
import 'add_wallet.dart';
import 'requests_page.dart';
import 'delete_mr.dart';
import '../common/gradient_button.dart';
import '../common/custom_consumer_button.dart';
import '../user_provider.dart';
import '../common/pallete.dart';
import '../common/change_password.dart';

class PatientDashboard extends StatefulWidget {
  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
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
              Consumer<MetaMaskProvider>(
                builder: (context, provider, child) {
                  if (provider.isConnected) {
                    return Text(
                      'web3 address: ${provider.currentAddress}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  } else {
                    return const Text(
                      'Wallet not connected, limited access',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 15),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 15),
              const Text(
                'Patient Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
              const SizedBox(height: 15),
              CustomConsumerButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMedicalRecord(),
                    ),
                  );
                },
                buttonText: 'Add medical record',
              ),
              const SizedBox(height: 15),
              CustomConsumerButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return DeleteMedicalRecord();
                    },
                  );
                },
                buttonText: 'Delete medical record',
              ),
              const SizedBox(height: 15),
              CustomConsumerButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return GrantAccess();
                    },
                  );
                },
                buttonText: 'Grant access',
              ),
              const SizedBox(height: 15),
              CustomConsumerButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return RevokeAccess();
                    },
                  );
                },
                buttonText: 'Revoke access',
              ),
              const SizedBox(height: 15),
              GradientButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowAccessesScreen(),
                    ),
                  );
                },
                buttonText: 'Show accesses',
              ),
              const SizedBox(height: 15),
              CustomConsumerButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddWallet();
                    },
                  );
                },
                buttonText: 'Add wallet',
              ),
              const SizedBox(height: 15),
              GradientButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestsPage(),
                    ),
                  );
                },
                buttonText: 'Received requests',
              ),
              const SizedBox(height: 15),
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
