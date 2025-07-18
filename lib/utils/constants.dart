import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color secondary = Color(0xFF8BC34A);

  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  static const Color border = Color(0xFFE0E0E0);
}

class AppStrings {
  static const String appName = 'روبين للبذور';
  static const String appTitle = 'لوحة التحكم';

  // Customers - العملاء
  static const String customers = 'العملاء';
  static const String customer = 'العميل';
  static const String customerName = 'اسم العميل';
  static const String customerPhone = 'رقم الهاتف';
  static const String customerNotes = 'ملاحظات';
  static const String addCustomer = 'إضافة عميل';
  static const String editCustomer = 'تعديل العميل';
  static const String deleteCustomer = 'حذف العميل';
  static const String noCustomers = 'لا يوجد عملاء حتى الآن';
  static const String addFirstCustomer = 'أضف أول عميل للبدء';

  // Sheets - الجداول
  static const String sheets = 'الجداول';
  static const String sheet = 'الجدول';
  static const String sheetTitle = 'عنوان الجدول';
  static const String addSheet = 'إضافة جدول';
  static const String editSheet = 'تعديل الجدول';
  static const String deleteSheet = 'حذف الجدول';
  static const String noSheets = 'لا توجد جداول حتى الآن';
  static const String addFirstSheet = 'أضف أول جدول لهذا العميل';

  // Actions - الإجراءات
  static const String add = 'إضافة';
  static const String edit = 'تعديل';
  static const String delete = 'حذف';
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';
  static const String ok = 'موافق';
  static const String yes = 'نعم';
  static const String no = 'لا';
  static const String retry = 'إعادة المحاولة';
  static const String refresh = 'تحديث';

  // Table actions - إجراءات الجدول
  static const String addRow = 'إضافة صف';
  static const String addColumn = 'إضافة عمود';
  static const String deleteRow = 'حذف صف';
  static const String deleteColumn = 'حذف عمود';
  static const String cellValue = 'قيمة الخلية';
  static const String emptyCell = 'خلية فارغة';

  // PDF - ملف PDF
  static const String exportPdf = 'تصدير PDF';
  static const String generatePdf = 'إنشاء PDF';
  static const String sharePdf = 'مشاركة PDF';
  static const String pdfGenerated = 'تم إنشاء ملف PDF بنجاح';
  static const String pdfError = 'خطأ في إنشاء ملف PDF';

  // Messages - الرسائل
  static const String loading = 'جاري التحميل...';
  static const String saving = 'جاري الحفظ...';
  static const String deleting = 'جاري الحذف...';
  static const String success = 'نجح';
  static const String error = 'خطأ';
  static const String tryAgain = 'حاول مرة أخرى';

  // Validation - التحقق
  static const String required = 'هذا الحقل مطلوب';
  static const String invalidPhone = 'رقم هاتف غير صحيح';
  static const String invalidName = 'اسم غير صحيح';
  static const String tooShort = 'قصير جداً';
  static const String tooLong = 'طويل جداً';

  // Delete confirmation - تأكيد الحذف
  static const String deleteConfirmTitle = 'تأكيد الحذف';
  static const String deleteCustomerConfirm = 'هل أنت متأكد من حذف هذا العميل؟';
  static const String deleteSheetConfirm = 'هل أنت متأكد من حذف هذا الجدول؟';
  static const String deleteCannotBeUndone = 'لا يمكن التراجع عن هذا الإجراء.';
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  static const double buttonHeight = 48.0;
  static const double cardHeight = 120.0;

  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}

class AppConstants {
  static const String customersCollection = 'customers';
  static const String sheetsCollection = 'sheets';

  static const int defaultRows = 10;
  static const int defaultColumns = 5;
  static const int maxRows = 100;
  static const int maxColumns = 20;

  static const int maxCustomerNameLength = 50;
  static const int maxPhoneNumberLength = 20;
  static const int maxNotesLength = 500;
  static const int maxSheetTitleLength = 100;
}