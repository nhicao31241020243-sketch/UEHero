import 'package:flutter/material.dart';

@immutable
class AppRouteSnapshot {
  const AppRouteSnapshot({this.name, this.isPageRoute = true});

  final String? name;
  final bool isPageRoute;
}

class UeHeroRouteObserver extends RouteObserver<ModalRoute<void>> {}

class CompanionRouteObserver extends NavigatorObserver {
  final ValueNotifier<AppRouteSnapshot> routeChanges = ValueNotifier(
    const AppRouteSnapshot(),
  );

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _publish(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _publish(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _publish(newRoute);
  }

  void _publish(Route<dynamic> route) {
    routeChanges.value = AppRouteSnapshot(
      name: route.settings.name,
      isPageRoute: route is PageRoute<dynamic>,
    );
  }
}

final UeHeroRouteObserver ueHeroRouteObserver = UeHeroRouteObserver();
final CompanionRouteObserver companionRouteObserver = CompanionRouteObserver();
