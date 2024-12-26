class Users {
  final int? id;
  final String fullname;
  final String email;
  final String password;
  final double? height;
  final double? weight;

  Users({this.id, this.height, this.weight, required this.fullname, required this.email, required this.password});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullname': fullname,
      'email': email,
      'password': password,
      'height': height,
      'weight': weight
    };
  }

}