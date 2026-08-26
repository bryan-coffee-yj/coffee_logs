import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/export_service.dart';

// Import our two tab screens!
import 'screens/bean_list_screen.dart';
import 'screens/method_list_screen.dart';

// --- YOUR PREMIUM COFFEE PALETTE ---
class CoffeeColors {
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFFAFAFA);
  static const Color accent = Color(0xFFB7966B);
  static const Color primary = Color(0xFF946D43);
  static const Color textDark = Color(0xFF2E1402);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: CoffeeColors.background,
        primaryColor: CoffeeColors.primary,

        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: CoffeeColors.textDark,
              displayColor: CoffeeColors.textDark,
            ),

        appBarTheme: AppBarTheme(
          backgroundColor: CoffeeColors.background,
          foregroundColor: CoffeeColors.textDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.montserrat(
            color: CoffeeColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(), // <--- Start at our new Dashboard!
    );
  }
}

// --- THE DASHBOARD (Handles Tab Navigation) ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Track which tab is active (0 = Cellar, 1 = Methods)
  int _currentIndex = 0;

  // The actual screens that correspond to our tabs
  final List<Widget> _screens = const [BeanListScreen(), MethodListScreen()];

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. The Unified Header
      appBar: AppBar(
        title: const Text('Coffee Log'), // Constant title! No more switching.
        actions: [
          // The export button stays here so you can back up from any tab
          IconButton(
            icon: const Icon(
              Icons.ios_share,
              color: CoffeeColors.primary,
              size: 22,
            ),
            tooltip: 'Export Logs',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating CSV...')),
              );
              await ExportService.exportLogsToCSV(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // 2. The Body (Only ONE body!)
      body: IndexedStack(index: _currentIndex, children: _screens),

      // 3. PREMIUM BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,

          // Styling the selected/unselected states
          selectedItemColor: CoffeeColors.primary,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),

          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.inventory_2_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.inventory_2),
              ),
              label: 'Cellar',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.menu_book_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.menu_book),
              ),
              label: 'Methods',
            ),
          ],
        ),
      ),
    );
  }
}
