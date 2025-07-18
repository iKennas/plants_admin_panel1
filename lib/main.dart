import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: AppDimensions.elevationMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          contentPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
        ),
      ),
      home: const FirebaseInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Firebase initializer widget
class FirebaseInitializer extends StatefulWidget {
  const FirebaseInitializer({Key? key}) : super(key: key);

  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  bool _isInitializing = true;
  String _initializationError = '';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Firebase initialization error: $e');

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.eco,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'ROBIN SEED',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return HomeScreen(firebaseError: _initializationError);
  }
}

// Main home screen
class HomeScreen extends StatefulWidget {
  final String firebaseError;

  const HomeScreen({Key? key, this.firebaseError = ''}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _firebaseStatus = 'Checking Firebase...';
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  void _checkFirebaseStatus() {
    if (widget.firebaseError.isNotEmpty) {
      setState(() {
        _firebaseStatus = 'Firebase Error ❌';
      });
    } else if (Firebase.apps.isNotEmpty) {
      setState(() {
        _firebaseStatus = 'Firebase Connected ✅';
      });
    } else {
      setState(() {
        _firebaseStatus = 'Firebase Not Initialized ❌';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            // App branding
            const Icon(
              Icons.eco,
              size: 100,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            const Text(
              'ROBIN SEED',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text(
              'Seeds & Plants Admin Panel',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppDimensions.paddingLarge * 2),

            // Firebase status card
            _buildStatusCard(),

            const SizedBox(height: AppDimensions.paddingLarge),

            // Action buttons
            _buildActionButtons(),

            // Error details (if any)
            if (widget.firebaseError.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildErrorDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            const Text(
              'Firebase Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _firebaseStatus,
              style: TextStyle(
                fontSize: 16,
                color: _firebaseStatus.contains('✅')
                    ? AppColors.success
                    : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_testResult.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Test Result:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _testResult,
                style: TextStyle(
                  fontSize: 14,
                  color: _testResult.contains('success')
                      ? AppColors.success
                      : AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Test Firestore button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testFirestoreConnection,
            icon: const Icon(Icons.wifi_protected_setup),
            label: const Text('Test Firestore Connection'),
          ),
        ),

        const SizedBox(height: 12),

        // Retry Firebase button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _retryFirebaseInit,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Firebase Initialization'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDetails() {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                SizedBox(width: 8),
                Text(
                  'Error Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.firebaseError,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testFirestoreConnection() async {
    setState(() {
      _testResult = 'Testing...';
    });

    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        setState(() {
          _testResult = 'Error: Firebase not initialized';
        });
        return;
      }

      // Try to access Firestore
      final firestore = FirebaseFirestore.instance;

      // Test connection with a simple read
      await firestore.collection('test').limit(1).get();

      setState(() {
        _testResult = 'Firestore connection success! ✅';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firestore connection successful! ✅'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() {
        _testResult = 'Firestore error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firestore error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _retryFirebaseInit() async {
    // Restart the app to retry Firebase initialization
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const FirebaseInitializer()),
    );
  }
}