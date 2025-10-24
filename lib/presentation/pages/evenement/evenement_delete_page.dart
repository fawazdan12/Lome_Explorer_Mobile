import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Classe utilitaire pour gérer la suppression d'événements
class EvenementDeleteHelper {
  /// Afficher le dialogue de confirmation de suppression
  static Future<bool?> showDeleteDialog({
    required BuildContext context,
    required String evenementId,
    required String evenementNom,
    DateTime? dateDebut,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _DeleteEvenementDialog(
        evenementId: evenementId,
        evenementNom: evenementNom,
        dateDebut: dateDebut,
      ),
    );
  }
}

/// Widget du dialogue de suppression avec gestion de l'état
class _DeleteEvenementDialog extends StatefulWidget {
  final String evenementId;
  final String evenementNom;
  final DateTime? dateDebut;

  const _DeleteEvenementDialog({
    required this.evenementId,
    required this.evenementNom,
    this.dateDebut,
  });

  @override
  State<_DeleteEvenementDialog> createState() => _DeleteEvenementDialogState();
}

class _DeleteEvenementDialogState extends State<_DeleteEvenementDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = widget.dateDebut != null &&
        widget.dateDebut!.isAfter(DateTime.now());

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Supprimer l\'événement')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Êtes-vous sûr de vouloir supprimer cet événement ?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                if (widget.dateDebut != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.dateDebut!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isUpcoming)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Événement à venir',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
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
          if (isUpcoming) ...[
            const SizedBox(height: 8),
            Text(
              'Les participants qui se sont inscrits seront notifiés de l\'annulation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
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

      await context.read<LieuEvenementService>().deleteEvenement(widget.evenementId);

      // Simulation de la suppression
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context, true);
        SnackBarHelper.showSuccess(
          context,
          '${widget.evenementNom} a été supprimé',
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
extension EvenementDeleteExtension on BuildContext {
  /// Supprimer un événement avec confirmation
  Future<bool> deleteEvenement({
    required String evenementId,
    required String evenementNom,
    DateTime? dateDebut,
  }) async {
    final confirmed = await EvenementDeleteHelper.showDeleteDialog(
      context: this,
      evenementId: evenementId,
      evenementNom: evenementNom,
      dateDebut: dateDebut,
    );
    return confirmed ?? false;
  }
}