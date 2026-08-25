import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/storage/saf_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('trainlibre.storage/saf');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('SafStorageService.pickDirectory', () {
    test('returns null for invalid payload shapes', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => 'not-a-map');

      final result = await SafStorageService.instance.pickDirectory();
      expect(result, isNull);
    });

    test('returns null when required fields are missing/blank', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, dynamic>{
          'treeUri': '   ',
          'displayPath': '/storage/backups',
        };
      });

      final result = await SafStorageService.instance.pickDirectory();
      expect(result, isNull);
    });

    test('returns trimmed directory values when payload is valid', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, dynamic>{
          'treeUri': ' content://tree/abc ',
          'displayPath': ' /storage/backups ',
        };
      });

      final result = await SafStorageService.instance.pickDirectory();

      expect(result, isNotNull);
      expect(result!.treeUri, 'content://tree/abc');
      expect(result.displayPath, '/storage/backups');
    });
  });

  group('SafStorageService file operations', () {
    test('writeFileToTree forwards args with default mimeType', () async {
      late MethodCall capturedCall;
      messenger.setMockMethodCallHandler(channel, (call) async {
        capturedCall = call;
        return <String, dynamic>{'displayPath': '/storage/backups/file.zip'};
      });

      final result = await SafStorageService.instance.writeFileToTree(
        treeUri: 'content://tree/abc',
        fileName: 'file.zip',
        sourcePath: '/tmp/staged.zip',
      );

      expect(result, '/storage/backups/file.zip');
      expect(capturedCall.method, 'writeFileToTree');
      expect(capturedCall.arguments, <String, dynamic>{
        'treeUri': 'content://tree/abc',
        'fileName': 'file.zip',
        'sourcePath': '/tmp/staged.zip',
        'mimeType': 'application/zip',
      });
    });

    test('writeFileToTree returns null for invalid response shape', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => 42);

      final result = await SafStorageService.instance.writeFileToTree(
        treeUri: 'content://tree/abc',
        fileName: 'file.zip',
        sourcePath: '/tmp/staged.zip',
      );

      expect(result, isNull);
    });

    test('pruneAutoBackupsInTree forwards method and arguments', () async {
      late MethodCall capturedCall;
      messenger.setMockMethodCallHandler(channel, (call) async {
        capturedCall = call;
        return null;
      });

      await SafStorageService.instance.pruneAutoBackupsInTree(
        treeUri: 'content://tree/abc',
        filePrefix: 'hypertrack_auto_',
        retention: 7,
      );

      expect(capturedCall.method, 'pruneAutoBackupsInTree');
      expect(capturedCall.arguments, <String, dynamic>{
        'treeUri': 'content://tree/abc',
        'filePrefix': 'hypertrack_auto_',
        'retention': 7,
      });
    });
  });
}
