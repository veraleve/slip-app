import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth_screen.dart';
import 'screens/main_scaffold.dart';
import 'services/supabase_service.dart';
import 'theme/slip_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: SlipTheme.canvas,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase service
  await SupabaseService().initialize();

  runApp(const SlipApp());
}

class SlipApp extends StatefulWidget {
  const SlipApp({super.key});

  @override
  State<SlipApp> createState() => _SlipAppState();
}

class _SlipAppState extends State<SlipApp> {
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  void _checkInitialAuth() {
    final auth = SupabaseService().isAuthenticated;
    setState(() {
      _isAuthenticated = auth;
    });
  }

  void _onAuthenticated() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _onSignOut() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slip',
      debugShowCheckedModeBanner: false,
      theme: SlipTheme.lightTheme,
      home: _isAuthenticated
          ? MainScaffold(onSignOut: _onSignOut)
          : AuthScreen(onAuthenticated: _onAuthenticated),
    );
  }
}
