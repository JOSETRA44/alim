import 'package:alim_engine/alim_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';

/// Pantalla única del flujo de autenticación: muestra el formulario que
/// corresponda al [AuthState] vigente (teléfono, código o contraseña 2FA).
class AuthFlowScreen extends ConsumerWidget {
  const AuthFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).value ?? const AuthInitializing();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (auth) {
                  AuthWaitingPhoneNumber(:final error) =>
                    _PhoneForm(key: const ValueKey('phone'), error: error),
                  AuthWaitingCode(:final phoneNumber, :final error) => _CodeForm(
                      key: const ValueKey('code'),
                      phoneNumber: phoneNumber,
                      error: error,
                    ),
                  AuthWaitingPassword(:final hint, :final error) =>
                    _PasswordForm(
                      key: const ValueKey('password'),
                      hint: hint,
                      error: error,
                    ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormShell extends StatelessWidget {
  const _FormShell({
    required this.title,
    required this.subtitle,
    required this.field,
    required this.buttonLabel,
    required this.onSubmit,
    this.error,
  });

  final String title;
  final String subtitle;
  final Widget field;
  final String buttonLabel;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ALIM',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        field,
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(onPressed: onSubmit, child: Text(buttonLabel)),
      ],
    );
  }
}

class _PhoneForm extends ConsumerStatefulWidget {
  const _PhoneForm({super.key, this.error});

  final String? error;

  @override
  ConsumerState<_PhoneForm> createState() => _PhoneFormState();
}

class _PhoneFormState extends ConsumerState<_PhoneForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() =>
      ref.read(engineProvider).submitPhoneNumber(_controller.text);

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: 'Inicia sesión',
      subtitle: 'Introduce tu número de teléfono para continuar.',
      error: widget.error,
      buttonLabel: 'Continuar',
      onSubmit: _submit,
      field: TextField(
        controller: _controller,
        keyboardType: TextInputType.phone,
        autofocus: true,
        decoration: const InputDecoration(hintText: '+34 600 000 000'),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}

class _CodeForm extends ConsumerStatefulWidget {
  const _CodeForm({super.key, required this.phoneNumber, this.error});

  final String phoneNumber;
  final String? error;

  @override
  ConsumerState<_CodeForm> createState() => _CodeFormState();
}

class _CodeFormState extends ConsumerState<_CodeForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => ref.read(engineProvider).submitCode(_controller.text);

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: 'Código de verificación',
      subtitle: 'Enviamos un código a ${widget.phoneNumber}.',
      error: widget.error,
      buttonLabel: 'Verificar',
      onSubmit: _submit,
      field: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        maxLength: 5,
        decoration: const InputDecoration(hintText: '·····', counterText: ''),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}

class _PasswordForm extends ConsumerStatefulWidget {
  const _PasswordForm({super.key, this.hint, this.error});

  final String? hint;
  final String? error;

  @override
  ConsumerState<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends ConsumerState<_PasswordForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => ref.read(engineProvider).submitPassword(_controller.text);

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: 'Verificación en dos pasos',
      subtitle: widget.hint == null
          ? 'Introduce tu contraseña.'
          : 'Introduce tu contraseña. Pista: ${widget.hint}',
      error: widget.error,
      buttonLabel: 'Entrar',
      onSubmit: _submit,
      field: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Contraseña'),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
