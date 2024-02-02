import 'dart:io';

import 'package:flutter/material.dart';
import 'package:starsector_rules_helper/poller.dart';
import 'package:starsector_rules_helper/utils.dart';
import 'package:window_size/window_size.dart';

const version = "0.0.1";
const appTitle = "Rules Helper v$version";

void main() {
  runApp(const MyApp());
  setWindowTitle(appTitle);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _modsBeingWatched = 0;

  late Directory gamePath;
  late Directory gameFiles;
  late File vanillaRulesCsv;
  late Directory modsFolder;
  late List<File> modRulesCsvs;

  @override
  void initState() {
    super.initState();

    gamePath = defaultGamePath()!;
    gameFiles = gameFilesPath(gamePath)!;
    vanillaRulesCsv = getVanillaRulesCsvInGameFiles(gameFiles);
    modsFolder = modFolderPath(gamePath)!;
    modRulesCsvs = getAllRulesCsvsInModsFolder(modsFolder);

    _modsBeingWatched = modRulesCsvs.length;

    for (var element in modRulesCsvs) {
      pollFileForModification(element, 1).listen((event) {
        _saveVanillaRulesCsv();
      });
    }
  }

  _saveVanillaRulesCsv() {
    vanillaRulesCsv.setLastModified(DateTime.now());

    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Watching $_modsBeingWatched rules.csv files.',
            ),
            const SizedBox(height: 20),
            const Text(
              'Vanilla rules.csv updated this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
