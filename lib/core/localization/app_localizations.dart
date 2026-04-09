import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../utils/formatters.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  bool get isArabic => locale.languageCode.toLowerCase() == 'ar';

  static AppLocalizations of(BuildContext context) {
    final localization =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localization != null, 'AppLocalizations not found in context.');
    return localization!;
  }

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  String get appTitle => isArabic ? 'GoWIFI للموزعين' : 'GoWIFI Reseller';
  String get loginTitle => isArabic ? 'تسجيل دخول ' : 'Login';
  String get loginSubtitle => isArabic
      ? 'سجّل الدخول للبحث عن العملاء بالاسم أو رقم الجوال.'
      : 'Sign in to search customers by mobile number or name.';
  String get usernameLabel => isArabic ? 'اسم المستخدم' : 'Username';
  String get enterUsername =>
      isArabic ? 'أدخل اسم المستخدم' : 'Enter your username';
  String get passwordLabel => isArabic ? 'كلمة المرور' : 'Password';
  String get enterPassword =>
      isArabic ? 'أدخل كلمة المرور' : 'Enter your password';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get signInWithBiometrics =>
      isArabic ? 'تسجيل الدخول بالقياسات الحيوية' : 'Sign in with biometrics';
  String get signInWithFaceId =>
      isArabic ? 'تسجيل الدخول عبر Face ID' : 'Sign in with Face ID';
  String get signInWithTouchId =>
      isArabic ? 'تسجيل الدخول عبر Touch ID' : 'Sign in with Touch ID';
  String get signInWithFingerprint =>
      isArabic ? 'تسجيل الدخول ببصمة الإصبع' : 'Sign in with fingerprint';
  String get biometricSignInReason => isArabic
      ? 'أكّد هويتك لتسجيل الدخول.'
      : 'Confirm your identity to sign in.';
  String get biometricLoginUnavailable => isArabic
      ? 'تسجيل الدخول بالقياسات الحيوية غير متاح الآن.'
      : 'Biometric sign-in is not available right now.';
  String get biometricLoginCancelled => isArabic
      ? 'تم إلغاء التحقق الحيوي.'
      : 'Biometric authentication was cancelled.';
  String get biometricLoginFailed => isArabic
      ? 'فشل تسجيل الدخول بالقياسات الحيوية. استخدم كلمة المرور وحاول مرة أخرى.'
      : 'Biometric sign-in failed. Use your password and try again.';
  String get biometricLoginNeedsPassword => isArabic
      ? 'لا توجد بيانات محفوظة لتسجيل الدخول الحيوي. سجّل الدخول بكلمة المرور أولاً.'
      : 'No saved biometric sign-in is available. Sign in with your password first.';
  String get biometricLoginCredentialsExpired => isArabic
      ? 'بيانات تسجيل الدخول الحيوي لم تعد صالحة. سجّل الدخول بكلمة المرور مرة أخرى.'
      : 'Saved biometric sign-in details are no longer valid. Sign in with your password again.';
  String get changeLanguageTooltip =>
      isArabic ? 'تغيير اللغة' : 'Change language';
  String get switchToDarkModeTooltip =>
      isArabic ? 'التبديل إلى الوضع الداكن' : 'Switch to dark mode';
  String get switchToLightModeTooltip =>
      isArabic ? 'التبديل إلى الوضع الفاتح' : 'Switch to light mode';
  String get loginFailedTryAgain => isArabic
      ? 'فشل تسجيل الدخول. حاول مرة أخرى.'
      : 'Login failed. Please try again.';
  String loginApiConfigured(String deviceName) => isArabic
      ? 'يتم استخدام واجهة تسجيل الدخول الحية. سيتم إرسال device_name بالقيمة "$deviceName".'
      : 'Using the live login API. The request sends device_name as "$deviceName".';
  String get loginApiNotConfigured => isArabic
      ? 'حدّد API_BASE_URL عند تشغيل التطبيق، مثال: flutter run --dart-define=API_BASE_URL=https://your-domain.com'
      : 'Set API_BASE_URL when you run the app, for example: flutter run --dart-define=API_BASE_URL=https://your-domain.com';

  String get customerSearchTitle =>
      isArabic ? 'بحث العملاء' : 'Customer Search';
  String get dashboardTitle => isArabic ? 'لوحة التحكم' : 'Dashboard';
  String get navMenuTooltip => isArabic ? 'القائمة' : 'Menu';
  String get transactionsTitle => isArabic ? 'معاملاتي' : 'My Transactions';
  String get myTransactionsTooltip => isArabic ? 'معاملاتي' : 'My transactions';
  String get refreshUserTooltip => isArabic ? 'تحديث المستخدم' : 'Refresh user';
  String get logoutTooltip => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get notConfigured => isArabic ? 'غير مهيأ' : 'Not configured';
  String signedInAs(String username) =>
      isArabic ? 'مسجل الدخول باسم $username' : 'Signed in as $username';
  String get userIdLabel => isArabic ? 'رقم المستخدم' : 'User ID';
  String get mobileLabel => isArabic ? 'الجوال' : 'Mobile';
  String get roleLabel => isArabic ? 'الدور' : 'Role';
  String get creditLabel => isArabic ? 'الدائن' : 'Credit';
  String get debitLabel => isArabic ? 'المدين' : 'Debit';
  String get apiHostLabel => isArabic ? 'مضيف الواجهة' : 'API Host';
  String get searchCustomerServicesTitle =>
      isArabic ? 'البحث في خدمات العملاء' : 'Search customer services';
  String get searchCustomerServicesSubtitle => isArabic
      ? 'ابحث باسم العميل أو رقم الجوال أو كليهما. يتم جلب النتائج من /api/customers/services/search.'
      : 'Search with customer name, mobile number, or both. Results come from /api/customers/services/search.';
  String get serviceStatusFilterLabel =>
      isArabic ? 'تصفية حالة الخدمة' : 'Service status';
  String get connectionStatusFilterLabel =>
      isArabic ? 'حالة الاتصال' : 'Connection status';
  String get customerNameLabel => isArabic ? 'اسم العميل' : 'Customer name';
  String get mobileNumberLabel => isArabic ? 'رقم الجوال' : 'Mobile number';
  String get search => isArabic ? 'بحث' : 'Search';
  String get enterCustomerNameOrMobileOrBoth => isArabic
      ? 'أدخل اسم العميل أو رقم الجوال أو كليهما.'
      : 'Enter a customer name, a mobile number, or both.';
  String get searchFailedTryAgain => isArabic
      ? 'فشل البحث. حاول مرة أخرى.'
      : 'Search failed. Please try again.';
  String get unableToRefreshAccount =>
      isArabic ? 'تعذر تحديث حسابك.' : 'Unable to refresh your account.';
  String transactionCompleted(int number, String balance) => isArabic
      ? 'تمت العملية $number. الرصيد الدائن الجديد: $balance'
      : 'Transaction $number completed. New credit balance: $balance';
  String get noSearchYet => isArabic ? 'لا يوجد بحث بعد' : 'No search yet';
  String get noSearchYetDescription => isArabic
      ? 'أدخل اسم العميل أو رقم الجوال أو كليهما لعرض الاشتراكات المطابقة.'
      : 'Enter a customer name, mobile number, or both to see matching subscriptions.';
  String get noResultsFound => isArabic ? 'لا توجد نتائج' : 'No results found';
  String noSubscriptionMatched(String criteria) => isArabic
      ? 'لا يوجد اشتراك يطابق $criteria. تحقق من القيم وحاول مرة أخرى.'
      : 'No subscription matched $criteria. Check the values and try again.';
  String resultCount(int count) =>
      isArabic ? '$count نتيجة' : '$count result${count == 1 ? '' : 's'}';
  String get subscriptionIdLabel =>
      isArabic ? 'رقم الاشتراك' : 'Subscription ID';
  String get customerIdLabel => isArabic ? 'رقم العميل' : 'Customer ID';
  String get usernameFieldLabel => isArabic ? 'اسم المستخدم' : 'Username';
  String get priceLabel => isArabic ? 'السعر' : 'Price';
  String get startLabel => isArabic ? 'البداية' : 'Start';
  String get endLabel => isArabic ? 'النهاية' : 'End';
  String get addCredit => isArabic ? 'إضافة رصيد' : 'Add Credit';
  String get addCreditTitle => isArabic ? 'إضافة رصيد' : 'Add Credit';
  String get extendServiceAction =>
      isArabic ? 'تمديد الخدمة' : 'Extend Service';
  String serviceExtendedUntil(String endDate) => isArabic
      ? 'تم تمديد الخدمة بنجاح حتى $endDate.'
      : 'Service extended successfully until $endDate.';
  String get amountLabel => isArabic ? 'المبلغ' : 'Amount';
  String get enterValidAmount =>
      isArabic ? 'أدخل مبلغًا صحيحًا' : 'Enter a valid amount';
  String get paymentMethodLabel => isArabic ? 'طريقة الدفع' : 'Payment method';
  String get cashLabel => isArabic ? 'نقدي' : 'Cash';
  String get chequeLabel => isArabic ? 'شيك' : 'Cheque';
  String get chequeDateLabel =>
      isArabic ? 'تاريخ الشيك (YYYY-MM-DD)' : 'Cheque date (YYYY-MM-DD)';
  String get enterChequeDate =>
      isArabic ? 'أدخل تاريخ الشيك' : 'Enter the cheque date';
  String get noteLabel => isArabic ? 'ملاحظة' : 'Note';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get submit => isArabic ? 'إرسال' : 'Submit';
  String get unableToAddCredit =>
      isArabic ? 'تعذر إضافة الرصيد الآن.' : 'Unable to add credit right now.';
  String get unableToExtendService => isArabic
      ? 'تعذر تمديد الخدمة الآن.'
      : 'Unable to extend service right now.';
  String get apiRechargeNote => isArabic ? 'شحن عبر الواجهة' : 'API recharge';

  String get filterTransactions =>
      isArabic ? 'تصفية المعاملات' : 'Filter transactions';
  String get exportTransactionsTooltip =>
      isArabic ? 'تصدير إلى إكسل' : 'Export to Excel';
  String get expiringCustomersTitle =>
      isArabic ? 'اشتراكات تنتهي قريبًا' : 'Expiring Subscriptions';
  String get expiringCustomersTooltip => isArabic
      ? 'اشتراكات تنتهي خلال 3 أيام'
      : 'Subscriptions expiring within 3 days';
  String get expiredCustomersTitle =>
      isArabic ? 'اشتراكات منتهية' : 'Expired Subscriptions';
  String get expiredCustomersTooltip =>
      isArabic ? 'اشتراكات منتهية الصلاحية' : 'Expired subscriptions';
  String get loadingCustomers => isArabic ? 'جارٍ التحميل...' : 'Loading...';
  String get noExpiringSubscriptions => isArabic
      ? 'لا توجد اشتراكات تنتهي خلال 3 أيام.'
      : 'No subscriptions expiring within 3 days.';
  String get noExpiredSubscriptions =>
      isArabic ? 'لا توجد اشتراكات منتهية.' : 'No expired subscriptions.';
  String noExpiredSubscriptionsForStatus(String status) => isArabic
      ? 'لا توجد اشتراكات منتهية بحالة $status.'
      : 'No expired subscriptions with $status status.';
  String get failedToLoadCustomers => isArabic
      ? 'فشل تحميل البيانات. حاول مرة أخرى.'
      : 'Failed to load data. Please try again.';
  String get expiringTodayLabel => isArabic ? 'ينتهي اليوم' : 'Expiring Today';
  String get expiringIn3DaysLabel =>
      isArabic ? 'ينتهي خلال 3 أيام' : 'Expiring in 3 Days';
  String get todayRevenueLabel =>
      isArabic ? 'إيرادات اليوم' : "Today's Revenue";
  String get todayTransactionsLabel =>
      isArabic ? 'معاملات اليوم' : "Today's Transactions";
  String get recentTransactionsLabel =>
      isArabic ? 'آخر المعاملات' : 'Recent Transactions';
  String get showAllLabel => isArabic ? 'عرض الكل' : 'Show all';
  String get customersWord => isArabic ? 'عميل' : 'customer';
  String get customersWordPlural => isArabic ? 'عملاء' : 'customers';
  String get noTransactionsToday =>
      isArabic ? 'لا توجد معاملات اليوم.' : 'No transactions today.';

  String get noTransactionsToExport =>
      isArabic ? 'لا توجد معاملات للتصدير.' : 'No transactions to export.';
  String transactionsExported(int count) => isArabic
      ? 'تم تجهيز ملف إكسل لـ $count معاملات.'
      : 'Prepared an Excel file for $count transactions.';
  String get unableToExportTransactions => isArabic
      ? 'تعذر تصدير المعاملات الآن.'
      : 'Unable to export transactions right now.';
  String get showFilters => isArabic ? 'إظهار المرشحات' : 'Show filters';
  String get hideFilters => isArabic ? 'إخفاء المرشحات' : 'Hide filters';
  String get filterTransactionsSubtitle => isArabic
      ? 'استخدم المرشحات لتضييق سجل المعاملات حسب النوع أو العملية أو طريقة الدفع أو الفترة الزمنية.'
      : 'Use the API filters to narrow your transaction history by type, operation, payment method, or date range.';
  String get perPageLabel => isArabic ? 'لكل صفحة' : 'Per page';
  String get transactionTypeLabel =>
      isArabic ? 'نوع المعاملة' : 'Transaction type';
  String get allLabel => isArabic ? 'الكل' : 'All';
  String get operationTypeLabel => isArabic ? 'نوع العملية' : 'Operation type';
  String get startDateLabel => isArabic ? 'تاريخ البداية' : 'Start date';
  String get endDateLabel => isArabic ? 'تاريخ النهاية' : 'End date';
  String get apply => isArabic ? 'تطبيق' : 'Apply';
  String get clear => isArabic ? 'مسح' : 'Clear';
  String get totalLabel => isArabic ? 'الإجمالي' : 'Total';
  String get pageLabel => isArabic ? 'الصفحة' : 'Page';
  String get noTransactionsFound =>
      isArabic ? 'لا توجد معاملات' : 'No transactions found';
  String get transactionsUnavailable =>
      isArabic ? 'المعاملات غير متاحة' : 'Transactions unavailable';
  String get noTransactionsMatchedFilters => isArabic
      ? 'لا توجد معاملات تطابق المرشحات الحالية.'
      : 'No transactions matched the current filters.';
  String get unusableTransactionList => isArabic
      ? 'لم يُرجع الخادم قائمة معاملات قابلة للاستخدام.'
      : 'The server did not return a usable transaction list.';
  String get previous => isArabic ? 'السابق' : 'Previous';
  String get next => isArabic ? 'التالي' : 'Next';
  String transactionNumber(int number) =>
      isArabic ? 'المعاملة رقم $number' : 'Transaction #$number';
  String get amountChipLabel => isArabic ? 'المبلغ' : 'Amount';
  String get fromLabel => isArabic ? 'من' : 'From';
  String get toLabel => isArabic ? 'إلى' : 'To';
  String get transfersLabel => isArabic ? 'التحويلات' : 'Transfers';
  String get balanceLabel => isArabic ? 'الرصيد' : 'Balance';
  String get lastBalanceLabel => isArabic ? 'الرصيد السابق' : 'Last balance';
  String get operationLabel => isArabic ? 'العملية' : 'Operation';
  String get chequeDateShortLabel => isArabic ? 'تاريخ الشيك' : 'Cheque date';
  String get fromAccountTitle => isArabic ? 'من الحساب' : 'From account';
  String get toAccountTitle => isArabic ? 'إلى الحساب' : 'To account';
  String get noAccountDetails =>
      isArabic ? 'لا توجد بيانات حساب' : 'No account details';
  String accountTypeLabel(String value) =>
      isArabic ? 'النوع: $value' : 'Type: $value';
  String accountNatureLabel(String value) =>
      isArabic ? 'الطبيعة: $value' : 'Nature: $value';
  String transferAmount(String amount) =>
      isArabic ? 'المبلغ: $amount' : 'Amount: $amount';
  String transferFrom(String value) => isArabic ? 'من: $value' : 'From: $value';
  String transferTo(String value) => isArabic ? 'إلى: $value' : 'To: $value';

  String languageOptionLabel(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }

  String localizeValue(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'credit':
        return creditLabel;
      case 'debit':
        return debitLabel;
      case 'cash':
        return cashLabel;
      case 'cheque':
        return chequeLabel;
      case 'online':
        return isArabic ? 'متصل' : 'Online';
      case 'offline':
        return isArabic ? 'غير متصل' : 'Offline';
      case 'active':
        return isArabic ? 'نشط' : 'Active';
      case 'enabled':
        return isArabic ? 'مفعل' : 'Enabled';
      case 'pending':
        return isArabic ? 'معلق' : 'Pending';
      case 'suspended':
        return isArabic ? 'موقوف' : 'Suspended';
      case 'admin':
        return isArabic ? 'مدير' : 'Admin';
      case 'customer-service-credit':
        return isArabic ? 'شحن خدمة عميل' : 'Customer service credit';
      case 'transaction':
        return isArabic ? 'معاملة' : 'Transaction';
      case 'unknown':
        return isArabic ? 'غير معروف' : 'Unknown';
      default:
        return formatApiMessage(value, fallback: value);
    }
  }

  String localizeDynamicMessage(String message) {
    final normalized = message.trim();

    const englishToArabic = {
      'Login failed. Please try again.': 'فشل تسجيل الدخول. حاول مرة أخرى.',
      'Unable to load your account.': 'تعذر تحميل حسابك.',
      'Unable to refresh your account.': 'تعذر تحديث حسابك.',
      'Logout failed.': 'فشل تسجيل الخروج.',
      'Search failed. Please try again.': 'فشل البحث. حاول مرة أخرى.',
      'Unable to add credit right now.': 'تعذر إضافة الرصيد الآن.',
      'Unable to extend service right now.': 'تعذر تمديد الخدمة الآن.',
      'Unable to load transactions.': 'تعذر تحميل المعاملات.',
      'The transaction response is missing required data.':
          'استجابة المعاملات تفتقد إلى البيانات المطلوبة.',
      'The credit response is missing required data.':
          'استجابة إضافة الرصيد تفتقد إلى البيانات المطلوبة.',
      'The login response is missing required data.':
          'استجابة تسجيل الدخول تفتقد إلى البيانات المطلوبة.',
      'The account response is missing required data.':
          'استجابة الحساب تفتقد إلى البيانات المطلوبة.',
      'The request timed out.': 'انتهت مهلة الطلب.',
      'The server returned invalid JSON.': 'أعاد الخادم JSON غير صالح.',
      'Unable to connect to the API server.': 'تعذر الاتصال بخادم الواجهة.',
      'The server returned an unexpected response.':
          'أعاد الخادم استجابة غير متوقعة.',
      'Session expired. Please sign in again.':
          'انتهت الجلسة. سجّل الدخول مرة أخرى.',
      'Set API_BASE_URL before using the app.':
          'حدّد API_BASE_URL قبل استخدام التطبيق.',
      'Customer search failed.': 'فشل البحث عن العملاء.',
      'Unable to add credit.': 'تعذر إضافة الرصيد.',
      'Unable to extend service.': 'تعذر تمديد الخدمة.',
      'Failed to load data. Please try again.':
          'فشل تحميل البيانات. حاول مرة أخرى.',
      'Customer service ID is required.': 'رقم خدمة العميل مطلوب.',
      'Enter a customer name or mobile number.':
          'أدخل اسم العميل أو رقم الجوال.',
      'Unauthenticated.': 'غير مصرح. سجّل الدخول مرة أخرى.',
      'Unauthenticated': 'غير مصرح. سجّل الدخول مرة أخرى.',
      'Invalid credentials': 'بيانات الدخول غير صحيحة',
      'Subscription not found': 'لم يتم العثور على الاشتراك',
      'Source user credit account not found':
          'لم يتم العثور على حساب رصيد المستخدم المصدر',
      'Customer service accounts not ready': 'حسابات خدمة العميل غير جاهزة',
      'Insufficient source balance': 'رصيد المصدر غير كاف',
      'Error': 'خطأ',
    };

    if (!isArabic) {
      return normalized;
    }

    return englishToArabic[normalized] ?? normalized;
  }

  String searchCriteria({
    String? customerName,
    String? mobile,
    String? serviceFilter,
  }) {
    final parts = <String>[];
    if (customerName != null && customerName.trim().isNotEmpty) {
      parts.add(
        isArabic ? 'الاسم "$customerName"' : 'name "$customerName"',
      );
    }
    if (mobile != null && mobile.trim().isNotEmpty) {
      parts.add(
        isArabic ? 'الجوال "$mobile"' : 'mobile "$mobile"',
      );
    }
    if (serviceFilter != null && serviceFilter.trim().isNotEmpty) {
      parts.add(
        isArabic ? 'الحالة "$serviceFilter"' : 'status "$serviceFilter"',
      );
    }
    return parts.join(isArabic ? ' و ' : ' and ');
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
