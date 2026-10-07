import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/compliance_rules_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/inbox_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/listings/presentation/create_listing_screen.dart';
import '../../features/listings/presentation/listing_detail_screen.dart';
import '../../features/moderation/presentation/moderation_screen.dart';
import '../../features/my_listings/data/my_listings_repository.dart';
import '../../features/my_listings/presentation/edit_listing_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/operations/domain/operation.dart';
import '../../features/operations/presentation/operations_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/saved_searches/presentation/saved_searches_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/security/presentation/security_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/security/presentation/two_factor_challenge_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../../shared/widgets/app_shell.dart';

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 550),
    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

CustomTransitionPage<void> _sheetPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', pageBuilder: (context, state) => _fadePage(state, const LoginScreen())),
      GoRoute(
        path: '/two-factor',
        // Sin token pendiente (p. ej. recarga de la app) no hay nada que verificar: a iniciar sesión.
        redirect: (context, state) => state.extra is String ? null : '/login',
        builder: (context, state) => TwoFactorChallengeScreen(challengeToken: state.extra! as String),
      ),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => _fadePage(state, AppShell(shell: shell)),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/inbox', builder: (context, state) => const InboxScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/compliance-rules', builder: (context, state) => const ComplianceRulesScreen()),
      GoRoute(path: '/saved-searches', builder: (context, state) => const SavedSearchesScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/verification', builder: (context, state) => const VerificationScreen()),
      GoRoute(path: '/security', builder: (context, state) => const SecurityScreen()),
      GoRoute(
        path: '/listing/:id/edit',
        redirect: (context, state) => state.extra is MyListing ? null : '/profile',
        builder: (context, state) => EditListingScreen(listing: state.extra! as MyListing),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) => ListingDetailScreen(
          id: state.pathParameters['id']!,
          heroTag: state.uri.queryParameters['hero'],
        ),
      ),
      GoRoute(path: '/create', pageBuilder: (context, state) => _sheetPage(state, const CreateListingScreen())),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/moderation', builder: (context, state) => const ModerationScreen()),
      GoRoute(path: '/purchases', builder: (context, state) => const OperationsScreen(role: OperationRole.buyer)),
      GoRoute(path: '/sales', builder: (context, state) => const OperationsScreen(role: OperationRole.seller)),
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    ],
  );
});
