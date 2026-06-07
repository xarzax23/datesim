import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseInitError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (firebaseAuthEmulatorEnabled) {
      await FirebaseAuth.instance.useAuthEmulator(
        firebaseAuthEmulatorHost,
        firebaseAuthEmulatorPort,
      );
    }
  } catch (e) {
    firebaseInitError = e.toString();
  }

  runApp(
    ProviderScope(child: DateSimApp(firebaseInitError: firebaseInitError)),
  );
}

class DateSimApp extends ConsumerWidget {
  final String? firebaseInitError;

  const DateSimApp({super.key, this.firebaseInitError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (firebaseInitError != null) {
      return MaterialApp(
        title: 'DateSim',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: _FirebaseConfigErrorScreen(errorMessage: firebaseInitError!),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'DateSim',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _FirebaseConfigErrorScreen extends StatelessWidget {
  final String errorMessage;

  const _FirebaseConfigErrorScreen({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo inicializar Firebase',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Configura Firebase para continuar. Ejecuta flutterfire configure y vuelve a iniciar la app.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
