enum LayerGroup {
  background,
  art,
  layout;

  String get label {
    switch (this) {
      case LayerGroup.background:
        return 'BACKGROUND';
      case LayerGroup.art:
        return 'ART';
      case LayerGroup.layout:
        return 'LAYOUT';
    }
  }
}
