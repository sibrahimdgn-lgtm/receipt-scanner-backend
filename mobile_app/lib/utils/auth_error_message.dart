import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import '../services/auth_service.dart';

String authErrorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;

  if (error is AuthFlowException) {
    switch (error.code) {
      case 'firebase_not_configured':
        return l10n.authFirebaseNotConfigured;
      case 'account_setup_required':
        return l10n.authAccountSetupRequired;
      case 'invalid_email':
        return l10n.enterValidEmail;
      case 'email_already_in_use':
        return l10n.authEmailAlreadyInUse;
      case 'weak_password':
        return l10n.authWeakPassword;
      case 'invalid_credentials':
        return l10n.authInvalidCredentials;
      case 'network_error':
        return l10n.authNetworkError;
      case 'too_many_requests':
        return l10n.authTooManyRequests;
      default:
        return l10n.authUnexpectedError;
    }
  }

  return error.toString().replaceFirst('Exception: ', '');
}
