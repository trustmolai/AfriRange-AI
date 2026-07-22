import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectivityState { online, offline }

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;
  Timer? _debounceTimer;

  ConnectivityCubit() : super(ConnectivityState.online) {
    _init();
  }

  void _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateState(result);

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      // 5-second debounce to prevent network flapping in rural rangeland areas
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 5), () {
        _updateState(result);
      });
    });
  }

  void _updateState(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      emit(ConnectivityState.offline);
    } else {
      emit(ConnectivityState.online);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
    return super.close();
  }
}
