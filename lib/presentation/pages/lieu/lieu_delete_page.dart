import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Classe utilitaire pour gérer la suppression de lieux
class LieuDeleteHelper {
  /// Afficher le dialogue de confirmation de suppression
  static Future<bool?> showDeleteDialog({
    required BuildContext context,
    required String lieuId,
    required String lieuNom,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _DeleteLieuDialog(
        lieuId: lieuId,
        lieuNom: lieuNom,
      ),
    );
  }
}

/// Widget du dialogue de suppression avec gestion de l'état
class _DeleteLieuDialog extends StatefulWidget {
  final String lieuId;
  final String lieuNom;

  const _DeleteLieuDialog({
    required this.lieuId,
    required this.lieuNom,
  });

  @override
  State<_DeleteLieuDialog> createState() => _DeleteLieuDialogState();
}

class _DeleteLieuDialogState extends State<_DeleteLieuDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Supprimer le lieu'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Êtes-vous sûr de vouloir supprimer ce lieu ?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lieuNom,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette action est irréversible',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tous les événements associés à ce lieu seront également affectés.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Supprimer'),
        ),
      ],
    );
  }

  void _handleDelete() async {
    setState(() => _isDeleting = true);

    try {
      // TAppeler le service de suppression
      await context.read<LieuEvenementService>().deleteLieu(widget.lieuId);

      if (mounted) {
        Navigator.pop(context, true); // Retourner true pour indiquer le succès
        SnackBarHelper.showSuccess(
          context,
          '${widget.lieuNom} a été supprimé',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        SnackBarHelper.showError(
          context,
          'Erreur lors de la suppression: $e',
        );
      }
    }
  }
}

/// Extension pour faciliter l'utilisation dans les widgets
extension LieuDeleteExtension on BuildContext {
  /// Supprimer un lieu avec confirmation
  Future<bool> deleteLieu({
    required String lieuId,
    required String lieuNom,
  }) async {
    final confirmed = await LieuDeleteHelper.showDeleteDialog(
      context: this,
      lieuId: lieuId,
      lieuNom: lieuNom,
    );
    return confirmed ?? false;
  }
}