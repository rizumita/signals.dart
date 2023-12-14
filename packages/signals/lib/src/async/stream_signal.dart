import 'dart:async';

import 'async_signal.dart';
import 'async_signal_state.dart';

class StreamSignal<T> extends AsyncSignal<T> {
  StreamSignal({
    Stream<T>? stream,
    T? initialValue,
    this.cancelOnError,
    super.debugLabel,
  }) : super(initialValue != null
            ? AsyncSignalState.data(initialValue)
            : AsyncSignalState.loading()) {
    if (stream != null) addStream(stream);
  }

  final _subscriptions = <(StreamSubscription<T>, void Function()?)>[];
  bool? cancelOnError;

  @override
  void reset() {
    for (final (sub, cb) in _subscriptions) {
      sub.cancel();
      cb?.call();
    }
    _subscriptions.clear();
  }

  /// Add a stream to listen to for updating the signal.
  ///
  /// This will not cancel any previous streams and will continue to listen to
  /// all streams until the signal is disposed.
  void addStream(
    Stream<T> stream, {
    bool? cancelOnError,
    void Function()? onDone,
  }) {
    final subscription = stream.listen(
      setValue,
      onError: setError,
      cancelOnError: cancelOnError,
      onDone: onDone,
    );
    _subscriptions.add((subscription, onDone));
  }

  /// Reset the signal and add a new stream to listen to for
  /// updating the signal.
  ///
  /// This will cancel any previous streams and will continue to listen to
  /// the new stream until the signal is disposed.
  void resetStream(
    Stream<T> stream, {
    bool? cancelOnError,
    void Function()? onDone,
  }) {
    reset();
    addStream(
      stream,
      cancelOnError: cancelOnError,
      onDone: onDone,
    );
  }

  @override
  void dispose() {
    for (final (sub, cb) in _subscriptions) {
      sub.cancel();
      cb?.call();
    }
    super.dispose();
  }
}

StreamSignal<T> streamSignal<T>(
  Stream<T> Function() stream, {
  T? initialValue,
  bool? cancelOnError,
  String? debugLabel,
}) {
  return StreamSignal(
    stream: stream(),
    initialValue: initialValue,
    cancelOnError: cancelOnError,
    debugLabel: debugLabel,
  );
}