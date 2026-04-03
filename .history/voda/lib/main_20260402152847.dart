import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/water_provider.dart';
import 'providers/climate_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProxyProvider<WaterProvider, ClimateProvider>(
          create: (_) => ClimateProvider(),
          update: (_, water, climate) {
            climate!.attachWaterProvider(water);
            return climate;
          },
        ),
      ],
      child: const AquaTrackApp(),
    ),
  );
}

class AquaTrackApp extends StatelessWidget {
  const AquaTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
