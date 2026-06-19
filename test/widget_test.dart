import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vault/main.dart';
import 'package:vault/services/auth_service.dart';

class FakeAuthService extends AuthService {
  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);
}

void main() {
  testWidgets('Vault app renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(VaultApp(authService: FakeAuthService()));
    await tester.pump();

    expect(find.text('VAULT'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
