import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// Normalizes streaming Markdown text so unclosed bold or code tags don't flash.
String normalizeStreamingMarkdown(String raw, {required bool isStreaming}) {
  if (!isStreaming || raw.isEmpty) return raw;
  var text = raw;
  // Strip a lone trailing '**' before the first character of the bold span
  // arrives so raw syntax markers never flash for a frame.
  if (text.endsWith('**') && !text.endsWith('***')) {
    final withoutTrailing = text.substring(0, text.length - 2);
    if ('**'.allMatches(withoutTrailing).length.isEven) {
      return withoutTrailing;
    }
  }
  // Auto-close an active '**bold**' span while words are streaming inside it.
  final boldMatches = '**'.allMatches(text).length;
  if (boldMatches.isOdd) {
    final trimmed = text.trimRight();
    if (!trimmed.endsWith('*')) {
      text = '$trimmed**';
    }
  }
  // Auto-close an active inline '`code`' span when not inside a fenced block.
  final fenceMatches = '```'.allMatches(text).length;
  if (fenceMatches.isEven) {
    final withoutFences = text.replaceAll('```', '');
    final backtickMatches = '`'.allMatches(withoutFences).length;
    if (backtickMatches.isOdd) {
      final trimmed = text.trimRight();
      if (trimmed.endsWith('`')) {
        text = trimmed.substring(0, trimmed.length - 1);
      } else {
        text = '$trimmed`';
      }
    }
  }
  return text;
}

/// Renders Markdown response bodies with LaTeX, GitHub-flavored extensions,
/// code blocks, tables, and link launching support.
class CloudOverlayMarkdown extends StatelessWidget {
  const CloudOverlayMarkdown({
    super.key,
    required this.rawResponse,
    required this.contrastColor,
    required this.softColor,
    required this.isStreaming,
  });

  final String rawResponse;
  final Color contrastColor;
  final Color softColor;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = normalizeStreamingMarkdown(
      rawResponse,
      isStreaming: isStreaming,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: contrastColor,
      height: 1.5,
    );
    final codeStyle = bodyStyle?.copyWith(
      fontFamily: 'monospace',
      fontSize: 13,
      color: contrastColor,
      backgroundColor: softColor,
    );

    return MarkdownBody(
      data: normalized,
      selectable: false,
      onTapLink: (text, href, title) {
        if (href == null || href.trim().isEmpty) return;
        final uri = Uri.tryParse(href.trim());
        if (uri != null) {
          unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
        }
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: bodyStyle,
        pPadding: const EdgeInsets.only(bottom: 8),
        h1: theme.textTheme.titleLarge?.copyWith(
          color: contrastColor,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h2: theme.textTheme.titleMedium?.copyWith(
          color: contrastColor,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        h3: theme.textTheme.titleSmall?.copyWith(
          color: contrastColor,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        h4: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
        h5: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
        h6: bodyStyle?.copyWith(
          fontWeight: FontWeight.w600,
          color: contrastColor.withValues(alpha: 0.82),
        ),
        strong: bodyStyle?.copyWith(
          fontWeight: FontWeight.w700,
          color: contrastColor,
        ),
        em: bodyStyle?.copyWith(
          fontStyle: FontStyle.italic,
          color: contrastColor,
        ),
        del: bodyStyle?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: contrastColor.withValues(alpha: 0.72),
        ),
        a: bodyStyle?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        listBullet: bodyStyle,
        listIndent: 18,
        code: codeStyle,
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: softColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: contrastColor.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        blockquote: bodyStyle?.copyWith(
          color: contrastColor.withValues(alpha: 0.84),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: contrastColor.withValues(alpha: 0.35),
              width: 3,
            ),
          ),
        ),
        tableHead: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
        tableBody: bodyStyle,
        tableBorder: TableBorder.all(
          color: contrastColor.withValues(alpha: 0.18),
          width: 0.5,
          borderRadius: BorderRadius.circular(8),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: contrastColor.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
        ),
      ),
      builders: {
        'latex': LatexElementBuilder(
          textStyle: bodyStyle,
        ),
      },
      extensionSet: md.ExtensionSet(
        [
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          LatexBlockSyntax(),
        ],
        [
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          LatexInlineSyntax(),
        ],
      ),
    );
  }
}
