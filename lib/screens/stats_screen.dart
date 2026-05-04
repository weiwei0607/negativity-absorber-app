import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/session_provider.dart';
import '../providers/goal_provider.dart';
import '../models/emotion_type.dart';
import '../models/chat_session.dart';
import '../models/goal.dart';

enum ReportPeriod { week, month, year, all }

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  ReportPeriod _period = ReportPeriod.month;

  List<ChatSession> _filterSessions(List<ChatSession> all) {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.week:
        final start = now.subtract(const Duration(days: 7));
        return all.where((s) => s.startedAt.isAfter(start)).toList();
      case ReportPeriod.month:
        final start = now.subtract(const Duration(days: 30));
        return all.where((s) => s.startedAt.isAfter(start)).toList();
      case ReportPeriod.year:
        final start = now.subtract(const Duration(days: 365));
        return all.where((s) => s.startedAt.isAfter(start)).toList();
      case ReportPeriod.all:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSessions = ref.watch(sessionProvider);
    final sessions = _filterSessions(allSessions);
    final goals = ref.watch(goalProvider);
    final goalNotifier = ref.read(goalProvider.notifier);

    if (allSessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('📊 心情數據')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('還沒有數據', style: TextStyle(color: Colors.grey, fontSize: 16)),
              SizedBox(height: 8),
              Text('多聊幾次後就可以看到統計圖表囉', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('📊 心情數據')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildSummaryCards(sessions),
            const SizedBox(height: 24),
            if (goals.where((g) => g.isActive).isNotEmpty) ...[
              _buildSectionTitle('🎯 目標進度'),
              const SizedBox(height: 12),
              _buildGoalProgress(goals.where((g) => g.isActive).toList(), sessions, goalNotifier),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle('情緒分布'),
            const SizedBox(height: 12),
            _buildPieChart(sessions),
            const SizedBox(height: 24),
            _buildSectionTitle('對話趨勢'),
            const SizedBox(height: 12),
            _buildTrendChart(sessions),
            const SizedBox(height: 24),
            _buildSectionTitle('各情緒次數'),
            const SizedBox(height: 12),
            _buildEmotionList(sessions),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final segments = <ButtonSegment<ReportPeriod>>[
      const ButtonSegment(value: ReportPeriod.week, label: Text('本週')),
      const ButtonSegment(value: ReportPeriod.month, label: Text('本月')),
      const ButtonSegment(value: ReportPeriod.year, label: Text('本年')),
      const ButtonSegment(value: ReportPeriod.all, label: Text('全部')),
    ];

    return Center(
      child: SegmentedButton<ReportPeriod>(
        segments: segments,
        selected: {_period},
        onSelectionChanged: (set) => setState(() => _period = set.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A2E),
          selectedBackgroundColor: const Color(0xFFE94560),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<ChatSession> sessions) {
    final taggedSessions = sessions.where((s) => s.taggedEmotion != null).toList();
    final emotionCounts = <EmotionType, int>{};
    for (final s in taggedSessions) {
      final emotion = s.taggedEmotion!;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }
    final topEmotion = emotionCounts.isNotEmpty
        ? emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard('總對話', '${sessions.length} 次', Icons.chat_bubble,
                  const Color(0xFFE94560)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '最常見',
                topEmotion != null ? '${topEmotion.key.emoji} ${topEmotion.key.label}' : '-',
                Icons.trending_up,
                topEmotion != null ? Color(topEmotion.key.colorValue) : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '已標記',
                '${taggedSessions.length} 次',
                Icons.label,
                const Color(0xFF00B894),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '平均頻率',
                sessions.length >= 2
                    ? '${(sessions.length / _getDaySpan(sessions)).toStringAsFixed(1)} 次/天'
                    : '-',
                Icons.calendar_today,
                const Color(0xFFFECA57),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getDaySpan(List<ChatSession> sessions) {
    if (sessions.length < 2) return 1;
    final first = sessions.last.startedAt;
    final last = sessions.first.startedAt;
    return last.difference(first).inDays.clamp(1, 9999).toDouble();
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGoalProgress(
    List<Goal> goals,
    List<ChatSession> sessions,
    GoalNotifier notifier,
  ) {
    return Column(
      children: goals.map((goal) {
        final progress = notifier.getProgress(goal, sessions);
        final current = notifier.getCurrentCount(goal, sessions);
        final isAchieved = current < goal.maxCount;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(
                          isAchieved ? const Color(0xFF00B894) : const Color(0xFFE94560),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$current/${goal.maxCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAchieved ? const Color(0xFF00B894) : const Color(0xFFE94560),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildPieChart(List<ChatSession> sessions) {
    final taggedSessions = sessions.where((s) => s.taggedEmotion != null).toList();
    final emotionCounts = <EmotionType, int>{};
    for (final s in taggedSessions) {
      final emotion = s.taggedEmotion!;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }
    final total = emotionCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('尚無情緒標記數據', style: TextStyle(color: Colors.grey)),
      );
    }

    final sections = emotionCounts.entries.map((e) {
      final percentage = (e.value / total) * 100;
      return PieChartSectionData(
        color: Color(e.key.colorValue),
        value: e.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 30,
                sectionsSpace: 2,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: emotionCounts.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(e.key.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${e.key.emoji} ${e.key.label}'),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<ChatSession> sessions) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    // Group by day
    final dailyCounts = <DateTime, int>{};
    for (final s in sessions) {
      final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
    }

    final sortedDays = dailyCounts.keys.toList()..sort();
    final spots = sortedDays.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), dailyCounts[e.value]!.toDouble());
    }).toList();

    final maxY = spots.isEmpty
        ? 1.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY < 1 ? 1 : maxY + 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFE94560),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFE94560).withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionList(List<ChatSession> sessions) {
    final taggedSessions = sessions.where((s) => s.taggedEmotion != null).toList();
    final emotionCounts = <EmotionType, int>{};
    for (final s in taggedSessions) {
      final emotion = s.taggedEmotion!;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }
    final sorted = emotionCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.isEmpty ? 1 : sorted.first.value;

    if (sorted.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('尚無情緒標記數據', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: sorted.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(e.key.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value / maxCount,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(Color(e.key.colorValue)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('${e.value}次', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
