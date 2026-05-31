import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/core/theme.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/screens/home_screen.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/state/editor_model.dart';

class TgcMakerApp extends StatefulWidget {
  const TgcMakerApp({super.key});

  @override
  State<TgcMakerApp> createState() => _TgcMakerAppState();
}

class _TgcMakerAppState extends State<TgcMakerApp> {
  late final CardModel _cardModel;
  late final EditorModel _editorModel;

  @override
  void initState() {
    super.initState();
    _cardModel = CardModel(CardDocument.blank(size: CardSize.standard));
    _editorModel = EditorModel();
    // Load shaders once at boot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editorModel.loadShaders();
      _editorModel.loadFonts();
    });
  }

  @override
  void dispose() {
    _cardModel.dispose();
    _editorModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _cardModel),
        ChangeNotifierProvider.value(value: _editorModel),
      ],
      child: MaterialApp(
        title: 'TGC Maker',
        theme: TgcTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
