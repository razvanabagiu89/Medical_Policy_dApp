import 'package:flutter/material.dart';

class ShowAccessesScreen extends StatefulWidget {
  @override
  _ShowAccessesScreenState createState() => _ShowAccessesScreenState();
}

class _ShowAccessesScreenState extends State<ShowAccessesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fileHashController = TextEditingController();

  @override
  void dispose() {
    _fileHashController.dispose();
    super.dispose();
  }

  Future<void> _showAccesses(BuildContext context) async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Show Accesses'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _fileHashController,
                decoration: InputDecoration(labelText: 'Filehash'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a filehash';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _showAccesses(context);
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
