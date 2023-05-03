import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_provider.dart';
import 'metamask_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'utils.dart';
import 'package:hex/hex.dart';
import 'dart:typed_data';

class ShowDocuments extends StatefulWidget {
  final Future<List<String>> futureMedicalHashes;

  ShowDocuments({required this.futureMedicalHashes});

  @override
  _ShowDocumentsState createState() => _ShowDocumentsState();
}

class _ShowDocumentsState extends State<ShowDocuments> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Show Documents')),
      body: Center(
        child: FutureBuilder<List<String>>(
          future: widget.futureMedicalHashes,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              // Render the list of documents with buttons
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  String medicalHash = snapshot.data![index];
                  return ListTile(
                    title: Text(medicalHash),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Add your logic here for handling the "See" button press
                      },
                      child: Text('See'),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }

            // Show a loading spinner while waiting for the data
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
