import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/providers/danmaku_provider.dart';
import 'package:fladder/util/localization_helper.dart';

/// 手动匹配弹幕：搜索番剧 → 选择分集 → 写入映射并重载。
///
/// 与 Kazumi 的三步式选源一致，但只保留节目匹配这一条路径；
/// 写入后映射保存在 DanmakuCache.mapping.json，下次播放直接命中。
Future<bool?> showDanmakuMatchDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const DanmakuMatchDialog(),
  );
}

enum _MatchStep { search, anime, episode }

class DanmakuMatchDialog extends ConsumerStatefulWidget {
  const DanmakuMatchDialog({super.key});

  @override
  ConsumerState<DanmakuMatchDialog> createState() => _DanmakuMatchDialogState();
}

class _DanmakuMatchDialogState extends ConsumerState<DanmakuMatchDialog> {
  late final TextEditingController _keyword;
  final _episodeFilter = TextEditingController();

  _MatchStep _step = _MatchStep.search;
  List<DanmakuAnime> _animes = const [];
  List<DanmakuEpisodeRef> _episodes = const [];
  DanmakuAnime? _selectedAnime;
  String? _error;
  bool _loading = false;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _keyword = TextEditingController(
      text: ref.read(danmakuProvider.notifier).media?.searchTitle ?? '',
    );
  }

  @override
  void dispose() {
    _keyword.dispose();
    _episodeFilter.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _keyword.text.trim();
    if (keyword.isEmpty) {
      setState(() => _error = context.localized.danmakuEnterAnimeName);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _step = _MatchStep.anime;
      _animes = const [];
      _episodes = const [];
      _selectedAnime = null;
    });
    try {
      final animes =
          await ref.read(danmakuProvider.notifier).searchAnime(keyword);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _animes = animes;
        if (animes.isEmpty) _error = context.localized.danmakuNoAnimeFound;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _selectAnime(DanmakuAnime anime) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedAnime = anime;
      _episodes = const [];
      _episodeFilter.clear();
      _step = _MatchStep.episode;
    });
    try {
      // danmu_api 的搜索结果已带分集；旧服务/异常响应才需要按番名重搜。
      final episodes = anime.episodes.isNotEmpty
          ? anime.episodes
          : await ref.read(danmakuProvider.notifier).episodesForAnime(anime);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _episodes = episodes;
        if (episodes.isEmpty) _error = context.localized.danmakuNoEpisodes;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _apply(DanmakuEpisodeRef episode) async {
    final anime = _selectedAnime;
    if (anime == null) return;
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      await ref.read(danmakuProvider.notifier).applyManualMatch(
            episodeId: episode.episodeId,
            animeTitle: anime.animeTitle,
            episodeTitle: episode.episodeTitle,
            url: episode.url,
            provider: episode.provider,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = error.toString();
      });
    }
  }

  void _back() {
    setState(() {
      _error = null;
      _step = switch (_step) {
        _MatchStep.episode => _MatchStep.anime,
        _MatchStep.anime => _MatchStep.search,
        _MatchStep.search => _MatchStep.search,
      };
    });
  }

  String _title(BuildContext context) => switch (_step) {
        _MatchStep.search => context.localized.danmakuManualMatchTitle,
        _MatchStep.anime => context.localized.danmakuSelectAnime,
        _MatchStep.episode => context.localized.danmakuSelectEpisode,
      };

  String _episodeSubtitle(BuildContext context, DanmakuEpisodeRef episode) {
    final host = Uri.tryParse(episode.url)?.host ?? '';
    if (host.isEmpty) {
      return context.localized
          .danmakuNoUrlEpisode(episode.episodeId.toString());
    }
    return '$host · episodeId ${episode.episodeId}';
  }

  String? _subtitle() => switch (_step) {
        _MatchStep.search => null,
        _MatchStep.anime => _keyword.text.trim(),
        _MatchStep.episode => _selectedAnime?.animeTitle,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _loading || _applying;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (_step != _MatchStep.search)
                    IconButton(
                      onPressed: busy ? null : _back,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: context.localized.danmakuBack,
                    )
                  else
                    const Icon(Icons.link_rounded),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title(context), style: theme.textTheme.titleLarge),
                        if (_subtitle() != null && _subtitle()!.isNotEmpty)
                          Text(
                            _subtitle()!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        busy ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (busy) const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 8),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return switch (_step) {
      _MatchStep.search => _buildSearch(theme),
      _MatchStep.anime => _buildAnimeList(theme),
      _MatchStep.episode => _buildEpisodeList(theme),
    };
  }

  Widget _buildSearch(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _keyword,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            labelText: context.localized.danmakuAnimeName,
            hintText: context.localized.danmakuAnimeNameHint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _loading ? null : _search,
            icon: const Icon(Icons.search),
            label: Text(context.localized.search),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.localized.danmakuSearchNote,
          style: theme.textTheme.bodySmall,
        ),
        const Spacer(),
        Text(
          context.localized.danmakuSearchFooter,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAnimeList(ThemeData theme) {
    if (_loading) return const SizedBox.shrink();
    if (_animes.isEmpty) {
      return Center(
        child: Text(context.localized.danmakuNoAnime, style: theme.textTheme.bodyMedium),
      );
    }
    return ListView.separated(
      itemCount: _animes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final anime = _animes[index];
        return ListTile(
          title: Text(anime.animeTitle),
          subtitle: anime.typeDescription.isEmpty
              ? null
              : Text(anime.typeDescription),
          trailing: const Icon(Icons.chevron_right),
          onTap: _applying ? null : () => _selectAnime(anime),
        );
      },
    );
  }

  Widget _buildEpisodeList(ThemeData theme) {
    if (_loading) return const SizedBox.shrink();
    if (_episodes.isEmpty) {
      return Center(
        child: Text(context.localized.danmakuNoEpisode, style: theme.textTheme.bodyMedium),
      );
    }
    final filter = _episodeFilter.text.trim().toLowerCase();
    final visible = filter.isEmpty
        ? _episodes
        : _episodes
            .where((episode) =>
                episode.episodeTitle.toLowerCase().contains(filter))
            .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _episodeFilter,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            hintText: context.localized.danmakuFilterEpisodes,
            prefixIcon: const Icon(Icons.filter_list),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.localized.danmakuEpisodeCount(
              _episodes.length, visible.length),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final episode = visible[index];
              return ListTile(
                dense: true,
                title: Text(episode.episodeTitle),
                subtitle: Text(_episodeSubtitle(context, episode)),
                trailing: const Icon(Icons.check_circle_outline, size: 18),
                onTap: _applying ? null : () => _apply(episode),
              );
            },
          ),
        ),
      ],
    );
  }
}
