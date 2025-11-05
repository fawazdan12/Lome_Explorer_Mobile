// 🧪 PAGE DE TEST À AJOUTER TEMPORAIREMENT
// Pour déboguer les problèmes d'ownership

import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DebugOwnershipPage extends StatelessWidget {
  const DebugOwnershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐛 Debug Ownership'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Utilisateur
            _buildSectionHeader('👤 UTILISATEUR CONNECTÉ'),
            Consumer<AuthNotifier>(
              builder: (context, authNotifier, _) {
                if (!authNotifier.isAuthenticated) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '❌ NON CONNECTÉ',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ),
                  );
                }

                final user = authNotifier.currentUser;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDebugRow('✅ Authentifié', 'OUI', Colors.green),
                        const Divider(),
                        _buildCopyableRow('ID', user?.id ?? 'null'),
                        _buildDebugRow('Username', user?.username ?? 'null', null),
                        _buildDebugRow('Email', user?.email ?? 'null', null),
                        _buildDebugRow('Lieux créés', '${user?.nombreLieux ?? 0}', null),
                        _buildDebugRow('Événements créés', '${user?.nombreEvenements ?? 0}', null),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Section Lieux
            _buildSectionHeader('📍 MES LIEUX (Premiers 5)'),
            Consumer<LieuxNotifier>(
              builder: (context, lieuxNotifier, _) {
                if (lieuxNotifier.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (lieuxNotifier.lieux.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun lieu disponible'),
                    ),
                  );
                }

                final authNotifier = context.read<AuthNotifier>();
                final currentUserId = authNotifier.currentUser?.id;

                return Column(
                  children: lieuxNotifier.lieux.take(5).map((lieu) {
                    final isOwner = currentUserId == lieu.proprietaireId;
                    return Card(
                      color: isOwner ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isOwner ? Icons.check_circle : Icons.cancel,
                                  color: isOwner ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lieu.nom,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            _buildCopyableRow('Propriétaire ID', lieu.proprietaireId),
                            _buildDebugRow('Propriétaire nom', lieu.proprietaireNom, null),
                            _buildDebugRow(
                              'Match avec user ?',
                              isOwner ? '✅ OUI' : '❌ NON',
                              isOwner ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Section Événements
            _buildSectionHeader('📅 MES ÉVÉNEMENTS (Premiers 5)'),
            Consumer<EvenementsNotifier>(
              builder: (context, evenementsNotifier, _) {
                if (evenementsNotifier.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (evenementsNotifier.evenements.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun événement disponible'),
                    ),
                  );
                }

                final authNotifier = context.read<AuthNotifier>();
                final currentUserId = authNotifier.currentUser?.id;

                return Column(
                  children: evenementsNotifier.evenements.take(5).map((evt) {
                    final isOwner = currentUserId == evt.organisateurId;
                    return Card(
                      color: isOwner ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isOwner ? Icons.check_circle : Icons.cancel,
                                  color: isOwner ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    evt.nom,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            _buildCopyableRow('Organisateur ID', evt.organisateurId!),
                            _buildDebugRow('Organisateur nom', evt.organisateurNom, null),
                            _buildDebugRow(
                              'Match avec user ?',
                              isOwner ? '✅ OUI' : '❌ NON',
                              isOwner ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Bouton de rafraîchissement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<LieuxNotifier>().fetchLieux();
                  context.read<EvenementsNotifier>().fetchEvenements();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraîchir les données'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildDebugRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      value,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}