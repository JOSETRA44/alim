import 'user.dart';

/// Máquina de estados de autenticación, modelada sobre el flujo de TDLib
/// (`updateAuthorizationState`) porque es el superconjunto: los demás
/// motores emiten un subconjunto de estos estados.
sealed class AuthState {
  const AuthState();
}

/// El motor aún no terminó de arrancar.
class AuthInitializing extends AuthState {
  const AuthInitializing();
}

class AuthWaitingPhoneNumber extends AuthState {
  const AuthWaitingPhoneNumber({this.error});

  /// Error del intento anterior (p. ej. número inválido), si lo hubo.
  final String? error;
}

class AuthWaitingCode extends AuthState {
  const AuthWaitingCode({required this.phoneNumber, this.error});

  final String phoneNumber;
  final String? error;
}

/// Contraseña de verificación en dos pasos (2FA).
class AuthWaitingPassword extends AuthState {
  const AuthWaitingPassword({this.hint, this.error});

  final String? hint;
  final String? error;
}

class AuthReady extends AuthState {
  const AuthReady({required this.user});

  /// Usuario autenticado (cuenta propia).
  final AlimUser user;
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

/// El motor liberó todos sus recursos; no acepta más comandos.
class AuthClosed extends AuthState {
  const AuthClosed();
}
