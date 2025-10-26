import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorSchemeSeed: const Color(0xFF5C2E91),
      useMaterial3: true,
      //textTheme: GoogleFonts.interTextTheme(),
    );
    return MaterialApp(
      title: 'Taskoon Chat',
      theme: theme,
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/* ======================================================================= */
/*                                 CHAT UI                                  */
/* ======================================================================= */

enum MessageKind { text, video }

class ChatMessage {
  ChatMessage.text({
    required this.id,
    required this.fromMe,
    required this.timestamp,
    required String text,
  })  : kind = MessageKind.text,
        this.text = text,
        videoPath = null;

  ChatMessage.video({
    required this.id,
    required this.fromMe,
    required this.timestamp,
    required String this.videoPath,
  })  : kind = MessageKind.video,
        text = null;

  final String id;
  final bool fromMe;
  final DateTime timestamp;
  final MessageKind kind;
  final String? text;
  final String? videoPath;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _messages = <ChatMessage>[
    ChatMessage.text(
      id: 'm1',
      fromMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      text: 'Hi Alex! I’m on my way 👋',
    ),
    ChatMessage.text(
      id: 'm2',
      fromMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
      text: 'Great, see you soon!',
    ),
  ];

  final _input = TextEditingController();
  final _scroll = ScrollController();

  // keep video controllers per message id (dispose on remove)
  final Map<String, VideoPlayerController> _controllers = {};

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /* ------------------------------ Actions -------------------------------- */

  void _sendText() {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final msg = ChatMessage.text(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fromMe: true,
      timestamp: DateTime.now(),
      text: text,
    );
    setState(() {
      _messages.add(msg);
      _input.clear();
    });
    _scrollToBottom();

    // Simulate a reply (you would call your backend here)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.text(
          id: 'r${DateTime.now().microsecondsSinceEpoch}',
          fromMe: false,
          timestamp: DateTime.now(),
          text: 'Thanks for the update!',
        ));
      });
      _scrollToBottom();
    });
  }

  Future<void> _pickVideo() async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PickVideoSheet(),
    );
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? file =
          await picker.pickVideo(source: source, maxDuration: const Duration(minutes: 5));
      if (file == null) return;

      final msg = ChatMessage.video(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        fromMe: true,
        timestamp: DateTime.now(),
        videoPath: file.path,
      );

      setState(() => _messages.add(msg));
      _scrollToBottom();
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick video: ${e.message}')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /* ------------------------------ Build ---------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const _ChatHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isMe = m.fromMe;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _MessageBubble(
                        message: m,
                        isMe: isMe,
                        controllerProvider: _getController,
                        onRemove: () => _removeMessage(m),
                      ),
                    ),
                  );
                },
              ),
            ),
            _InputBar(
              controller: _input,
              onSend: _sendText,
              onAttach: _pickVideo,
            ),
          ],
        ),
      ),
    );
  }

  /* --------------------------- Video controllers ------------------------- */

  Future<VideoPlayerController> _getController(ChatMessage m) async {
    assert(m.kind == MessageKind.video && m.videoPath != null);
    if (_controllers.containsKey(m.id)) {
      final c = _controllers[m.id]!;
      if (c.value.isInitialized) return c;
      await c.initialize();
      return c;
    } else {
      final c = VideoPlayerController.file(File(m.videoPath!));
      _controllers[m.id] = c;
      await c.initialize();
      return c;
    }
  }

  void _removeMessage(ChatMessage m) {
    setState(() => _messages.remove(m));
    final c = _controllers.remove(m.id);
    c?.dispose();
  }
}

/* ======================================================================= */
/*                             UI WIDGETS                                   */
/* ======================================================================= */

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF5C2E91);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: purple),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Chat with your tasker',
                style: TextStyle(
                  color: purple,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chat_bubble_outline_rounded, color: purple),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.controllerProvider,
    required this.onRemove,
  });

  final ChatMessage message;
  final bool isMe;
  final Future<VideoPlayerController> Function(ChatMessage) controllerProvider;
  final VoidCallback onRemove;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  VideoPlayerController? _controller;
  bool _playing = false;

  @override
  void dispose() {
    _controller?.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    setState(() => _playing = _controller?.value.isPlaying ?? false);
  }

  Future<void> _togglePlay() async {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      await _controller!.pause();
    } else {
      await _controller!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.isMe;
    final bubbleColor = me ? const Color(0xFF5C2E91) : Colors.white;
    final textColor = me ? Colors.white : const Color(0xFF111827);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(me ? 18 : 4),
      bottomRight: Radius.circular(me ? 4 : 18),
    );

    Widget content;
    if (widget.message.kind == MessageKind.text) {
      content = Text(
        widget.message.text!,
        style: TextStyle(color: textColor, fontSize: 16),
      );
    } else {
      content = FutureBuilder<VideoPlayerController>(
        future: widget.controllerProvider(widget.message),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(
              width: 240,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (!snap.hasData) {
            return const Text('Unable to load video');
          }
          _controller ??= snap.data!;
          _controller!.removeListener(_sync);
          _controller!.addListener(_sync);

          return GestureDetector(
            onTap: _togglePlay,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio == 0
                        ? 16 / 9
                        : _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                  AnimatedOpacity(
                    opacity: _playing ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      color: Colors.black26,
                      child: const Icon(Icons.play_circle_fill_rounded,
                          size: 64, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          builder: (_) => SafeArea(
            child: ListTileTheme(
              iconColor: Colors.grey.shade800,
              textColor: Colors.grey.shade900,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.message.kind == MessageKind.text)
                    ListTile(
                      leading: const Icon(Icons.copy_rounded),
                      title: const Text('Copy'),
                      onTap: () {
                        Navigator.pop(context);
                        Clipboard.setData(
                          ClipboardData(text: widget.message.text ?? ''),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied')),
                        );
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('Delete'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onRemove();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: EdgeInsets.all(widget.message.kind == MessageKind.text ? 12 : 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            boxShadow: me
                ? [
                    BoxShadow(
                      color: const Color(0xFF5C2E91).withOpacity(.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: content,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF5C2E91);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Attach
            InkWell(
              onTap: onAttach,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.link_rounded, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 10),
            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Send a reply to your tasker!',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 10),
            // Send
            SizedBox(
              height: 44,
              width: 44,
              child: FilledButton(
                onPressed: onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================ Pick Video Sheet ============================ */

class _PickVideoSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListTileTheme(
        iconColor: Colors.grey.shade800,
        textColor: Colors.grey.shade900,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_rounded),
              title: const Text('Record video'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}