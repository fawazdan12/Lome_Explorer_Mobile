import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Classe utilitaire pour gérer la suppression d'avis de lieu
class AvisLieuDeleteHelper {
  /// Afficher le dialogue de confirmation de suppression
  static Future<bool?> showDeleteDialog({
    required BuildContext context,
    required String avisId,
    required String lieuNom,
    required int note,
    required String texte,
    DateTime? date,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _DeleteAvisLieuDialog(
        avisId: avisId,
        lieuNom: lieuNom,
        note: note,
        texte: texte,
        date: date,
      ),
    );
  }
}

/// Widget du dialogue de suppression avec gestion de l'état
class _DeleteAvisLieuDialog extends StatefulWidget {
  final String avisId;
  final String lieuNom;
  final int note;
  final String texte;
  final DateTime? date;

  const _DeleteAvisLieuDialog({
    required this.avisId,
    required this.lieuNom,
    required this.note,
    required this.texte,
    this.date,
  });

  @override
  State<_DeleteAvisLieuDialog> createState() => _DeleteAvisLieuDialogState();
}

class _DeleteAvisLieuDialogState extends State<_DeleteAvisLieuDialog> {
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
      content: SingleChildScrollView(
        child: Column(
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lieu
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.lieuNom,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Note
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < widget.note ? Icons.star : Icons.star_border,
                          color: AppColors.ratingColor,
                          size: 18,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.note}/5',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Texte de l'avis
                  Text(
                    widget.texte.length > 100
                        ? '${widget.texte.substring(0, 100)}...'
                        : widget.texte,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.date != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Publié le ${DateFormat('dd/MM/yyyy').format(widget.date!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mediumGrey,
                            fontSize: 11,
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
            const SizedBox(height: 8),
            Text(
              'Votre avis sera définitivement supprimé et ne pourra pas être récupéré.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
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
      final deleteNotifier = context.read<DeleteAvisLieuNotifier>();
      final success = await deleteNotifier.deleteAvis(widget.avisId);

      if (success && mounted) {
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
extension AvisLieuDeleteExtension on BuildContext {
  /// Supprimer un avis de lieu avec confirmation
  Future<bool> deleteAvisLieu({
    required String avisId,
    required String lieuNom,
    required int note,
    required String texte,
    DateTime? date,
  }) async {
    final confirmed = await AvisLieuDeleteHelper.showDeleteDialog(
      context: this,
      avisId: avisId,
      lieuNom: lieuNom,
      note: note,
      texte: texte,
      date: date,
    );
    return confirmed ?? false;
  }
}