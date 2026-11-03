// lib/core/app_strings.dart
//
// Tiny, compile-checked localisation (English / Egyptian Arabic).
// Access it with `context.s` (see extension at the bottom).
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class S {
  const S(this.ar);
  final bool ar;

  String _t(String en, String arabic) => ar ? arabic : en;

  // App / navigation
  String get appName => _t('Masroufi', 'مصروفي');
  String get appTagline => _t('Girl Maths edition 🎀', 'نسخة حسابات البنات 🎀');
  String get navHome => _t('Home', 'الرئيسية');
  String get navExpenses => _t('Expenses', 'المصاريف');
  String get navInsights => _t('Insights', 'التحليلات');
  String get navGoals => _t('Goals', 'الأهداف');
  String get navSettings => _t('Settings', 'الإعدادات');

  // Home
  String greeting(String name) {
    final h = DateTime.now().hour;
    final part = h < 12
        ? _t('Good morning', 'صباح الخير')
        : h < 18
            ? _t('Good afternoon', 'مساء الخير')
            : _t('Good evening', 'مساء النور');
    return name.isEmpty ? '$part ✨' : '$part, $name ✨';
  }

  String get totalInvestments => _t("This month's 'investments'", "'استثمارات' الشهر ده");
  String get monthlyGoal => _t('Monthly Girl Math Goal', 'هدف الشهر');
  String leftForCoffee(String amount) =>
      _t('You still have $amount left for iced coffees! ☕',
          'لسه فاضلك $amount للآيس كوفي! ☕');
  String get overBudget => _t(
      "Over budget... but if you don't check, it doesn't count ✨",
      'عديتي الميزانية... بس لو مبصيتيش يبقى مش محسوب ✨');
  String get recentJustifications => _t('Recent Justifications', 'آخر التبريرات');
  String get seeAll => _t('See all', 'عرض الكل');
  String get noExpenses =>
      _t('No expenses yet!\nEverything was basically free ✨',
          'مفيش مصاريف لسه!\nكل حاجة كانت ببلاش ✨');
  String get addExpense => _t('Add Expense', 'إضافة مصروف');
  String get spendingBreakdown => _t('Spending Breakdown', 'توزيع المصاريف');
  String get quickStats => _t('Quick Girl Math', 'حسابات سريعة');
  String get todaySpent => _t('Today', 'النهارده');
  String get perDay => _t('Avg / day', 'متوسط اليوم');
  String get projected => _t('Month-end forecast', 'توقع آخر الشهر');
  String get freeLabel => _t('Basically free', 'ببلاش');
  String basicallyFree(int n) =>
      _t('$n purchases were basically free', '$n حاجات كانت ببلاش');

  // Expenses list
  String get searchHint => _t('Search purchases...', 'دوري على مشترياتك...');
  String get all => _t('All', 'الكل');
  String get deleted => _t('Expense deleted', 'تم حذف المصروف');
  String get undo => _t('Undo', 'تراجع');
  String get noResults => _t('Nothing matches your search 🔍', 'مفيش نتايج 🔍');
  String get today => _t('Today', 'النهارده');
  String get yesterday => _t('Yesterday', 'امبارح');
  String get selectExpense =>
      _t('Select an expense to see its details', 'اختاري مصروف لعرض تفاصيله');
  String get pendingSync => _t('Waiting to sync', 'في انتظار المزامنة');

  // Form
  String get logNewPurchase => _t('Log New Purchase 🛍️', 'سجلي مشترياتك 🛍️');
  String get editPurchase => _t('Edit Purchase ✏️', 'تعديل المصروف ✏️');
  String get whatDidYouBuy => _t('What did you buy?', 'اشتريتي إيه؟');
  String get titleHint => _t('e.g. Vanilla Sweet Cream Cold Brew', 'مثلاً: كولد برو فانيليا');
  String get amount => _t('Amount', 'المبلغ');
  String get justification => _t('Girl Math Justification', 'التبرير');
  String get date => _t('Date', 'التاريخ');
  String get changeDate => _t('Change Date', 'تغيير التاريخ');
  String get note => _t('Note (optional)', 'ملاحظة (اختياري)');
  String get photo => _t('Receipt / outfit photo', 'صورة الإيصال / اللبس');
  String get camera => _t('Camera', 'الكاميرا');
  String get gallery => _t('Gallery', 'المعرض');
  String get removePhoto => _t('Remove photo', 'إزالة الصورة');
  String get justifyExpense => _t('Justify Expense ✨', 'برري المصروف ✨');
  String get saveChanges => _t('Save Changes 💾', 'حفظ التعديلات 💾');
  String get errTitle => _t('Please tell us what you bought', 'اكتبي اشتريتي إيه');
  String get errAmount => _t('Enter a valid amount greater than 0', 'اكتبي مبلغ صحيح أكبر من صفر');
  String get cancel => _t('Cancel', 'إلغاء');
  String get save => _t('Save', 'حفظ');
  String get delete => _t('Delete', 'حذف');
  String get edit => _t('Edit', 'تعديل');
  String get ok => _t('Got it', 'تمام');
  String get errorTitle => _t('Girl Math Error 🎀', 'خطأ 🎀');

  // Detail
  String get expenseDetails => _t('Expense Details', 'تفاصيل المصروف');
  String get category => _t('Category', 'الفئة');
  String get deleteConfirm => _t('Delete this expense?', 'تحذفي المصروف ده؟');
  String get deleteConfirmBody =>
      _t('If you delete it, it never happened 💅', 'لو اتمسح يبقى محصلش 💅');
  String costPerWear(String perWear) =>
      _t('Wear it 30 times → only $perWear per wear!',
          'لو لبستيه ٣٠ مرة → $perWear بس للمرة!');

  // Insights
  String get insights => _t('Monthly Insights 📊', 'تحليلات الشهر 📊');
  String get byCategory => _t('By category', 'حسب الفئة');
  String get dailySpending => _t('Daily spending', 'المصروف اليومي');
  String get last6Months => _t('Last 6 months', 'آخر ٦ شهور');
  String get byWeekday => _t('By weekday', 'حسب أيام الأسبوع');
  String get trends => _t('Your trends ✨', 'اتجاهاتك ✨');
  String get noDataMonth =>
      _t('Spend some money to see the charts! ✨', 'اصرفي شوية عشان تشوفي الرسومات! ✨');
  String vsLastMonth(String pct, bool up) => up
      ? _t('$pct more than last month', '$pct أكتر من الشهر اللي فات')
      : _t('$pct less than last month', '$pct أقل من الشهر اللي فات');
  String get noLastMonth =>
      _t('No data for last month to compare', 'مفيش بيانات للشهر اللي فات');
  String topCategory(String cat) =>
      _t('Most of your money went to $cat', 'أغلب فلوسك راحت على $cat');
  String busiestDay(String day) =>
      _t('You spend the most on ${day}s', 'أكتر يوم بتصرفي فيه: $day');
  String biggest(String title, String amount) =>
      _t('Biggest investment: $title ($amount)', 'أكبر استثمار: $title ($amount)');
  String projectionOver(String amount) =>
      _t('At this pace you will pass your budget by $amount',
          'بالمعدل ده هتعدي الميزانية بـ $amount');
  String projectionUnder(String amount) =>
      _t('At this pace you will save $amount this month 🎉',
          'بالمعدل ده هتوفري $amount الشهر ده 🎉');
  String get transactions => _t('purchases', 'عملية');

  // Goals
  String get goalsTitle => _t('Goals 🎯', 'الأهداف 🎯');
  String get monthlyBudget => _t('Monthly budget', 'ميزانية الشهر');
  String get editBudget => _t('Edit budget', 'تعديل الميزانية');
  String get wishlist => _t('Wishlist savings', 'التحويش للأمنيات');
  String get addGoal => _t('New goal', 'هدف جديد');
  String get editGoal => _t('Edit goal', 'تعديل الهدف');
  String get goalTitle => _t('What are you saving for?', 'بتحوشي لإيه؟');
  String get goalTitleHint => _t('e.g. That bag 👜', 'مثلاً: الشنطة دي 👜');
  String get targetAmount => _t('Target amount', 'المبلغ المطلوب');
  String get deadline => _t('Deadline (optional)', 'الموعد (اختياري)');
  String get noDeadline => _t('No deadline', 'من غير موعد');
  String get addMoney => _t('Add money', 'إضافة فلوس');
  String get howMuchSaved => _t('How much did you save?', 'حوشتي قد إيه؟');
  String get noGoals =>
      _t('No wishlist goals yet.\nWhat are we manifesting? ✨',
          'مفيش أهداف لسه.\nنفسك في إيه؟ ✨');
  String saved(String saved, String target) =>
      _t('$saved of $target', '$saved من $target');
  String perDayToGoal(String amount) =>
      _t('Save $amount/day to make it on time', 'حوشي $amount في اليوم عشان تلحقي');
  String dailyAllowance(String amount, int days) =>
      _t('You can spend $amount/day for the next $days day(s) and stay on budget',
          'تقدري تصرفي $amount في اليوم لمدة $days يوم وتفضلي في الميزانية');
  String get goalReached => _t('Goal reached! Treat yourself 🎉', 'وصلتي للهدف! 🎉');
  String get emoji => _t('Emoji', 'إيموجي');

  // Settings
  String get settingsTitle => _t('Settings 💅', 'الإعدادات 💅');
  String get profile => _t('Profile', 'الملف الشخصي');
  String get yourName => _t('Your name', 'اسمك');
  String get mainCharacter => _t('Main Character', 'البطلة');
  String get changePhoto => _t('Change photo', 'تغيير الصورة');
  String get appearance => _t('Appearance', 'المظهر');
  String get theme => _t('Theme', 'الثيم');
  String get themeSystem => _t('System', 'النظام');
  String get themeLight => _t('Light', 'فاتح');
  String get themeDark => _t('Midnight 🌙', 'ليلي 🌙');
  String get language => _t('Language', 'اللغة');
  String get currency => _t('Currency', 'العملة');
  String get girlMath => _t('Girl Math rules', 'قواعد حسابات البنات');
  String get freeThreshold => _t('"Basically free" under', '"ببلاش" لو أقل من');
  String get freeThresholdHelp =>
      _t('Purchases under this amount count as basically free',
          'أي حاجة أقل من المبلغ ده تتحسب ببلاش');
  String get cloud => _t('Cloud backup (Firebase)', 'النسخ السحابي (Firebase)');
  String get syncNow => _t('Sync now', 'مزامنة الآن');
  String get syncing => _t('Syncing...', 'جاري المزامنة...');
  String get notConfigured =>
      _t('Add FIREBASE_DB_URL to .env to enable cloud backup',
          'أضيفي FIREBASE_DB_URL في ملف .env لتفعيل النسخ السحابي');
  String lastSynced(String when) => _t('Last synced: $when', 'آخر مزامنة: $when');
  String get neverSynced => _t('Not synced yet', 'لسه متزامنش');
  String pendingChanges(int n) =>
      _t('$n change(s) waiting to upload', '$n تغيير في انتظار الرفع');
  String get offline =>
      _t('Offline – showing cached data', 'مفيش إنترنت – بنعرض البيانات المحفوظة');
  String get syncDone => _t('All synced ☁️', 'تمت المزامنة ☁️');
  String get dangerZone => _t('Danger zone', 'منطقة الخطر');
  String get clearData => _t('Delete all local data', 'حذف كل البيانات المحلية');
  String get clearDataConfirm =>
      _t('This deletes every expense and goal on this device. Continue?',
          'ده هيمسح كل المصاريف والأهداف من الجهاز. تكملي؟');
  String get about => _t('About', 'عن التطبيق');
  String get aboutBody => _t(
      'Masroufi – CSEN 1114 Assignment.\nTrack expenses, see trends and set goals… girl math style.',
      'مصروفي – واجب CSEN 1114.\nتابعي مصاريفك وشوفي اتجاهاتك وحطي أهدافك… بحسابات البنات.');

  List<String> get weekdays => ar
      ? ['الاتنين', 'التلات', 'الأربع', 'الخميس', 'الجمعة', 'السبت', 'الحد']
      : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  List<String> get weekdaysShort => ar
      ? ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']
      : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
}

extension StringsX on BuildContext {
  /// Localised strings that rebuild when the language changes.
  S get s => S(watch<SettingsProvider>().isArabic);

  /// Same, without listening (for callbacks).
  S get sRead => S(read<SettingsProvider>().isArabic);
}
