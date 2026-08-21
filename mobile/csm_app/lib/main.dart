import 'package:flutter/material.dart';

import 'features/auth/auth_session.dart';

import 'features/admin/presentation/admin_shell.dart';
import 'features/auth/presentation/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authSession = AuthSession();
  await authSession.restoreSession();

  runApp(
    CsmApp(authSession: authSession),
  );
}

class CsmApp extends StatelessWidget {
  const CsmApp({
    super.key,
    required this.authSession,
  });

  final AuthSession authSession;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HBG Construction Site Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
        ),
        useMaterial3: true,
      ),
      home: AuthGate(authSession: authSession),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authSession,
  });

  final AuthSession authSession;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authSession,
      builder: (context, _) {
        switch (authSession.status) {
          case AuthStatus.initializing:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );

          case AuthStatus.unauthenticated:
            return LoginScreen(
              authSession: authSession,
            );
            case AuthStatus.authenticated:
            final currentUser = authSession.currentUser;

            if (currentUser == null) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'Authenticated user information is unavailable.',
                  ),
                ),
              );
            }

            return AdminShell(
              userName: currentUser.name ?? 'User',
              userEmail: currentUser.email,
              roles: currentUser.roles.toSet(),
              onLogout: authSession.logout,
            );


        }
      },
    );
  }
}
