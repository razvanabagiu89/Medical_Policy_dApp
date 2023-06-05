import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../common/pallete.dart';
import '../user_provider.dart';
import 'package:provider/provider.dart';

class DisplayDocument extends StatefulWidget {
  final String medicalHash;

  DisplayDocument({required this.medicalHash});

  @override
  _DisplayDocumentState createState() => _DisplayDocumentState();
}

class _DisplayDocumentState extends State<DisplayDocument> {
  String? _htmlContent;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFile();
  }

  Future<void> _fetchFile() async {
    final userModel = context.read<UserProvider>();
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/get_file/${widget.medicalHash}'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${userModel.getToken()}',
      },
    );

    if (response.statusCode == 200) {
      String fileBase64 = jsonDecode(response.body)['filedata'];
      setState(() {
        _htmlContent =
            '<iframe src="data:application/pdf;base64,$fileBase64" width="100%" height="100%" frameborder="0" allowfullscreen></iframe>';
        _loading = false;
      });
    } else {
      throw Exception('Failed to load file');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Pallete.gradient1,
                Pallete.gradient2,
                Pallete.gradient3,
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
        ),
        title: Text('${widget.medicalHash}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Pallete.gradient3,
        titleTextStyle: TextStyle(color: Pallete.whiteColor),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: HtmlWidget(_htmlContent!),
              ),
            ),
    );
  }
}
