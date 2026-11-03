// test/widget_test.dart – UI smoke tests incl. responsiveness.
import 'package:flutter/material.dart';
import 'package:girl_maths/main.dart';
import 'package:girl_maths/models/expense.dart';
import 'package:girl_maths/providers/settings_provider.dart';
import 'package:girl_maths/services/local_store.dart';
import 'package:girl_maths/services/sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, {required Size size, LocalStore? store}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final settings = await SettingsProvider.create();
  final repo = SyncRepository(local: store ?? InMemoryLocalStore());
  await tester.pumpWidget(MasroufiRoot(settings: settings, repository: repo));
  await tester.pumpAndSettle();
}

const portrait = Size(400, 860);
const landscape = Size(860, 400);
const tablet = Size(1280, 800);

void main() {
  setUpAll(() async => initializeDateFormatting());

  testWidgets('app starts on the dashboard with an empty state',
      (tester) async {
    await pumpApp(tester, size: portrait);
    expect(find.text('MASROUFI 🎀'), findsOneWidget);
    expect(find.text('Monthly Girl Math Goal'), findsOneWidget);
    expect(find.textContaining('Everything was basically free'), findsOneWidget);
  });

  testWidgets('portrait uses a bottom bar, landscape uses a side rail',
      (tester) async {
    await pumpApp(tester, size: portrait);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    // "rotate" the phone
    tester.view.physicalSize = landscape * 2;
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull); // no overflow errors
  });

  testWidgets('selected tab survives rotation', (tester) async {
    await pumpApp(tester, size: portrait);
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Insights 📊'), findsOneWidget);

    tester.view.physicalSize = landscape * 2;
    await tester.pumpAndSettle();
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 2);
    expect(find.text('Monthly Insights 📊'), findsOneWidget);
  });

  testWidgets('large screens use an extended rail', (tester) async {
    await pumpApp(tester, size: tablet);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
  });

  testWidgets('add an expense through the form', (tester) async {
    await pumpApp(tester, size: portrait);
    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Log New Purchase 🛍️'), findsOneWidget);

    // validation
    await tester.ensureVisible(find.byKey(const Key('submitExpense')));
    await tester.tap(find.byKey(const Key('submitExpense')));
    await tester.pumpAndSettle();
    expect(find.text('Please tell us what you bought'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('titleField')), 'Iced latte');
    await tester.enterText(find.byKey(const Key('amountField')), '85');
    await tester.ensureVisible(find.byKey(const Key('submitExpense')));
    await tester.tap(find.byKey(const Key('submitExpense')));
    await tester.pumpAndSettle();

    expect(find.text('Log New Purchase 🛍️'), findsNothing);
    expect(find.text('Iced latte'), findsOneWidget);
  });

  testWidgets('existing expenses are listed and grouped on the Expenses tab',
      (tester) async {
    final store = InMemoryLocalStore();
    final now = DateTime.now();
    await store.upsertExpense(Expense(
        title: 'Manicure', amount: 400, date: now, categoryId: 'selfcare'));
    await pumpApp(tester, size: portrait, store: store);

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('switching to Arabic flips the layout to RTL', (tester) async {
    await pumpApp(tester, size: portrait);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    final dir = Directionality.of(tester.element(find.byType(NavigationBar)));
    expect(dir, TextDirection.rtl);
    expect(find.text('الإعدادات'), findsWidgets); // nav label
  });
}
