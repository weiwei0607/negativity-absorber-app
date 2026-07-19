import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/pin_service.dart';
import '../providers/theme_provider.dart';
import 'relaxation_screen.dart';
import 'pin_lock_screen.dart';
import 'goals_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _pinEnabled = false;
  late TextEditingController _companionNameController;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    final settings = ref.read(settingsProvider);
    _companionNameController = TextEditingController(text: settings.companionName);
    _apiKeyController = TextEditingController(text: settings.apiKey);
  }

  @override
  void dispose() {
    _companionNameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final pinEnabled = await PinService.isPinEnabled();
    setState(() => _pinEnabled = pinEnabled);
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyCheckIn(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await NotificationService.cancelDailyCheckIn();
    }
    setState(() => _reminderEnabled = value);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      if (_reminderEnabled) {
        await NotificationService.scheduleDailyCheckIn(
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    }
  }

  Future<void> _setupPin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PinLockScreen(isSetup: true)),
    );
    if (result == true) {
      setState(() => _pinEnabled = true);
    }
  }

  Future<void> _clearPin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除 PIN 碼'),
        content: const Text('確定要移除 PIN 密碼鎖嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('移除')),
        ],
      ),
    );
    if (confirm == true) {
      await PinService.clearPin();
      setState(() => _pinEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ 設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('工具'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.nightlight_round, color: Color(0xFF9B59B6)),
                  title: const Text('🌙 睡眠前放鬆'),
                  subtitle: const Text('4-7-8 呼吸、身體掃描、肌肉放鬆等引導'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RelaxationScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.track_changes, color: Color(0xFF00B894)),
                  title: const Text('🎯 情緒目標'),
                  subtitle: const Text('設定並追蹤你的情緒管理目標'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('每日提醒'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('🔔 每日情緒檢查'),
                  subtitle: const Text('每天提醒你記錄情緒'),
                  value: _reminderEnabled,
                  onChanged: _toggleReminder,
                ),
                if (_reminderEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('提醒時間'),
                    trailing: Text(
                      _reminderTime.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                    onTap: _pickReminderTime,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('安全'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('🔐 PIN 密碼鎖'),
                  subtitle: Text(_pinEnabled ? '已啟用' : '未啟用'),
                  value: _pinEnabled,
                  onChanged: (value) {
                    if (value) {
                      _setupPin();
                    } else {
                      _clearPin();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('個人化'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('主題顏色', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final currentTheme = ref.watch(themeProvider);
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: presetThemes.map((theme) {
                          final isSelected = currentTheme.id == theme.id;
                          return GestureDetector(
                            onTap: () => ref.read(themeProvider.notifier).setTheme(theme),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: theme.primary.withValues(alpha: 0.5),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('AI 朋友', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _companionNameController,
                    decoration: const InputDecoration(
                      labelText: '朋友名字',
                      hintText: '例如：阿樹',
                    ),
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).save(
                            settings.copyWith(companionName: value),
                          );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '你可以幫 AI 朋友取任何名字。預設是「阿樹」。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('AI 設定（必要）'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!settings.hasApiKey)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '尚未設定 API Key，請在下方輸入你的 API Key',
                              style: TextStyle(color: Colors.orange, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: _getApiKeyHint(settings.aiProvider),
                    ),
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).save(
                            settings.copyWith(apiKey: value),
                          );
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: settings.aiProvider,
                    decoration: const InputDecoration(labelText: 'AI 提供者'),
                    items: const [
                      DropdownMenuItem(value: 'gemini', child: Text('Google Gemini')),
                      DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                      DropdownMenuItem(value: 'moonshot', child: Text('Moonshot (Kimi)')),
                    ],
                    onChanged: (value) {
                      // 切換提供者時重設模型，避免沿用不屬於新提供者的模型
                      ref.read(settingsProvider.notifier).save(
                            AppSettings(
                              apiKey: settings.apiKey,
                              aiProvider: value ?? 'gemini',
                              companionName: settings.companionName,
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _getModelItems(settings.aiProvider)
                            .any((item) => item.value == settings.aiModel)
                        ? settings.aiModel
                        : null,
                    decoration: const InputDecoration(labelText: '模型'),
                    items: _getModelItems(settings.aiProvider),
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).save(
                            settings.copyWith(aiModel: value),
                          );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'API Key 只儲存在你的裝置上，不會上傳到任何伺服器。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('關於'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('負能量吸收器'),
                  subtitle: Text('v1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('隱私說明'),
                  subtitle: const Text('所有資料只儲存在你的裝置上'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrivacyDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.health_and_safety),
                  title: const Text('免責聲明'),
                  subtitle: const Text('本 App 不是專業治療的替代'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDisclaimerDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  String _getApiKeyHint(String provider) {
    switch (provider) {
      case 'openai':
        return '在 platform.openai.com 取得';
      case 'moonshot':
        return '在 platform.moonshot.cn 取得';
      default:
        return '在 Google AI Studio 取得';
    }
  }

  List<DropdownMenuItem<String>> _getModelItems(String? provider) {
    switch (provider) {
      case 'openai':
        return const [
          DropdownMenuItem(value: null, child: Text('預設 (gpt-4o-mini)')),
          DropdownMenuItem(value: 'gpt-4o', child: Text('GPT-4o')),
          DropdownMenuItem(value: 'gpt-4o-mini', child: Text('GPT-4o Mini')),
          DropdownMenuItem(value: 'gpt-3.5-turbo', child: Text('GPT-3.5 Turbo')),
        ];
      case 'moonshot':
        return const [
          DropdownMenuItem(value: null, child: Text('預設 (moonshot-v1-8k)')),
          DropdownMenuItem(value: 'moonshot-v1-8k', child: Text('Moonshot v1 8k')),
          DropdownMenuItem(value: 'moonshot-v1-32k', child: Text('Moonshot v1 32k')),
          DropdownMenuItem(value: 'moonshot-v1-128k', child: Text('Moonshot v1 128k')),
        ];
      case 'gemini':
        return const [
          DropdownMenuItem(value: null, child: Text('預設 (gemini-2.5-flash)')),
          DropdownMenuItem(value: 'gemini-2.5-flash', child: Text('Gemini 2.5 Flash')),
          DropdownMenuItem(value: 'gemini-2.5-pro', child: Text('Gemini 2.5 Pro')),
          DropdownMenuItem(value: 'gemini-2.0-flash', child: Text('Gemini 2.0 Flash')),
          DropdownMenuItem(value: 'gemini-2.0-pro', child: Text('Gemini 2.0 Pro')),
        ];
      case 'custom':
        return const [
          DropdownMenuItem(value: null, child: Text('自定義')),
        ];
      default:
        return const [
          DropdownMenuItem(value: null, child: Text('請先選擇 AI 提供者')),
        ];
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隱私說明'),
        content: const Text(
          '負能量吸收器非常重視你的隱私：\n\n'
          '• 所有日記內容都儲存在你的裝置上（使用 Hive 本地資料庫）\n'
          '• 不會上傳任何資料到伺服器\n'
          '• 對話內容會直接傳送到你選擇的 AI 服務商（Gemini / OpenAI / Moonshot）\n'
          '• API Key 只儲存在你的裝置上，不會出現在程式碼或伺服器中\n'
          '• 記憶摘要儲存在你的裝置上，不會上傳到任何伺服器\n'
          '• 對話紀錄儲存在你的裝置上（Hive 本地資料庫）\n\n'
          '你的祕密，只有你和你的裝置知道 🤫',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('了解')),
        ],
      ),
    );
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('免責聲明'),
        content: const Text(
          '本 App 的設計基於以下心理學研究：\n\n'
          '• 表達性書寫（Expressive Writing）— Pennebaker & Beall (1986)\n'
          '• 憤怒管理的元分析 — Kjærvik & Bushman (2024), Clinical Psychology Review\n'
          '• 認知行為療法（CBT）— NICE 指南推薦\n\n'
          '但請注意：\n'
          '• 本 App 是情緒自我照顧工具，不是專業心理治療的替代\n'
          '• 若你有自殺/自傷念頭、嚴重憂鬱、焦慮影響日常生活，請立即尋求專業協助\n'
          '• 本 App 無法處理危機狀況\n\n'
          '緊急求助資源：\n'
          '• 台灣 安心專線：1925\n'
          '• 台灣 生命線：1995\n'
          '• 台灣 張老師：1980\n\n'
          '你的情緒很重要，值得被專業對待。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('了解')),
        ],
      ),
    );
  }
}
