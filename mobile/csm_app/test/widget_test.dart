import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:csm_app/features/auth/auth_session.dart';
import 'package:csm_app/main.dart';

void main() {
  testWidgets('CSM application shell initializes', (tester) async {
    final authSession = AuthSession();

    await tester.pumpWidget(
      CsmApp(authSession: authSession),
    );

    expect(
      authSession.status,
      AuthStatus.initializing,
    );

    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
    );
  });
}

