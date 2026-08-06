import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:sentinel/core/theme/app_theme.dart';
import 'package:sentinel/screens/dashboard_screen.dart';
import 'package:sentinel/widgets/cards/temperature_card.dart';
import 'package:sentinel/widgets/cards/humidity_card.dart';

void main() {
  runApp(const SentinelApp());
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Sentinel",
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [Locale('en'), Locale('tr')],

      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}

// Sandbox ekranı geliştirme sırasında widget denemeleri için kullanılmıştır.
// class Sandbox extends StatelessWidget {
//   const Sandbox({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Sentinel')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: const [
//             Row(
//               children: [
//                 Expanded(
//                   child: TemperatureCard(
//                     temperature: 28.5,
//                     status: 'Normal',
//                     statusColor: Colors.green,
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: HumidityCard(
//                     humidity: 49.6,
//                     status: "Normal",
//                     statusColor: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
