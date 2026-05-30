import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/local_database.dart';
import '../../data/repositories/auth_repository.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Démarrer l'écoute du changement de réseau
  void initializeSyncListener() {
    _subscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        print(
          '🌐 Connexion Internet détectée ! Lancement de la synchronisation...',
        );
        syncLocalDataToFirebase();
      }
    });

    _connectivity.checkConnectivity().then((results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        syncLocalDataToFirebase();
      }
    });
  }

  // Logique de synchronisation automatique
  Future<void> syncLocalDataToFirebase() async {
    final localDb = LocalDatabase.instance;
    final authRepo = AuthRepository();

    try {
      // Synchroniser les inscriptions en attente
      await authRepo.syncPendingRegistrations();

      // Synchroniser les sondages
      List<Map<String, dynamic>> unsyncedSurveys = await localDb
          .getUnsyncedResponses();

      if (unsyncedSurveys.isEmpty) {
        print('✅ Aucune donnée locale à synchroniser.');
        return;
      }

      for (var survey in unsyncedSurveys) {
        Map<String, dynamic> firestoreData = Map.from(survey);
        firestoreData.remove('isSynced');

        await _firestore
            .collection('surveys')
            .doc(firestoreData['id'])
            .set(firestoreData);

        await localDb.markAsSynced(firestoreData['id']);
        print('☁️ Sondage ${firestoreData['id']} synchronisé avec succès !');
      }
    } catch (e) {
      print('❌ Erreur lors de la synchronisation : $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
