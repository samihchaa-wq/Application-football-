import 'package:petit_filet/core/security/password_policy.dart';
import 'package:petit_filet/features/auth/data/account_email_repository.dart';
import 'package:petit_filet/core/utils/name_validation.dart';
import 'package:petit_filet/core/widgets/pf_adaptive_form.dart';
import 'package:petit_filet/core/widgets/pf_auth_surface.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/features/auth/presentation/consent_fields.dart';
import 'package:petit_filet/features/auth/presentation/registration_success_dialog.dart';
import 'package:petit_filet/features/club/data/club_repository.dart';
import 'package:petit_filet/features/legal/domain/legal_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Les deux façons de s'inscrire.
enum RegisterMode {
  /// Rejoindre un club existant avec son code d'invitation.
  join,

  /// Créer un nouveau club et en devenir l'administrateur.
  create,
}

class AuthRegisterPage extends ConsumerStatefulWidget {
  const AuthRegisterPage({super.key, this.initialInviteCode});

  /// Code d'invitation reçu par le lien partagé, déjà rempli à l'ouverture.
  final String? initialInviteCode;

  @override
  ConsumerState<AuthRegisterPage> createState() => _AuthRegisterPageState();
}

class _AuthRegisterPageState extends ConsumerState<AuthRegisterPage> {
  final _inviteCodeController = TextEditingController();
  final _clubNameController = TextEditingController();
  final _clubShortNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  /// Dernier refus du formulaire, répété juste au-dessus du bouton : le
  /// message éphémère du bas de l'écran passait inaperçu et le bouton
  /// semblait ne rien faire.
  String? _formError;

  /// Erreur propre au champ e-mail (vide ou mal écrit).
  String? _emailError;
  final _emailFocus = FocusNode();
  bool _acceptedTerms = false;
  bool _acceptedClubContract = false;
  AgeConfirmation? _ageConfirmation;
  RegisterMode _mode = RegisterMode.join;

  @override
  void initState() {
    super.initState();
    final code = widget.initialInviteCode;
    if (code != null && code.trim().isNotEmpty) {
      _inviteCodeController.text = normalizeInviteCode(code);
    }
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _clubNameController.dispose();
    _clubShortNameController.dispose();
    _referralCodeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _formError = message);
  }

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _emailError = null;
    });
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text;
    final inviteCode = normalizeInviteCode(_inviteCodeController.text);
    final clubName = _clubNameController.text.trim();
    final clubShortName = _clubShortNameController.text.trim();
    final referralCode = normalizeReferralCode(_referralCodeController.text);

    if (_mode == RegisterMode.join && !inviteCodePattern.hasMatch(inviteCode)) {
      _showError(
        'Saisis le code d’invitation de ton club : 8 lettres ou chiffres.',
      );
      return;
    }
    if (_mode == RegisterMode.create) {
      if (clubName.length < 2 || clubName.length > 80) {
        _showError('Le nom du club doit compter entre 2 et 80 caractères.');
        return;
      }
      if (clubShortName.length > 12) {
        _showError('Le nom court ne doit pas dépasser 12 caractères.');
        return;
      }
      if (referralCode.isNotEmpty && !isValidReferralCode(referralCode)) {
        _showError(
          'Code parrain invalide : il commence par PF et compte 8 caractères.',
        );
        return;
      }
    }
    if (firstName.isEmpty || lastName.isEmpty) {
      _showError('Renseigne ton prénom et ton nom.');
      return;
    }
    if (!isValidPersonName(firstName) || !isValidPersonName(lastName)) {
      _showError('Le prénom et le nom ne doivent contenir que des lettres.');
      return;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Adresse e-mail obligatoire.');
      _emailFocus.requestFocus();
      _showError(
        _mode == RegisterMode.create
            ? 'Pour créer un club, indique ton adresse e-mail : c’est par '
                'elle qu’on te contacte pour l’abonnement.'
            : 'Indique ton adresse e-mail : elle sert à retrouver ton compte '
                'si tu perds ton mot de passe.',
      );
      return;
    }
    if (!looksLikeEmail(email)) {
      setState(() => _emailError = 'Adresse e-mail non valide.');
      _emailFocus.requestFocus();
      _showError('Cette adresse e-mail n’est pas valide.');
      return;
    }
    final passwordError = PasswordPolicy.validate(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }
    if (password != _confirmController.text) {
      _showError('Les deux mots de passe ne correspondent pas.');
      return;
    }

    final ageConfirmation = _ageConfirmation;
    if (ageConfirmation == null) {
      _showError('Indique si tu as 15 ans ou plus.');
      return;
    }
    if (!_acceptedTerms) {
      _showError(
        'Accepte les conditions d’utilisation et la politique de '
        'confidentialité pour créer ton compte.',
      );
      return;
    }
    if (_mode == RegisterMode.create && !_acceptedClubContract) {
      _showError(
        'Pour créer le club, confirme que tu peux l’engager et accepte les '
        'conditions d’abonnement et l’accord sur les données.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repository = ref.read(clubRepositoryProvider);
      final registration = _mode == RegisterMode.create
          ? await repository.createClub(
              clubName: clubName,
              clubShortName: clubShortName,
              firstName: firstName,
              lastName: lastName,
              password: password,
              acceptedTermsVersion: legalVersion,
              acceptedClubContractVersion: clubContractVersion,
              ageConfirmation: ageConfirmation,
              email: email,
              referralCode: referralCode,
            )
          : await repository.joinClub(
              inviteCode: inviteCode,
              firstName: firstName,
              lastName: lastName,
              password: password,
              acceptedTermsVersion: legalVersion,
              ageConfirmation: ageConfirmation,
              email: email,
            );
      final username = registration.username;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RegistrationSuccessDialog(
          username: username,
          teamName: registration.clubName,
          isActive: registration.isActive,
          emailConfirmationSent: registration.emailConfirmationSent,
        ),
      );
      if (mounted) context.go('/auth/sign-in');
    } on StateError catch (error) {
      _showError(error.message);
    } on ArgumentError catch (error) {
      _showError(error.message?.toString() ?? PasswordPolicy.helperText);
    } catch (_) {
      _showError('La création du compte a échoué.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PfAuthSurface(
      maxWidth: 760,
      title:
          _mode == RegisterMode.create ? 'Créer mon club' : 'Créer mon compte',
      subtitle: _mode == RegisterMode.create
          ? 'Tu deviens l’administrateur du club et tu invites tes joueurs.'
          : 'Le compte sera accessible après validation par un admin du club.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<RegisterMode>(
            segments: const [
              ButtonSegment(
                value: RegisterMode.join,
                icon: Icon(Icons.group_add_outlined),
                label: Text('Rejoindre un club'),
              ),
              ButtonSegment(
                value: RegisterMode.create,
                icon: Icon(Icons.add_business_outlined),
                label: Text('Créer un club'),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: _submitting
                ? null
                : (selection) => setState(() => _mode = selection.first),
          ),
          const SizedBox(height: 20),
          if (_mode == RegisterMode.join)
            TextField(
              key: const Key('register-invite-code'),
              controller: _inviteCodeController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Code d’invitation du club',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            )
          else
            PfAdaptiveForm(
              children: [
                TextField(
                  key: const Key('register-club-name'),
                  controller: _clubNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom du club',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                ),
                TextField(
                  key: const Key('register-club-short-name'),
                  controller: _clubShortNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Nom court (facultatif)',
                    prefixIcon: Icon(Icons.short_text),
                  ),
                ),
                TextField(
                  key: const Key('register-referral-code'),
                  controller: _referralCodeController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Code parrain (facultatif)',
                    helperText:
                        'Donné par un club qui utilise déjà Petit Filet.',
                    prefixIcon: Icon(Icons.card_giftcard_outlined),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          PfAdaptiveForm(
            children: [
              TextField(
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
              ),
              TextField(
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('register-email'),
            controller: _emailController,
            focusNode: _emailFocus,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'Adresse e-mail',
              helperText: _mode == RegisterMode.create
                  ? 'Obligatoire pour créer un club : abonnement et '
                      'récupération du compte.'
                  : 'Sert à retrouver ton compte si tu perds ton mot '
                      'de passe. Un lien de confirmation te sera envoyé.',
              helperMaxLines: 4,
              errorText: _emailError,
              prefixIcon: const Icon(Icons.mail_outlined),
            ),
          ),
          const SizedBox(height: 16),
          // Un AutofillGroup dédié + un seul champ marqué "newPassword" :
          // avec deux champs identiquement tagués, certains navigateurs
          // (Safari en particulier) confondent les deux champs après la
          // confirmation et le premier redevient impossible à retoucher
          // (le clavier ne se réaffiche plus).
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    helperText: PasswordPolicy.helperText,
                    helperMaxLines: 4,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Afficher le mot de passe'
                          : 'Masquer le mot de passe',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitting ? null : _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Répète le mot de passe',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ConsentFields(
            ageConfirmation: _ageConfirmation,
            acceptedTerms: _acceptedTerms,
            enabled: !_submitting,
            onAgeChanged: (value) => setState(() => _ageConfirmation = value),
            onTermsChanged: (value) => setState(() => _acceptedTerms = value),
            showClubContract: _mode == RegisterMode.create,
            acceptedClubContract: _acceptedClubContract,
            onClubContractChanged: (value) =>
                setState(() => _acceptedClubContract = value),
          ),
          const SizedBox(height: 24),
          if (_formError case final formError?) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                formError,
                key: const Key('register-form-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: PfProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sports_soccer_outlined),
            label: Text(
              _submitting
                  ? 'Création en cours…'
                  : _mode == RegisterMode.create
                      ? 'Créer mon club'
                      : 'Créer mon compte',
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _submitting ? null : () => context.go('/auth/sign-in'),
            child: const Text('J’ai déjà un compte — se connecter'),
          ),
        ],
      ),
    );
  }
}
