const List<String> tanzaniaRegions = [
  'Arusha',
  'Dar es Salaam',
  'Dodoma',
  'Geita',
  'Iringa',
  'Kagera',
  'Kaskazini Pemba',
  'Kaskazini Unguja',
  'Katavi',
  'Kigoma',
  'Kilimanjaro',
  'Kusini Pemba',
  'Kusini Unguja',
  'Lindi',
  'Manyara',
  'Mara',
  'Mbeya',
  'Mjini Magharibi',
  'Morogoro',
  'Mtwara',
  'Mwanza',
  'Njombe',
  'Pwani',
  'Rukwa',
  'Ruvuma',
  'Shinyanga',
  'Simiyu',
  'Singida',
  'Songwe',
  'Tabora',
  'Tanga',
];

bool isValidTanzanianPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return RegExp(r'^[67]\d{8}$').hasMatch(digits);
}

String formatTanzanianPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '+255 ';
  if (digits.length <= 3) return '+255 $digits';
  if (digits.length <= 6)
    return '+255 ${digits.substring(0, 3)} ${digits.substring(3)}';
  return '+255 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
}

String cleanTanzanianPhone(String phone) {
  return phone.replaceAll(RegExp(r'[^0-9]'), '');
}
