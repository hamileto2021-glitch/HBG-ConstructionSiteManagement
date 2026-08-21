class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceName,
  });

  final String email;
  final String password;
  final String? deviceName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'deviceName': deviceName,
    };
  }
}
