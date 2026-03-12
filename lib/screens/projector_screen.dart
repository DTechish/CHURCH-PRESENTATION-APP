import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROJECTOR NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class ProjectorNotifier extends ChangeNotifier {
  ProjectorNotifier._();
  static final ProjectorNotifier instance = ProjectorNotifier._();

  ScriptureQueueItem? queueItem;
  Map<String, String>? song;
  ServiceItem? announcement;
  bool showLogo = false;
  bool isBlank = false;

  void update({
    ScriptureQueueItem? queueItem,
    Map<String, String>? song,
    ServiceItem? announcement,
    bool showLogo = false,
  }) {
    this.queueItem = queueItem;
    this.song = song;
    this.announcement = announcement;
    this.showLogo = showLogo;
    isBlank = false;
    notifyListeners();
  }

  void clear() {
    isBlank = true;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECTOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ProjectorScreen extends StatefulWidget {
  const ProjectorScreen({
    super.key,
    this.queueItem,
    this.song,
    this.announcement,
    this.showLogo = false,
  });

  final ScriptureQueueItem? queueItem;
  final Map<String, String>? song;
  final ServiceItem? announcement;
  final bool showLogo;

  @override
  State<ProjectorScreen> createState() => _ProjectorScreenState();
}

class _ProjectorScreenState extends State<ProjectorScreen> {
  @override
  void initState() {
    super.initState();
    ProjectorNotifier.instance.update(
      queueItem: widget.queueItem,
      song: widget.song,
      announcement: widget.announcement,
      showLogo: widget.showLogo,
    );
    ProjectorNotifier.instance.addListener(_onUpdate);
  }

  @override
  void dispose() {
    ProjectorNotifier.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final n = ProjectorNotifier.instance;

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        },
        child: GestureDetector(
          onDoubleTap: () => Navigator.of(context).pop(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: _buildContent(n),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ProjectorNotifier n) {
    if (n.isBlank) {
      return Container(key: const ValueKey('blank'), color: Colors.black);
    }
    if (n.showLogo) {
      return _LogoView(key: const ValueKey('logo'));
    }
    if (n.queueItem != null) {
      return _ScriptureView(key: ValueKey(n.queueItem!.reference), item: n.queueItem!);
    }
    if (n.song != null) {
      return _SongView(key: ValueKey(n.song!['title']), song: n.song!);
    }
    if (n.announcement != null) {
      return _AnnouncementView(key: ValueKey(n.announcement!.id), item: n.announcement!);
    }
    return Container(key: const ValueKey('idle'), color: Colors.black);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCRIPTURE VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _ScriptureView extends StatelessWidget {
  const _ScriptureView({super.key, required this.item});
  final ScriptureQueueItem item;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 38, height: 1.65, color: Colors.white,
      fontWeight: FontWeight.w400, letterSpacing: 0.1,
    );
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(72, 60, 72, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.reference,
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w600,
              color: Color(0xFF4FC3F7), letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 36),
          Expanded(
            child: SingleChildScrollView(
              child: RichText(text: item.buildRichText(textStyle)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            item.version.abbreviation,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SONG VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _SongView extends StatelessWidget {
  const _SongView({super.key, required this.song});
  final Map<String, String> song;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(72, 60, 72, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            song['title'] ?? '',
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w600,
              color: Color(0xFFB39DDB), letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 36),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  song['lyrics'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 38, height: 1.7, color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANNOUNCEMENT VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementView extends StatelessWidget {
  const _AnnouncementView({super.key, required this.item});
  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(72, 60, 72, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.announcementTitle?.isNotEmpty == true) ...[
            Text(
              item.announcementTitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w600,
                color: Color(0xFFE6C349), letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 32),
          ],
          Text(
            item.announcementText ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36, height: 1.6, color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGO VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _LogoView extends StatelessWidget {
  const _LogoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.church_rounded, size: 120,
                color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 24),
            Text(
              'CHURCH LOGO',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// PROJECTOR NOTIFIER
//
// A lightweight ChangeNotifier that lets the operator window push new content
// to the already-open ProjectorScreen without rebuilding the whole tree.
//
// Usage:
//   ProjectorNotifier.instance.update(queueItem: item);  // push scripture
//   ProjectorNotifier.instance.update(song: song);        // push song
//   ProjectorNotifier.instance.clear();                   // blank screen