import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.requireProdInvariants();
  final ProviderContainer container = ProviderContainer();
  await container.read(supabaseInitProvider.future);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ConnectApp(),
    ),
  );
}
