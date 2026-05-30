import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../connexion_ecran.dart';
import '../home/role_based_home_screen.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();

  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _identifiantController = TextEditingController();
  final _motDePasseController = TextEditingController();

  String? _sexeSelectionne;
  String? _promotionSelectionnee;
  String? _mentionSelectionnee;
  String _roleSelectionne = 'etudiant';

  bool _isLoading = false;

  void _soumettreFormulaire() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final utilisateur = await _authRepo.inscrireUtilisateur(
        nomComplet: _nomController.text.trim(),
        sexe: _sexeSelectionne!,
        promotion: _promotionSelectionnee ?? '',
        mention: _mentionSelectionnee ?? '',
        email: _emailController.text.trim(),
        telephone: _telephoneController.text.trim(),
        identifiant: _identifiantController.text.trim(),
        motDePasse: _motDePasseController.text.trim(),
        role: _roleSelectionne!,
      );

      if (utilisateur == null) {
        throw Exception('Erreur lors de la création du compte.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription réussie ! Bienvenue sur UNIKAM Survey.'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un email valide';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre nom';
    }
    final nameRegex = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ'’\-\s]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Nom invalide';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro';
    }
    if (value.length < 8) {
      return 'Veuillez entrer un numéro valide';
    }
    return null;
  }

  String? _validateIdentifiant(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un identifiant';
    }
    if (value.trim().length < 3) {
      return 'L\'identifiant doit contenir au moins 3 caractères';
    }
    return null;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
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
        title: const Text('Inscription - UNIKAM'),
        backgroundColor: Colors.blue[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
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
                            vertical: 26,
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.school_outlined,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Inscription Étudiant UNIKAM',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ce formulaire est réservé aux étudiants.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
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
                                Text(
                                  'Informations personnelles',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nomController,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ '’\-]"),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Nom complet',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: _validateName,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _sexeSelectionne,
                                  decoration: const InputDecoration(
                                    labelText: 'Sexe',
                                  ),
                                  items: ['Masculin', 'Féminin']
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _sexeSelectionne = v),
                                  validator: (v) => v == null
                                      ? 'Veuillez sélectionner votre sexe'
                                      : null,
                                ),
                                if (_roleSelectionne == 'etudiant' ||
                                    _roleSelectionne == 'enseignant') ...[
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _promotionSelectionnee,
                                    decoration: InputDecoration(
                                      labelText:
                                          _roleSelectionne == 'enseignant'
                                          ? 'Promotion (optionnelle)'
                                          : 'Promotion',
                                    ),
                                    items:
                                        [
                                              'Bac 1',
                                              'Bac 2',
                                              'Bac 3',
                                              'Master 1',
                                              'Master 2',
                                            ]
                                            .map(
                                              (p) => DropdownMenuItem(
                                                value: p,
                                                child: Text(p),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) => setState(
                                      () => _promotionSelectionnee = v,
                                    ),
                                    validator: (v) {
                                      if (_roleSelectionne == 'etudiant' &&
                                          v == null) {
                                        return 'Veuillez sélectionner votre promotion';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _mentionSelectionnee,
                                    decoration: InputDecoration(
                                      labelText:
                                          _roleSelectionne == 'enseignant'
                                          ? 'Mention (optionnelle)'
                                          : 'Mention',
                                    ),
                                    items:
                                        [
                                              'Génie Logiciel',
                                              'Systèmes Informatiques',
                                            ]
                                            .map(
                                              (m) => DropdownMenuItem(
                                                value: m,
                                                child: Text(m),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) => setState(
                                      () => _mentionSelectionnee = v,
                                    ),
                                    validator: (v) {
                                      if (_roleSelectionne == 'etudiant' &&
                                          v == null) {
                                        return 'Veuillez sélectionner votre mention';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                const SizedBox(height: 24),
                                Text(
                                  'Compte et accès',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: 'etudiant',
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Rôle',
                                    prefixIcon: Icon(Icons.school),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Les comptes enseignant et admin sont déjà pré-créés.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _telephoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Numéro de téléphone',
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  validator: _validatePhone,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _identifiantController,
                                  decoration: const InputDecoration(
                                    labelText: 'Identifiant',
                                    prefixIcon: Icon(Icons.badge),
                                  ),
                                  validator: _validateIdentifiant,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Adresse Email',
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 16),
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
                                  onPressed: _soumettreFormulaire,
                                  child: const Text('S\'inscrire'),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ConnexionScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Déjà un compte ? Se connecter',
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
    );
  }
}
