import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/danmaku/ddp_client.dart';
import 'package:fladder/providers/danmaku_provider.dart';
import 'package:fladder/providers/settings/danmaku_settings_provider.dart';
import 'package:fladder/screens/video_player/components/danmaku_match_dialog.dart';

Future<void> showDanmakuSettings(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _DanmakuSettingsDialog(),
  );
}

class _DanmakuSettingsDialog extends ConsumerStatefulWidget {
  const _DanmakuSettingsDialog();

  @override
  ConsumerState<_DanmakuSettingsDialog> createState() =>
      _DanmakuSettingsDialogState();
}

class _DanmakuSettingsDialogState
    extends ConsumerState<_DanmakuSettingsDialog> {
  late final TextEditingController _appId;
  late final TextEditingController _appSecret;
  bool _testing = false;
  bool _pickingFile = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(danmakuSettingsProvider);
    _appId = TextEditingController(text: settings.appId);
    _appSecret = TextEditingController(text: settings.appSecret);
  }

  @override
  void dispose() {
    _appId.dispose();
    _appSecret.dispose();
    super.dispose();
  }

  Future<void> _pickLocalFile() async {
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择本地弹幕文件',
        type: FileType.custom,
        allowedExtensions: const ['xml', 'json'],
      );
      final files = result?.files;
      if (files == null || files.isEmpty) return;
      final path = files.single.path;
      if (path == null || path.isEmpty || !mounted) return;
      ref.read(danmakuSettingsProvider.notifier).setLocalFile(path);
    } catch (error) {
      if (mounted) setState(() => _testResult = '选择文件失败：$error');
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  Future<void> _testConnection() async {
    final settings = ref.read(danmakuSettingsProvider);
    if (!settings.hasCredentials) {
      setState(() => _testResult = '请先填写 AppId / AppSecret');
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final client = DdpClient(
      baseUrl: settings.apiBase,
      appId: settings.appId,
      appSecret: settings.appSecret,
    );
    try {
      await client.testConnection();
      if (mounted) setState(() => _testResult = '连接成功');
    } catch (error) {
      if (mounted) setState(() => _testResult = error.toString());
    } finally {
      client.dispose();
      if (mounted) setState(() => _testing = false);
    }
  }

  String _statusLabel(DanmakuLoadStatus status) => switch (status) {
        DanmakuLoadStatus.idle => '空闲',
        DanmakuLoadStatus.disabled => '已禁用',
        DanmakuLoadStatus.loading => '加载中',
        DanmakuLoadStatus.ready => '已就绪',
        DanmakuLoadStatus.noCredentials => '未配置凭证（可本地导入）',
        DanmakuLoadStatus.noMatch => '未匹配到弹幕',
        DanmakuLoadStatus.error => '错误',
      };

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(danmakuSettingsProvider);
    final state = ref.watch(danmakuProvider);
    final theme = Theme.of(context);
    final notifier = ref.read(danmakuSettingsProvider.notifier);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded),
                  const SizedBox(width: 8),
                  Text('弹幕设置', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('弹弹play · 状态：${_statusLabel(state.status)}',
                  style: theme.textTheme.bodySmall),
              if (state.match != null)
                Text(
                  '已匹配：${state.match!.animeTitle}'
                  '${state.match!.episodeTitle.isEmpty ? '' : ' · ${state.match!.episodeTitle}'}'
                  '（${switch (state.match!.source) {
                    'manual' => '手动',
                    'local' => '本地',
                    _ => '自动',
                  }}）',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(state.error!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('启用弹幕'),
                      value: settings.enabled,
                      onChanged: (value) {
                        notifier.setEnabled(value);
                        if (value) {
                          ref.read(danmakuProvider.notifier).reload();
                        }
                      },
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: const Text('高级：弹弹play AppId（可选）'),
                      subtitle: Text(
                        settings.hasCredentials
                            ? '已配置，可使用在线匹配'
                            : '不填也能用本地导入；在线匹配才需要',
                        style: theme.textTheme.bodySmall,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _appId,
                                decoration: const InputDecoration(
                                  labelText: '弹弹play AppId',
                                  hintText: '在 dev.dandanplay.com 申请',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) =>
                                    notifier.setCredentials(appId: value),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _appSecret,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: '弹弹play AppSecret',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) =>
                                    notifier.setCredentials(appSecret: value),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed:
                                        _testing ? null : _testConnection,
                                    icon: _testing
                                        ? const SizedBox.square(
                                            dimension: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.wifi_tethering),
                                    label: const Text('测试连接'),
                                  ),
                                  const SizedBox(width: 12),
                                  if (_testResult != null)
                                    Expanded(
                                      child: Text(
                                        _testResult!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Text('本地弹幕文件', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      (settings.localFile ?? '').isEmpty
                          ? '未选择。支持 Bilibili XML / DDP JSON；'
                              '选择后优先于在线匹配，且不需要 AppId。'
                          : '当前：${_fileName(settings.localFile!)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _pickingFile ? null : _pickLocalFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('选择文件…'),
                        ),
                        if ((settings.localFile ?? '').isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () =>
                                notifier.setLocalFile(null),
                            icon: const Icon(Icons.close),
                            label: const Text('清除本地文件'),
                          ),
                      ],
                    ),
                    const Divider(height: 28),
                    _SliderTile(
                      label: '字体大小',
                      value: settings.fontSize,
                      min: 16,
                      max: 72,
                      divisions: 56,
                      display: settings.fontSize.toStringAsFixed(0),
                      onChanged: notifier.setFontSize,
                    ),
                    _SliderTile(
                      label: '透明度',
                      value: settings.opacity,
                      min: 0.1,
                      max: 1,
                      divisions: 18,
                      display: '${(settings.opacity * 100).round()}%',
                      onChanged: notifier.setOpacity,
                    ),
                    _SliderTile(
                      label: '滚动时长',
                      value: settings.speedSeconds,
                      min: 3,
                      max: 20,
                      divisions: 17,
                      display: '${settings.speedSeconds.toStringAsFixed(0)} 秒',
                      onChanged: notifier.setSpeed,
                    ),
                    _SliderTile(
                      label: '显示区域',
                      value: settings.displayArea,
                      min: 0.2,
                      max: 1,
                      divisions: 16,
                      display: '${(settings.displayArea * 100).round()}%',
                      onChanged: notifier.setDisplayArea,
                    ),
                    _SliderTile(
                      label: '时间偏移',
                      value: settings.offsetSeconds,
                      min: -60,
                      max: 60,
                      divisions: 120,
                      display:
                          '${settings.offsetSeconds > 0 ? '+' : ''}'
                          '${settings.offsetSeconds.toStringAsFixed(1)} 秒',
                      onChanged: notifier.setOffset,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('简繁转换'),
                        const Spacer(),
                        DropdownButton<int>(
                          value: settings.chConvert,
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('关闭')),
                            DropdownMenuItem(
                                value: 1, child: Text('简体')),
                            DropdownMenuItem(
                                value: 2, child: Text('繁体')),
                          ],
                          onChanged: (value) {
                            if (value != null) notifier.setChConvert(value);
                          },
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('显示滚动弹幕'),
                      value: settings.showScroll,
                      onChanged: notifier.setShowScroll,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('显示顶部弹幕'),
                      value: settings.showTop,
                      onChanged: notifier.setShowTop,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('显示底部弹幕'),
                      value: settings.showBottom,
                      onChanged: notifier.setShowBottom,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('合并重复弹幕'),
                      subtitle: const Text('5 秒内相同内容合并为“xN”顶部弹幕'),
                      value: settings.mergeDuplicates,
                      onChanged: notifier.setMergeDuplicates,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('保留弹幕颜色'),
                      subtitle: const Text('关闭后全部按白色绘制'),
                      value: settings.showColor,
                      onChanged: notifier.setShowColor,
                    ),
                    _SliderTile(
                      label: '描边粗细',
                      value: settings.strokeWidth,
                      min: 0,
                      max: 6,
                      divisions: 12,
                      display: settings.strokeWidth.toStringAsFixed(1),
                      onChanged: notifier.setStrokeWidth,
                    ),
                    const Divider(height: 28),
                    Text('弹幕来源', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '弹弹play 会把第三方站点弹幕合并进同一条响应，'
                      '这里只控制显示，不额外发请求。',
                      style: theme.textTheme.bodySmall,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('BiliBili'),
                      value: settings.showBiliBiliSource,
                      onChanged: notifier.setShowBiliBiliSource,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gamer（巴哈动画疯）'),
                      value: settings.showGamerSource,
                      onChanged: notifier.setShowGamerSource,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('弹弹play 自有'),
                      subtitle: const Text('关闭时只保留 BiliBili / Gamer 来源'),
                      value: settings.showDanDanPlaySource,
                      onChanged: notifier.setShowDanDanPlaySource,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('本地导入'),
                      subtitle: const Text('本地 XML/JSON 文件导入'),
                      value: settings.showLocalSource,
                      onChanged: notifier.setShowLocalSource,
                    ),
                    const Divider(height: 28),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: (settings.localFile ?? '').isNotEmpty
                              ? null
                              : () async {
                            final applied =
                                await showDanmakuMatchDialog(context);
                            if (!context.mounted) return;
                            if (applied == true) {
                              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                const SnackBar(content: Text('已应用手动匹配')),
                              );
                            }
                          },
                          icon: const Icon(Icons.manage_search),
                          label: const Text('手动匹配…'),
                        ),
                        OutlinedButton.icon(
                          onPressed: state.status == DanmakuLoadStatus.loading
                              ? null
                              : () => ref.read(danmakuProvider.notifier).reload(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新加载'),
                        ),
                        OutlinedButton.icon(
                          onPressed: state.match?.source == 'manual'
                              ? () async {
                                  await ref
                                      .read(danmakuProvider.notifier)
                                      .clearManualMatch();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.maybeOf(context)
                                      ?.showSnackBar(
                                    const SnackBar(content: Text('已清除手动匹配')),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.link_off),
                          label: const Text('清除匹配'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '弹幕数据由弹弹play开放弹幕网络提供（www.dandanplay.com）。'
                      'AppSecret 仅保存在本地，请勿分享。',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 64, child: Text(display, textAlign: TextAlign.end)),
      ],
    );
  }
}
