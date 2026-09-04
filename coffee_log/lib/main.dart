import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // Required for ImageFilter blur!

// Import all our tab screens
import 'screens/home_feed_screen.dart';
import 'screens/bean_list_screen.dart';
import 'screens/method_list_screen.dart';
import 'screens/toolkit_screen.dart';
import 'services/export_service.dart';
import 'screens/add_brew_screen.dart';
import 'databases/database_helper.dart';

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
      title: 'Cofi Logs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: CoffeeColors.background,
        primaryColor: CoffeeColors.primary,

        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,

        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: CoffeeColors.textDark,
              displayColor: CoffeeColors.textDark,
            ),

        // --- FIXED: MODERN POP-UP BUBBLE (SNACKBAR) ---
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating, // Makes it float!
          insetPadding: const EdgeInsets.only(
            bottom: 32,
            left: 24,
            right: 24,
          ), // Fixed property name!
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ), // Rounded bubble
          backgroundColor: CoffeeColors.textDark.withValues(
            alpha: 0.9,
          ), // Sleek dark bubble
          contentTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          elevation: 10,
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
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
      home: const DashboardScreen(),
    );
  }
}

// --- THE GLASS-THEMED DASHBOARD ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeFeedScreen(),
    BeanListScreen(),
    MethodListScreen(),
    ToolkitScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar:
          true, // FIXED: Lets the background flow smoothly behind the app bar!
      // --- FROSTED GLASS APP BAR ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              title: const Text('Cofi Logs'),
              backgroundColor: Colors.white.withValues(
                alpha: 0.6,
              ), // Translucent white
              scrolledUnderElevation:
                  0.0, // FIXED: Kills the ugly grey tint when scrolling!
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.ios_share,
                    color: CoffeeColors.primary,
                    size: 22,
                  ),
                  tooltip: 'Export Logs',
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating CSV Backup...')),
                    );
                    await ExportService.exportLogsToCSV(context);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),

      // --- BACKDROP CANVAS + CONTENT ---
      body: Stack(
        children: [
          // 1. Organic, warm coffee-toned background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFFFFBF0), Color(0xFFF5EFE6)],
              ),
            ),
          ),

          // 2. Subtle blurred golden bubble in the bottom left
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CoffeeColors.accent.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: const SizedBox(),
              ),
            ),
          ),

          // 3. Our active screen
          _screens[_currentIndex],
        ],
      ),

      // --- FLOATING CENTER ACTION BUTTON ---
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: CoffeeColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () => _showBeanSelector(context),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- CIRCULAR NOTCHED BOTTOM BAR ---
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: Colors.white.withValues(
              alpha: 0.8,
            ), // Slightly more opaque for readability
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ), // Clean internal spacing
            child: SizedBox(
              height: 60, // Fixed height for consistency
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabItem(0, Icons.home_outlined, Icons.home, 'Home'),
                  _buildTabItem(
                    1,
                    Icons.inventory_2_outlined,
                    Icons.inventory_2,
                    'Bean',
                  ),

                  const SizedBox(width: 48), // Notch space

                  _buildTabItem(
                    2,
                    Icons.menu_book_outlined,
                    Icons.menu_book,
                    'Method',
                  ),
                  _buildTabItem(
                    3,
                    Icons.bar_chart_outlined,
                    Icons.bar_chart,
                    'Other',
                  ), // Setup for our future analytics!
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI HELPER: Custom Text & Icon Tab ---
  Widget _buildTabItem(
    int index,
    IconData normalIcon,
    IconData activeIcon,
    String label,
  ) {
    bool isSelected = _currentIndex == index;
    final color = isSelected ? CoffeeColors.primary : Colors.grey.shade400;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : normalIcon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER: Global Bean Selector Modal ---
  void _showBeanSelector(BuildContext context) async {
    final activeBeans = await DatabaseHelper.instance.getActiveCoffeeBeans();

    if (!context.mounted) return;

    if (activeBeans.isEmpty) {
      // Look at this beautiful modern popup bubble in action!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cellar is empty! Add a bean first.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Bean to Brew',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CoffeeColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: activeBeans.length,
                  itemBuilder: (context, index) {
                    final bean = activeBeans[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: CoffeeColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(
                          bean.beanName,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${bean.roasterName} • ${bean.currentWeight}g left',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: CoffeeColors.primary,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddBrewScreen(bean: bean),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
