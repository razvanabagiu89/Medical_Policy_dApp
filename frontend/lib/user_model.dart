class UserModel {
  final String id;
  final String username;
  final String userType;
  final String token;

  UserModel(
      {required this.id,
      required this.username,
      required this.userType,
      required this.token});
}
