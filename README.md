# 🕌 Smart Masjid TV — نظام شاشات المساجد الذكي (Android TV & Digital Signage)

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20(Feature--Based)-0D6B4B)
![State Management](https://img.shields.io/badge/State%20Management-Cubit%20%2F%20BLoC-blueviolet)
![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android%20TV%20%7C%20Windows%20%7C%20Mobile-success)

تطبيق **Smart Masjid TV (`masjid_app`)** هو نظام عرض رقمي ذكي (Digital Signage) مصمم خصيصاً لشاشات المساجد الذكية (**Android TV / Smart Screens**). يعمل التطبيق على مدار الساعة (24/7) لعرض مواقيت الصلاة بدقة، العد التنازلي للأذان والإقامة، الآيات القرآنية والأحاديث النبوية والأدعية المتناوبة، أذكار ما بعد الصلاة وأذكار الصباح والمساء، وشريط الإعلانات الإخباري، مع دعم كامل للعمل بدون إنترنت (**Offline-First**) والتزامن اللحظي مع تطبيق لوحة التحكم (**Masjid Admin**).

---

## ✨ المميزات الرئيسية (Key Features)

### 1. 🕰️ إدارة ذكية لمواقيت الصلاة والأذان والإقامة
- عرض مواقيت الصلوات الخمس والشروق مع عدّاد تنازلي دقيق بالثواني للصلاة القادمة.
- **دورة حياة آلية كاملة للصلاة (Automated Prayer State Machine)**:
  - الانتقال التلقائي إلى **شاشة الأذان** وتشغيل الصوت عند دخول الوقت.
  - الانتقال إلى **شاشة العد التنازلي للإقامة** حسب المدة المحددة لكل صلاة من لوحة التحكم (مع استثناء الشروق تلقائياً ودعم خاص لصلاة الجمعة).
  - الانتقال إلى **شاشة إقامة الصلاة** ("يرجى تسوية الصفوف وإغلاق الهواتف") طوال مدة الصلاة.
  - الانتقال التلقائي بعد انتهاء الصلاة إلى **أذكار ما بعد الصلاة** (مع عرض أذكار الصباح مرتين بعد الفجر، وأذكار المساء بعد العصر).
- **حفظ واستعادة حالة العد التنازلي (Crash/Reboot Recovery)**: في حال انقطاع الكهرباء أو إعادة تشغيل الشاشة أثناء انتظار الإقامة، يستعيد التطبيق العد التنازلي من حيث توقف عبر `SharedPreferences`.

### 2. 🎮 تحكم كامل عبر ريموت الشاشة (TV Remote Control Integration)
- **الزر الأحمر (`Red` / `A`)**: تفعيل فوري لشاشة الإقامة يدوياً مع مؤقت ذكي للخروج التلقائي إلى الأذكار.
- **الزر الأخضر (`Green` / `S`)**: تشغيل أذكار ما بعد الصلاة يدوياً.
- **الزر الأصفر (`Yellow` / `D`)**: تشغيل أذكار الصباح يدوياً.
- **الزر الأزرق (`Blue` / `F`)**: تشغيل أذكار المساء يدوياً.
- **الزر (`0`)**: العودة الفورية إلى الشاشة الطبيعية أو استئناف عداد الإقامة النشط.
- **الأزرار (`1` إلى `7`)**: التبديل الفوري بين **7 ثيمات وخلفيات فيديو متحركة عالية الدقة** (بما فيها ثيمات الحج والوضع الليلي والنهاري).

### 3. ☁️ تزامن سحابي لحظي + عمل بدون إنترنت (Offline-First & Smart Versioned Caching)
- نظام تخزين محلي ذكي (`Versioned Cache`) يقلل استهلاك قراءات Firestore بنسبة تتجاوز **90%**؛ حيث لا يقوم التطبيق بتحميل المجموعات أو النصوص إلا عند تغيّر رقم الإصدار (`messages_version`, `iqama_version`) من تطبيق الأدمن.
- في حال انقطاع الإنترنت نهائياً داخل المسجد، يعمل التطبيق بكفاءة كاملة اعتماداً على الكاش المحلي وملفات الـ JSON المدمجة (`Fallback Assets`).
- **البث المباشر الفوري (`Live Display`)**: إمكانية تثبيت أي آية أو حديث أو تنبيه من تطبيق الأدمن ليظهر فوراً على شاشة المسجد في نفس اللحظة.
- **تزامن التاريخ الهجري (`Hijri Offset`)**: تعديل الرؤية الشرعية (+1 / -1 يوم) من لوحة التحكم يتحدث لحظياً على الشاشة.

### 4. 🎬 معالجة متقدمة لخلفيات الفيديو (24/7 Video Watchdog)
- تشغيل خلفيات الفيديو بصيغة `mixWithOthers` لمنع توقف الفيديو عند تشغيل صوت الأذان.
- نظام مراقبة ذاتي (`Watchdog Timer` كل 10 ثوانٍ + `WidgetsBindingObserver`) يضمن استمرارية عمل خلفية الفيديو على شاشات Android TV دون تجمّد على مدار الأيام.

---

## 🏗️ الهيكلة المعمارية (Clean Architecture + Cubit)

تم بناء المشروع وفق معمارية **Feature-Based Clean Architecture** مع فصل صارم بين الطبقات (`Domain`, `Data`, `Presentation`) وإدارة الحالة باستخدام **`flutter_bloc` (Cubit)**:

```text
lib/
├── core/
│   ├── constants/        # ثوابت النصوص والألوان
│   ├── enums/            # حالات الشاشة (AppState, AdhkarType, AppThemeEnum)
│   ├── theme/            # إعدادات الثيمات الـ 7 وخلفيات الفيديو
│   ├── utils/            # حسابات التاريخ الهجري والميلادي (DateHelper)
│   └── widgets/          # العناصر المشتركة (MasjidLogo, BlurOverlay,Responsive)
└── features/
    ├── prayer/           # مواقيت الصلاة، الأذان، الإقامة، والفارق الهجري
    │   ├── domain/       # Entities (DayPrayer) & PrayerRepository Interface
    │   ├── data/         # PrayerDataSource, DayPrayerModel, PrayerRepositoryImpl
    │   └── presentation/ # PrayerCubit, PrayerState, AdhanScreen, IqamaScreen
    ├── content/          # الآيات، الأحاديث، الأدعية، الأذكار، والبث المباشر
    │   ├── domain/       # Message Entity & ContentRepository Interface
    │   ├── data/         # ContentDataSource (Versioned Cache), MessageModel
    │   └── presentation/ # ContentCubit, ContentState, AyatColumn
    ├── theme/            # إدارة الثيمات الـ 7 ومشغل الفيديو الخلفي
    │   ├── domain/       # ThemeRepository Interface
    │   ├── data/         # ThemeRepositoryImpl
    │   └── presentation/ # ThemeCubit, ThemeState
    ├── ticker/           # الشريط الإخباري السفلي المتحرك
    │   ├── domain/       # TickerMessage Entity & TickerRepository Interface
    │   ├── data/         # TickerMessageModel, TickerRepositoryImpl
    │   └── presentation/ # TickerCubit, TickerState, BottomTicker
    └── home/             # الشاشة الرئيسية وربط أزرار الريموت (HomeScreen)
```

---

## 🧪 الاختبارات وضمان الجودة (Automated QA & Testing)

يحتوي المشروع على حزمة اختبارات شاملة (`test/widget_test.dart`) تغطي **12 اختباراً آلياً**:
1. فحص سلامة جميع ملفات البيانات المحلية (`JSON Assets Integrity`).
2. التحقق من صحة تحليل مواقيت الصلاة لـ 365 يوماً (`AM/PM/Noon/Midnight`).
3. اختبار آلة الحالة (`PrayerCubit State Machine`) والتأكد من عدم الخروج المبكر من شاشة الإقامة اليدوية أو التلقائية.
4. اختبار تكرار أذكار الصباح مرتين بعد صلاة الفجر ودمج أذكار المساء بعد العصر.
5. اختبار البث المباشر الفوري (`Live Display`) والتبديل اللحظي.
6. محاكاة كاملة لشاشة تلفزيون `1920x1080` واختبار استجابة جميع أزرار الريموت (`Red, Green, Yellow, Blue, 0, 1..7`).

لتشغيل الاختبارات:
```bash
flutter test
dart analyze
```

---

## 🚀 طريقة التشغيل (Getting Started)

1. تأكد من تثبيت Flutter SDK (`^3.7.0`).
2. قم بتحميل الحزم:
   ```bash
   flutter pub get
   ```
3. تأكد من وجود ملف إعدادات Firebase (`firebase_options.dart` / `google-services.json`).
4. شغّل التطبيق على شاشة Android TV أو Windows أو الهاتف:
   ```bash
   flutter run
   ```
