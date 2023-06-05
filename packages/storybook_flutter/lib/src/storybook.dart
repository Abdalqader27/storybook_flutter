import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:storybook_flutter/src/plugins/plugin.dart';
import 'package:storybook_flutter/src/plugins/plugin_panel.dart';
import 'package:storybook_flutter/src/story.dart';

/// Use this wrapper to wrap each story into a [MaterialApp] widget.
Widget materialWrapper(
  BuildContext context,
  Widget? child, {
  ThemeData? theme,
  ThemeData? darkTheme,
}) =>
    MaterialApp(
      theme: theme ?? ThemeData.light(),
      darkTheme: darkTheme ?? ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: Directionality.of(context),
        child: Scaffold(
          body: Center(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );

/// Use this wrapper to wrap each story into a [CupertinoApp] widget.
Widget cupertinoWrapper(BuildContext context, Widget? child) => CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: Directionality.of(context),
        child: CupertinoPageScaffold(
          child: Center(child: child),
        ),
      ),
    );

final _defaultPlugins = initializePlugins();

class Storybook extends StatefulWidget {
  Storybook({
    Key? key,
    required Iterable<Story> stories,
    Iterable<Plugin>? plugins,
    this.initialStory,
    this.wrapperBuilder = materialWrapper,
    this.showPanel = true,
    this.brandingWidget,
    this.splashWidget,
    this.theme,
    this.darkTheme,
  })  : plugins = UnmodifiableListView(plugins ?? _defaultPlugins),
        stories = UnmodifiableListView(stories),
        super(key: key);

  /// All enabled plugins.
  final List<Plugin> plugins;

  /// All available stories.
  final List<Story> stories;

  /// Optional initial story.
  final String? initialStory;

  /// Each story will be wrapped into a widget returned by this builder.
  final TransitionBuilder wrapperBuilder;

  /// Whether to show the plugin panel at the bottom.
  final bool showPanel;

  /// Theme to use in the plugin panel.
  final ThemeData? theme;

  /// Dark theme to use in the plugin panel.
  final ThemeData? darkTheme;

  /// Branding widget to use in the plugin panel.
  final Widget? brandingWidget;

  /// Branding widget to use in the plugin panel.
  final Widget? splashWidget;

  @override
  State<Storybook> createState() => _StorybookState();
}

class _StorybookState extends State<Storybook> {
  final _overlayKey = GlobalKey<OverlayState>();
  final _layerLink = LayerLink();
  late final StoryNotifier _storyNotifier;

  @override
  void initState() {
    super.initState();
    _storyNotifier = StoryNotifier(
      widget.stories,
      initial: widget.initialStory,
    );
  }

  @override
  void didUpdateWidget(covariant Storybook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stories != oldWidget.stories) {
      _storyNotifier.stories = widget.stories;
    }
  }

  @override
  void dispose() {
    _storyNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = CurrentStory(
      wrapperBuilder: widget.wrapperBuilder,
    );

    return AdaptiveTheme(
      light: widget.theme ?? ThemeData.light(useMaterial3: true),
      dark: widget.darkTheme ?? ThemeData.dark(useMaterial3: true),
      initial: AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        theme: theme,
        darkTheme: darkTheme,
        home: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: MediaQuery.fromView(
            view: View.of(context),
            child: Nested(
              children: [
                Provider.value(value: widget.plugins),
                ChangeNotifierProvider.value(value: _storyNotifier),
                ...widget.plugins
                    .map((p) => p.wrapperBuilder)
                    .whereType<TransitionBuilder>()
                    .map((builder) => SingleChildBuilder(builder: builder))
              ],
              child: widget.showPanel
                  ? Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Column(
                          children: [
                            Expanded(child: currentStory),
                            RepaintBoundary(
                              child: Material(
                                child: SafeArea(
                                  top: false,
                                  child: CompositedTransformTarget(
                                    link: _layerLink,
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: Colors.black12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: PluginPanel(
                                                plugins: widget.plugins,
                                                overlayKey: _overlayKey,
                                                layerLink: _layerLink,
                                              ),
                                            ),
                                            widget.brandingWidget ??
                                                const SizedBox.shrink(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Overlay(key: _overlayKey),
                        ),
                      ],
                    )
                  : currentStory,
            ),
          ),
        ),
      ),
    );
  }
}

class CurrentStory extends StatelessWidget {
  const CurrentStory({Key? key, required this.wrapperBuilder})
      : super(key: key);

  final TransitionBuilder wrapperBuilder;

  @override
  Widget build(BuildContext context) {
    final story = context.watch<StoryNotifier>().currentStory;
    if (story == null) {
      return const Directionality(
        textDirection: TextDirection.ltr,
        child: Material(child: Center(child: Text('Select story'))),
      );
    }

    final plugins = context.watch<List<Plugin>>();
    final pluginBuilders = plugins
        .map((p) => p.storyBuilder)
        .whereType<TransitionBuilder>()
        .map((builder) => SingleChildBuilder(builder: builder))
        .toList();

    final effectiveWrapperBuilder = story.wrapperBuilder ?? wrapperBuilder;

    final child = effectiveWrapperBuilder(
      context,
      Builder(builder: story.builder),
    );

    return KeyedSubtree(
      key: ValueKey(story.name),
      child: pluginBuilders.isEmpty
          ? child
          : story.docBuilder != null
              ? _Tabs(
                  tabs: const [
                    Tab(text: 'Story'),
                    Tab(text: 'Documentation'),
                  ],
                  children: [
                    Nested(children: pluginBuilders, child: child),
                    story.docBuilder?.call(context) ?? const SizedBox.shrink(),
                  ],
                )
              : Nested(children: pluginBuilders, child: child),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    Key? key,
    required this.tabs,
    required this.children,
  }) : super(key: key);

  final List<Widget> tabs;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
        child: DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              TabBar(
                tabs: tabs,
                labelStyle: Theme.of(context).textTheme.labelLarge,
              ),
              Expanded(
                child: TabBarView(
                  children: children,
                ),
              ),
            ],
          ),
        ),
      );
}
