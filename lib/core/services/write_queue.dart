import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Serializes all database write operations to prevent SQLite write contention.
/// Enqueue a closure; it executes after all previously enqueued closures finish.
///
/// Usage:
///   final queue = ref.read(writeQueueProvider);
///   final result = await queue.enqueue(() => db.insert(...));
class WriteQueue {
  final _queue = <_QueueEntry>[];
  bool _running = false;

  Future<T> enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _queue.add(_QueueEntry(
      run: () async {
        try {
          completer.complete(await operation());
        } catch (e, st) {
          completer.completeError(e, st);
        }
      },
    ));
    _drain();
    return completer.future;
  }

  void _drain() {
    if (_running || _queue.isEmpty) return;
    _running = true;
    _runNext();
  }

  Future<void> _runNext() async {
    if (_queue.isEmpty) {
      _running = false;
      return;
    }
    final entry = _queue.removeAt(0);
    await entry.run();
    _runNext();
  }
}

class _QueueEntry {
  final Future<void> Function() run;
  _QueueEntry({required this.run});
}

final writeQueueProvider = Provider<WriteQueue>((ref) => WriteQueue());
