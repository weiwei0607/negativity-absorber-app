import 'dart:async';
import 'package:flutter/material.dart';

class RelaxationExercise {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final int durationMinutes;
  final List<String> steps;
  final Color color;

  const RelaxationExercise({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.durationMinutes,
    required this.steps,
    required this.color,
  });
}

final List<RelaxationExercise> _exercises = [
  const RelaxationExercise(
    id: 'breathing_478',
    title: '4-7-8 呼吸法',
    emoji: '🫁',
    description: '吸氣4秒、憋氣7秒、吐氣8秒。經研究證實能有效降低生理喚醒。',
    durationMinutes: 3,
    steps: [
      '找個舒適的姿勢坐好或躺好',
      '用鼻子吸氣，心裡默數 4 秒',
      '屏住呼吸，默數 7 秒',
      '用嘴巴完全吐氣，默數 8 秒',
      '重複這個循環',
      '如果覺得憋氣7秒太長，可以先從較短的時間開始',
    ],
    color: Color(0xFF00D9FF),
  ),
  const RelaxationExercise(
    id: 'body_scan',
    title: '身體掃描',
    emoji: '🧘',
    description: '從頭到腳慢慢掃描身體每個部位，釋放緊繃。',
    durationMinutes: 10,
    steps: [
      '躺下，閉上眼睛，深呼吸三次',
      '把注意力放到頭頂，感受那裡的感覺',
      '慢慢往下移：額頭、眼睛、下巴、脖子',
      '繼續往下：肩膀、手臂、手掌、手指',
      '胸口、腹部、背部',
      '臀部、大腿、小腿、腳掌、腳趾',
      '不需要改變任何東西，只是觀察',
    ],
    color: Color(0xFF9B59B6),
  ),
  const RelaxationExercise(
    id: 'muscle_relaxation',
    title: '漸進式肌肉放鬆',
    emoji: '💆',
    description: '收緊再放鬆各部位肌肉，讓身體進入深度放鬆狀態。',
    durationMinutes: 8,
    steps: [
      '從右手開始，用力握拳 5 秒',
      '突然放鬆，感受放鬆的感覺',
      '換左手，重複同樣的動作',
      '聳起肩膀靠近耳朵，保持 5 秒，然後放下',
      '收緊腹部肌肉 5 秒，然後放鬆',
      '繃緊大腿肌肉 5 秒，然後放鬆',
      '腳趾用力往內勾 5 秒，然後放鬆',
      '最後，全身一起放鬆',
    ],
    color: Color(0xFF00B894),
  ),
  const RelaxationExercise(
    id: 'grounding_54321',
    title: 'Grounding 5-4-3-2-1',
    emoji: '🌿',
    description: '用五種感官把自己拉回當下，有效中斷焦慮循環。',
    durationMinutes: 3,
    steps: [
      '睜開眼睛，環顧四周',
      '說出你看到的 5 樣東西',
      '說出你聽到的 4 種聲音',
      '說出你摸到的 3 種觸感',
      '說出你聞到的 2 種味道',
      '說出你嚐到的 1 種味道',
      '深呼吸一下，感受此刻的安全',
    ],
    color: Color(0xFFFECA57),
  ),
];

class RelaxationScreen extends StatelessWidget {
  const RelaxationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌙 睡眠前放鬆')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Text(exercise.emoji, style: const TextStyle(fontSize: 36)),
              title: Text(
                exercise.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(exercise.description, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text('${exercise.durationMinutes} 分鐘'),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: exercise.color.withValues(alpha: 0.2),
                    side: BorderSide(color: exercise.color.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RelaxationSessionScreen(exercise: exercise),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RelaxationSessionScreen extends StatefulWidget {
  final RelaxationExercise exercise;

  const RelaxationSessionScreen({super.key, required this.exercise});

  @override
  State<RelaxationSessionScreen> createState() => _RelaxationSessionScreenState();
}

class _RelaxationSessionScreenState extends State<RelaxationSessionScreen> {
  int _currentStep = 0;
  bool _isRunning = false;
  Timer? _timer;
  int _elapsedSeconds = 0;

  void _start() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _nextStep() {
    if (_currentStep < widget.exercise.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _timer?.cancel();
      setState(() => _isRunning = false);
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🌟 放鬆完成'),
        content: const Text('感覺有沒有好一點？記得，放鬆是一種可以練習的能力，每一次練習都在讓自己變得更強大。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.exercise.steps[_currentStep];
    final progress = (_currentStep + 1) / widget.exercise.steps.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(widget.exercise.color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '步驟 ${_currentStep + 1} / ${widget.exercise.steps.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Text(
                  step,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, height: 1.6),
                ),
              ),
            ),
            if (_isRunning)
              Text(
                _formatTime(_elapsedSeconds),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: widget.exercise.color,
                ),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning && _elapsedSeconds == 0)
                  ElevatedButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('開始練習'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.exercise.color,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  )
                else ...[
                  IconButton(
                    onPressed: _isRunning ? _pause : _start,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 32),
                    color: widget.exercise.color,
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: const Icon(Icons.skip_next),
                    label: Text(_currentStep < widget.exercise.steps.length - 1
                        ? '下一步'
                        : '完成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.exercise.color,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
