import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';
import '../services/llm_client.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _testingConnection = false;
  String? _connectionResult;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _apiKeyController.text = settings.apiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  static const _colorOptions = [
    _ColorOption('Red', Color(0xFFE74C3C)),
    _ColorOption('Orange', Color(0xFFE67E22)),
    _ColorOption('Yellow', Color(0xFFF1C40F)),
    _ColorOption('Green', Color(0xFF27AE60)),
    _ColorOption('Blue', Color(0xFF2980B9)),
    _ColorOption('Purple', Color(0xFF8E44AD)),
    _ColorOption('Pink', Color(0xFFE91E63)),
    _ColorOption('Teal', Color(0xFF009688)),
    _ColorOption('Grey', Color(0xFF999999)),
    _ColorOption('Dark', Color(0xFF34495E)),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Display Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(theme, 'Unknown Words'),
          const SizedBox(height: 4),
          Text(
            'Words not yet in your vocabulary list',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _buildColorPicker(context, settings, 'unknown', settings.colors.unknownColor, (c) => settings.setUnknownColor(c)),
          const SizedBox(height: 24),
          _buildSectionTitle(theme, 'Learning Words'),
          const SizedBox(height: 4),
          Text(
            'Words you are currently studying',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _buildColorPicker(context, settings, 'learning', settings.colors.learningColor, (c) => settings.setLearningColor(c)),
          const SizedBox(height: 24),
          _buildSectionTitle(theme, 'Known Words'),
          const SizedBox(height: 4),
          Text(
            'Words you have already mastered (shown with subtle underline)',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _buildColorPicker(context, settings, 'known', settings.colors.knownColor, (c) => settings.setKnownColor(c)),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          _buildSectionTitle(theme, 'AI Settings'),
          const SizedBox(height: 4),
          Text(
            'Configure your DeepSeek API key to enable AI features',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _buildApiKeyField(theme, settings),
          const SizedBox(height: 12),
          _buildTestConnectionButton(theme, settings),
          if (_connectionResult != null) ...[
            const SizedBox(height: 8),
            Text(
              _connectionResult!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _connectionResult!.contains('成功')
                    ? Colors.green
                    : theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildClearCacheButton(theme, settings),
        ],
      ),
    );
  }

  Widget _buildApiKeyField(ThemeData theme, SettingsService settings) {
    return TextField(
      controller: _apiKeyController,
      obscureText: _obscureKey,
      decoration: InputDecoration(
        labelText: 'DeepSeek API Key',
        hintText: 'sk-...',
        prefixIcon: const Icon(Icons.key, size: 20),
        suffixIcon: IconButton(
          icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off, size: 20),
          onPressed: () => setState(() => _obscureKey = !_obscureKey),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (value) {
        settings.setApiKey(value);
        _connectionResult = null;
      },
    );
  }

  Widget _buildTestConnectionButton(ThemeData theme, SettingsService settings) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _testingConnection || settings.apiKey.isEmpty
            ? null
            : () => _testConnection(settings),
        icon: _testingConnection
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.wifi_find, size: 18),
        label: Text(_testingConnection ? '测试中...' : '测试连接'),
      ),
    );
  }

  Future<void> _testConnection(SettingsService settings) async {
    setState(() {
      _testingConnection = true;
      _connectionResult = null;
    });

    final client = LLMClient(settings);
    final ok = await client.testConnection(settings.apiKey);

    setState(() {
      _testingConnection = false;
      _connectionResult = ok ? '连接成功' : '连接失败，请检查 API Key';
    });
  }

  Widget _buildClearCacheButton(ThemeData theme, SettingsService settings) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showClearCacheDialog(),
        icon: const Icon(Icons.delete_sweep, size: 18),
        label: const Text('清除 AI 缓存'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清除 AI 缓存'),
        content: const Text('将清除所有章节总结和练习题缓存。下次使用需要重新调用 AI 生成。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<ReadingProvider>().clearAICache();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI 缓存已清除')),
                );
              }
            },
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600));
  }

  Widget _buildColorPicker(
    BuildContext context,
    SettingsService settings,
    String category,
    Color currentColor,
    void Function(Color) onColorChanged,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colorOptions.map((opt) {
        final isSelected = currentColor.toARGB32() == opt.color.toARGB32();
        return GestureDetector(
          onTap: () => onColorChanged(opt.color),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: opt.color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                  : Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: isSelected
                  ? [BoxShadow(color: opt.color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  static Widget previewWord({
    required Color color,
    String word = 'example',
    bool showUnderline = false,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        word,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
          decoration: showUnderline ? TextDecoration.underline : TextDecoration.underline,
          decorationColor: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ColorOption {
  final String name;
  final Color color;
  const _ColorOption(this.name, this.color);
}
