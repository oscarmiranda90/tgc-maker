class TgcShaders {
  static const holographic = 'assets/shaders/holographic.frag';
  static const sparkle = 'assets/shaders/sparkle.frag';
  static const pixelFoil = 'assets/shaders/pixel_foil.frag';
  static const rainbowFoil = 'assets/shaders/rainbow_foil.frag';
  static const oilSlick = 'assets/shaders/oil_slick.frag';
  static const sequins = 'assets/shaders/sequins.frag';

  static const all = [
    holographic,
    sparkle,
    pixelFoil,
    rainbowFoil,
    oilSlick,
    sequins,
  ];

  static const labels = [
    'Holographic',
    'Sparkle',
    'Pixel Foil',
    'Rainbow Foil',
    'Oil Slick',
    'Sequins',
  ];

  static String labelFor(String asset) {
    final i = all.indexOf(asset);
    return i >= 0 ? labels[i] : asset;
  }
}
