import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../models/reader_font.dart';
import '../providers/reading/reading_config_provider.dart';

class FontSettingsSheet extends StatelessWidget {
  const FontSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.52,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return _FontSettingsPanelSurface(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: _FontSettingsPanelContent(
              scrollController: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              onClose: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }
}

class FontSettingsDropdownPanel extends StatelessWidget {
  final VoidCallback? onClose;
  final double? width;
  final double maxHeight;

  const FontSettingsDropdownPanel({
    super.key,
    this.onClose,
    this.width,
    this.maxHeight = 600,
  });

  static double preferredWidthFor(Size screenSize) {
    return (screenSize.width * 0.72).clamp(560.0, 820.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final panelWidth = width ?? preferredWidthFor(screenSize);
    final panelHeight = (screenSize.height - 96)
        .clamp(420.0, maxHeight)
        .toDouble();

    return SizedBox(
      key: const ValueKey('font-settings-dropdown-panel'),
      width: panelWidth,
      height: panelHeight,
      child: _FontSettingsPanelSurface(
        borderRadius: BorderRadius.circular(8),
        elevation: 8,
        child: _FontSettingsPanelContent(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
          onClose: onClose,
          showPreview: false,
        ),
      ),
    );
  }
}

class _FontSettingsPanelSurface extends StatelessWidget {
  final BorderRadius borderRadius;
  final double elevation;
  final Widget child;

  const _FontSettingsPanelSurface({
    required this.borderRadius,
    required this.child,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: elevation,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.16),
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _FontSettingsPanelContent extends riverpod.ConsumerWidget {
  final ScrollController? scrollController;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onClose;
  final bool showPreview;

  const _FontSettingsPanelContent({
    required this.padding,
    this.scrollController,
    this.onClose,
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final provider = ref.watch(readingConfigProvider);
    final theme = Theme.of(context);
    final panelPadding = padding.resolve(Directionality.of(context));

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            panelPadding.left,
            panelPadding.top,
            panelPadding.right,
            0,
          ),
          child: Column(
            children: [
              _PanelHeader(onClose: onClose),
              if (showPreview) ...[
                const SizedBox(height: 14),
                _ReadingPreviewCard(
                  key: const ValueKey('reading-settings-preview'),
                  provider: provider,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= 640;
              return ListView(
                controller: scrollController,
                primary: false,
                padding: EdgeInsets.fromLTRB(
                  panelPadding.left,
                  16,
                  panelPadding.right,
                  18,
                ),
                children: [
                  _CompactAdjustmentGrid(provider: provider),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (twoColumn)
                    _DesktopChoiceGrid(provider: provider)
                  else
                    _CompactChoiceStack(provider: provider),
                ],
              );
            },
          ),
        ),
        _PanelFooter(provider: provider),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const _PanelHeader({this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '阅读设置',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '调整排版与外观，获得更舒适的阅读体验',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          tooltip: '关闭阅读设置',
          onPressed: onClose,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }
}

class _ReadingPreviewCard extends StatelessWidget {
  final ReadingConfigController provider;

  const _ReadingPreviewCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _themePalette(provider.readingTheme, theme);
    final fontSize = provider.fontSize.clamp(15.0, 20.0).toDouble();
    final bodyStyle = TextStyle(
      color: palette.foreground,
      fontFamily: provider.fontFamily,
      fontSize: fontSize,
      height: provider.lineHeight.clamp(1.4, 2.4).toDouble(),
      letterSpacing: 0,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '春天的夜晚，空气里有一点潮湿的气息。远处的灯光在树影间若隐若现，仿佛在诉说着这座城市的故事。',
              style: bodyStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'The quick brown fox jumps over the lazy dog.',
              style: bodyStyle.copyWith(height: 1.45),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '链接示例',
                  style: bodyStyle.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '粗体示例',
                  style: bodyStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '斜体示例',
                  style: bodyStyle.copyWith(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.codeBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      '代码示例',
                      style: bodyStyle.copyWith(
                        fontFamily: ReaderFonts.systemMonospace,
                        fontSize: 13,
                        color: palette.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FontSizeControl extends StatelessWidget {
  final ReadingConfigController provider;

  const _FontSizeControl({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _CompactAdjustControl(
      title: '字体大小',
      valueLabel: '${provider.fontSize.round()} pt',
      value: provider.fontSize,
      min: 12,
      max: 24,
      divisions: 12,
      onChanged: provider.setFontSize,
      step: 1,
      minLabel: '小',
      maxLabel: '超大',
    );
  }
}

class _LineHeightControl extends StatelessWidget {
  final ReadingConfigController provider;

  const _LineHeightControl({required this.provider});

  @override
  Widget build(BuildContext context) {
    final level = _lineHeightLevel(provider.lineHeight);
    return _CompactAdjustControl(
      title: '行间距',
      valueLabel: '${provider.lineHeight.toStringAsFixed(1)} 倍 · $level',
      value: provider.lineHeight,
      min: 1.4,
      max: 2.8,
      divisions: 7,
      onChanged: provider.setLineHeight,
      step: 0.2,
      minLabel: '紧凑',
      maxLabel: '宽松',
    );
  }
}

class _CompactAdjustmentGrid extends StatelessWidget {
  final ReadingConfigController provider;

  const _CompactAdjustmentGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 640) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _FontSizeControl(provider: provider)),
              const SizedBox(width: 14),
              Expanded(child: _LineHeightControl(provider: provider)),
            ],
          );
        }
        return Column(
          children: [
            _FontSizeControl(provider: provider),
            const SizedBox(height: 12),
            _LineHeightControl(provider: provider),
          ],
        );
      },
    );
  }
}

class _CompactAdjustControl extends StatelessWidget {
  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final double step;
  final String minLabel;
  final String maxLabel;

  const _CompactAdjustControl({
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.step,
    required this.minLabel,
    required this.maxLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrease = value > min;
    final canIncrease = value < max;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.22,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  valueLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _AdjustIconButton(
                  icon: Icons.remove,
                  tooltip: '减小$title',
                  enabled: canDecrease,
                  onPressed: () => _adjust(-step),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      tickMarkShape: SliderTickMarkShape.noTickMark,
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.55),
                      thumbColor: theme.colorScheme.primary,
                      overlayColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      divisions: divisions,
                      onChanged: onChanged,
                    ),
                  ),
                ),
                _AdjustIconButton(
                  icon: Icons.add,
                  tooltip: '增大$title',
                  enabled: canIncrease,
                  onPressed: () => _adjust(step),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  minLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  maxLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _adjust(double delta) {
    final next = (value + delta).clamp(min, max).toDouble();
    onChanged(next);
  }
}

class _AdjustIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _AdjustIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _HoverableSettingsCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? selectedColor;
  final Color? hoverColor;
  final Color? selectedBorderColor;

  const _HoverableSettingsCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.selected,
    this.width,
    this.height,
    this.constraints,
    this.padding,
    this.color,
    this.selectedColor,
    this.hoverColor,
    this.selectedBorderColor,
  });

  @override
  State<_HoverableSettingsCard> createState() => _HoverableSettingsCardState();
}

class _HoverableSettingsCardState extends State<_HoverableSettingsCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = widget.selected
        ? widget.selectedColor ??
              colorScheme.primaryContainer.withValues(alpha: 0.18)
        : _hovered
        ? widget.hoverColor ??
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.36)
        : widget.color ?? colorScheme.surface;
    final borderColor = widget.selected
        ? widget.selectedBorderColor ?? colorScheme.primary
        : _hovered
        ? colorScheme.primary.withValues(alpha: 0.34)
        : colorScheme.outlineVariant;
    final borderWidth = widget.selected
        ? 1.6
        : _hovered
        ? 1.2
        : 1.0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovered) {
          if (_hovered == hovered) return;
          setState(() => _hovered = hovered);
        },
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: colorScheme.primary.withValues(alpha: 0.06),
        splashColor: colorScheme.primary.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          constraints: widget.constraints,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _DesktopChoiceGrid extends StatelessWidget {
  final ReadingConfigController provider;

  const _DesktopChoiceGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _FontStyleSection(provider: provider),
              const SizedBox(height: 22),
              _ThemeSection(provider: provider),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(child: _SpecificFontSection(provider: provider)),
      ],
    );
  }
}

class _CompactChoiceStack extends StatelessWidget {
  final ReadingConfigController provider;

  const _CompactChoiceStack({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FontStyleSection(provider: provider),
        const SizedBox(height: 22),
        _SpecificFontSection(provider: provider),
        const SizedBox(height: 22),
        _ThemeSection(provider: provider),
      ],
    );
  }
}

class _FontStyleSection extends StatelessWidget {
  final ReadingConfigController provider;

  const _FontStyleSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _fontCategoryFor(provider.fontFamily);
    return _Section(
      title: '字体风格',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 24) / 3;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _fontCategories.map((category) {
              return SizedBox(
                width: cardWidth.clamp(88.0, 132.0).toDouble(),
                child: _FontStyleCard(
                  category: category,
                  selected: selectedCategory == category.id,
                  onTap: () => provider.setFontFamily(category.defaultFamily),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _FontStyleCard extends StatelessWidget {
  final _FontCategoryChoice category;
  final bool selected;
  final VoidCallback onTap;

  const _FontStyleCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _HoverableSettingsCard(
      key: ValueKey('font-category-${category.id}'),
      onTap: onTap,
      selected: selected,
      height: 92,
      selectedColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Aa',
                  style: TextStyle(
                    fontFamily: category.previewFamily,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  category.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  category.caption,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: 8,
              right: 8,
              child: _SelectionBadge(color: theme.colorScheme.primary),
            ),
        ],
      ),
    );
  }
}

class _SpecificFontSection extends StatelessWidget {
  final ReadingConfigController provider;

  const _SpecificFontSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selectedFamily = ReaderFonts.normalizeFamily(provider.fontFamily);
    final category = _fontCategoryFor(selectedFamily);
    final options = ReaderFonts.options
        .where((option) => _fontCategoryFor(option.family) == category)
        .toList();

    return _Section(
      title: '具体字体',
      trailing: _SelectedFamilyLabel(family: selectedFamily),
      child: Column(
        children: options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FontFamilyTile(
              option: option,
              selected: selectedFamily == option.family,
              onTap: () => provider.setFontFamily(option.family),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SelectedFamilyLabel extends StatelessWidget {
  final String family;

  const _SelectedFamilyLabel({required this.family});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _fontLabelFor(family);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _FontFamilyTile extends StatelessWidget {
  final ReaderFontOption option;
  final bool selected;
  final VoidCallback onTap;

  const _FontFamilyTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _HoverableSettingsCard(
      key: ValueKey('font-family-option-${option.family}'),
      onTap: onTap,
      selected: selected,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      selectedColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
      selectedBorderColor: theme.colorScheme.primary.withValues(alpha: 0.52),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: option.family,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fontDescriptionFor(option.family),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check, size: 22, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  final ReadingConfigController provider;

  const _ThemeSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '主题',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 24) / 3;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _themeChoices.map((choice) {
              return SizedBox(
                width: cardWidth.clamp(88.0, 132.0).toDouble(),
                child: _ThemeCard(
                  choice: choice,
                  selected: provider.readingTheme == choice.key,
                  onTap: () => provider.setReadingTheme(choice.key),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final _ThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoverTint = theme.colorScheme.primary.withValues(
      alpha: choice.key == 'dark' ? 0.12 : 0.07,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HoverableSettingsCard(
          key: ValueKey('reading-theme-${choice.key}'),
          onTap: onTap,
          selected: selected,
          height: 86,
          color: choice.background,
          hoverColor: Color.alphaBlend(hoverTint, choice.background),
          selectedColor: choice.background,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 56 + index * 4,
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: choice.lineColor.withValues(
                          alpha: index == 3 ? 0.38 : 0.55,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    );
                  }),
                ),
              ),
              if (selected)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _SelectionBadge(color: theme.colorScheme.primary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          choice.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _PanelFooter extends StatelessWidget {
  final ReadingConfigController provider;

  const _PanelFooter({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: () => _restoreDefaults(provider),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('恢复默认'),
            ),
            const Spacer(),
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '已自动保存',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  final Color color;

  const _SelectionBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const Padding(
        padding: EdgeInsets.all(3),
        child: Icon(Icons.check, size: 14, color: Colors.white),
      ),
    );
  }
}

class _FontCategoryChoice {
  final String id;
  final String label;
  final String caption;
  final String previewFamily;
  final String defaultFamily;

  const _FontCategoryChoice({
    required this.id,
    required this.label,
    required this.caption,
    required this.previewFamily,
    required this.defaultFamily,
  });
}

class _ThemeChoice {
  final String key;
  final String label;
  final Color background;
  final Color foreground;
  final Color lineColor;

  const _ThemeChoice({
    required this.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.lineColor,
  });
}

class _PreviewPalette {
  final Color background;
  final Color foreground;
  final Color mutedForeground;
  final Color codeBackground;

  const _PreviewPalette({
    required this.background,
    required this.foreground,
    required this.mutedForeground,
    required this.codeBackground,
  });
}

const _fontCategories = <_FontCategoryChoice>[
  _FontCategoryChoice(
    id: 'serif',
    label: '衬线',
    caption: 'Serif',
    previewFamily: ReaderFonts.systemSerif,
    defaultFamily: ReaderFonts.systemSerif,
  ),
  _FontCategoryChoice(
    id: 'sans',
    label: '无衬线',
    caption: 'Sans-serif',
    previewFamily: ReaderFonts.systemSansSerif,
    defaultFamily: ReaderFonts.systemSansSerif,
  ),
  _FontCategoryChoice(
    id: 'mono',
    label: '等宽',
    caption: 'Monospace',
    previewFamily: ReaderFonts.systemMonospace,
    defaultFamily: ReaderFonts.systemMonospace,
  ),
];

const _themeChoices = <_ThemeChoice>[
  _ThemeChoice(
    key: 'light',
    label: '浅色',
    background: Colors.white,
    foreground: Color(0xFF20231F),
    lineColor: Color(0xFF8D938B),
  ),
  _ThemeChoice(
    key: 'sepia',
    label: '护眼',
    background: Color(0xFFF5ECD7),
    foreground: Color(0xFF30281F),
    lineColor: Color(0xFF9D8E75),
  ),
  _ThemeChoice(
    key: 'dark',
    label: '深色',
    background: Color(0xFF2D2D2D),
    foreground: Color(0xFFE8E3DA),
    lineColor: Color(0xFF9A958D),
  ),
];

String _fontCategoryFor(String family) {
  return switch (ReaderFonts.normalizeFamily(family)) {
    ReaderFonts.systemSansSerif => 'sans',
    ReaderFonts.systemMonospace => 'mono',
    _ => 'serif',
  };
}

String _fontLabelFor(String family) {
  final normalized = ReaderFonts.normalizeFamily(family);
  for (final option in ReaderFonts.options) {
    if (option.family == normalized) return option.label;
  }
  return ReaderFonts.options.first.label;
}

String _fontDescriptionFor(String family) {
  return switch (ReaderFonts.normalizeFamily(family)) {
    ReaderFonts.literata => '优雅衬线，适合长文阅读',
    ReaderFonts.systemSerif => '系统衬线，经典耐读',
    ReaderFonts.systemSansSerif => '系统无衬线，清晰利落',
    ReaderFonts.systemMonospace => '等宽字形，适合代码与标注',
    _ => '适合阅读的字体',
  };
}

String _lineHeightLevel(double value) {
  if (value < 1.75) return '紧凑';
  if (value < 2.15) return '标准';
  return '宽松';
}

_PreviewPalette _themePalette(String key, ThemeData theme) {
  final selected = _themeChoices.firstWhere(
    (choice) => choice.key == key,
    orElse: () => _themeChoices.first,
  );
  final isDark = selected.key == 'dark';
  return _PreviewPalette(
    background: selected.background,
    foreground: selected.foreground,
    mutedForeground: isDark ? const Color(0xFFC8C1B7) : const Color(0xFF666B63),
    codeBackground: isDark
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
  );
}

void _restoreDefaults(ReadingConfigController provider) {
  provider.restoreDefaults();
}
