import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tgc_maker/tgc_maker.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TGC Maker Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final EditorModel _editorModel = EditorModel();
  CardDocument? _document;
  String? _migratedFromVersion;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _editorModel.loadShaders();
    _editorModel.loadFonts();
    _loadBundledCard();
  }

  Future<void> _loadBundledCard() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/integrator_sample_card.json',
      );
      final result = await CardDocumentCodec.migrateAndDecode(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        _document = result.decoded.document;
        _migratedFromVersion = result.migratedFromVersion;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _editorModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TGC Maker Package Example'),
        actions: [
          IconButton(
            tooltip: 'Reload from JSON',
            onPressed: _loadBundledCard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: _editorModel,
          builder: (context, _) {
            if (_loadError != null) {
              return _ErrorBlock(message: '$_loadError');
            }
            final doc = _document;
            if (doc == null) {
              return const CircularProgressIndicator();
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CardPreviewWidget(
                  document: doc,
                  shaderPrograms: _editorModel.shaders,
                  maxWidth: 320,
                  maxHeight: 450,
                ),
                const SizedBox(height: 16),
                Text(
                  'schemaVersion: ${CardDocumentCodec.currentSchemaVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_migratedFromVersion != null)
                  Text(
                    'migrated from: $_migratedFromVersion',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  const _ErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Failed to load card: $message',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
