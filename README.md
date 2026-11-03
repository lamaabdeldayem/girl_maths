# Masroufi – Girl Maths edition 🎀
CSEN 1114 – Lab 2 (all 4 phases). A Flutter expense tracker that tracks
spending across days and months, shows trends and lets you set goals – with
girl-math justifications.

* **Phase 1** – requirements, data model, wireframes → [`docs/PHASE1_PLANNING.md`](docs/PHASE1_PLANNING.md)
* **Phase 2** – development & testing → `lib/`, `test/`
* **Phase 3** – 5 screens with navigation, monthly summaries, charts & trends,
  SharedPreferences settings (dark mode, language, currency…), images
* **Phase 4** – Providers, Firebase Realtime Database backend, caching
* **Extra** – fully responsive (portrait / landscape / tablet / desktop), Arabic + RTL,
  wishlist savings goals, receipt photos, undo delete, offline sync queue

## Run it

```bash
flutter pub get
flutter run          # phone, emulator, desktop
flutter test         # unit + widget tests
```

The app works **offline out of the box** (SQLite cache). To turn on the cloud
backup:

1. Firebase console → *Build → Realtime Database → Create database* (test mode).
2. Copy the database URL into `.env`:
   ```
   FIREBASE_DB_URL=https://<your-project>-default-rtdb.firebaseio.com
   ```
3. Restart the app. The cloud icon in the app bar shows the sync state
   (green = synced, orange = changes waiting, red = offline).

Test-mode rules for the lab:
```json
{ "rules": { ".read": true, ".write": true } }
```

## Project structure

```
lib/
  main.dart                  loads .env + prefs, wires the providers (MultiProvider)
  app.dart                   MaterialApp: themes, locale/RTL, named routes
  core/                      theme, strings (EN/AR), formatters, responsive breakpoints
  models/                    Expense, ExpenseCategory, SavingsGoal, MonthlySummary
  providers/                 ExpenseProvider, GoalsProvider, SettingsProvider
  services/                  DatabaseHelper (SQLite), FirebaseService (REST),
                             SyncRepository (cache-first sync), ImageStorage
  screens/                   main_navigation (responsive shell), home, expenses,
                             expense_detail, insights, goals, settings, about
  widgets/                   expense form, tiles, dashboard cards, charts, common
assets/images/               logo, avatar and empty-state illustrations
docs/                        Phase 1 document, diagrams, wireframes
test/                        models, analytics, repository (mock HTTP), widgets
```

## Responsiveness

| Window | Navigation | Layout |
|--------|-----------|--------|
| phone portrait (< 600 px) | bottom `NavigationBar` | one column, form in a bottom sheet |
| phone landscape / 600–1023 px | `NavigationRail` | dashboard + list side by side, 2-column charts/grids, form as a 2-column dialog, details split in two |
| ≥ 1024 px | extended `NavigationRail` | up to 3 columns, master/detail on the Expenses tab |

Rotating keeps the current tab, month, search text and filters
(`IndexedStack` with a `GlobalKey` + UI state in the provider).
