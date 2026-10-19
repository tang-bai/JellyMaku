import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/danmaku/ddp_client.dart';
import 'package:fladder/providers/danmaku_provider.dart';
import 'package:fladder/providers/settings/danmaku_settings_provider.dart';

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

  Future<void> _testConnection() async {
    final settings = ref.read(danmakuSettingsProvider);
    if (!settings.hasCredentials) {
      setState(() => _testResult = 'AppId / AppSecret required');
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
      if (mounted) setState(() => _testResult = 'Connection OK');
    } catch (error) {
      if (mounted) setState(() => _testResult = error.toString());
    } finally {
      client.dispose();
      if (mounted) setState(() => _testing = false);
    }
  }

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
                  Text('Danmaku', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('DanDanPlay (弹弹play) · status: ${state.status.name}',
                  style: theme.textTheme.bodySmall),
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
                      title: const Text('Enable danmaku'),
                      value: settings.enabled,
                      onChanged: (value) {
                        notifier.setEnabled(value);
                        if (value) {
                          ref.read(danmakuProvider.notifier).reload();
                        }
                      },
                    ),
                    TextField(
                      controller: _appId,
                      decoration: const InputDecoration(
                        labelText: 'DanDanPlay AppId',
                        hintText: 'Apply at dev.dandanplay.com',
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
                        labelText: 'DanDanPlay AppSecret',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) =>
                          notifier.setCredentials(appSecret: value),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _testing ? null : _testConnection,
                          icon: _testing
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: const Text('Test connection'),
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
                    const Divider(height: 28),
                    _SliderTile(
                      label: 'Font size',
                      value: settings.fontSize,
                      min: 16,
                      max: 72,
                      divisions: 56,
                      display: settings.fontSize.toStringAsFixed(0),
                      onChanged: notifier.setFontSize,
                    ),
                    _SliderTile(
                      label: 'Opacity',
                      value: settings.opacity,
                      min: 0.1,
                      max: 1,
                      divisions: 18,
                      display: '${(settings.opacity * 100).round()}%',
                      onChanged: notifier.setOpacity,
                    ),
                    _SliderTile(
                      label: 'Scroll duration',
                      value: settings.speedSeconds,
                      min: 3,
                      max: 20,
                      divisions: 17,
                      display: '${settings.speedSeconds.toStringAsFixed(0)}s',
                      onChanged: notifier.setSpeed,
                    ),
                    _SliderTile(
                      label: 'Display area',
                      value: settings.displayArea,
                      min: 0.2,
                      max: 1,
                      divisions: 16,
                      display: '${(settings.displayArea * 100).round()}%',
                      onChanged: notifier.setDisplayArea,
                    ),
                    _SliderTile(
                      label: 'Time offset',
                      value: settings.offsetSeconds,
                      min: -15,
                      max: 15,
                      divisions: 60,
                      display: '${settings.offsetSeconds.toStringAsFixed(1)}s',
                      onChanged: notifier.setOffset,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Chinese conversion'),
                        const Spacer(),
                        DropdownButton<int>(
                          value: settings.chConvert,
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Off')),
                            DropdownMenuItem(
                                value: 1, child: Text('Simplified')),
                            DropdownMenuItem(
                                value: 2, child: Text('Traditional')),
                          ],
                          onChanged: (value) {
                            if (value != null) notifier.setChConvert(value);
                          },
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show scrolling'),
                      value: settings.showScroll,
                      onChanged: notifier.setShowScroll,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show top'),
                      value: settings.showTop,
                      onChanged: notifier.setShowTop,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show bottom'),
                      value: settings.showBottom,
                      onChanged: notifier.setShowBottom,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Danmaku data provided by 弹弹play开放弹幕网络 (www.dandanplay.com). '
                      'AppSecret is stored locally; do not share it.',
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
