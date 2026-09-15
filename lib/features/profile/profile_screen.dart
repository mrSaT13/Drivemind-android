import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';
import 'achievements.dart';
import 'pdf_report.dart';

class ProfileScreen extends ConsumerStatefulWidget { const ProfileScreen({super.key}); @override ConsumerState<ProfileScreen> createState()=>_P(); }
class _P extends ConsumerState<ProfileScreen> {
  ImageProvider? _avatar(String? path){
    if(path==null) return null;
    if(path.startsWith('asset:')) return AssetImage('assets/images/${path.replaceFirst('asset:', '')}');
    return FileImage(File(path));
  }
  @override Widget build(BuildContext context){
    final p = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Stack(children: [
          CircleAvatar(radius: 56, backgroundImage: _avatar(p.avatarPath), child: p.avatarPath==null ? const Icon(Icons.person, size:48):null),
          Positioned(bottom:0, right:0, child: CircleAvatar(child: IconButton(icon: const Icon(Icons.camera_alt, size:18), onPressed: () async {
            final choice = await showModalBottomSheet<int>(context: context, builder: (_)=> SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children:[
              ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Камера'), onTap: ()=> Navigator.pop(context, 0)),
              ListTile(leading: const Icon(Icons.photo_library), title: const Text('Галерея'), onTap: ()=> Navigator.pop(context, 1)),
              ListTile(leading: const Icon(Icons.person), title: const Text('Выбрать аватар из магазина'), onTap: ()=> Navigator.pop(context, 2)),
            ])));
            if(choice==0 || choice==1){
              final src = choice==0 ? ImageSource.camera : ImageSource.gallery;
              final x = await ImagePicker().pickImage(source: src);
              if(x!=null){ ref.read(profileProvider.notifier).setAvatarFile(x.path); setState((){});}
            } else if(choice==2){
              Navigator.pushNamed(context, '/shop');
            }
          }))),
        ])),
        const SizedBox(height:12),
        Center(child: Text('Точность ${p.accuracy.toStringAsFixed(1)}% • ${p.correctAnswers}/${p.totalAnswered} • ${p.coins}🪙', style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(height:16),
        const AchievementsGrid(),
        const SizedBox(height:16),
        Card(child: Column(children: [
          ListTile(title: const Text('Статистика по темам'), trailing: const Icon(Icons.bar_chart), onTap: ()=>Navigator.pushNamed(context, '/stats')),
          ListTile(title: const Text('Достижения'), trailing: const Icon(Icons.emoji_events), onTap: ()=>Navigator.pushNamed(context, '/achievements')),
          ListTile(title: const Text('Магазин'), trailing: const Icon(Icons.store), onTap: ()=>Navigator.pushNamed(context, '/shop')),
          ListTile(title: const Text('Настройки'), trailing: const Icon(Icons.settings), onTap: ()=>Navigator.pushNamed(context, '/settings')),
          ...p.mistakesByTheme.entries.map((e)=> ListTile(title: Text(e.key), trailing: Text('${e.value} ош.'))),
          if(p.mistakesByTheme.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Пока нет данных')),
        ])),
        const SizedBox(height:16),
        Card(child: Column(children: [
          ListTile(title: const Text('PDF-отчёт'), leading: const Icon(Icons.picture_as_pdf), onTap: ()=> generatePdfReport(context)),
          ListTile(title: const Text('Экспорт прогресса'), leading: const Icon(Icons.upload), onTap: () async { await Share.share(StorageService.export(), subject: 'DriveMind progress'); }),
          ListTile(title: const Text('Импорт прогресса'), leading: const Icon(Icons.download), onTap: () async { final c = TextEditingController(); await showDialog(context: context, builder: (_)=> AlertDialog(title: const Text('Вставьте данные экспорта'), content: TextField(controller: c, maxLines: 6), actions: [FilledButton(onPressed: () async { await StorageService.import(c.text); ref.read(profileProvider.notifier).reload(); Navigator.pop(context); }, child: const Text('Импорт'))])); }),
        ])),
      ]),
    );
  }
}
