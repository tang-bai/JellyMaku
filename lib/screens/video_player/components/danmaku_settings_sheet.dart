import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/danmaku/danmaku_api_client.dart';
import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/providers/danmaku_provider.dart';
import 'package:fladder/providers/settings/danmaku_settings_provider.dart';
import 'package:fladder/util/localization_helper.dart';
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
  late final TextEditingController _apiBase;
  bool _testing = false;
  bool _pickingFile = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(danmakuSettingsProvider);
    _apiBase = TextEditingController(text: settings.apiBase);
  }

  @override
  void dispose() {
    _apiBase.dispose();
    super.dispose();
  }

  Future<void> _pickLocalFile() async {
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: context.localized.danmakuPickFileTitle,
        type: FileType.custom,
        allowedExtensions: const ['xml', 'json'],
      );
      final files = result?.files;
      if (files == null || files.isEmpty) return;
      final path = files.single.path;
      if (path == null || path.isEmpty || !mounted) return;
      ref.read(danmakuSettingsProvider.notifier).setLocalFile(path);
    } catch (error) {
      if (mounted) setState(() => _testResult = context.localized.danmakuPickFileError(error.toString()));
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final client = DanmakuApiClient(baseUrl: _apiBase.text);
    try {
      await client.testConnection();
      if (mounted) setState(() => _testResult = context.localized.danmakuConnectionOk);
    } catch (error) {
      if (mounted) setState(() => _testResult = error.toString());
    } finally {
      client.dispose();
      if (mounted) setState(() => _testing = false);
    }
  }

  String _statusLabel(BuildContext context, DanmakuLoadStatus status) =>
      switch (status) {
        DanmakuLoadStatus.idle => context.localized.danmakuStatusIdle,
        DanmakuLoadStatus.disabled => context.localized.danmakuStatusDisabled,
        DanmakuLoadStatus.loading => context.localized.danmakuStatusLoading,
        DanmakuLoadStatus.ready => context.localized.danmakuStatusReady,
        DanmakuLoadStatus.noMatch => context.localized.danmakuStatusNoMatch,
        DanmakuLoadStatus.error => context.localized.danmakuStatusError,
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
                  Text(context.localized.danmakuSettingsTitle, style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.localized
                    .danmakuApiStatus(_statusLabel(context, state.status)),
                style: theme.textTheme.bodySmall,
              ),
              if (state.match != null)
                Text(
                  context.localized.danmakuMatched(
                    [
                      state.match!.animeTitle,
                      if (state.match!.episodeTitle.isNotEmpty)
                        state.match!.episodeTitle,
                    ].join(' · '),
                    switch (state.match!.source) {
                      'manual' => context.localized.danmakuSourceManual,
                      'local' => context.localized.danmakuSourceLocal,
                      _ => context.localized.danmakuSourceAuto,
                    },
                  ),
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
                      title: Text(context.localized.danmakuEnable),
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
                      title: Text(context.localized.danmakuAdvancedApi),
                      subtitle: Text(
                        context.localized.danmakuApiBaseSubtitle(kDefaultDanmuApiBase),
                        style: theme.textTheme.bodySmall,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _apiBase,
                                decoration: InputDecoration(
                                  labelText: context.localized.danmakuApiBaseLabel,
                                  hintText: kDefaultDanmuApiBase,
                                  helperText: context.localized
                                      .danmakuApiBaseHelper,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) =>
                                    notifier.setApiBase(value),
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
                                    label: Text(context.localized.danmakuTestConnection),
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
                    Text(context.localized.danmakuLocalFileTitle, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      (settings.localFile ?? '').isEmpty
                          ? context.localized.danmakuLocalFileEmpty
                          : context.localized.danmakuLocalFileCurrent(
                              _fileName(settings.localFile!)),
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
                          label: Text(context.localized.danmakuChooseFile),
                        ),
                        if ((settings.localFile ?? '').isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => notifier.setLocalFile(null),
                            icon: const Icon(Icons.close),
                            label: Text(context.localized.danmakuClearLocalFile),
                          ),
                      ],
                    ),
                    const Divider(height: 28),
                    _SliderTile(
                      label: context.localized.danmakuFontSize,
                      value: settings.fontSize,
                      min: 16,
                      max: 72,
                      divisions: 56,
                      display: settings.fontSize.toStringAsFixed(0),
                      onChanged: notifier.setFontSize,
                    ),
                    _SliderTile(
                      label: context.localized.danmakuOpacity,
                      value: settings.opacity,
                      min: 0.1,
                      max: 1,
                      divisions: 18,
                      display: '${(settings.opacity * 100).round()}%',
                      onChanged: notifier.setOpacity,
                    ),
                    _SliderTile(
                      label: context.localized.danmakuSpeed,
                      value: settings.speedSeconds,
                      min: 3,
                      max: 20,
                      divisions: 17,
                      display: context.localized.danmakuSecondsValue(
                          settings.speedSeconds.toStringAsFixed(0)),
                      onChanged: notifier.setSpeed,
                    ),
                    _SliderTile(
                      label: context.localized.danmakuDisplayArea,
                      value: settings.displayArea,
                      min: 0.2,
                      max: 1,
                      divisions: 16,
                      display: '${(settings.displayArea * 100).round()}%',
                      onChanged: notifier.setDisplayArea,
                    ),
                    _SliderTile(
                      label: context.localized.danmakuOffset,
                      value: settings.offsetSeconds,
                      min: -60,
                      max: 60,
                      divisions: 120,
                      display: context.localized.danmakuSecondsValue(
                          '${settings.offsetSeconds > 0 ? '+' : ''}'
                          '${settings.offsetSeconds.toStringAsFixed(1)}'),
                      onChanged: notifier.setOffset,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.localized.danmakuShowScroll),
                      value: settings.showScroll,
                      onChanged: notifier.setShowScroll,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.localized.danmakuShowTop),
                      value: settings.showTop,
                      onChanged: notifier.setShowTop,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.localized.danmakuShowBottom),
                      value: settings.showBottom,
                      onChanged: notifier.setShowBottom,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.localized.danmakuMerge),
                      subtitle: Text(context.localized.danmakuMergeHint),
                      value: settings.mergeDuplicates,
                      onChanged: notifier.setMergeDuplicates,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.localized.danmakuShowColor),
                      subtitle: Text(context.localized.danmakuShowColorHint),
                      value: settings.showColor,
                      onChanged: notifier.setShowColor,
                    ),
                    _SliderTile(
                      label: context.localized.danmakuStrokeWidth,
                      value: settings.strokeWidth,
                      min: 0,
                      max: 6,
                      divisions: 12,
                      display: settings.strokeWidth.toStringAsFixed(1),
                      onChanged: notifier.setStrokeWidth,
                    ),
                    const Divider(height: 28),
                    Text(context.localized.danmakuSourceTitle, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      context.localized.danmakuSourceDescription,
                      style: theme.textTheme.bodySmall,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.localized.danmakuLocalImport),
                      subtitle: Text(context.localized.danmakuLocalImportHint),
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
                                    ScaffoldMessenger.maybeOf(context)
                                        ?.showSnackBar(
                                      SnackBar(content: Text(context.localized.danmakuManualApplied)),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.manage_search),
                          label: Text(context.localized.danmakuManualMatch),
                        ),
                        OutlinedButton.icon(
                          onPressed: state.status == DanmakuLoadStatus.loading
                              ? null
                              : () =>
                                  ref.read(danmakuProvider.notifier).reload(),
                          icon: const Icon(Icons.refresh),
                          label: Text(context.localized.danmakuReload),
                        ),
                        OutlinedButton.icon(
                          onPressed: state.match != null &&
                                  state.match!.source != 'local'
                              ? () async {
                                  await ref
                                      .read(danmakuProvider.notifier)
                                      .clearManualMatch();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.maybeOf(context)
                                      ?.showSnackBar(
                                    SnackBar(content: Text(context.localized.danmakuMatchCleared)),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.link_off),
                          label: Text(context.localized.danmakuClearMatch),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.localized
                          .danmakuFooter(kDefaultDanmuApiBase),
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
