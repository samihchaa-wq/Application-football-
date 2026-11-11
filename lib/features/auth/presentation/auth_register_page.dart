import 'package:as_grinta/core/security/password_policy.dart';
import 'package:as_grinta/features/auth/data/account_email_repository.dart';
import 'package:as_grinta/core/utils/name_validation.dart';
import 'package:as_grinta/core/widgets/grinta_adaptive_form.dart';
import 'package:as_grinta/core/widgets/grinta_auth_surface.dart';
import 'package:as_grinta/core/widgets/grinta_loader.dart';
import 'package:as_grinta/features/auth/presentation/consent_fields.dart';
import 'package:as_grinta/features/club/data/club_repository.dart';
import 'package:as_grinta/features/legal/domain/legal_documents.dart';
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  bool _acceptedTerms = false;
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text;
    final inviteCode = normalizeInviteCode(_inviteCodeController.text);
    final clubName = _clubNameController.text.trim();
    final clubShortName = _clubShortNameController.text.trim();

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
    if (email.isNotEmpty && !looksLikeEmail(email)) {
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
              ageConfirmation: ageConfirmation,
              email: email,
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
        builder: (dialogContext) => AlertDialog(
          title: Text(
            registration.isActive
                ? 'Club créé : ${registration.clubName}'
                : 'Compte créé',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Retiens bien ton identifiant, tu en auras besoin pour te '
                'connecter :',
              ),
              const SizedBox(height: 12),
              SelectableText(
                username,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                registration.isActive
                    ? 'Tu es l’administrateur du club. Connecte-toi, puis '
                        'partage le lien d’inscription depuis le menu '
                        'Administration pour inviter tes joueurs.'
                    : 'Ton compte chez ${registration.clubName} restera en '
                        'attente jusqu’à sa validation par un admin.',
              ),
              if (registration.emailConfirmationSent) ...[
                const SizedBox(height: 12),
                const Text(
                  'Un e-mail de confirmation vient d’être envoyé : ouvre le '
                  'lien qu’il contient pour valider ton adresse.',
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Compris'),
            ),
          ],
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
    return GrintaAuthSurface(
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
                helperText: 'Donné par l’administrateur de ton club.',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            )
          else
            GrintaAdaptiveForm(
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
                    helperText: 'Affiché sur les scores. Ex. : FCV',
                    prefixIcon: Icon(Icons.short_text),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          GrintaAdaptiveForm(
            children: [
              TextField(
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: Icon(Icons.person_outline),
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
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Adresse e-mail (facultatif)',
              helperText: 'Sert à retrouver ton compte si tu perds ton mot '
                  'de passe. Un lien de confirmation te sera envoyé.',
              helperMaxLines: 2,
              prefixIcon: Icon(Icons.mail_outline),
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
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.lock_outline),
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
                    labelText: 'Confirme ton mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
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
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: GrintaProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sports_soccer),
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
