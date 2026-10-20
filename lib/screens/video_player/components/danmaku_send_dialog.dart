import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/providers/danmaku_provider.dart';
import 'package:fladder/providers/video_player_provider.dart';

/// 发送弹幕（本地回显）。
///
/// DDP 没有发送接口，这里与 Kazumi 一致：只把弹幕插入当前会话的评论列表，
/// 不上传、不写缓存；暂停/切集/关闭后消失。
Future<bool?> showDanmakuSendDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const DanmakuSendDialog(),
  );
}

class DanmakuSendDialog extends ConsumerStatefulWidget {
  const DanmakuSendDialog({super.key});

  @override
  ConsumerState<DanmakuSendDialog> createState() => _DanmakuSendDialogState();
}

class _DanmakuSendDialogState extends ConsumerState<DanmakuSendDialog> {
  final _text = TextEditingController();
  DanmakuMode _mode = DanmakuMode.scroll;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '请输入弹幕内容');
      return;
    }
    final position = ref.read(mediaPlaybackProvider).position;
    final added = ref.read(danmakuProvider.notifier).addLocalEcho(
          text: text,
          mode: _mode,
          time: position.inMilliseconds / Duration.millisecondsPerSecond,
        );
    if (!added) {
      setState(() => _error = '弹幕尚未加载，暂时不能发送');
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.send_rounded),
                  const SizedBox(width: 8),
                  Text('发送弹幕', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _text,
                autofocus: true,
                maxLength: 60,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  labelText: '弹幕内容',
                  hintText: '最多 60 字',
                  border: OutlineInputBorder(),
                ),
              ),
              Row(
                children: [
                  const Text('类型'),
                  const SizedBox(width: 12),
                  DropdownButton<DanmakuMode>(
                    value: _mode,
                    items: const [
                      DropdownMenuItem(
                          value: DanmakuMode.scroll, child: Text('滚动')),
                      DropdownMenuItem(
                          value: DanmakuMode.top, child: Text('顶部')),
                      DropdownMenuItem(
                          value: DanmakuMode.bottom, child: Text('底部')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _mode = value);
                    },
                  ),
                  const Spacer(),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '只在当前播放中显示，不会上传到弹弹play；切换剧集后消失。',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('发送'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
