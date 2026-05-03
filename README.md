# محاميك Flutter v4

هذه النسخة مبنية على التصميم المرفوع من مشروع React/Vite، وتمت إعادة تنفيذ الصفحات الأساسية في Flutter/Dart مع الحفاظ على:

- الهوية اللونية نفسها تقريبًا
- ترتيب العناصر والأزرار وتدفق التنقل الأساسي
- تفعيل Gemini API للاستشارات القانونية الأولية
- تفعيل Google Maps داخل شاشة الملف الشخصي
- إضافة تحديد الموقع الحالي وفرز أقرب المحامين
- طبقة Backend قابلة للربط عبر `.env`

## أهم الملفات

- `lib/config/app_config.dart` إعدادات الربط
- `lib/services/api_client.dart` عميل HTTP موحد
- `lib/services/auth_service.dart` تسجيل الدخول الحقيقي أو fallback تجريبي
- `lib/services/lawyers_service.dart` جلب المحامين
- `lib/services/location_service.dart` تحديد الموقع وحساب المسافة
- `lib/services/requests_service.dart` جلب/إنشاء الطلبات
- `lib/services/cases_service.dart` جلب القضايا
- `lib/services/gemini_service.dart` محادثة AI عبر backend أو Gemini مباشرة

## ملف `.env`

النسخة الحالية تحتوي ملف `.env` جاهزًا حتى لا يظهر خطأ asset عند التشغيل.

عدّل القيم التالية قبل الربط الحقيقي:

```env
API_BASE_URL=https://your-backend-domain.com/api
AUTH_LOGIN_ENDPOINT=/auth/login/
LAWYERS_ENDPOINT=/lawyers/
LAWYER_PROFILE_ENDPOINT=/lawyers/{id}/
BOOKINGS_ENDPOINT=/bookings/
REQUESTS_ENDPOINT=/requests/
CASES_ENDPOINT=/cases/
AI_CHAT_ENDPOINT=/ai/legal-chat/
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-2.5-flash
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

## تشغيل المشروع

إذا كانت هذه النسخة تحتوي فقط على `lib/` و`pubspec.yaml` عندك، شغّل أولًا:

```bash
flutter create .
```

ثم:

```bash
flutter pub get
flutter run
```

## ربط Google Maps

### Android
ضع المفتاح داخل:

`android/app/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

وأضف صلاحيات الموقع عند الحاجة داخل نفس الملف:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS
أضف مفاتيح الوصف داخل `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>نحتاج إلى الموقع لإظهار أقرب المحامين إليك.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>نحتاج إلى الموقع لإظهار أقرب المحامين إليك.</string>
```

### Web / Chrome
في حال التشغيل على Chrome، قد تحتاج مفتاح خرائط Google للويب داخل:

`web/index.html`

على شكل script حسب إعداد مشروعك المحلي.

## Backend الحقيقي

الربط الحالي يفترض endpoints مستقلة للمحامين، الطلبات، القضايا، والحجز. إذا كان backend لديك Django/DRF فيمكنك فقط تعديل المسارات داخل `.env` لتطابق المسارات الفعلية.

## ملاحظات مهمة

- ما زلت تحتاج تشغيل `flutter analyze` و `flutter run` محليًا للتأكد النهائي من بيئتك.
- في الإنتاج، الأفضل أن يمر Gemini عبر الـ backend بدل وضع المفتاح مباشرة داخل التطبيق.
- إذا لم يتم السماح بالموقع، التطبيق سيعود تلقائيًا إلى موقع افتراضي في الرياض بدل التعطل.
