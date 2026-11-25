import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordRecoveryDialog extends StatefulWidget {
  const PasswordRecoveryDialog({super.key, required this.savePassword});

  final Future<void> Function(String password) savePassword;

  @override
  State<PasswordRecoveryDialog> createState() => _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<PasswordRecoveryDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.savePassword(_password.text);
      TextInput.finishAutofillContext();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() {
          _busy = false;
          _error =
              'No se pudo cambiar la contraseña. Si el enlace expiró, solicita otro.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Cambiar contraseña'),
    content: AutofillGroup(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
              validator: (value) =>
                  (value?.length ?? 0) < 8 ? 'Usa al menos 8 caracteres' : null,
            ),
            TextFormField(
              controller: _confirmation,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
              ),
              validator: (value) => value != _password.text
                  ? 'Las contraseñas no coinciden'
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(_busy ? 'Guardando…' : 'Guardar'),
      ),
    ],
  );
}
