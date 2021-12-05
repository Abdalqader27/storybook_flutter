import 'package:flutter/material.dart';

import 'plugin.dart';

class PluginPanel extends StatefulWidget {
  const PluginPanel({
    Key? key,
    required this.plugins,
    required this.layerLink,
    required this.overlayKey,
  }) : super(key: key);

  final List<Plugin> plugins;
  final LayerLink layerLink;
  final GlobalKey<OverlayState> overlayKey;

  @override
  State<PluginPanel> createState() => _PluginPanelState();
}

class _PluginPanelState extends State<PluginPanel> {
  PluginOverlay? _overlay;

  OverlayEntry _createEntry(WidgetBuilder childBuilder) => OverlayEntry(
        builder: (context) => Positioned(
          height: 350,
          width: 250,
          child: CompositedTransformFollower(
            link: widget.layerLink,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            showWhenUnlinked: false,
            child: Localizations(
              delegates: const [
                DefaultMaterialLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
              ],
              locale: const Locale('en', 'US'),
              child: Dialog(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                insetPadding: EdgeInsets.zero,
                child: Material(
                  child: childBuilder(context),
                ),
              ),
            ),
          ),
        ),
      );

  void _onPluginButtonPressed(Plugin p) {
    p.onPressed?.call(context);
    if (p.panelBuilder == null) return;

    void insertOverlay() {
      _overlay = PluginOverlay(
        plugin: p,
        entry: _createEntry((context) => p.panelBuilder!(context)),
      );
      widget.overlayKey.currentState!.insert(_overlay!.entry);
    }

    if (_overlay != null) {
      _overlay!.remove();
      if (_overlay!.plugin != p) {
        insertOverlay();
      } else {
        _overlay = null;
      }
    } else {
      insertOverlay();
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
        runAlignment: WrapAlignment.center,
        children: widget.plugins
            .where((p) => p.icon != null)
            .map(
              (p) => IconButton(
                icon: p.icon!.call(context),
                onPressed: () => _onPluginButtonPressed(p),
              ),
            )
            .toList(),
      );
}

@immutable
class PluginOverlay {
  const PluginOverlay({required this.entry, required this.plugin});

  final OverlayEntry entry;
  final Plugin plugin;

  void remove() => entry.remove();
}
