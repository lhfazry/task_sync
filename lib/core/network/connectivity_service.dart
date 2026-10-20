import 'dart:async';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();

  ConnectivityService() {
    _controller.add(true);
  }

  Stream<bool> get onlineStream => _controller.stream;

  Future<bool> get isOnline async => true;

  void dispose() => _controller.close();
}
