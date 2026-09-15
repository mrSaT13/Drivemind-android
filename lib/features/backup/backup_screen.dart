import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    return Scaffold(appBar: AppBar(title: const Text('Бэкап')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: ListTile(leading: const Icon(Icons.save), title: const Text('Создать бэкап-файл'), subtitle: const Text('Сохранить прогресс и поделиться'), onTap: () async {
          final d = await getApplicationDocumentsDirectory();
          final f = File('${d.path}/drivemind_backup.json');
          await f.writeAsString(StorageService.export());
          await Share.shareXFiles([XFile(f.path)], subject: 'DriveMind backup');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Бэкап создан')));
        })),
        Card(child: ListTile(leading: const Icon(Icons.restore), title: const Text('Импорт из текста'), subtitle: const Text('Вставьте данные экспорта'), onTap: () async {
          final c = TextEditingController();
          await showDialog(context: context, builder: (_)=> AlertDialog(title: const Text('Импорт'), content: TextField(controller: c, maxLines: 6), actions: [FilledButton(onPressed: () async { await StorageService.import(c.text); ref.read(profileProvider.notifier).reload(); Navigator.pop(context); }, child: const Text('Импорт'))]));
        })),
        const Card(child: ListTile(leading: Icon(Icons.cloud), title: Text('Облако (Google Drive / Firebase)'), subtitle: Text('Требует сервер — заглушка. Локальный бэкап выше работает оффлайн.'))),
      ]),
    );
  }
}
