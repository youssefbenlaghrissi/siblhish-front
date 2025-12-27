import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/transactions_screen.dart';
import 'providers/budget_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for DateFormat
  await initializeDateFormatting('fr', null);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SiblhishApp());
}

class SiblhishApp extends StatelessWidget {
  const SiblhishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BudgetProvider(),
      child: MaterialApp(
        title: 'Siblhish',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/main': (context) => MainScreen(key: MainScreen.navigatorKey),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static final GlobalKey<_MainScreenState> navigatorKey = GlobalKey<_MainScreenState>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  
  // Obtenir le nom de l'écran à partir de l'index
  String _getScreenName(int index) {
    switch (index) {
      case 0:
        return 'Accueil';
      case 1:
        return 'Transactions';
      case 2:
        return 'Statistiques';
      case 3:
        return 'Objectifs';
      case 4:
        return 'Profil';
      default:
        return 'Inconnu';
    }
  }
  
  // Méthode publique pour changer d'onglet depuis d'autres écrans
  void changeTab(int index) {
    if (index >= 0 && index < 5) {
      // Effacer les erreurs précédentes lors du changement d'onglet
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      provider.clearError();
      
      debugPrint('📱 Ouverture de screen: ${_getScreenName(index)}');
      
      setState(() {
        _currentIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  // Créer les écrans de manière lazy pour éviter les appels API au démarrage
  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(isVisible: _currentIndex == 0);
      case 1:
        return TransactionsScreen(isVisible: _currentIndex == 1);
      case 2:
        return StatisticsScreen(isVisible: _currentIndex == 2);
      case 3:
        return GoalsScreen(isVisible: _currentIndex == 3);
      case 4:
        return ProfileScreen(isVisible: _currentIndex == 4);
      default:
        return HomeScreen(isVisible: _currentIndex == 0);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    debugPrint('📱 Ouverture de screen: ${_getScreenName(_currentIndex)}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Ne pas nettoyer les données quand l'app passe en arrière-plan
    // Seulement nettoyer si l'app est complètement détachée (fermée)
    if (state == AppLifecycleState.detached) {
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      // Ne pas nettoyer la session, seulement les données temporaires si nécessaire
      // provider.clearAllData(); // Commenté pour préserver la session
      if (kDebugMode) {
        debugPrint('📱 Application détachée (fermée)');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier que l'utilisateur est authentifié avant d'afficher l'app
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        // Si l'utilisateur n'est pas chargé, rediriger vers le login
        if (!provider.isInitialized || provider.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(5, (index) => _buildScreen(index)),
          ),
          bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Effacer les erreurs précédentes lors du changement d'onglet
            provider.clearError();
            
            debugPrint('📱 Ouverture de screen: ${_getScreenName(index)}');
            
            setState(() {
              _currentIndex = index;
            });
            _animationController.reset();
            _animationController.forward();
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Statistiques',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.savings_rounded),
              label: 'Objectifs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
        ),
      );
      },
    );
  }
}
