import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';

class FontSettingsSheet extends StatelessWidget {
  const FontSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.65,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
            child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 20),
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('字体设置', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              _buildFontSizeSection(provider, theme),
              const SizedBox(height: 20),
              _buildFontFamilySection(provider, theme),
              const SizedBox(height: 20),
              _buildLineHeightSection(provider, theme),
              const SizedBox(height: 20),
              _buildThemeSection(provider, theme),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontSizeSection(ReadingProvider provider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('字号', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${provider.fontSize.toInt()}',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: provider.fontSize,
          min: 12,
          max: 24,
          divisions: 12,
          activeColor: theme.colorScheme.primary,
          onChanged: (v) => provider.setFontSize(v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('A', style: theme.textTheme.labelSmall),
            Text('A', style: theme.textTheme.titleLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildFontFamilySection(ReadingProvider provider, ThemeData theme) {
    final families = ['Serif', 'Sans-serif', 'Monospace'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('字体', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: families.map((family) {
            final isSelected = provider.fontFamily == family;
            return ChoiceChip(
              label: Text(
                family,
                style: TextStyle(
                  fontFamily: family,
                  fontSize: 14,
                  color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primaryContainer,
              onSelected: (_) => provider.setFontFamily(family),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLineHeightSection(ReadingProvider provider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('行间距', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              provider.lineHeight.toStringAsFixed(1),
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: provider.lineHeight,
          min: 1.4,
          max: 2.8,
          divisions: 7,
          activeColor: theme.colorScheme.primary,
          onChanged: (v) => provider.setLineHeight(v),
        ),
      ],
    );
  }

  Widget _buildThemeSection(ReadingProvider provider, ThemeData theme) {
    final themes = [
      {'key': 'light', 'label': '浅色', 'color': Colors.white},
      {'key': 'sepia', 'label': '护眼', 'color': const Color(0xFFF5ECD7)},
      {'key': 'dark', 'label': '深色', 'color': const Color(0xFF2D2D2D)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('主题', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: themes.map((t) {
            final isSelected = provider.readingTheme == t['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => provider.setReadingTheme(t['key'] as String),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: t['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: t['key'] == 'dark' ? Colors.white : theme.colorScheme.primary, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(t['label'] as String, style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
