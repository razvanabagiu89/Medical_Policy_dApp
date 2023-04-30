import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'metamask_provider.dart';

class AddMedicalRecord extends StatelessWidget {
  const AddMedicalRecord({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final provider = context.read<MetaMaskProvider>();
        final userModel = context.read<UserProvider>();
        final patientId = userModel.getUserID();

        // Show file picker to select a PDF file
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null) {
          final fileBytes = result.files.single.bytes!;
          final fileName = result.files.single.name;

          // Convert file data to base64 string
          final fileData = base64Encode(fileBytes);

          // Prepare the request body
          final requestBody = jsonEncode({
            'patient_id': patientId,
            'patient_address': provider.currentAddress,
            'filename': fileName,
            'file_data': fileData,
          });

          // Send the HTTP POST request to the backend
          final response = await http.post(
            Uri.parse(
                'http://localhost:5000/api/patient/$patientId/medical_record'),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          );

          if (response.statusCode == 201) {
            Navigator.pop(context);
            final responseData = jsonDecode(response.body);
            final mrHash = responseData['medical_record_hash'];
            print("mrHash: $mrHash");
          } else {
            print("Error: ${response.body}");
          }
        }
      },
      child: const Text('Add Medical Record'),
    );
  }
}
