import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

const Map<String, IconData> kSpeciesIcons = {
  'Cattle': Icons.agriculture,
  'Goat': Icons.cruelty_free,
  'Poultry': Icons.egg,
  'Sheep': Icons.cloud,
  'Pig': Icons.savings,
};

IconData iconForSpecies(String species) => kSpeciesIcons[species] ?? Icons.pets;

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key, required this.farmerId});
  final String farmerId;
  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _name = TextEditingController();
  final _tag = TextEditingController();
  final _breed = TextEditingController();
  final _age = TextEditingController();
  String _species = 'Cattle';
  String _sex = 'F';
  String _status = 'healthy';
  bool _saving = false;

  static const _speciesOptions = ['Cattle', 'Goat', 'Poultry', 'Sheep', 'Pig'];
  static const _statusOptions = ['healthy', 'sick', 'vaccinated', 'recovering'];

  @override
  void dispose() {
    _name.dispose();
    _tag.dispose();
    _breed.dispose();
    _age.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    final name = _name.text.trim();
    final tag = _tag.text.trim();
    if (name.isEmpty || tag.isEmpty) {
      _snack('Enter at least a name and tag ID');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('animals')
          .doc('${widget.farmerId}_$tag')
          .set({
            'ownerId': widget.farmerId,
            'tagId': tag,
            'name': name,
            'species': _species,
            'breed': _breed.text.trim().isEmpty ? '—' : _breed.text.trim(),
            'sex': _sex,
            'age': _age.text.trim().isEmpty ? '—' : _age.text.trim(),
            'status': _status,
            'lastCheckup': Timestamp.now(),
          });
      if (!mounted) return;
      _snack('Animal added');
      Navigator.pop(context);
    } catch (e) {
      _snack('Could not add: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final topInset = MediaQuery.of(context).padding.top;
              return Container(
                padding: EdgeInsets.fromLTRB(8, topInset + 8, 16, 14),
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text(
                      'Add animal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            iconForSpecies(_species),
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _label('Name'),
                      _field(_name, 'e.g. Daisy'),
                      const SizedBox(height: 14),
                      _label('Tag ID'),
                      _field(_tag, 'e.g. TZ-001'),
                      const SizedBox(height: 14),
                      _label('Species'),
                      _speciesDropdown(),
                      const SizedBox(height: 14),
                      _label('Breed'),
                      _field(_breed, 'e.g. Friesian'),
                      const SizedBox(height: 14),
                      _label('Sex'),
                      _dropdown(_sex, const [
                        'F',
                        'M',
                      ], (v) => setState(() => _sex = v)),
                      const SizedBox(height: 14),
                      _label('Age'),
                      _field(_age, 'e.g. 3y'),
                      const SizedBox(height: 14),
                      _label('Status'),
                      _dropdown(
                        _status,
                        _statusOptions,
                        (v) => setState(() => _status = v),
                      ),
                      const SizedBox(height: 20),
                      _saveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: _saving ? null : AppColors.heroGradient,
        color: _saving ? AppColors.textSecondary : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _saving
            ? null
            : [
                BoxShadow(
                  color: AppColors.deepGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _saving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Save animal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _field(TextEditingController c, String hint) => TextField(
    controller: c,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.primaryTint.withOpacity(0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );

  Widget _speciesDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.primaryTint.withOpacity(0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _species,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        items: _speciesOptions
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Row(
                  children: [
                    Icon(iconForSpecies(e), size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(e),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _species = v ?? _species),
      ),
    ),
  );

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.primaryTint.withOpacity(0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    ),
  );
}
