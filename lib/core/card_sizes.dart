enum CardSizePreset { standard, japanese, custom }

class CardSize {
  final double widthPx;
  final double heightPx;
  final CardSizePreset preset;
  final String label;

  const CardSize({
    required this.widthPx,
    required this.heightPx,
    required this.preset,
    required this.label,
  });

  double get aspectRatio => widthPx / heightPx;

  static const standard = CardSize(
    widthPx: 750,
    heightPx: 1050,
    preset: CardSizePreset.standard,
    label: 'Standard',
  );

  static const japanese = CardSize(
    widthPx: 700,
    heightPx: 1015,
    preset: CardSizePreset.japanese,
    label: 'Japanese',
  );

  static CardSize custom(double w, double h) => CardSize(
        widthPx: w,
        heightPx: h,
        preset: CardSizePreset.custom,
        label: 'Custom',
      );

  @override
  bool operator ==(Object other) =>
      other is CardSize && widthPx == other.widthPx && heightPx == other.heightPx;

  @override
  int get hashCode => Object.hash(widthPx, heightPx);
}
