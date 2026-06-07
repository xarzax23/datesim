import 'package:datesim/features/auth/presentation/email_auth_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('valida email y contraseña antes de autenticar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmailAuthSheet(
            onSignIn: (_, _) async {},
            onSignUp: (_, _) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('email-auth-sign-in')));
    await tester.pump();

    expect(find.text('Introduce un email válido.'), findsOneWidget);
    expect(find.text('Usa al menos 6 caracteres.'), findsOneWidget);
  });

  testWidgets('crea una cuenta de prueba con los datos introducidos', (
    tester,
  ) async {
    String? submittedEmail;
    String? submittedPassword;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmailAuthSheet(
            onSignIn: (_, _) async {},
            onSignUp: (email, password) async {
              submittedEmail = email;
              submittedPassword = password;
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('email-auth-email')),
      'pruebas@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('email-auth-password')),
      'datesim123',
    );
    await tester.tap(find.byKey(const Key('email-auth-sign-up')));
    await tester.pumpAndSettle();

    expect(submittedEmail, 'pruebas@example.com');
    expect(submittedPassword, 'datesim123');
  });
}
