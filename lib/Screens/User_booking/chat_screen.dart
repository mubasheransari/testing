import 'package:flutter/material.dart';
import 'package:taskoon/Models/chat/chat_model.dart';


class ChattScreen extends StatefulWidget {
  const ChattScreen({
    super.key,
    required this.viewerRole,
    required this.user,
    required this.tasker,
    required this.bookingInfo,
  });

  final ViewerRole viewerRole;
  final ChatParticipant user;
  final ChatParticipant tasker;
  final ChatBookingInfo bookingInfo;

  @override
  State<ChattScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChattScreen> {
  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kPrimaryDark = Color(0xFF3E1E69);
  static const Color kBg = Color(0xFFF8F7FB);
  static const Color kMuted = Color(0xFF75748A);
  static const Color kBorder = Color(0xFFE8E8EF);
  static const Color kUserBubble = Color(0xFF5C2E91);
  static const Color kTaskerBubble = Colors.white;
  static const Color kSystemBg = Color(0xFFF1EEF8);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<ChatMessage> _messages;

  List<String> get _quickReplies {
    if (widget.viewerRole == ViewerRole.user) {
      return [
        'Where are you?',
        'I have shared access details',
        'Please call on arrival',
        'Need help',
      ];
    } else {
      return [
        'I am on my way',
        'I have arrived',
        'Need 10 more minutes',
        'Task completed',
      ];
    }
  }

  ChatParticipant get _headerPerson =>
      widget.viewerRole == ViewerRole.user ? widget.tasker : widget.user;

  @override
  void initState() {
    super.initState();

    _messages = [
      ChatMessage(
        id: '1',
        text: 'Booking confirmed',
        senderRole: ChatRole.system,
        time: DateTime.now().subtract(const Duration(minutes: 30)),
        isSystem: true,
      ),
      ChatMessage(
        id: '2',
        text: widget.viewerRole == ViewerRole.user
            ? 'Hi, I am on my way.'
            : 'Hi, please come to the side gate.',
        senderRole: widget.viewerRole == ViewerRole.user
            ? ChatRole.tasker
            : ChatRole.user,
        time: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      ChatMessage(
        id: '3',
        text: widget.viewerRole == ViewerRole.user
            ? 'Okay, please call when you arrive.'
            : 'Sure, I will call on arrival.',
        senderRole: widget.viewerRole == ViewerRole.user
            ? ChatRole.user
            : ChatRole.tasker,
        time: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final senderRole =
        widget.viewerRole == ViewerRole.user ? ChatRole.user : ChatRole.tasker;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text.trim(),
          senderRole: senderRole,
          time: DateTime.now(),
        ),
      );
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _sendQuickReply(String text) {
    _sendMessage(text);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  bool _isMyMessage(ChatMessage msg) {
    if (widget.viewerRole == ViewerRole.user) {
      return msg.senderRole == ChatRole.user;
    } else {
      return msg.senderRole == ChatRole.tasker;
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerName = _headerPerson.name;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryDark,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kPrimary.withOpacity(.12),
              child: Text(
                headerName.isNotEmpty ? headerName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: kPrimaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          headerName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_headerPerson.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.bookingInfo.serviceName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBookingCard(),
          _buildQuickReplies(),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final msg = _messages[index];

                if (msg.isSystem || msg.senderRole == ChatRole.system) {
                  return _buildSystemMessage(msg);
                }

                return _buildMessageBubble(msg);
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildBookingCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline, color: kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.bookingInfo.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: kPrimaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.bookingInfo.status,
                  style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.confirmation_number_outlined, widget.bookingInfo.bookingId),
          const SizedBox(height: 6),
          _infoRow(Icons.schedule_outlined, widget.bookingInfo.dateTimeLabel),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, widget.bookingInfo.location),
          const SizedBox(height: 6),
          _infoRow(Icons.payments_outlined, '\$${widget.bookingInfo.amount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReplies() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _quickReplies[index];
          return ActionChip(
            side: BorderSide(color: kPrimary.withOpacity(.18)),
            backgroundColor: Colors.white,
            label: Text(
              item,
              style: const TextStyle(
                color: kPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            onPressed: () => _sendQuickReply(item),
          );
        },
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage msg) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kSystemBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          msg.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kPrimaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMine = _isMyMessage(msg);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .75,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: isMine ? kUserBubble : kTaskerBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 6),
              bottomRight: Radius.circular(isMine ? 6 : 18),
            ),
            border: isMine ? null : Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                style: TextStyle(
                  color: isMine ? Colors.white : kPrimaryDark,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(msg.time),
                    style: TextStyle(
                      color: isMine ? Colors.white70 : kMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline),
              color: kPrimary,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: kBorder),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  decoration: const InputDecoration(
                    hintText: 'Send a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _sendMessage(_controller.text),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                height: 46,
                width: 46,
                decoration: const BoxDecoration(
                  color: kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}