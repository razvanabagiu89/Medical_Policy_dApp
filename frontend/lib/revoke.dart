import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_provider.dart';
import 'metamask_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'utils.dart';

class RevokeAccess extends StatefulWidget {
  @override
  _RevokeAccessState createState() => _RevokeAccessState();
}

class _RevokeAccessState extends State<RevokeAccess> {
  final _formKey = GlobalKey<FormState>();
  String _doctorId = '';
  String _fileHash = '';

  Future<void> revokeAccess(BuildContext context) async {
    final patientAddress = context.read<MetaMaskProvider>().currentAddress;
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    ////////////////////////// blockchain //////////////////////////
    final signer = provider!.getSigner();
    final contract = await getAccessPolicyContract(signer);
    final tx = await contract.send('revokeAccess', [
      patientAddress,
      hexStringToUint8List(_fileHash),
      stringToBytes32(_doctorId)
    ]);
    await tx.wait();
    List<dynamic> ids = await contract.call(
        'getPatientPolicyAllowedByMedicalRecordHash',
        [patientAddress, hexStringToUint8List(_fileHash)]);
    ////////////////////////// backend //////////////////////////
    final url = 'http://localhost:5000/api/patient/$patientId/revoke';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'doctor_id': _doctorId,
        'file_hash': _fileHash,
        'patient_address': patientAddress,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      print("Access revoked successfully");
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revoke Access'),
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
                  hintText: 'Enter doctor ID',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid doctor ID';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _doctorId = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter file hash',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid file hash';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _fileHash = value;
                  });
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await revokeAccess(context);
                    }
                  },
                  child: Text('Revoke Access'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
