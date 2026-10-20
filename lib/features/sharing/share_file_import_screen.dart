import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'share_link_codec.dart';
import 'share_link_preview_screen.dart';

/// Handles a JSON document opened from another app's share sheet.
class ShareFileImportScreen extends StatefulWidget {
  const ShareFileImportScreen({super.key, required this.uri});

  final Uri? uri;

  @override
  State<ShareFileImportScreen> createState() => _ShareFileImportScreenState();
}

class _ShareFileImportScreenState extends State<ShareFileImportScreen> {
  static const _channel = MethodChannel('trainlibre.app/shared_file');
  late final Future<ShareLinkPayload> _payload = _read();

  Future<ShareLinkPayload> _read() async {
    final uri = widget.uri;
    if (uri == null) throw const FormatException('Missing shared file');
    String content;
    if (uri.scheme == 'content') {
      content = await _channel.invokeMethod<String>(
            'readJson',
            {'uri': uri.toString()},
          ) ??
          '';
    } else if (uri.scheme == 'file') {
      final file = File.fromUri(uri);
      if (await file.length() > SharePortableCodec.maxFileBytes) {
        throw const FormatException('Share file is too large');
      }
      content = await file.readAsString();
    } else {
      throw const FormatException('Unsupported shared file');
    }
    return SharePortableCodec.decode(content);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShareLinkPayload>(
      future: _payload,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ShareLinkPreviewScreen(error: 'Invalid shared file');
        }
        final payload = snapshot.data;
        if (payload != null) return ShareLinkPreviewScreen(payload: payload);
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
