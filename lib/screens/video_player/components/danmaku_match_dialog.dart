import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/providers/danmaku_provider.dart';

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
      setState(() => _error = '请输入番剧名称');
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
      final animes = await ref.read(danmakuProvider.notifier).searchAnime(keyword);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _animes = animes;
        if (animes.isEmpty) _error = '未找到番剧，试试日文原名或更短的关键词';
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
      // danmu_api 的搜索结果已带分集；官方 DDP 才需要再查 /bangumi/{id}。
      final episodes = anime.episodes.isNotEmpty
          ? anime.episodes
          : await ref
              .read(danmakuProvider.notifier)
              .episodesForAnime(anime.animeId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _episodes = episodes;
        if (episodes.isEmpty) _error = '该条目没有分集';
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

  String get _title => switch (_step) {
        _MatchStep.search => '手动匹配弹幕',
        _MatchStep.anime => '选择番剧',
        _MatchStep.episode => '选择分集',
      };

  String? get _subtitle => switch (_step) {
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
                      tooltip: '返回',
                    )
                  else
                    const Icon(Icons.link_rounded),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title, style: theme.textTheme.titleLarge),
                        if (_subtitle != null && _subtitle!.isNotEmpty)
                          Text(
                            _subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.of(context).pop(false),
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
          decoration: const InputDecoration(
            labelText: '番剧名称',
            hintText: '例如：孤独摇滚 / Bocchi the Rock!',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _loading ? null : _search,
            icon: const Icon(Icons.search),
            label: const Text('搜索'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '匹配结果会优先于自动匹配保存；清除匹配后恢复按标题+集号自动搜索。',
          style: theme.textTheme.bodySmall,
        ),
        const Spacer(),
        Text(
          '弹幕数据由弹弹play开放弹幕网络提供（www.dandanplay.com）。',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAnimeList(ThemeData theme) {
    if (_loading) return const SizedBox.shrink();
    if (_animes.isEmpty) {
      return Center(
        child: Text('没有可选番剧', style: theme.textTheme.bodyMedium),
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
        child: Text('没有可选分集', style: theme.textTheme.bodyMedium),
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
          decoration: const InputDecoration(
            isDense: true,
            hintText: '按标题筛选分集',
            prefixIcon: Icon(Icons.filter_list),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '共 ${_episodes.length} 集，当前显示 ${visible.length} 集',
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
                subtitle: Text('episodeId ${episode.episodeId}'),
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
