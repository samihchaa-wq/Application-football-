import 'package:as_grinta/core/security/password_policy.dart';
import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/core/utils/name_validation.dart';
import 'package:as_grinta/core/widgets/grinta_app_bar.dart';
import 'package:as_grinta/core/widgets/grinta_loader.dart';
import 'package:as_grinta/core/widgets/photo_crop_preview.dart';
import 'package:as_grinta/features/auth/data/account_email_repository.dart';
import 'package:as_grinta/features/auth/domain/auth_profile.dart';
import 'package:as_grinta/features/auth/presentation/auth_state.dart';
import 'package:as_grinta/features/profile/presentation/my_data_section.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/composition_pitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _surnomController;
  String? _localError;
  // Les erreurs de saisie sont portées par le champ concerné
  // (InputDecoration.errorText) : un texte voisin est bien lu par les lecteurs
  // d'écran, mais sans jamais être rattaché au champ qu'il décrit.
  String? _firstNameError;
  String? _lastNameError;
  String? _surnomError;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).profile;
    _firstNameController = TextEditingController(
      text: profile?.firstName ?? '',
    );
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _surnomController = TextEditingController(text: profile?.surnom ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;
    final busy = authState.isBusy;
    final displayName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : 'Profil utilisateur';
    final photoActionLabel = (profile?.photoUrl ?? '').trim().isEmpty
        ? 'Ajouter une photo de profil'
        : 'Modifier la photo de profil';

    return Scaffold(
      appBar: GrintaAppBar(title: const Text('Profil')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          final avatarSize = compact ? 74.0 : 82.0;
          final sectionGap = compact ? 12.0 : 16.0;
          final fieldGap = compact ? 6.0 : 8.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              compact ? 4 : 8,
              16,
              compact ? 10 : 16,
            ),
            children: [
              Semantics(
                container: true,
                explicitChildNodes: true,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 14,
                    vertical: compact ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: AppTheme.outline.withValues(alpha: .56),
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Photo affichée seule, sans pastille ronde autour :
                          // les photos de joueurs sont détourées.
                          PlayerAvatar(
                            photoUrl: profile?.photoUrl,
                            name: profile?.displayName ?? '',
                            lastName: profile?.lastName,
                            size: avatarSize,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -1,
                            child: Tooltip(
                              message: photoActionLabel,
                              child: Semantics(
                                button: true,
                                enabled: !busy,
                                label: photoActionLabel,
                                child: Material(
                                  color: AppTheme.primary,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: busy ? null : _pickAndUploadPhoto,
                                    child: Padding(
                                      padding: EdgeInsets.all(compact ? 7 : 8),
                                      child: Icon(
                                        Icons.photo_camera_rounded,
                                        size: compact ? 15 : 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -.25,
                                  ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if ((profile?.username ?? '').isNotEmpty)
                                  _ProfileMetaChip(
                                    icon: Icons.alternate_email_rounded,
                                    label: profile!.username!,
                                  ),
                                _ProfileMetaChip(
                                  icon: Icons.shield_outlined,
                                  label: profile == null
                                      ? 'Rôle inconnu'
                                      : profile.role.label,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: sectionGap),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 10 : 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Prénom',
                          errorText: _firstNameError,
                          isDense: true,
                        ),
                      ),
                      SizedBox(height: fieldGap),
                      TextField(
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          errorText: _lastNameError,
                          isDense: true,
                        ),
                      ),
                      SizedBox(height: fieldGap),
                      TextField(
                        controller: _surnomController,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Surnom (optionnel)',
                          errorText: _surnomError,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 10 : 12),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _changePassword(context),
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Changer le mot de passe'),
              ),
              SizedBox(height: compact ? 6 : 8),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _editEmail(context, profile),
                icon: const Icon(Icons.mail_outline_rounded),
                label: Text(_emailLabel(profile)),
              ),
              SizedBox(height: compact ? 6 : 8),
              FilledButton.icon(
                onPressed: busy ? null : _saveProfile,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: GrintaProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Enregistrer les modifications'),
              ),
              if (_localError != null || authState.error != null) ...[
                SizedBox(height: compact ? 6 : 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _localError ?? authState.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const MyDataSection(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final cropped = await cropProfilePhoto(
      context,
      bytes,
      isGoalkeeper:
          ref.read(authControllerProvider).profile?.isGoalkeeper ?? false,
    );
    if (cropped == null) return;
    await ref
        .read(authControllerProvider.notifier)
        .uploadPhoto(bytes: cropped, fileExt: 'jpg');
    if (!mounted) return;
    final error = ref.read(authControllerProvider).error;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Photo mise à jour.')));
  }

  Future<void> _saveProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final surnom = _surnomController.text.trim();
    const lettersOnly = 'Uniquement des lettres : ni emoji, ni chiffre, '
        'ni symbole.';
    String? nameError(String value, {required bool required}) {
      if (value.isEmpty) return required ? 'Ce champ est obligatoire.' : null;
      return isValidPersonName(value) ? null : lettersOnly;
    }

    final firstNameError = nameError(firstName, required: true);
    final lastNameError = nameError(lastName, required: true);
    final surnomError = nameError(surnom, required: false);

    setState(() {
      _localError = null;
      _firstNameError = firstNameError;
      _lastNameError = lastNameError;
      _surnomError = surnomError;
    });
    if (firstNameError != null ||
        lastNameError != null ||
        surnomError != null) {
      return;
    }
    await ref.read(authControllerProvider.notifier).updateProfile(
          firstName: firstName,
          lastName: lastName,
          surnom: surnom,
        );
    if (!mounted) return;
    // Un échec doit se voir : sans ce retour, un refus serveur était
    // indiscernable d'un enregistrement réussi. Le bandeau d'erreur du corps
    // de l'écran affiche déjà le détail, le SnackBar signale l'événement.
    final error = ref.read(authControllerProvider).error;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Profil enregistré.')));
  }

  String _emailLabel(AuthProfile? profile) {
    if (profile?.contactEmail != null) {
      return 'E-mail : ${profile!.contactEmail}';
    }
    if (profile?.pendingContactEmail != null) {
      return 'E-mail à confirmer : ${profile!.pendingContactEmail}';
    }
    return 'Ajouter une adresse e-mail';
  }

  Future<void> _editEmail(BuildContext context, AuthProfile? profile) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ContactEmailDialog(
        confirmedEmail: profile?.contactEmail,
        pendingEmail: profile?.pendingContactEmail,
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? validationError;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Changer le mot de passe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Un AutofillGroup dédié + un seul champ marqué
                // "newPassword" : avec deux champs identiquement tagués,
                // certains navigateurs (Safari en particulier) confondent
                // les deux champs après la confirmation et le premier
                // redevient impossible à retoucher (le clavier ne se
                // réaffiche plus).
                AutofillGroup(
                  child: Column(
                    children: [
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          helperText: PasswordPolicy.helperText,
                          helperMaxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmationController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmation',
                        ),
                      ),
                    ],
                  ),
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    validationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  final password = passwordController.text;
                  final policyError = PasswordPolicy.validate(password);
                  final error = policyError ??
                      (password != confirmationController.text
                          ? 'Les deux mots de passe ne correspondent pas.'
                          : null);
                  if (error != null) {
                    setDialogState(() => validationError = error);
                    return;
                  }
                  Navigator.pop(dialogContext, password);
                },
                child: const Text('Modifier'),
              ),
            ],
          ),
        );
      },
    );
    passwordController.dispose();
    confirmationController.dispose();
    if (result == null || !mounted) return;
    await ref.read(authControllerProvider.notifier).updatePassword(result);
  }
}

class _ProfileMetaChip extends StatelessWidget {
  const _ProfileMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline.withValues(alpha: .44)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textFaint),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }
}

/// Ajouter ou changer l'adresse e-mail du compte. Elle ne sert à retrouver le
/// compte qu'une fois confirmée par le lien envoyé.
class ContactEmailDialog extends ConsumerStatefulWidget {
  const ContactEmailDialog({super.key, this.confirmedEmail, this.pendingEmail});

  final String? confirmedEmail;
  final String? pendingEmail;

  @override
  ConsumerState<ContactEmailDialog> createState() => _ContactEmailDialogState();
}

class _ContactEmailDialogState extends ConsumerState<ContactEmailDialog> {
  late final TextEditingController _controller;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.pendingEmail ?? widget.confirmedEmail ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _controller.text.trim();
    if (!looksLikeEmail(email)) {
      setState(() => _error = 'Saisis une adresse e-mail valide.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(accountEmailRepositoryProvider).requestConfirmation(email);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = widget.confirmedEmail;
    return AlertDialog(
      title: const Text('Adresse e-mail'),
      content: _sent
          ? const Text(
              'Un lien de confirmation vient d’être envoyé. Ouvre-le pour '
              'valider ton adresse : elle ne sera utilisable qu’ensuite.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  confirmed != null
                      ? 'Adresse confirmée : $confirmed. Tu peux la '
                          'remplacer ; l’ancienne reste active jusqu’à la '
                          'confirmation de la nouvelle.'
                      : 'Ajoute une adresse pour pouvoir retrouver ton '
                          'compte si tu perds ton mot de passe. Un lien de '
                          'confirmation te sera envoyé.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Adresse e-mail',
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ],
            ),
      actions: [
        if (_sent)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          )
        else ...[
          TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? 'Envoi…' : 'Envoyer le lien'),
          ),
        ],
      ],
    );
  }
}
