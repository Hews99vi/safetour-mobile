import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VpnStatus { protected, unsecured, connecting }

class VpnState {
  const VpnState({
    this.status = VpnStatus.unsecured,
  });

  final VpnStatus status;

  bool get isActive => status == VpnStatus.protected;
  bool get isConnecting => status == VpnStatus.connecting;

  VpnState copyWith({VpnStatus? status}) {
    return VpnState(status: status ?? this.status);
  }
}

class VpnController extends Notifier<VpnState> {
  Timer? _timer;

  @override
  VpnState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const VpnState();
  }

  void toggle() {
    if (state.isConnecting) return;
    if (state.isActive) {
      state = state.copyWith(status: VpnStatus.unsecured);
      return;
    }
    state = state.copyWith(status: VpnStatus.connecting);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      state = state.copyWith(status: VpnStatus.protected);
    });
  }
}

final vpnControllerProvider =
    NotifierProvider<VpnController, VpnState>(VpnController.new);
