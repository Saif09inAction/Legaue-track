import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently has a network interface that can reach the feed.
final isOnlineProvider = NotifierProvider<ConnectivityController, bool>(
  ConnectivityController.new,
);

class ConnectivityController extends Notifier<bool> {
  @override
  bool build() {
    final connectivity = Connectivity();
    var active = true;
    final subscription = connectivity.onConnectivityChanged.listen((results) {
      if (!active) {
        return;
      }
      state = results.hasNetwork;
    }, onError: (_, _) {});
    ref.onDispose(() {
      active = false;
      subscription.cancel();
    });
    unawaited(
      connectivity
          .checkConnectivity()
          .then((results) {
            if (!active) {
              return;
            }
            state = results.hasNetwork;
          })
          .catchError((_) {}),
    );
    return true;
  }
}

extension on List<ConnectivityResult> {
  bool get hasNetwork {
    return any((result) => result != ConnectivityResult.none);
  }
}
