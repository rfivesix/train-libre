// lib/features/diary/presentation/widgets/animated_transcript_text.dart

import 'package:flutter/material.dart';

/// Reveals a transcript one word at a time as it arrives.
///
/// Words already on screen never move or re-animate — only what is genuinely
/// new fades in. Re-running the whole paragraph on every partial result (which
/// arrive several times a second) would read as flicker rather than as writing.
class AnimatedTranscriptText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Text shown while nothing has been recognised yet.
  final String placeholder;
  final TextStyle? placeholderStyle;

  const AnimatedTranscriptText({
    super.key,
    required this.text,
    required this.placeholder,
    this.style,
    this.placeholderStyle,
  });

  @override
  State<AnimatedTranscriptText> createState() => _AnimatedTranscriptTextState();
}

class _AnimatedTranscriptTextState extends State<AnimatedTranscriptText> {
  /// Word index -> when it first appeared, so each word runs its own fade.
  final Map<int, DateTime> _seenAt = {};
  List<String> _words = const [];

  @override
  void initState() {
    super.initState();
    _syncWords(widget.text, animate: false);
  }

  @override
  void didUpdateWidget(AnimatedTranscriptText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _syncWords(widget.text, animate: true);
    }
  }

  void _syncWords(String text, {required bool animate}) {
    final next = text.trim().isEmpty
        ? const <String>[]
        : text.trim().split(RegExp(r'\s+'));

    // A rewritten transcript — the cleanup pass, or a fresh recording — starts
    // over; an extended one keeps the timing of the words it already showed.
    final isExtension = next.length >= _words.length &&
        _words.asMap().entries.every((e) => next[e.key] == e.value);

    if (!isExtension) _seenAt.clear();

    final now = DateTime.now();
    for (var i = 0; i < next.length; i++) {
      _seenAt.putIfAbsent(i, () => animate ? now : DateTime(2000));
    }
    _seenAt.removeWhere((index, _) => index >= next.length);
    _words = next;
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return Text(
        widget.placeholder,
        style: widget.placeholderStyle ?? widget.style,
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: List.generate(_words.length, (i) {
        return _FadeInWord(
          // Keyed by position and content: a word that changes in place is a
          // correction and should animate again.
          key: ValueKey('$i:${_words[i]}'),
          word: _words[i],
          style: widget.style,
        );
      }),
    );
  }
}

class _FadeInWord extends StatefulWidget {
  final String word;
  final TextStyle? style;

  const _FadeInWord({super.key, required this.word, this.style});

  @override
  State<_FadeInWord> createState() => _FadeInWordState();
}

class _FadeInWordState extends State<_FadeInWord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(_curve),
        child: Text(widget.word, style: widget.style),
      ),
    );
  }
}
