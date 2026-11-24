import 'package:petit_filet/features/profile/data/personal_data_repository.dart';
import 'package:flutter/material.dart';

/// Saisie du téléphone et de la date de naissance d'un membre par un
/// administrateur. Renvoie les nouvelles valeurs, ou null si on annule.
Future<PrivateDetails?> showMemberContactDialog(
  BuildContext context, {
  required String memberName,
  PrivateDetails? initial,
}) {
  return showDialog<PrivateDetails>(
    context: context,
    builder: (_) => _MemberContactDialog(
      memberName: memberName,
      initial: initial ?? const PrivateDetails(),
    ),
  );
}

class _MemberContactDialog extends StatefulWidget {
  const _MemberContactDialog({required this.memberName, required this.initial});

  final String memberName;
  final PrivateDetails initial;

  @override
  State<_MemberContactDialog> createState() => _MemberContactDialogState();
}

class _MemberContactDialogState extends State<_MemberContactDialog> {
  late final _phone = TextEditingController(text: widget.initial.phone ?? '');
  late DateTime? _birthDate = widget.initial.birthDate;
  String? _phoneError;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.input,
      helpText: 'Date de naissance',
      fieldLabelText: 'Date de naissance',
      fieldHintText: 'jj/mm/aaaa',
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  void _submit() {
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && !phoneNumberPattern.hasMatch(phone)) {
      setState(() => _phoneError =
          'Numéro invalide : chiffres, espaces et « + » uniquement.');
      return;
    }
    Navigator.pop(
      context,
      PrivateDetails(
        phone: phone.isEmpty ? null : phone,
        birthDate: _birthDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final birthDate = _birthDate;
    return AlertDialog(
      title: Text('Coordonnées de ${widget.memberName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('member-contact-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              errorText: _phoneError,
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            isEmpty: birthDate == null,
            decoration: InputDecoration(
              labelText: 'Date de naissance',
              suffixIcon: birthDate == null
                  ? const Icon(Icons.calendar_today_outlined)
                  : IconButton(
                      tooltip: 'Effacer la date de naissance',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _birthDate = null),
                    ),
            ),
            // Sans nom, le lecteur d'écran annonçait un bouton vide.
            child: Semantics(
              label: birthDate == null
                  ? 'Choisir la date de naissance'
                  : 'Date de naissance : ${formatDay(birthDate)}, modifier',
              excludeSemantics: true,
              child: InkWell(
                key: const Key('member-contact-birth-date'),
                onTap: _pickDate,
                child: Text(birthDate == null ? '' : formatDay(birthDate)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Visibles par tous les membres du club dans l’Effectif.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('member-contact-save'),
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
