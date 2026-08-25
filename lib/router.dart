import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/active_job/active_job_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/earnings/earnings_screen.dart';
import 'screens/home/home_dashboard_screen.dart';
import 'screens/onboarding/worker_registration_screen.dart';
import 'screens/profile/worker_profile_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/welfare/welfare_fund_screen.dart';
import 'widgets/animated_bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final _authRefresh = ChangeNotifierProvider<_AuthRefresh>((ref) {
  final notifier = _AuthRefresh();
  ref.listen(authProvider, (_, __) => notifier.ping());
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _AuthRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: ref.watch(_authRefresh),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading && state.matchedLocation == '/') return null;

      final location = state.matchedLocation;

      if (!auth.isAuthenticated) {
        // Splash handles its own wait; everything else funnels to login.
        return location == '/' ? null : '/login';
      }
      if (location == '/' || location == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WorkerRegistrationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            extendBody: true,
            bottomNavigationBar: AnimatedBottomNav(
              currentIndex: navigationShell.currentIndex,
              onTap: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
              items: const [
                AnimatedNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home'),
                AnimatedNavItem(
                    icon: Icons.navigation_outlined,
                    activeIcon: Icons.navigation_rounded,
                    label: 'Job'),
                AnimatedNavItem(
                    icon: Icons.payments_outlined,
                    activeIcon: Icons.payments_rounded,
                    label: 'Earnings'),
                AnimatedNavItem(
                    icon: Icons.volunteer_activism_outlined,
                    activeIcon: Icons.volunteer_activism_rounded,
                    label: 'Welfare'),
                AnimatedNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile'),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/home',
                builder: (context, state) => const HomeDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/active-job',
                builder: (context, state) => const ActiveJobScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/earnings',
                builder: (context, state) => const EarningsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/welfare',
                builder: (context, state) => const WelfareFundScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile',
                builder: (context, state) => const WorkerProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
