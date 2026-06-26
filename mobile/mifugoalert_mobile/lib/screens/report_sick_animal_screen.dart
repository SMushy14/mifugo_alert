import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'case_widgets.dart';
import 'farmer_widgets.dart';

class ReportSickAnimalScreen extends StatefulWidget {
  const ReportSickAnimalScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.farmerArea,
    this.onOpenTab,
    this.onOpenMenu,
  });

  final String farmerId;
  final String farmerName;
  final String farmerArea;
  final void Function(int)? onOpenTab;
  final VoidCallback? onOpenMenu;

  @override
  State<ReportSickAnimalScreen> createState() => _ReportSickAnimalScreenState();
}

class _ReportSickAnimalScreenState extends State<ReportSickAnimalScreen> {
  static const _animalTypes = ['Cattle', 'Goat', 'Poultry', 'Sheep', 'Pig'];
  static const _symptomOptions = [
    'Fever',
    'Loss of appetite',
    'Diarrhea',
    'Coughing',
    'Lameness',
    'Nasal discharge',
    'Sudden death',
    'Swelling',
  ];

  String _animalType = 'Cattle';
  int _count = 1;
  final Set<String> _symptoms = {};
  final _detailsController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    _countController.dispose();
    super.dispose();
  }

  String _generateCaseCode() =>
      'MA-${1000 + DateTime.now().millisecondsSinceEpoch % 9000}';

  Future<void> _submit() async {
    if (_symptoms.isEmpty) {
      _snack('Please select at least one symptom');
      return;
    }
    setState(() => _submitting = true);
    try {
      final caseCode = _generateCaseCode();
      final priority = _symptoms.contains('Sudden death')
          ? 'emergency'
          : 'normal';

      final assign = await autoAssignVet(widget.farmerArea);

      await FirebaseFirestore.instance.collection('cases').doc(caseCode).set({
        'caseCode': caseCode,
        'farmerId': widget.farmerId,
        'farmerName': widget.farmerName,
        'area': widget.farmerArea,
        'species': _animalType,
        'symptom': _symptoms.join(', '),
        'symptoms': _symptoms.toList(),
        'count': _count,
        'details': _detailsController.text.trim(),
        'source': 'mobile_app',
        'status': assign['assignedVetId'] == null ? 'pending' : 'assigned',
        'assignedVetId': assign['assignedVetId'],
        'assignedVetName': assign['assignedVetName'],
        'priority': priority,
        'createdAt': Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('activities').add({
        'userId': widget.farmerId,
        'type': 'app_submission',
        'title': 'Submitted case $caseCode ($_animalType)',
        'source': 'Mobile App',
        'channel': 'app',
        'createdAt': Timestamp.now(),
      });

      notifyAssignment(
        caseCode: caseCode,
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
        vetId: assign['assignedVetId'],
        vetName: assign['assignedVetName'],
        vetPhone: assign['assignedVetPhone'],
      );

      if (!mounted) return;
      _snack('Report submitted — case $caseCode created');
      setState(() {
        _symptoms.clear();
        _detailsController.clear();
        _countController.text = '1';
        _count = 1;
        _animalType = 'Cattle';
      });
    } catch (e) {
      if (mounted) _snack('Could not submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            farmerTopBar(
              widget.farmerName,
              farmerId: widget.farmerId,
              onBell: () => widget.onOpenTab?.call(5),
              onMenu: () => widget.onOpenMenu?.call(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report a sick animal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'A case will be created and assigned to a vet.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formCard() => Container(
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
        _label('Animal type'),
        _dropdown(),
        const SizedBox(height: 16),
        _label('Number of affected animals'),
        _numberField(),
        const SizedBox(height: 16),
        _label('Symptoms'),
        _symptomChips(),
        const SizedBox(height: 16),
        _label('Additional details'),
        _detailsField(),
        const SizedBox(height: 20),
        _submitButton(),
      ],
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _dropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.primaryTint.withOpacity(0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _animalType,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        items: _animalTypes
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
        onChanged: (v) => setState(() => _animalType = v ?? _animalType),
      ),
    ),
  );

  Widget _numberField() => TextField(
    controller: _countController,
    keyboardType: TextInputType.number,
    onChanged: (v) => _count = int.tryParse(v) ?? 1,
    decoration: InputDecoration(
      filled: true,
      fillColor: AppColors.primaryTint.withOpacity(0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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

  Widget _symptomChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _symptomOptions.map((s) {
      final selected = _symptoms.contains(s);
      final isEmergency = s == 'Sudden death';
      final selFg = isEmergency ? AppColors.maroon : AppColors.primary;
      final selBg = isEmergency ? AppColors.maroonTint : AppColors.primaryTint;
      return GestureDetector(
        onTap: () => setState(() {
          if (selected) {
            _symptoms.remove(s);
          } else {
            _symptoms.add(s);
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selBg : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? selFg : AppColors.border),
          ),
          child: Text(
            s,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? selFg : AppColors.textPrimary,
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _detailsField() => TextField(
    controller: _detailsController,
    maxLines: 5,
    decoration: InputDecoration(
      hintText: "Describe what you've observed...",
      filled: true,
      fillColor: AppColors.primaryTint.withOpacity(0.4),
      contentPadding: const EdgeInsets.all(14),
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

  Widget _submitButton() => SizedBox(
    width: double.infinity,
    height: 54,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: _submitting ? null : AppColors.heroGradient,
        color: _submitting ? AppColors.textSecondary : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _submitting
            ? null
            : [
                BoxShadow(
                  color: AppColors.deepGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox.shrink()
            : const Icon(Icons.send_rounded, size: 18),
        label: _submitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit report',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
  );
}
