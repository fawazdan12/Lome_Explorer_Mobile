import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Classe utilitaire pour vérifier l'authentification
class AuthGuard {
  /// Vérifier si l'utilisateur est connecté
  static bool isAuthenticated(BuildContext context) {
    return context.read<AuthNotifier>().isAuthenticated;
  }

  /// Afficher le dialogue de connexion requise
  static Future<bool> requireAuth(
    BuildContext context, {
    String? message,
  }) async {
    if (isAuthenticated(context)) {
      return true;
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => _AuthRequiredDialog(message: message),
        ) ??
        false;
  }

  /// Wrapper pour une action nécessitant une authentification
  static Future<void> guardedAction(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? message,
  }) async {
    if (isAuthenticated(context)) {
      onAuthenticated();
    } else {
      final shouldLogin = await requireAuth(context, message: message);
      if (shouldLogin && context.mounted) {
        // Naviguer vers la page de connexion
        Navigator.pushNamed(context, '/login');
      }
    }
  }
}

/// Dialogue demandant à l'utilisateur de se connecter
class _AuthRequiredDialog extends StatelessWidget {
  final String? message;

  const _AuthRequiredDialog({this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lock,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Connexion requise'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message ??
                'Vous devez être connecté pour effectuer cette action.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Créez un compte gratuitement ou connectez-vous',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Plus tard'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Se connecter'),
        ),
      ],
    );
  }
}

/// Widget qui affiche son contenu uniquement si l'utilisateur est connecté
class AuthenticatedWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AuthenticatedWidget({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, _) {
        if (authNotifier.isAuthenticated) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget qui affiche son contenu uniquement si l'utilisateur N'est PAS connecté
class UnauthenticatedWidget extends StatelessWidget {
  final Widget child;

  const UnauthenticatedWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, _) {
        if (!authNotifier.isAuthenticated) {
          return child;
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Extension pour faciliter l'utilisation
extension AuthGuardExtension on BuildContext {
  /// Vérifier si l'utilisateur est authentifié
  bool get isAuthenticated => AuthGuard.isAuthenticated(this);

  /// Exécuter une action protégée
  Future<void> guardedAction({
    required VoidCallback onAuthenticated,
    String? message,
  }) {
    return AuthGuard.guardedAction(
      this,
      onAuthenticated: onAuthenticated,
      message: message,
    );
  }
}

/// Bouton qui nécessite une authentification
class AuthGuardedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final String? authMessage;
  final ButtonStyle? style;

  const AuthGuardedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.authMessage,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.guardedAction(
          onAuthenticated: onPressed,
          message: authMessage,
        );
      },
      style: style,
      child: child,
    );
  }
}

/// IconButton qui nécessite une authentification
class AuthGuardedIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? authMessage;
  final String? tooltip;

  const AuthGuardedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.authMessage,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () {
        context.guardedAction(
          onAuthenticated: onPressed,
          message: authMessage,
        );
      },
    );
  }
}