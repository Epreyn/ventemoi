import 'dart:async';
import 'package:get/get.dart';

mixin StreamMixin on GetxController {
  final Map<String, StreamSubscription> _subscriptions = {};
  
  void addSubscription(String key, StreamSubscription subscription) {
    cancelSubscription(key);
    _subscriptions[key] = subscription;
  }
  
  void cancelSubscription(String key) {
    _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
  }
  
  void cancelAllSubscriptions() {
    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
  
  bool hasSubscription(String key) {
    return _subscriptions.containsKey(key);
  }
  
  StreamSubscription? getSubscription(String key) {
    return _subscriptions[key];
  }
  
  @override
  void onClose() {
    cancelAllSubscriptions();
    super.onClose();
  }
}