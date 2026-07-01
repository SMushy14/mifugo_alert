import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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

  File? _photo;

  @override
  void dispose() {
    _detailsController.dispose();
    _countController.dispose();
    super.dispose();
  }

  String _generateCaseCode() =>
      'MA-${1000 + DateTime.now().millisecondsSinceEpoch % 9000}';

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() => _photo = File(picked.path));
      }
    } catch (e) {
      _snack('Could not pick image: $e');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.goldDark,
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.maroon,
                ),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photo = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadPhoto(String caseCode) async {
    if (_photo == null) return null;
    try {
      final supabase = Supabase.instance.client;
      final safe = caseCode.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
      final path = '$safe.jpg';

      await supabase.storage
          .from('disease-case_photos')
          .upload(
            path,
            _photo!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return supabase.storage.from('disease-case_photos').getPublicUrl(path);
    } catch (e) {
      _snack('Upload error: $e');
      return null;
    }
  }

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

      final photoUrl = await _uploadPhoto(caseCode);

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
        'photoUrl': photoUrl,
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
        _photo = null;
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          farmerTopBar(
            widget.farmerName,
            farmerId: widget.farmerId,
            onBell: () => widget.onOpenTab?.call(5),
            onMenu: () => widget.onOpenMenu?.call(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
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
          ),
        ],
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
        _label('Photo (optional)'),
        _photoPicker(),
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

  Widget _photoPicker() {
    if (_photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _photo!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _photoActionBtn(Icons.edit, _showPhotoOptions),
                const SizedBox(width: 8),
                _photoActionBtn(
                  Icons.close,
                  () => setState(() => _photo = null),
                  bg: AppColors.maroon,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.primaryTint.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
              size: 30,
            ),
            SizedBox(height: 8),
            Text(
              'Add a photo of the animal',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Camera or gallery',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoActionBtn(
    IconData icon,
    VoidCallback onTap, {
    Color bg = Colors.black54,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

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
