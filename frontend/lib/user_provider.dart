import 'package:flutter/material.dart';
import 'user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  void setUser(UserModel? newUser) {
    _user = newUser;
    notifyListeners();
  }

  String getUserID() {
    return _user!.id;
  }

  String getUsername() {
    return _user!.username;
  }

  String getUserType() {
    return _user!.userType;
  }

  String getToken() {
    return _user!.token;
  }
}
