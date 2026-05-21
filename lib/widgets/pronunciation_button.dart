import 'package:flutter/material.dart';

typedef SpeakWordCallback = Future<void> Function(String word);

class PronunciationButton extends StatefulWidget {
  const PronunciationButton({
    super.key,
    required this.word,
    required this.onSpeakWord,
    this.buttonSize = 36,
    this.iconSize = 19,
  });

  final String word;
  final SpeakWordCallback? onSpeakWord;
  final double buttonSize;
  final double iconSize;

  @override
  State<PronunciationButton> createState() => _PronunciationButtonState();
}

class _PronunciationButtonState extends State<PronunciationButton> {
  bool _isSpeaking = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSpeak =
        widget.onSpeakWord != null && widget.word.trim().isNotEmpty;

    return IconButton(
      tooltip: '播放发音',
      onPressed: canSpeak && !_isSpeaking ? _speak : null,
      icon: _isSpeaking
          ? SizedBox.square(
              dimension: widget.iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : Icon(Icons.volume_up_rounded, size: widget.iconSize),
      color: theme.colorScheme.primary,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: widget.buttonSize,
        height: widget.buttonSize,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _speak() async {
    final callback = widget.onSpeakWord;
    if (callback == null || _isSpeaking) return;

    setState(() => _isSpeaking = true);
    try {
      await callback(widget.word);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('发音暂不可用')));
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }
}
