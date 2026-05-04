class Constants {
  static const String appName = '負能量吸收器';
  static const String hiveBoxName = 'journal_entries';
  static const String chatSessionsBoxName = 'chat_sessions';
  static const String memoryBoxName = 'memory_profile';
  static const String prefsKey = 'na_settings';

  static const List<String> angryKeywords = [
    '氣', '怒', '火大', '幹', '靠', '媽的', '不爽', '討厭', '恨', '炸', '爆', '煩', '怒',
    '賭爛', '幹你', '去死', '白目', '智障', '白痴', '神經', '有病'
  ];

  static const List<String> sadKeywords = [
    '難過', '哭', '傷心', '難受', '痛', '委屈', '失落', '沮喪', '憂鬱', '悶',
    '孤單', '寂寞', '無助', '絕望', '失望', '心累', '好累'
  ];

  static const List<String> tiredKeywords = [
    '累', '疲憊', '倦', '撐', '壓力', '忙', '加班', '睡不飽', '耗盡', '透支',
    '爆肝', '沒力', '虛', '精神差', '想睡'
  ];

  static const List<String> anxiousKeywords = [
    '焦慮', '緊張', '擔心', '害怕', '恐懼', '不安', '慌', '壓力大', '喘不過氣',
    '煩躁', '坐立難安', '想太多'
  ];
}
