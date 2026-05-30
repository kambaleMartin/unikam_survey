import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/local_database.dart';
import '../models/user_modele.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabase _localDb = LocalDatabase.instance;

  // 1. INSCRIPTION ÉTUDIANT (avec gestion hors ligne)
  Future<UserModel?> inscrireUtilisateur({
    required String nomComplet,
    required String sexe,
    required String promotion,
    required String mention,
    required String email,
    required String telephone,
    required String identifiant,
    required String motDePasse,
    required String role,
  }) async {
    try {
      final effectiveRole = role;

      // Vérifier la connectivité
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      final isConnected =
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);

      if (!isConnected) {
        // Mode hors ligne : enregistrement local
        return await _inscrireUtilisateurHorsLigne(
          nomComplet: nomComplet,
          sexe: sexe,
          promotion: promotion,
          mention: mention,
          email: email,
          telephone: telephone,
          identifiant: identifiant,
          motDePasse: motDePasse,
          role: role,
        );
      }

      // Mode connecté : enregistrement normal
      final identifiantQuery = await _firestore
          .collection('utilisateurs')
          .where('identifier', isEqualTo: identifiant)
          .limit(1)
          .get();

      if (identifiantQuery.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'identifier-already-in-use',
          message: 'Cet identifiant est déjà utilisé.',
        );
      }

      UserCredential resultat = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );

      User? firebaseUser = resultat.user;
      if (firebaseUser != null) {
        UserModel nouvelUtilisateur = UserModel(
          uid: firebaseUser.uid,
          identifiant: identifiant,
          nomComplet: nomComplet,
          sexe: sexe,
          promotion: promotion,
          mention: mention,
          email: email,
          telephone: telephone,
          role: effectiveRole,
        );

        await _firestore
            .collection('utilisateurs')
            .doc(firebaseUser.uid)
            .set(nouvelUtilisateur.toMap());

        await _localDb.saveSession(nouvelUtilisateur.toMap());

        return nouvelUtilisateur;
      }
    } catch (e) {
      print('Erreur d\'inscription : $e');
      rethrow;
    }
    return null;
  }

  // Méthode privée pour l'enregistrement hors ligne
  Future<UserModel?> _inscrireUtilisateurHorsLigne({
    required String nomComplet,
    required String sexe,
    required String promotion,
    required String mention,
    required String email,
    required String telephone,
    required String identifiant,
    required String motDePasse,
    required String role,
  }) async {
    try {
      const uuid = Uuid();
      final tempId = uuid.v4();

      // Créer un objet utilisateur temporaire
      final tempUser = {
        'tempId': tempId,
        'identifier': identifiant,
        'fullName': nomComplet,
        'gender': sexe,
        'promotion': promotion,
        'mention': mention,
        'email': email,
        'phone': telephone,
        'role': role,
        'password': motDePasse,
        'createdAt': DateTime.now().toIso8601String(),
        'isSynced': 0,
      };

      // Sauvegarder dans la base de données locale
      await _localDb.savePendingRegistration(tempUser);

      print(
        '💾 Inscription sauvegardée localement (ID: $tempId). Sera synchronisée à la reconnexion.',
      );

      // Retourner un UserModel temporaire (sans UID Firebase)
      return UserModel(
        uid: tempId,
        identifiant: identifiant,
        nomComplet: nomComplet,
        sexe: sexe,
        promotion: promotion,
        mention: mention,
        email: email,
        telephone: telephone,
        role: role,
      );
    } catch (e) {
      print('Erreur lors de l\'enregistrement hors ligne : $e');
      rethrow;
    }
  }

  // 2. CONNEXION (Étudiant, Chef de groupe ou Enseignant)
  Future<UserModel?> connecterUtilisateur({
    required String identifiant,
    required String motDePasse,
  }) async {
    try {
      final loginKey = identifiant.trim();
      String email = loginKey;

      if (!loginKey.contains('@')) {
        final query = await _firestore
            .collection('utilisateurs')
            .where('identifier', isEqualTo: loginKey)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Identifiant introuvable.',
          );
        }

        final userData = query.docs.first.data();
        email = userData['email'] as String;
      }

      UserCredential resultat = await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );

      User? firebaseUser = resultat.user;
      if (firebaseUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('utilisateurs')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> donnees = doc.data() as Map<String, dynamic>;
          UserModel utilisateur = UserModel.fromMap(donnees);

          await _localDb.saveSession(utilisateur.toMap());

          // Mettre à jour le statut en ligne
          await _firestore
              .collection('utilisateurs')
              .doc(firebaseUser.uid)
              .update({
                'isOnline': true,
                'lastSeen': DateTime.now().toIso8601String(),
              });

          return utilisateur;
        }
      }
    } catch (e) {
      print('Erreur de connexion : $e');
      rethrow;
    }
    return null;
  }

  // 3. SYNCHRONISER LES INSCRIPTIONS EN ATTENTE
  Future<void> syncPendingRegistrations() async {
    try {
      final pendingRegistrations = await _localDb.getUnsyncedRegistrations();

      if (pendingRegistrations.isEmpty) {
        print('✅ Aucune inscription en attente à synchroniser.');
        return;
      }

      print(
        '🔄 Synchronisation de ${pendingRegistrations.length} inscription(s) en attente...',
      );

      for (var reg in pendingRegistrations) {
        try {
          // Vérifier si l'identifiant est déjà utilisé
          final identifiantQuery = await _firestore
              .collection('utilisateurs')
              .where('identifier', isEqualTo: reg['identifier'])
              .limit(1)
              .get();

          if (identifiantQuery.docs.isNotEmpty) {
            print(
              '⚠️ Identifiant ${reg['identifier']} déjà utilisé. Suppression de l\'inscription locale.',
            );
            await _localDb.deletePendingRegistration(reg['tempId']);
            continue;
          }

          // Créer l'utilisateur sur Firebase Auth
          UserCredential resultat = await _auth.createUserWithEmailAndPassword(
            email: reg['email'],
            password: reg['password'],
          );

          User? firebaseUser = resultat.user;
          if (firebaseUser != null) {
            // Préparer les données utilisateur
            final userData = {
              'uid': firebaseUser.uid,
              'identifier': reg['identifier'],
              'fullName': reg['fullName'],
              'gender': reg['gender'],
              'promotion': reg['promotion'],
              'mention': reg['mention'],
              'email': reg['email'],
              'phone': reg['phone'],
              'role': reg['role'],
            };

            // Sauvegarder dans Firestore
            await _firestore
                .collection('utilisateurs')
                .doc(firebaseUser.uid)
                .set(userData);

            // Marquer comme synchronisé
            await _localDb.markRegistrationAsSynced(reg['tempId']);

            print(
              '✅ Inscription ${reg['identifier']} synchronisée avec succès (UID: ${firebaseUser.uid}).',
            );
          }
        } catch (e) {
          print(
            '❌ Erreur lors de la synchronisation de ${reg['identifier']}: $e',
          );
        }
      }

      print('✅ Synchronisation des inscriptions terminée.');
    } catch (e) {
      print('Erreur lors de la synchronisation des inscriptions : $e');
    }
  }

  // 3. VÉRIFICATION DE LA SESSION LOCALE (Au démarrage de l'appli)
  Future<UserModel?> verifierSessionLocale() async {
    Map<String, dynamic>? sessionDonnees = await _localDb.getSession();
    if (sessionDonnees != null) {
      return UserModel.fromMap(sessionDonnees);
    }
    return null;
  }

  // 4. DÉCONNEXION
  Future<void> deconnexion() async {
    try {
      // Récupérer l'UID de l'utilisateur actuellement connecté
      final sessionDonnees = await _localDb.getSession();
      if (sessionDonnees != null && sessionDonnees['uid'] != null) {
        final uid = sessionDonnees['uid'] as String;

        // Mettre à jour le statut hors ligne dans Firestore
        await _firestore.collection('utilisateurs').doc(uid).update({
          'isOnline': false,
          'lastSeen': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut hors ligne : $e');
    }

    await _auth.signOut();
    await _localDb.clearSession();
  }
}
