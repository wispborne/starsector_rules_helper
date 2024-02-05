import 'dart:async';
import 'dart:io';

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starsector_rules_helper/poller.dart';
import 'package:starsector_rules_helper/utils.dart';
import 'package:window_size/window_size.dart';

const version = "1.0.0";
const appTitle = "Rules Reloader v$version";
const appSubtitle = "by Wisp";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Size size = await DesktopWindow.getWindowSize();
  const height = 350.0;
  const width = (4 / 3) * height;
  DesktopWindow.setWindowSize(const Size(width, height));
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
      home: const MyHomePage(title: appTitle, subtitle: appSubtitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _modsBeingWatched = 0;

  late SharedPreferences _prefs;
  Directory? gamePath = defaultGamePath();
  Directory? gameFiles = null;
  File? vanillaRulesCsv = null;
  Directory? modsFolder = null;
  List<File> modRulesCsvs = [];
  final gamePathTextController = TextEditingController();
  String? pathError;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      setState(() {
        gamePath =
            Directory(_prefs.getString('gamePath') ?? defaultGamePath()!.path);
        if (!gamePath!.existsSync()) {
          gamePath = Directory(defaultGamePath()!.path);
        }
      });
      _updatePaths();
    });
  }

  _do() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      gamePath =
          // Directory(_prefs.getString('gamePath') ?? defaultGamePath()!.path);
          Directory(defaultGamePath()!.path);
    });
    _updatePaths();
  }

  _saveVanillaRulesCsv() {
    vanillaRulesCsv?.setLastModified(DateTime.now());

    setState(() {
      _counter++;
    });
  }

  _updatePaths() {
    setState(() {
      gameFiles = gameFilesPath(gamePath!)!;
      vanillaRulesCsv = getVanillaRulesCsvInGameFiles(gameFiles!);
      modsFolder = modFolderPath(gamePath!)!;
      modRulesCsvs = getAllRulesCsvsInModsFolder(modsFolder!);

      gamePathTextController.text = gamePath!.path;
      _modsBeingWatched = modRulesCsvs.length;
    });

    fileChanges.close();
    fileChanges = StreamController();

    fileChanges.stream.listen((event) {
      _saveVanillaRulesCsv();
    });

    for (var element in modRulesCsvs) {
      pollFileForModification(element, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          Text(widget.subtitle, style: Theme.of(context).textTheme.bodyMedium)
        ]),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              RichText(
                text: TextSpan(
                  text: 'Watching ',
                  children: [
                    TextSpan(
                      text: '$_modsBeingWatched',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' rules.csv files for changes.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vanilla rules.csv auto-reloaded',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Text(
                'times',
              ),
              const Spacer(),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: gamePathTextController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Starsector Folder',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: OutlinedButton(
                          onPressed: () {
                            if (!Directory(gamePathTextController.text)
                                .existsSync()) {
                              setState(() {
                                pathError = "Invalid path";
                              });
                              return;
                            }
                            setState(() {
                              pathError = null;
                            });
                            _prefs.setString(
                                'gamePath', gamePathTextController.text);
                            setState(() {
                              gamePath = Directory(gamePathTextController.text);
                            });
                            _updatePaths();
                          },
                          child: const Text('Set'),
                        ),
                      ),
                    ],
                  ),
                  if (pathError != null)
                    Text(
                      pathError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
