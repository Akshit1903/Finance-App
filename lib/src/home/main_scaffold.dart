import 'package:confetti/confetti.dart';
import 'package:expense_and_net_worth_automation/src/features/action/action_tab.dart';
import 'package:expense_and_net_worth_automation/src/features/journey/journey_tab.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:expense_and_net_worth_automation/src/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main scaffold with 2-tab PageView navigation: Action (left) and Journey (right).
/// Includes confetti layer and animated hide/show bottom tab bar for journey evaluation.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  static const routeName = '/';

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late final PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<JourneyProvider>().attachPageController(_pageController);
      }
    });
  }

  @override
  void dispose() {
    context.read<JourneyProvider>().detachPageController();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final journeyProvider = context.watch<JourneyProvider>();

    String appBarTitle;
    if (_selectedIndex == 0) {
      final inProgress = journeyProvider.inProgressStep;
      appBarTitle = inProgress?.title ?? 'Finance';
    } else {
      appBarTitle = 'Journey';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        actions: [
          if (journeyProvider.isEvaluating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else ...[
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, SettingsView.routeName);
              },
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            ),
            IconButton(
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
              },
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: journeyProvider.isEvaluating
                ? const NeverScrollableScrollPhysics()
                : null,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: const [
              ActionTab(),
              JourneyTab(),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: journeyProvider.confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.amber,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        offset: journeyProvider.isTabBarVisible
            ? Offset.zero
            : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: journeyProvider.isTabBarVisible ? 1.0 : 0.0,
          child: NavigationBar(
            onDestinationSelected: _onItemTapped,
            selectedIndex: _selectedIndex,
            destinations: const <Widget>[
              NavigationDestination(
                icon: Icon(Icons.play_arrow_outlined),
                selectedIcon: Icon(Icons.play_arrow),
                label: 'Action',
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined),
                selectedIcon: Icon(Icons.route),
                label: 'Journey',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
