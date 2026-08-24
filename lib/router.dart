import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_colors.dart';
import 'screens/home/home_dashboard_screen.dart';
import 'screens/active_job/active_job_screen.dart';
import 'screens/earnings/earnings_screen.dart';
import 'screens/welfare/welfare_fund_screen.dart';
import 'screens/profile/worker_profile_screen.dart';
import 'screens/onboarding/worker_registration_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    // Onboarding multi-step registration
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const WorkerRegistrationScreen(),
    ),

    // Stateful Shell with Bottom Navigation Bar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.orange.withValues(alpha: 0.15),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon:
                      const Icon(Icons.home_rounded, color: AppColors.orange),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.navigation_outlined),
                  selectedIcon: const Icon(Icons.navigation_rounded,
                      color: AppColors.orange),
                  label: 'Active Job',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(Icons.account_balance_wallet_rounded,
                      color: AppColors.orange),
                  label: 'Earnings',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.shield_outlined),
                  selectedIcon:
                      const Icon(Icons.shield_rounded, color: AppColors.teal),
                  label: 'Welfare',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon:
                      const Icon(Icons.person_rounded, color: AppColors.orange),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/active-job',
              builder: (context, state) => const ActiveJobScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/earnings',
              builder: (context, state) => const EarningsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/welfare',
              builder: (context, state) => const WelfareFundScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const WorkerProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
