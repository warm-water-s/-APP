import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = await AppState.load();
  runApp(AiOutfitApp(appState: appState));
}
