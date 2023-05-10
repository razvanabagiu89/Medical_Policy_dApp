import 'package:flutter/material.dart';
import 'display_document.dart';

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
              // render the list of documents with buttons
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  String medicalHash = snapshot.data![index];
                  return ListTile(
                    title: Text(medicalHash),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              DisplayDocument(medicalHash: medicalHash),
                        ));
                      },
                      child: Text('See'),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
