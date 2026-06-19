import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/revenuecat_service.dart';
import 'firebase_options.dart';
export 'app.dart' show VaultApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseAvailable = _isFirebaseAuthSupported;
  if (firebaseAvailable) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await RevenueCatService.instance.prepareForStartup();

  runApp(VaultApp(firebaseAvailable: firebaseAvailable));
}

bool get _isFirebaseAuthSupported {
  if (kIsWeb) return true;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    TargetPlatform.linux || TargetPlatform.fuchsia => false,
  };
}
