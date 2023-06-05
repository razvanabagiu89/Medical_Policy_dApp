import 'package:flutter/material.dart';
import 'display_document.dart';
import '../common/gradient_button.dart';

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
      body: Center(
        child: FutureBuilder<List<String>>(
          future: widget.futureMedicalHashes,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return Center(
                  child: const Text(
                    'No documents approved',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 50,
                    ),
                  ),
                );
              } else {
                return ListView.separated(
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    String medicalHash = snapshot.data![index];
                    return ListTile(
                      title: Text(medicalHash),
                      trailing: GradientButton(
                        buttonText: 'See document',
                        onPressed: () async {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                DisplayDocument(medicalHash: medicalHash),
                          ));
                        },
                      ),
                    );
                  },
                );
              }
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
