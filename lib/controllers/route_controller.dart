import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/dashboard/dashboard.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref);

  final Ref ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) {
      // }
      return '/dashboard';
    },
    routes: [
      GoRoute(path: '/dashboard', builder: (context, state) => DashboardPage()),
    ],
  );
});
