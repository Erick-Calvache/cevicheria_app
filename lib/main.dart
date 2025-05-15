import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart'; // 🔧 Asegúrate de importar esto
import 'theme.dart';
import 'pages/intro_page.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/pedidos_page.dart'; // Asegúrate de importar la página de pedidos

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ✅ Aquí también
  );

  if (message.data.isNotEmpty) {
    // Notificación de tipo "data"
    _showNotification(
      message.data['title'] ?? 'Título desconocido',
      message.data['body'] ?? 'Cuerpo desconocido',
    );
  } else if (message.notification != null) {
    // Notificación estándar
    _showNotification(
      message.notification?.title ?? 'Título desconocido',
      message.notification?.body ?? 'Cuerpo desconocido',
    );
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'cevicheria_channel',
        'Notificaciones de Cevichería',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        sound: RawResourceAndroidNotificationSound(
          'default',
        ), // Asegúrate de usar el sonido por defecto
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'default_payload',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ Permiso de notificación concedido');
  } else {
    print('❌ Permiso de notificación denegado');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔔 Notificación en primer plano: ${message.notification?.title}');
    _showNotification(
      message.notification?.title ?? '',
      message.notification?.body ?? '',
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📲 App abierta desde notificación: ${message.notification?.title}');
    // Aquí puedes navegar a otra página si deseas
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cevichería App',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const IntroPage(),
        '/main': (context) => const HomePage(),
        '/menu': (context) => const MenuPage(),
        '/pedidos': (context) => const PedidosPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
