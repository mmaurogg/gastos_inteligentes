import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos_inteligentes/providers/debt_provider.dart';
import 'package:gastos_inteligentes/screens/add_debt_screen.dart';
import 'package:gastos_inteligentes/models/debt/debt.dart';

// Fake implementation to avoid Mockito complexity
class FakeDebtProvider extends DebtProvider {
  bool addDebtCalled = false;
  bool updateDebtCalled = false;

  @override
  Future<void> addDebt(Debt debt) async {
    addDebtCalled = true;
  }

  @override
  Future<void> updateDebt(Debt debt) async {
    updateDebtCalled = true;
  }

  @override
  Future<void> loadDebts() async {}
}

void main() {
  testWidgets('AddDebtWidget renders and validates form', (
    WidgetTester tester,
  ) async {
    final fakeDebtProvider = FakeDebtProvider();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [debtProvider.overrideWith((ref) => fakeDebtProvider)],
        child: const MaterialApp(home: AddDebtScreen()),
      ),
    );

    // Verify UI elements
    expect(find.text('Agregar Cuentas por Pagar'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Name, Interest

    // Check for dropdown icons existence
    expect(find.byIcon(Icons.date_range), findsOneWidget);
    expect(find.byIcon(Icons.event), findsOneWidget);

    // Try to save without input (should fail validation)
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Por favor ingresa un nombre'), findsOneWidget);

    // Enter valid data
    // Use widgetWithIcon to find the specific TextField associated with the Icon
    await tester.enterText(
      find.widgetWithIcon(TextFormField, Icons.credit_card),
      'New Debt',
    );
    await tester.enterText(
      find.widgetWithIcon(TextFormField, Icons.percent),
      '5',
    );

    // Tap save
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // Verify addDebt method was called on the fake provider
    expect(fakeDebtProvider.addDebtCalled, isTrue);
  });
}
