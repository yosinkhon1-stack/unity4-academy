
import 'package:flutter/material.dart';


import 'core/theme/app_theme.dart';


import 'shared/services/firebase_service.dart';


import 'features/dashboard/responsive_dashboard.dart';
import 'generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'shared/services/push_notification_service.dart';
import 'shared/services/local_notification_service.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/parent_home_screen.dart';
import 'package:unity4_academy/shared/services/auth_state_service.dart';
import 'core/models/student.dart';
import 'core/providers/student_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'teacher_login_screen.dart';
import 'teacher_home_screen.dart';
import 'student_login_screen.dart';
import 'student_home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Giriş yapan öğretmenin e-posta adresini tutan provider
final teacherEmailProvider = StateProvider<String?>((ref) => null);



/// Uygulamanın giriş noktası. Firebase başlatılır ve uygulama başlatılır.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.initialize();
    // Temporarily disabling App Check to troubleshoot token storage
    /*
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
    */
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }
  runApp(const ProviderScope(child: Unity4AcademyApp()));
}

/// Ana uygulama widget'ı. Tema, lokalizasyon ve giriş ekranı burada tanımlanır.
class Unity4AcademyApp extends ConsumerWidget {
  const Unity4AcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'UNITY4 ACADEMY',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      locale: const Locale('uz'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => NotificationInitializer(child: child!),
      home: const AuthGate(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/teacherLogin': (context) => const TeacherLoginScreen(),
        '/teacherHome': (context) => const TeacherHomeScreen(),
        '/adminHome': (context) => const ResponsiveDashboard(role: 'admin'),
        '/studentLogin': (context) => const StudentLoginScreen(),
        // '/studentHome': (context) => Scaffold(appBar: AppBar(title: const Text('Öğrenci Paneli')), body: Center(child: Text('Hoşgeldin, öğrenci!'))),
        '/studentHome': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return StudentHomeScreen(studentId: args);
          }
          return const Scaffold(body: Center(child: Text('Öğrenci bulunamadı.')));
        },
      },
    );
  }
}

/// Widget to initialize push notifications with a valid BuildContext
class NotificationInitializer extends StatefulWidget {
  final Widget child;
  const NotificationInitializer({super.key, required this.child});

  @override
  State<NotificationInitializer> createState() => _NotificationInitializerState();
}

class _NotificationInitializerState extends State<NotificationInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize push notifications after first frame
      PushNotificationService.initialize(context);
      LocalNotificationService.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _loading = true;
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = await AuthStateService.getSession();
    if (session == null) {
      if (mounted) setState(() { _startScreen = const WelcomeScreen(); _loading = false; });
      return;
    }

    final role = session['role'];
    final id = session['id'];
    final name = session['name'];

    if (role == 'admin') {
      ref.read(teacherEmailProvider.notifier).state = id;
      if (mounted) PushNotificationService.updateUserToken(context, id!);
      _startScreen = const ResponsiveDashboard(role: 'admin');
    } else if (role == 'teacher') {
      ref.read(teacherEmailProvider.notifier).state = id;
      if (mounted) PushNotificationService.updateUserToken(context, id!);
      _startScreen = const TeacherHomeScreen();
    } else if (role == 'student') {
      // Re-fetch student data to populate provider
      final doc = await FirebaseFirestore.instance.collection('students').doc(id).get();
      if (doc.exists) {
        final student = Student.fromFirestore(doc);
        ref.read(currentStudentProvider.notifier).state = student;
        if (mounted) PushNotificationService.updateUserToken(context, id!);
        _startScreen = StudentHomeScreen(studentId: id!);
      } else {
        await AuthStateService.logout();
        _startScreen = const WelcomeScreen();
      }
    } else if (role == 'parent') {
       if (mounted) PushNotificationService.updateUserToken(context, id!);
       _startScreen = ParentHomeScreen(studentId: id!, studentName: name!);
    } else {
      _startScreen = const WelcomeScreen();
    }

    if (mounted) setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _startScreen ?? const WelcomeScreen();
  }
}