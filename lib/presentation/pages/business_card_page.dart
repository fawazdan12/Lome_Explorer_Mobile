import 'package:event_flow/core/providers/business_card_provider.dart';
import 'package:event_flow/data/models/business_card_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BusinessHomePage extends StatefulWidget {
  const BusinessHomePage({super.key});

  @override
  State<BusinessHomePage> createState() => _BusinessHomePageState();
}

class _BusinessHomePageState extends State<BusinessHomePage> {
  // Déclarez des contrôleurs pour chaque champ de texte
  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _companyController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    // Initialisez les contrôleurs et attachez des auditeurs
    final provider = Provider.of<BusinessCardProvider>(context, listen: false);
    
    _nameController = TextEditingController(text: provider.card.name);
    _titleController = TextEditingController(text: provider.card.title);
    _companyController = TextEditingController(text: provider.card.company);
    _emailController = TextEditingController(text: provider.card.email);
    _phoneController = TextEditingController(text: provider.card.phone);
    _websiteController = TextEditingController(text: provider.card.website);

    // Ajoutez des auditeurs pour mettre à jour le provider lorsque le texte change
    _nameController.addListener(() => provider.updateName(_nameController.text));
    _titleController.addListener(() => provider.updateTitle(_titleController.text));
    _companyController.addListener(() => provider.updateCompany(_companyController.text));
    _emailController.addListener(() => provider.updateEmail(_emailController.text));
    _phoneController.addListener(() => provider.updatePhone(_phoneController.text));
    _websiteController.addListener(() => provider.updateWebsite(_websiteController.text));
  }

  @override
  void dispose() {
    // Il est crucial de libérer les contrôleurs pour éviter les fuites de mémoire
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Ma Carte Numérique',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<BusinessCardProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCardDisplay(provider.card),
                const SizedBox(height: 24),
                const Text(
                  'Modifier les informations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Nom',
                  controller: _nameController,
                ),
                _buildTextField(
                  label: 'Titre',
                  controller: _titleController,
                ),
                _buildTextField(
                  label: 'Entreprise',
                  controller: _companyController,
                ),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                ),
                _buildTextField(
                  label: 'Téléphone',
                  controller: _phoneController,
                ),
                _buildTextField(
                  label: 'Site Web',
                  controller: _websiteController,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardDisplay(BusinessCardModel card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.title,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business, card.company),
            _buildInfoRow(Icons.email, card.email),
            _buildInfoRow(Icons.phone, card.phone),
            _buildInfoRow(Icons.public, card.website),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.deepPurple.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.deepPurple),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
