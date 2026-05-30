import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../data/models/user_modele.dart';
import '../../connexion_ecran.dart';
import '../sondage/sondage_ecran.dart';
import '../../../data/repositories/auth_repository.dart';

class ManagementHomeScreen extends StatelessWidget {
  final UserModel user;

  const ManagementHomeScreen({super.key, required this.user});

  bool get isTeacher {
    final role = user.role.trim().toLowerCase();
    return role == 'enseignant' || role == 'teacher';
  }

  bool get isAdmin {
    final role = user.role.trim().toLowerCase();
    return role == 'admin' || role == 'chef de groupe';
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthRepository().deconnexion();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConnexionScreen()),
      );
    }
  }

  Future<void> _deleteUser(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text(
            'Voulez-vous vraiment supprimer cet utilisateur ? Cette action supprime le compte de la base de données.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(docId)
        .delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte utilisateur supprimé')),
      );
    }
  }

  Future<void> _showUserDetails(
    BuildContext context,
    QueryDocumentSnapshot userDoc,
  ) async {
    final data = userDoc.data() as Map<String, dynamic>;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Détails de l\'utilisateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nom complet : ${data['fullName'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Identifiant : ${data['identifier'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Email : ${data['email'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Téléphone : ${data['phone'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Rôle : ${data['role'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Promotion : ${data['promotion'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Mention : ${data['mention'] ?? 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editUser(
    BuildContext context,
    QueryDocumentSnapshot userDoc,
  ) async {
    final fullNameController = TextEditingController(
      text: userDoc['fullName'] as String? ?? '',
    );
    final phoneController = TextEditingController(
      text: userDoc['phone'] as String? ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifier l\'utilisateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Nom complet'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(dialogContext);

                await FirebaseFirestore.instance
                    .collection('utilisateurs')
                    .doc(userDoc.id)
                    .update({
                      'fullName': fullNameController.text.trim(),
                      'phone': phoneController.text.trim(),
                    });

                if (dialogContext.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Informations mises à jour')),
                  );
                }
                navigator.pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    Color? color,
  }) {
    return Card(
      color: color ?? Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queryBase = FirebaseFirestore.instance.collection('utilisateurs');
    final userStream = isAdmin
        ? queryBase.where('role', isEqualTo: 'etudiant').snapshots()
        : queryBase.snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? 'Espace Enseignant' : 'Espace Chef de groupe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTeacher ? 'Gestion avancée' : 'Tableau de bord',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bienvenue ${user.nomComplet}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatCard(
                      title: 'Rôle',
                      value: user.role,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    _buildStatCard(
                      title: 'Promotion',
                      value: user.promotion,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    _buildStatCard(
                      title: 'Mention',
                      value: user.mention,
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ],
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SondageScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text('Répondre au sondage'),
                  ),
                ],
              ],
            ),
          ),
          if (isTeacher) ...[
            _buildSectionTitle(context, 'Statistiques des sondages'),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('surveys')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucune réponse disponible.'),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final totalResponses = docs.length;
                final q1Yes = docs
                    .where(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['q1'] == 'Oui',
                    )
                    .length;
                final q2Yes = docs
                    .where(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['q2'] == 'Oui',
                    )
                    .length;
                final q4Yes = docs
                    .where(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['q4'] == 'Oui',
                    )
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStatCard(
                          title: 'Réponses totales',
                          value: '$totalResponses',
                        ),
                        _buildStatCard(
                          title: 'Q1 Oui',
                          value: '$q1Yes',
                          color: Colors.blue[50],
                        ),
                        _buildStatCard(
                          title: 'Q2 Oui',
                          value: '$q2Yes',
                          color: Colors.blue[50],
                        ),
                        _buildStatCard(
                          title: 'Q4 Oui',
                          value: '$q4Yes',
                          color: Colors.blue[50],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 340,
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Étudiant : ${data['studentUid'] ?? 'N/A'}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Promotion : ${data['promotion'] ?? 'N/A'}',
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      Text('Q1 : ${data['q1'] ?? ''}'),
                                      Text('Q2 : ${data['q2'] ?? ''}'),
                                      Text('Q3 : ${data['q3'] ?? ''}'),
                                    ],
                                  ),
                                  Text('Q4 : ${data['q4'] ?? ''}'),
                                  Text('Q5 : ${data['q5'] ?? ''}'),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Soumis le : ${data['submittedAt'] ?? ''}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          _buildSectionTitle(context, 'Gestion des comptes utilisateurs'),
          StreamBuilder<QuerySnapshot>(
            stream: userStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                final emptyMessage = isAdmin
                    ? 'Aucun utilisateur trouvé dans votre groupe. Vérifiez que les étudiants ont bien le rôle "etudiant" et les mêmes promotion/mention que votre compte (${user.promotion}, ${user.mention}).'
                    : 'Aucun utilisateur trouvé.';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Text(
                      emptyMessage,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4338CA),
                                    Color(0xFF06B6D4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  (data['fullName'] as String? ?? 'X')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            (data['isOnline'] as bool? ?? false)
                                ? Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                      title: Text(
                        data['fullName'] as String? ?? 'Sans nom',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        '${data['identifier'] ?? ''} • ${data['role'] ?? ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'Voir',
                            onPressed: () => _showUserDetails(context, doc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Modifier',
                            onPressed: () => _editUser(context, doc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Supprimer',
                            onPressed: () => _deleteUser(context, doc.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
