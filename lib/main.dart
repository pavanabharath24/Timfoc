import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'providers/stats_provider.dart';
import 'providers/timer_provider.dart';
import 'theme/lofi_theme.dart';
import 'screens/main_layout.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Storage and Notifications
  await StorageService.init();
  await NotificationService.init();
  
  // Initialize Foregound Task
  FlutterForegroundTask.initCommunicationPort();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: const WithForegroundTask(child: TimfocApp()),
    ),
  );
}

class TimfocApp extends StatelessWidget {
  const TimfocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timfoc',
      debugShowCheckedModeBanner: false,
      theme: LofiTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}
