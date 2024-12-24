class Users {
  final int? id;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String password;

  Users({this.id, required this.nom, required this.prenom, required this.telephone, required this.email, required this.password});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'password': password
    };
  }

}