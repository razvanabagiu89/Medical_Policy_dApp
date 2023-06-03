import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web3/flutter_web3.dart';
import '../utils.dart';

class AddWallet extends StatefulWidget {
  @override
  AddWalletState createState() => AddWalletState();
}

class AddWalletState extends State<AddWallet> {
  final _formKey = GlobalKey<FormState>();
  String newPatientAddress = '';

  Future<void> addWallet(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    ////////////////////////// backend //////////////////////////
    // check if this wallet is already authorized
    final url = 'http://localhost:5000/api/patient/$patientId/wallet';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'new_patient_address': newPatientAddress,
      }),
    );

    if (response.statusCode == 201) {
      print("Wallet can be added");
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String patientAddressConverted =
          jsonResponse['new_patient_address'].toString();
      ////////////////////////// blockchain //////////////////////////
      final signer = provider!.getSigner();
      final contract = await getPatientRegistryContract(signer);
      final tx = await contract
          .send('addWallet', [patientId, patientAddressConverted]);
      await tx.wait();
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grant Access'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter new wallet',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid wallet';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    newPatientAddress = value;
                  });
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await addWallet(context);
                    }
                  },
                  child: Text('Add Wallet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
