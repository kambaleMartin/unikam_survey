import 'package:flutter/material.dart';
import '../../connexion_ecran.dart';
import '../../../data/models/user_modele.dart';
import '../sondage/sondage_ecran.dart';
import '../../../data/repositories/auth_repository.dart';

class StudentHomeScreen extends StatelessWidget {
  final UserModel user;

  const StudentHomeScreen({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    await AuthRepository().deconnexion();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConnexionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Étudiant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.indigo[700],
                      child: Text(
                        user.nomComplet.isNotEmpty
                            ? user.nomComplet[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue ${user.nomComplet}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: const Text('Étudiant'),
                            backgroundColor: Colors.indigo[50],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accédez au sondage et suivez l’avancement de votre filière.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails du profil',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text('Promotion : ${user.promotion}'),
                      const SizedBox(height: 8),
                      Text('Mention : ${user.mention}'),
                      const SizedBox(height: 8),
                      Text('Email : ${user.email}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SondageScreen(),
                    ),
                  );
                },
                child: const Text('Répondre au sondage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
