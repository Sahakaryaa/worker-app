import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worker_app/screens/home/home_dashboard_screen.dart';
import 'package:worker_app/screens/earnings/earnings_screen.dart';
import 'package:worker_app/screens/welfare/welfare_fund_screen.dart';
import 'package:worker_app/screens/profile/worker_profile_screen.dart';
import 'package:worker_app/screens/onboarding/worker_registration_screen.dart';

void main() {
  testWidgets('Worker Home Dashboard renders smoothly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeDashboardScreen), findsOneWidget);
    expect(find.text('Namaste, Ramesh Kumar'), findsOneWidget);
  });

  testWidgets('Worker Earnings Screen renders with chart', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: EarningsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EarningsScreen), findsOneWidget);
    expect(find.text('+82% Higher Take-Home Pay'), findsOneWidget);
  });

  testWidgets('Worker Welfare Fund Screen renders balance & ledger', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WelfareFundScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WelfareFundScreen), findsOneWidget);
    expect(find.text('100% Ring-Fenced Member Fund'), findsOneWidget);
  });

  testWidgets('Worker Profile Screen renders credentials', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WorkerProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WorkerProfileScreen), findsOneWidget);
    expect(find.text('Certified Trade Skills'), findsOneWidget);
  });

  testWidgets('Worker Registration Screen renders onboarding flow', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WorkerRegistrationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WorkerRegistrationScreen), findsOneWidget);
    expect(find.text('Join the Cooperative Federation'), findsOneWidget);
  });
}
