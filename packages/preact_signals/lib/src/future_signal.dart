import 'package:preact_signals/preact_signals.dart';

/// A [Signal] that wraps a [Future]
///
/// The [FutureSignal] will return [SignalState] for the value. To react to
/// the various states you can use a switch statement:
///
/// ```dart
/// final s = FutureSignal(...);
/// final result = (switch(s.value) {
///   SignalValue result => print('value: ${result.value}'),
///   SignalTimeout _ => print('timeout error'),
///   SignalError result => print('error: ${result.error}'),
///   SignalLoading _ => print('loading'),
/// });
/// ```
class FutureSignal<T> extends Signal<SignalState<T>> {
  /// Future [Duration] to wait before timing out
  final Duration? timeout;

  /// If true then the future will be called immediately
  final bool fireImmediately;

  /// Creates a [FutureSignal] that wraps a [Future]
  FutureSignal(
    this._getFuture, {
    this.timeout,
    this.fireImmediately = true,
  }) : super(SignalLoading<T>()) {
    _stale = true;
    if (fireImmediately) _init();
  }

  final Future<T> Function() _getFuture;
  bool _stale = false;

  /// Resets the signal by calling the [Future] again
  void reset() {
    _stale = true;
    if (fireImmediately) _init();
  }

  void _init() {
    if (!_stale) return;
    _stale = false;
    if (peek() is! SignalLoading<T>) {
      value = SignalLoading<T>();
    }
    var f = _getFuture();
    if (timeout != null) {
      f = f.timeout(timeout!, onTimeout: () {
        throw SignalTimeout();
      });
    }
    f.then((value) {
      this.value = SignalValue<T>(value);
    }).catchError((error) {
      if (error is SignalTimeout<T>) {
        value = error;
      } else {
        value = SignalError<T, Object>(error);
      }
    });
  }

  @override
  SignalState<T> get value {
    _init();
    return super.value;
  }
}

/// Create a [FutureSignal] from a [Future]
FutureSignal<T> futureSignal<T>(
  Future<T> Function() compute, {
  Duration? timeout,
  bool fireImmediately = true,
}) {
  return FutureSignal<T>(
    compute,
    timeout: timeout,
    fireImmediately: fireImmediately,
  );
}
