import 'dart:io' show Platform;

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
  print('📩 [Background] Notificación recibida: ${message.messageId}');
}

// Plugin global para notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!Platform.isWindows) {
    // Handler de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Crear canal de notificaciones personalizado (solo Android)
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

    // Inicialización del plugin de notificaciones locales
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

    // Solicitar permisos al usuario
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso de notificaciones concedido');
    } else {
      print('❌ Permiso de notificaciones denegado');
    }

    // Escuchar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 [Foreground] Título: ${message.notification?.title}');

      final title = message.notification?.title ?? 'Nuevo pedido';
      final body = message.notification?.body ?? '';

      if (Platform.isWindows) {
        final context = GlobalNavigator.navigatorKey.currentContext;
        if (context != null) {
          showWindowsToast(context, title, body);
        }
      } else {
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
      }
    });

    // Manejar clic en notificación cuando app está en background o terminada
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 App abierta desde notificación');
      GlobalNavigator.navigatorKey.currentState?.pushNamed('/pedidos');
    });
  } else {
    print('🖥️ Ejecutando en Windows: se omiten notificaciones del sistema');
  }

  runApp(const MyApp());
}

void showWindowsToast(BuildContext context, String title, String body) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$title\n$body'),
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.black87,
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
