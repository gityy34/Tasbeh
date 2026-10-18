/// Verified, short Tasbeeh phrases shown by the in-app picker.
///
/// Arabic is kept as real RTL text so Flutter can shape it with the device's
/// Arabic-capable font fallback instead of relying on text baked into images.
class TasbeehPreset {
  const TasbeehPreset({
    required this.id,
    required this.label,
    required this.arabicText,
  });

  final String id;
  final String label;
  final String arabicText;
}

const bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
const defaultTasbeehId = 'bismillah';

const tasbeehPresets = <TasbeehPreset>[
  TasbeehPreset(
    id: defaultTasbeehId,
    label: 'Bismillah',
    arabicText: bismillah,
  ),
  TasbeehPreset(
    id: 'allahu-akbar',
    label: 'Allahu Akbar',
    arabicText: 'ٱللَّهُ أَكْبَرُ',
  ),
  TasbeehPreset(
    id: 'subhanallah',
    label: 'SubhanAllah',
    arabicText: 'سُبْحَانَ ٱللَّهِ',
  ),
  TasbeehPreset(
    id: 'alhamdulillah',
    label: 'Alhamdulillah',
    arabicText: 'ٱلْحَمْدُ لِلَّهِ',
  ),
  TasbeehPreset(
    id: 'la-ilaha-illa-anta',
    label: 'La ilaha illa anta',
    arabicText: 'لَا إِلَٰهَ إِلَّا أَنْتَ',
  ),
  TasbeehPreset(
    id: 'subhanaka-inni-kuntu',
    label: 'Subhanaka inni kuntu minaz-zalimin',
    arabicText: 'سُبْحَانَكَ إِنِّي كُنْتُ مِنَ ٱلظَّالِمِينَ',
  ),
  TasbeehPreset(
    id: 'la-ilaha-illallah',
    label: 'La ilaha illallah',
    arabicText: 'لَا إِلَٰهَ إِلَّا ٱللَّهُ',
  ),
  TasbeehPreset(
    id: 'muhammadur-rasulullah',
    label: 'Muhammadur Rasulullah',
    arabicText: 'مُحَمَّدٌ رَسُولُ ٱللَّهِ',
  ),
  TasbeehPreset(
    id: 'astaghfirullah',
    label: 'Astaghfirullah',
    arabicText: 'أَسْتَغْفِرُ ٱللَّهَ',
  ),
  TasbeehPreset(
    id: 'la-hawla',
    label: 'La hawla wa la quwwata illa billah',
    arabicText: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ',
  ),
];

TasbeehPreset tasbeehPresetForId(String id) {
  for (final preset in tasbeehPresets) {
    if (preset.id == id) return preset;
  }
  return tasbeehPresets.first;
}
