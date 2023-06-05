import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web3/flutter_web3.dart';
import '../utils.dart';
import '../common/gradient_button.dart';
import '../common/input_field.dart';

class AddWallet extends StatefulWidget {
  @override
  AddWalletState createState() => AddWalletState();
}

class AddWalletState extends State<AddWallet> {
  final TextEditingController newPatientAddressController =
      TextEditingController();

  Future<void> addWallet(BuildContext context) async {
    final String newPatientAddress = newPatientAddressController.text;
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    // check if this wallet is already authorized
    final url = 'https://localhost:8000/api/patient/$patientId/wallet';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'new_patient_address': newPatientAddress,
      }),
    );

    if (response.statusCode == 201) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String patientAddressConverted =
          jsonResponse['new_patient_address'].toString();
      ////////////////////////// blockchain //////////////////////////
      final signer = provider!.getSigner();
      final contract = await getPatientRegistryContract(signer);
      final tx = await contract
          .send('addWallet', [patientId, patientAddressConverted]);
      await tx.wait();
      showDialogCustom(context, 'Wallet added');
    } else {
      showDialogCustom(context, 'Error adding wallet\nPlease try again later');
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
                labelText: 'Enter new wallet address',
                controller: newPatientAddressController,
              ),
              const SizedBox(height: 15),
              GradientButton(
                onPressed: () async {
                  await addWallet(context);
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
