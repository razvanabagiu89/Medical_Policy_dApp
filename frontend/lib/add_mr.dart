import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'utils.dart';
import 'package:flutter_web3/flutter_web3.dart';

class AddMedicalRecord extends StatelessWidget {
  const AddMedicalRecord({Key? key}) : super(key: key);

  Future<void> _sendDataToBackend(BuildContext context) async {
    final userModel = context.read<UserProvider>();
    final patientId = userModel.getUserID();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final fileName = result.files.single.name;
      final fileBytes = result.files.single.bytes!;

      ////////////////////////// blockchain //////////////////////////
      final signer = provider!.getSigner();
      final contract = await getPatientRegistryContract(signer);
      String medicalRecordHash = computeHash(fileName);
      List<int> medicalRecordBytes32 = convertStringToBytes(medicalRecordHash);
      final tx = await contract.send(
          'addMedicalRecord', [int.parse(patientId), medicalRecordBytes32]);
      await tx.wait();
      ////////////////////////// backend //////////////////////////
      final fileData = base64Encode(fileBytes);
      final requestBody = jsonEncode({
        'patient_id': patientId,
        'filename': fileName,
        'filedata': fileData,
        'medical_record_hash':
            utf8.decode(medicalRecordBytes32), // send as string
      });

      final response = await http.post(
        Uri.parse(
            'http://localhost:5000/api/patient/$patientId/medical_record'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        print('Medical record added successfully');
      } else {
        print("Error: ${response.body}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _sendDataToBackend(context),
      child: Text('Add Medical Record'),
    );
  }
}
