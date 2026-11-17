import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/router.dart';
import '../data/logcat_repository.dart';
import '../logcat_parser.dart';

class LogcatView extends ConsumerStatefulWidget {
  const LogcatView({super.key});

  @override
  ConsumerState<LogcatView> createState() => _LogcatViewState();
}

class _LogcatViewState extends ConsumerState<LogcatView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final Set<LogcatLevel> _selectedLevels = {
    LogcatLevel.verbose,
    LogcatLevel.debug,
    LogcatLevel.info,
    LogcatLevel.warning,
    LogcatLevel.error,
    LogcatLevel.fatal,
  };

  bool _autoScroll = true;
  String _filterQuery = '';
  StreamSubscription? _logSub;
  List<LogcatEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _startLogcatStream();
  }

  void _startLogcatStream() {
    final nav = ref.read(navigationProvider);
    final serial = nav.selectedDeviceId;
    if (serial == null) return;

    final service = ref.read(logcatServiceProvider);
    service.start(serial);
    _logs = service.currentLogs;

    _logSub = service.logStream.listen((batch) {
      if (!mounted) return;
      setState(() {
        _logs.addAll(batch);
      });
      if (_autoScroll && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Color _getLevelColor(LogcatLevel level) {
    switch (level) {
      case LogcatLevel.verbose:
        return AppTokens.textMuted;
      case LogcatLevel.debug:
        return AppTokens.info;
      case LogcatLevel.info:
        return AppTokens.success;
      case LogcatLevel.warning:
        return AppTokens.warning;
      case LogcatLevel.error:
      case LogcatLevel.fatal:
        return AppTokens.error;
    }
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final serial = nav.selectedDeviceId;
    final service = ref.watch(logcatServiceProvider);

    if (serial == null) {
      return const Center(
        child: Text(
          'Please select an active device to view Logcat.',
          style: TextStyle(color: AppTokens.textMuted),
        ),
      );
    }

    final filteredLogs = _logs.where((l) {
      if (!_selectedLevels.contains(l.level)) return false;
      if (_filterQuery.isNotEmpty) {
        final q = _filterQuery.toLowerCase();
        return l.tag.toLowerCase().contains(q) ||
            l.message.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTokens.surface,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Filter by tag or message...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filterQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _filterQuery = val.trim()),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              // Level chips
              Wrap(
                spacing: 4,
                children: LogcatLevel.values.map((lvl) {
                  final isSelected = _selectedLevels.contains(lvl);
                  return FilterChip(
                    label: Text(lvl.code, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: _getLevelColor(lvl).withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? _getLevelColor(lvl)
                          : AppTokens.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLevels.add(lvl);
                        } else {
                          _selectedLevels.remove(lvl);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(service.isPaused ? Icons.play_arrow : Icons.pause),
                tooltip: service.isPaused ? 'Resume' : 'Pause',
                onPressed: () {
                  service.togglePause();
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear',
                onPressed: () {
                  service.clear();
                  setState(() => _logs.clear());
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_downward,
                  color: _autoScroll ? AppTokens.accent : AppTokens.textMuted,
                ),
                tooltip: 'Auto-scroll',
                onPressed: () {
                  setState(() => _autoScroll = !_autoScroll);
                },
              ),
            ],
          ),
        ),
        // Log view list
        Expanded(
          child: Container(
            color: AppTokens.background,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredLogs.length,
              itemExtent: 22.0,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                final color = _getLevelColor(log.level);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        log.time.isNotEmpty ? log.time : '--:--:--',
                        style: const TextStyle(
                          fontFamily: AppTokens.fontMono,
                          fontSize: 11,
                          color: AppTokens.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        log.level.code,
                        style: TextStyle(
                          fontFamily: AppTokens.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        child: Text(
                          log.tag,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTokens.fontMono,
                            fontSize: 11,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.message,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTokens.fontMono,
                            fontSize: 11,
                            color: AppTokens.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        // Footer line count
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: AppTokens.surface,
          alignment: Alignment.centerLeft,
          child: Text(
            'Lines: ${filteredLogs.length} / ${_logs.length}',
            style: const TextStyle(fontSize: 11, color: AppTokens.textMuted),
          ),
        ),
      ],
    );
  }
}
