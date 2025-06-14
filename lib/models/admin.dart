// Remove Shop class definition from this file. Only keep Admin class and related code here.

class Admin {
  final int? adminId;
  final String username;
  final String email;
  final String password;

  Admin({
    this.adminId,
    required this.username,
    required this.email,
    required this.password,
  });
}
