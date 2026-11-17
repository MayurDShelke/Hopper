import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab {
  overview,
  connect,
  devices,
  mirror,
  logcat,
  install,
  flutterPanel,
  diagnostics,
  settings,
}

class NavigationState {
  final AppTab currentTab;
  final String? selectedDeviceId;

  const NavigationState({
    this.currentTab = AppTab.connect,
    this.selectedDeviceId,
  });

  NavigationState copyWith({
    AppTab? currentTab,
    String? selectedDeviceId,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void setTab(AppTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void selectDevice(String? deviceId) {
    state = state.copyWith(
      selectedDeviceId: deviceId,
      currentTab: deviceId != null ? AppTab.overview : AppTab.connect,
    );
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});
