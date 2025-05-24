import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'pages/intro_page.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/pedidos_page.dart';
import 'pages/productos_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // Notificaciones para Android/iOS
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'cevicheria_channel',
      'Notificaciones de Pedidos',
      description: 'Notificaciones cuando llegan nuevos pedidos',
      importance: Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          GlobalNavigator.navigatorKey.currentState?.pushNamed('/pedidos');
        }
      },
    );

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 [Foreground] Título: ${message.notification?.title}');
      final title = message.notification?.title ?? 'Nuevo pedido';
      final body = message.notification?.body ?? '';

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: 'pedido',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      GlobalNavigator.navigatorKey.currentState?.pushNamed('/pedidos');
    });
  } else {
    // Notificaciones tipo snackbar para Windows o Web
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Nuevo pedido';
      final body = message.notification?.body ?? '';
      final context = GlobalNavigator.navigatorKey.currentContext;

      if (context != null) {
        showWindowsAlert(context, title, body);
      }
    });
  }

  runApp(const MyApp());
}

// Mostrar notificación en Windows o Web
void showWindowsAlert(BuildContext context, String title, String body) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$title\n$body'),
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.blueGrey[900],
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cevichería App',
      theme: AppTheme.lightTheme,
      navigatorKey: GlobalNavigator.navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const IntroPage(),
        '/main': (context) => const HomePage(),
        '/menu': (context) => const MenuPage(),
        '/pedidos': (context) => const PedidosPage(),
        '/productos': (context) => const ProductosPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class GlobalNavigator {
  static final navigatorKey = GlobalKey<NavigatorState>();
}
