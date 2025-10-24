import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 🔒 Classe utilitaire pour vérifier la propriété des ressources
class OwnershipGuard {
  /// Vérifier si l'utilisateur connecté est le propriétaire d'un lieu
  static bool isLieuOwner(BuildContext context, LieuEntity lieu) {
    final authNotifier = context.read<AuthNotifier>();
    if (!authNotifier.isAuthenticated) return false;
    
    final currentUserId = authNotifier.currentUser?.id;
    return currentUserId == lieu.proprietaireId;
  }

  /// Vérifier si l'utilisateur connecté est l'organisateur d'un événement
  static bool isEvenementOwner(BuildContext context, EvenementEntity evenement) {
    final authNotifier = context.read<AuthNotifier>();
    if (!authNotifier.isAuthenticated) return false;
    
    final currentUserId = authNotifier.currentUser?.id;
    return currentUserId == evenement.organisateurId;
  }

  /// Afficher un dialogue si l'utilisateur n'est pas le propriétaire
  static Future<void> showNotOwnerDialog(BuildContext context, {String? resourceType}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            const Text('Accès refusé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Vous n\'êtes pas autorisé à modifier ou supprimer ce ${resourceType ?? 'contenu'}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Seul le propriétaire peut effectuer cette action.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mediumGrey,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// Vérifier l'authentification ET la propriété pour une action protégée
  static Future<bool> checkOwnershipForAction({
    required BuildContext context,
    required String action, // 'modifier' ou 'supprimer'
    LieuEntity? lieu,
    EvenementEntity? evenement,
  }) async {
    final authNotifier = context.read<AuthNotifier>();

    // 1. Vérifier l'authentification
    if (!authNotifier.isAuthenticated) {
      final shouldLogin = await _showAuthRequiredDialog(
        context,
        action: action,
        resourceType: lieu != null ? 'lieu' : 'événement',
      );
      
      if (shouldLogin && context.mounted) {
        await Navigator.pushNamed(context, '/login');
        // Après retour du login, revérifier
        if (!authNotifier.isAuthenticated) {
          return false;
        }
      } else {
        return false;
      }
    }

    // 2. Vérifier la propriété
    bool isOwner = false;
    String? resourceType;

    if (lieu != null) {
      isOwner = isLieuOwner(context, lieu);
      resourceType = 'lieu';
    } else if (evenement != null) {
      isOwner = isEvenementOwner(context, evenement);
      resourceType = 'événement';
    }

    if (!isOwner && context.mounted) {
      await showNotOwnerDialog(context, resourceType: resourceType);
      return false;
    }

    return true;
  }

  /// Dialogue d'authentification requise avec contexte
  static Future<bool> _showAuthRequiredDialog(
    BuildContext context, {
    required String action,
    required String resourceType,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: AppColors.primaryOrange, size: 28),
            const SizedBox(width: 12),
            const Text('Connexion requise'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous devez être connecté pour $action ce $resourceType.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
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
      ),
    ) ?? false;
  }
}

/// Extension pour faciliter l'utilisation dans les widgets
extension OwnershipGuardExtension on BuildContext {
  /// Vérifier si l'utilisateur peut modifier un lieu
  Future<bool> canEditLieu(LieuEntity lieu) {
    return OwnershipGuard.checkOwnershipForAction(
      context: this,
      action: 'modifier',
      lieu: lieu,
    );
  }

  /// Vérifier si l'utilisateur peut supprimer un lieu
  Future<bool> canDeleteLieu(LieuEntity lieu) {
    return OwnershipGuard.checkOwnershipForAction(
      context: this,
      action: 'supprimer',
      lieu: lieu,
    );
  }

  /// Vérifier si l'utilisateur peut modifier un événement
  Future<bool> canEditEvenement(EvenementEntity evenement) {
    return OwnershipGuard.checkOwnershipForAction(
      context: this,
      action: 'modifier',
      evenement: evenement,
    );
  }

  /// Vérifier si l'utilisateur peut supprimer un événement
  Future<bool> canDeleteEvenement(EvenementEntity evenement) {
    return OwnershipGuard.checkOwnershipForAction(
      context: this,
      action: 'supprimer',
      evenement: evenement,
    );
  }
}

/// Widget conditionnel qui affiche son contenu seulement si l'utilisateur est propriétaire
class OwnerOnly extends StatelessWidget {
  final LieuEntity? lieu;
  final EvenementEntity? evenement;
  final Widget child;
  final Widget? fallback;

  const OwnerOnly({
    super.key,
    this.lieu,
    this.evenement,
    required this.child,
    this.fallback,
  }) : assert(lieu != null || evenement != null, 'Either lieu or evenement must be provided');

  @override
  Widget build(BuildContext context) {
    bool isOwner = false;

    if (lieu != null) {
      isOwner = OwnershipGuard.isLieuOwner(context, lieu!);
    } else if (evenement != null) {
      isOwner = OwnershipGuard.isEvenementOwner(context, evenement!);
    }

    if (isOwner) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Bouton d'édition avec vérification de propriété
class OwnershipEditButton extends StatelessWidget {
  final LieuEntity? lieu;
  final EvenementEntity? evenement;
  final VoidCallback onPressed;
  final String? tooltip;
  final IconData icon;

  const OwnershipEditButton({
    super.key,
    this.lieu,
    this.evenement,
    required this.onPressed,
    this.tooltip,
    this.icon = Icons.edit,
  }) : assert(lieu != null || evenement != null, 'Either lieu or evenement must be provided');

  @override
  Widget build(BuildContext context) {
    return OwnerOnly(
      lieu: lieu,
      evenement: evenement,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip ?? 'Modifier',
        onPressed: () async {
          bool canEdit = false;
          if (lieu != null) {
            canEdit = await context.canEditLieu(lieu!);
          } else if (evenement != null) {
            canEdit = await context.canEditEvenement(evenement!);
          }

          if (canEdit && context.mounted) {
            onPressed();
          }
        },
      ),
    );
  }
}

/// Bouton de suppression avec vérification de propriété
class OwnershipDeleteButton extends StatelessWidget {
  final LieuEntity? lieu;
  final EvenementEntity? evenement;
  final VoidCallback onPressed;
  final String? tooltip;
  final IconData icon;

  const OwnershipDeleteButton({
    super.key,
    this.lieu,
    this.evenement,
    required this.onPressed,
    this.tooltip,
    this.icon = Icons.delete,
  }) : assert(lieu != null || evenement != null, 'Either lieu or evenement must be provided');

  @override
  Widget build(BuildContext context) {
    return OwnerOnly(
      lieu: lieu,
      evenement: evenement,
      child: IconButton(
        icon: Icon(icon, color: AppColors.error),
        tooltip: tooltip ?? 'Supprimer',
        onPressed: () async {
          bool canDelete = false;
          if (lieu != null) {
            canDelete = await context.canDeleteLieu(lieu!);
          } else if (evenement != null) {
            canDelete = await context.canDeleteEvenement(evenement!);
          }

          if (canDelete && context.mounted) {
            onPressed();
          }
        },
      ),
    );
  }
}