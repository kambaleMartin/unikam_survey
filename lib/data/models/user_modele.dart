class UserModel {
  final String uid; // Identifiant unique Firebase
  final String identifiant;
  final String nomComplet;
  final String sexe;
  final String promotion;
  final String mention; // Génie Logiciel ou Systèmes Informatiques
  final String email;
  final String telephone;
  final String role; // 'etudiant', 'admin', ou 'enseignant'

  UserModel({
    required this.uid,
    required this.identifiant,
    required this.nomComplet,
    required this.sexe,
    required this.promotion,
    required this.mention,
    required this.email,
    required this.telephone,
    required this.role,
  });

  // Convertir un objet Dart en Map (format clé/valeur) pour SQLite et Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'identifier': identifiant,
      'fullName': nomComplet,
      'gender': sexe,
      'promotion': promotion,
      'mention': mention,
      'email': email,
      'phone': telephone,
      'role': role,
    };
  }

  // Créer un objet UserModel à partir d'une Map venant de SQLite ou Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      identifiant: map['identifier'] ?? map['identifiant'] ?? '',
      nomComplet: map['fullName'] ?? '',
      sexe: map['gender'] ?? '',
      promotion: map['promotion'] ?? '',
      mention: map['mention'] ?? '',
      email: map['email'] ?? '',
      telephone: map['phone'] ?? '',
      role: map['role'] ?? 'etudiant',
    );
  }
}
