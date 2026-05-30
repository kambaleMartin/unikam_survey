import 'package:flutter/material.dart';
import 'package:unikam_survey/data/repositories/auth_repository.dart';
import 'package:unikam_survey/ui/ecrans/auth/inscription_ecran.dart';
import 'package:unikam_survey/ui/ecrans/home/role_based_home_screen.dart';

class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifiantController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;

  String? _validateIdentifiant(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre identifiant ou email';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.contains('@')) {
      final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(trimmedValue)) {
        return 'Veuillez entrer un email valide';
      }
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  void _soumettreConnexion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final utilisateur = await _authRepository.connecterUtilisateur(
        identifiant: _identifiantController.text.trim(),
        motDePasse: _motDePasseController.text.trim(),
      );

      if (utilisateur == null) {
        throw Exception(
          'Impossible de récupérer les informations utilisateur.',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion réussie ! Bienvenue sur UNIKAM Survey.'),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoleBasedHomeScreen(user: utilisateur),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion : ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _identifiantController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Connexion - UNIKAM'),
        backgroundColor: Colors.blue[800],
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEAF4FF), Color(0xFFF5F8FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF4338CA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 56,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bienvenue sur UNIKAM Survey',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Votre portail professionnel d’évaluations pédagogiques.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Ouvrez l’application et connectez-vous pour continuer vos sondages et analyses.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _identifiantController,
                                    decoration: const InputDecoration(
                                      labelText: 'Identifiant ou Email',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: _validateIdentifiant,
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _motDePasseController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Mot de passe',
                                      prefixIcon: Icon(Icons.lock),
                                    ),
                                    validator: _validatePassword,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _soumettreConnexion,
                                    child: const Text('Se connecter'),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const InscriptionScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Pas encore de compte ? Inscrivez-vous',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
