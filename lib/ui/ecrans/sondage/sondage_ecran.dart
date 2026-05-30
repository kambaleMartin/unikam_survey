import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../../core/database/local_database.dart';

class SondageScreen extends StatefulWidget {
  const SondageScreen({super.key});

  @override
  State<SondageScreen> createState() => _SondageScreenState();
}

class _SondageScreenState extends State<SondageScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _suggestionController = TextEditingController();

  String? _q1;
  String? _q2;
  String? _q3;
  String? _q4;
  bool _isSaving = false;

  Future<bool> _tryUploadResponse(Map<String, dynamic> responseRow) async {
    try {
      final dynamic connectivity = await Connectivity().checkConnectivity();
      if (connectivity is List<ConnectivityResult>) {
        if (!connectivity.any((result) => result != ConnectivityResult.none)) {
          return false;
        }
      } else if (connectivity == ConnectivityResult.none) {
        return false;
      }

      final firestoreData = Map<String, dynamic>.from(responseRow);
      firestoreData.remove('isSynced');

      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(responseRow['id'] as String)
          .set(firestoreData);

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _enregistrerReponse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_q1 == null || _q2 == null || _q3 == null || _q4 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez répondre à toutes les questions fermées.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final session = await LocalDatabase.instance.getSession();
      final studentUid = session != null
          ? session['uid'] as String
          : 'unknown_student';
      final responseId =
          '${studentUid}_${DateTime.now().millisecondsSinceEpoch}';
      final Map<String, dynamic> responseRow = {
        'id': responseId,
        'studentUid': studentUid,
        'promotion': session?['promotion'] as String? ?? '',
        'mention': session?['mention'] as String? ?? '',
        'q1': _q1,
        'q2': _q2,
        'q3': _q3,
        'q4': _q4,
        'q5': _suggestionController.text.trim(),
        'submittedAt': DateTime.now().toIso8601String(),
        'isSynced': 0,
      };

      await LocalDatabase.instance.insertSurveyResponse(responseRow);
      final isUploaded = await _tryUploadResponse(responseRow);
      if (isUploaded) {
        await LocalDatabase.instance.markAsSynced(responseId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUploaded
                ? 'Réponse enregistrée et synchronisée sur Firestore.'
                : 'Réponse sauvegardée localement. La synchronisation se fera automatiquement.',
          ),
        ),
      );

      _formKey.currentState?.reset();
      setState(() {
        _q1 = null;
        _q2 = null;
        _q3 = null;
        _q4 = null;
      });
      _suggestionController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l’enregistrement : ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sondage Programmation Mobile')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Questionnaire sur le cours Programmation Mobile',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Votre avis est précieux pour améliorer les prochaines sessions.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '1. Le contenu du cours est-il clairement expliqué ?',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                RadioListTile<String>(
                                  title: const Text('Oui'),
                                  value: 'Oui',
                                  groupValue: _q1,
                                  onChanged: (value) =>
                                      setState(() => _q1 = value),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Moyennement'),
                                  value: 'Moyennement',
                                  groupValue: _q1,
                                  onChanged: (value) =>
                                      setState(() => _q1 = value),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Non'),
                                  value: 'Non',
                                  groupValue: _q1,
                                  onChanged: (value) =>
                                      setState(() => _q1 = value),
                                ),
                                const Divider(height: 34, thickness: 1),
                                Text(
                                  '2. Les exemples et démonstrations sont-ils compréhensibles ?',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                RadioListTile<String>(
                                  title: const Text('Oui'),
                                  value: 'Oui',
                                  groupValue: _q2,
                                  onChanged: (value) =>
                                      setState(() => _q2 = value),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Moyennement'),
                                  value: 'Moyennement',
                                  groupValue: _q2,
                                  onChanged: (value) =>
                                      setState(() => _q2 = value),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Non'),
                                  value: 'Non',
                                  groupValue: _q2,
                                  onChanged: (value) =>
                                      setState(() => _q2 = value),
                                ),
                                const Divider(height: 34, thickness: 1),
                                Text(
                                  '3. Les séances pratiques facilitent-elles la compréhension du cours ?',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                RadioListTile<String>(
                                  title: const Text('Oui'),
                                  value: 'Oui',
                                  groupValue: _q3,
                                  onChanged: (value) =>
                                      setState(() => _q3 = value),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Non'),
                                  value: 'Non',
                                  groupValue: _q3,
                                  onChanged: (value) =>
                                      setState(() => _q3 = value),
                                ),
                                const Divider(height: 34, thickness: 1),
                                Text(
                                  '4. L’enseignant encourage-t-il la participation des étudiants ?',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                RadioListTile<String>(
                                  title: const Text('Oui'),
                                  value: 'Oui',
                                  groupValue: _q4,
                                  onChanged: (value) =>
                                      setState(() => _q4 = value),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Non'),
                                  value: 'Non',
                                  groupValue: _q4,
                                  onChanged: (value) =>
                                      setState(() => _q4 = value),
                                ),
                                const Divider(height: 34, thickness: 1),
                                TextFormField(
                                  controller: _suggestionController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText:
                                        '5. Suggestion pour améliorer le cours',
                                    alignLabelWithHint: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Veuillez donner une suggestion, même courte.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _enregistrerReponse,
                                  child: const Text('Enregistrer la réponse'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
