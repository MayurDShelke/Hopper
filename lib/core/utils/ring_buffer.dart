import 'dart:collection';

class RingBuffer<T> {
  final int capacity;
  final ListQueue<T> _queue;

  RingBuffer(this.capacity) : _queue = ListQueue<T>(capacity) {
    if (capacity <= 0) {
      throw ArgumentError('Capacity must be positive');
    }
  }

  void add(T item) {
    if (_queue.length >= capacity) {
      _queue.removeFirst();
    }
    _queue.addLast(item);
  }

  void addAll(Iterable<T> items) {
    for (final item in items) {
      add(item);
    }
  }

  int get length => _queue.length;
  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;

  void clear() => _queue.clear();

  List<T> toList() => _queue.toList();
}
