import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

final _logger = Logger();

/// Classe utilitaire pour vérifier la propriété des ressources
class OwnershipGuard {
  /// Normaliser les UUIDs pour la comparaison
  static String _normalizeUuid(String? uuid) {
    if (uuid == null || uuid.isEmpty) return '';
    return uuid.trim().toLowerCase().replaceAll('-', '');
  }

  /// Vérifier si l'utilisateur connecté est le propriétaire d'un lieu
  static bool isLieuOwner(BuildContext context, LieuEntity lieu) {
    final authNotifier = context.read<AuthNotifier>();

    if (!authNotifier.isAuthenticated) {
      _logger.w('NON authentifié');
      return false;
    }

    if (authNotifier.currentUser == null) {
      _logger.w('currentUser est NULL');
      return false;
    }

    final currentUserId = _normalizeUuid(authNotifier.currentUser?.id);
    final proprietaireId = _normalizeUuid(lieu.proprietaireId);

    if (currentUserId.isEmpty) {
      _logger.w('ID utilisateur vide');
      return false;
    }

    if (proprietaireId.isEmpty) {
      _logger.w('ID propriétaire vide');
      return false;
    }

    final isOwner = currentUserId == proprietaireId;
    
    _logger.d(
      ' ${isOwner ? "EST propriétaire" : "N'EST PAS propriétaire"}',
    );

    return isOwner;
  }

  /// Vérifier si l'utilisateur connecté est l'organisateur d'un événement
  static bool isEvenementOwner(
    BuildContext context,
    EvenementEntity evenement,
  ) {
    final authNotifier = context.read<AuthNotifier>();

    if (!authNotifier.isAuthenticated) {
      _logger.w('NON authentifié');
      return false;
    }

    if (authNotifier.currentUser == null) {
      _logger.w('currentUser est NULL');
      return false;
    }

    final currentUserId = _normalizeUuid(authNotifier.currentUser?.id);
    final organisateurId = _normalizeUuid(evenement.organisateurId);

    _logger.d('ID utilisateur (normalisé): "$currentUserId"');
    _logger.d('ID organisateur (normalisé): "$organisateurId"');

    if (currentUserId.isEmpty) {
      _logger.w('ID utilisateur vide');
      return false;
    }

    if (organisateurId.isEmpty) {
      _logger.w('ID organisateur vide');
      return false;
    }

    final isOwner = currentUserId == organisateurId;
    
    _logger.d(
      '  └─ ${isOwner ? "EST organisateur" : "N'EST PAS organisateur"}',
    );

    return isOwner;
  }

  /// Vérifier si un événement est terminé
  static bool isEvenementTermine(EvenementEntity evenement) {
    final now = DateTime.now();
    final isTermine = evenement.dateFin.isBefore(now);
    return isTermine;
  }

  /// Vérifier si un événement peut être modifié
  static bool canEditEvenement(BuildContext context, EvenementEntity evenement) {
    // Vérifier la propriété
    if (!isEvenementOwner(context, evenement)) {
      return false;
    }

    // Vérifier si l'événement n'est pas terminé
    if (isEvenementTermine(evenement)) {
      _logger.w('❌ Événement terminé - modification interdite');
      return false;
    }

    return true;
  }

  /// Afficher un dialogue si l'utilisateur n'est pas le propriétaire
  static Future<void> showNotOwnerDialog(
    BuildContext context, {
    String? resourceType,
  }) {
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
              color: AppColors.error.withAlpha((255 * 0.5).round()),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
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

  /// Dialogue pour événement terminé
  static Future<void> showEvenementTermineDialog(
    BuildContext context,
    EvenementEntity evenement,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.event_busy, color: AppColors.mediumGrey, size: 28),
            const SizedBox(width: 12),
            const Text('Événement terminé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.mediumGrey.withAlpha((255 * 0.5).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'Cet événement est déjà terminé.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous ne pouvez pas modifier un événement passé.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Date de fin: ${_formatDate(evenement.dateFin)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
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
    required String action,
    LieuEntity? lieu,
    EvenementEntity? evenement,
  }) async {
    final ctx = context;
    final authNotifier = ctx.read<AuthNotifier>();

    _logger.i('Vérification action: $action');

    // 1. Vérifier l'authentification
    if (!authNotifier.isAuthenticated) {
      _logger.w('Non authentifié - demande de connexion');
      final shouldLogin = await _showAuthRequiredDialog(
        ctx,
        action: action,
        resourceType: lieu != null ? 'lieu' : 'événement',
      );

      if (!ctx.mounted) return false;

      if (shouldLogin) {
        await Navigator.pushNamed(context, '/login');
        if (!ctx.mounted) return false;

        if (!authNotifier.isAuthenticated) {
          _logger.w('Toujours non authentifié après login');
          return false;
        }
      } else {
        _logger.w('Utilisateur a refusé de se connecter');
        return false;
      }
    }

    // 2. Vérifier la propriété
    bool isOwner = false;
    String? resourceType;

    if (lieu != null) {
      isOwner = isLieuOwner(ctx, lieu);
      resourceType = 'lieu';
    } else if (evenement != null) {
      isOwner = isEvenementOwner(ctx, evenement);
      resourceType = 'événement';

      //  Vérifier si l'événement est terminé (seulement pour modification)
      if (isOwner && action == 'modifier' && isEvenementTermine(evenement)) {
        if (!ctx.mounted) return false;
        await showEvenementTermineDialog(ctx, evenement);
        if (!ctx.mounted) return false;
        return false;
      }
    }

    if (!isOwner) {
      if (!ctx.mounted) return false;
      _logger.w('N\'est pas propriétaire - dialogue d\'erreur');
      await showNotOwnerDialog(ctx, resourceType: resourceType);
      if (!ctx.mounted) return false;
      return false;
    }

    _logger.i('Action autorisée');
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
                    color: Colors.blue.withAlpha((255 * 0.1).round()),
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
        ) ??
        false;
  }

  /// Helper pour formater une date
  static String _formatDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
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

  /// Vérifier si l'utilisateur peut modifier un événement (avec vérification de date)
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
  final bool checkEvenementDate;

  const OwnerOnly({
    super.key,
    this.lieu,
    this.evenement,
    required this.child,
    this.fallback,
    this.checkEvenementDate = false, 
  }) : assert(
         lieu != null || evenement != null,
         'Either lieu or evenement must be provided',
       );

  @override
  Widget build(BuildContext context) {
    bool isOwner = false;

    if (lieu != null) {
      isOwner = OwnershipGuard.isLieuOwner(context, lieu!);
    } else if (evenement != null) {
      if (checkEvenementDate) {
        // Pour la modification : vérifier la date
        isOwner = OwnershipGuard.canEditEvenement(context, evenement!);
      } else {
        // Pour la suppression : juste vérifier la propriété
        isOwner = OwnershipGuard.isEvenementOwner(context, evenement!);
      }
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
  }) : assert(
         lieu != null || evenement != null,
         'Either lieu or evenement must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return OwnerOnly(
      lieu: lieu,
      evenement: evenement,
      checkEvenementDate: true, 
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
  }) : assert(
         lieu != null || evenement != null,
         'Either lieu or evenement must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return OwnerOnly(
      lieu: lieu,
      evenement: evenement,
      checkEvenementDate: false, 
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