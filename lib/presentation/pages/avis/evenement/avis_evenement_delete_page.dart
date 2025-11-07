import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Classe utilitaire pour gérer la suppression d'avis d'événements
class AvisEvenementDeleteHelper {
  /// Afficher le dialogue de confirmation de suppression
  static Future<bool?> showDeleteDialog({
    required BuildContext context,
    required String avisId,
    required String evenementNom,
    int? note,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _DeleteAvisEvenementDialog(
        avisId: avisId,
        evenementNom: evenementNom,
        note: note,
      ),
    );
  }
}

/// Widget du dialogue de suppression avec gestion de l'état
class _DeleteAvisEvenementDialog extends StatefulWidget {
  final String avisId;
  final String evenementNom;
  final int? note;

  const _DeleteAvisEvenementDialog({
    required this.avisId,
    required this.evenementNom,
    this.note,
  });

  @override
  State<_DeleteAvisEvenementDialog> createState() =>
      _DeleteAvisEvenementDialogState();
}

class _DeleteAvisEvenementDialogState
    extends State<_DeleteAvisEvenementDialog> {
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
          const Expanded(child: Text('Supprimer l\'avis')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Êtes-vous sûr de vouloir supprimer cet avis ?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withAlpha((255 * 0.3).round())),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.evenementNom,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (widget.note != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < widget.note!
                              ? Icons.star
                              : Icons.star_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.note}/5',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cette action est irréversible',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Votre avis sera définitivement supprimé et ne pourra pas être récupéré.',
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
      // Appeler le service de suppression
      await context.read<DeleteAvisEvenementNotifier>().deleteAvis(widget.avisId);


      if (mounted) {
        Navigator.pop(context, true);
        SnackBarHelper.showSuccess(
          context,
          'Avis supprimé avec succès',
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
extension AvisEvenementDeleteExtension on BuildContext {
  /// Supprimer un avis d'événement avec confirmation
  Future<bool> deleteAvisEvenement({
    required String avisId,
    required String evenementNom,
    int? note,
  }) async {
    final confirmed = await AvisEvenementDeleteHelper.showDeleteDialog(
      context: this,
      avisId: avisId,
      evenementNom: evenementNom,
      note: note,
    );
    return confirmed ?? false;
  }
}