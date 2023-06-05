import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_provider.dart';
import 'package:provider/provider.dart';
import '../utils.dart';
import 'package:flutter_web3/flutter_web3.dart';
import '../common/input_field.dart';
import '../common/gradient_button.dart';

class DeleteMedicalRecord extends StatefulWidget {
  @override
  DeleteMedicalRecordState createState() => DeleteMedicalRecordState();
}

class DeleteMedicalRecordState extends State<DeleteMedicalRecord> {
  final TextEditingController fileHashController = TextEditingController();

  Future<void> deleteMedicalRecord(BuildContext context) async {
    final String fileHash = fileHashController.text;
    if (fileHash.isEmpty) {
      showDialogCustom(
          context, "Filehash can't be empty. Please enter a valid value.");
      return;
    }
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();
    ////////////////////////// blockchain //////////////////////////
    final signer = provider!.getSigner();
    final contract = await getPatientRegistryContract(signer);
    List<int> medicalRecordBytes32 = hexStringToUint8List(fileHash);
    final tx = await contract.send(
        'deleteMedicalRecord', [int.parse(patientId), medicalRecordBytes32]);
    await tx.wait();
    ////////////////////////// backend //////////////////////////
    final url =
        'http://localhost:8000/api/patient/$patientId/delete_medical_record';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
      body: jsonEncode(<String, String>{
        'patient_id': patientId,
        'medical_record_hash': fileHash,
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context);
      showDialogCustom(context, 'Medical record deleted successfully');
    } else {
      showDialogCustom(
          context, 'Error deleting medical record\nPlease try again later');
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
                labelText: 'Enter filehash',
                controller: fileHashController,
              ),
              const SizedBox(height: 15),
              GradientButton(
                onPressed: () async {
                  await deleteMedicalRecord(context);
                },
                buttonText: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
