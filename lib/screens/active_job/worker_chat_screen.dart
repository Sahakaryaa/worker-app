import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';

/// ────────────────────────────────────────────────────────────────────────────
/// Worker-side trip chat — mirrors the customer ChatScreen UX (bubbles, quick
/// replies, typing indicator) but owns its own Socket.IO connection joined to
/// the booking room. Falls back to a local demo brain when offline.
/// ────────────────────────────────────────────────────────────────────────────

class _WChatMsg {
  final String text;
  final bool isMine;
  final DateTime time;
  _WChatMsg({required this.text, required this.isMine, required this.time});
}

const List<String> kWQuickReplies = [
  'On my way',
  'Reached the location',
  'Need 10 more minutes',
  'Work completed',
];

class WorkerChatScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String customerName;
  final String? serviceType;

  const WorkerChatScreen({
    super.key,
    required this.bookingId,
    required this.customerName,
    this.serviceType,
  });

  @override
  ConsumerState<WorkerChatScreen> createState() => _WorkerChatScreenState();
}

class _WorkerChatScreenState extends ConsumerState<WorkerChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_WChatMsg> _messages = [];
  io.Socket? _socket;
  StreamSubscription<void>? _demoSub;
  bool _connected = false;
  bool _customerTyping = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    try {
      _socket = io.io(
        kApiBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io')
            .enableReconnection()
            .setReconnectionDelay(1500)
            .build(),
      );
      _socket!.onConnect((_) {
        if (!mounted) return;
        setState(() => _connected = true);
        _socket!.emit('join_booking', {'booking_id': widget.bookingId});
      });
      _socket!.onDisconnect((_) {
        if (mounted) setState(() => _connected = false);
      });
      _socket!.onConnectError((_) {
        if (mounted) setState(() => _connected = false);
      });
      _socket!.on('chat_message', (data) {
        if (data is! Map || !mounted) return;
        final id = data['booking_id']?.toString();
        if (id != null && id != widget.bookingId) return;
        final text =
            (data['message'] ?? data['text'] ?? '').toString().trim();
        if (text.isEmpty) return;
        final role = data['sender_role']?.toString() ?? 'customer';
        setState(() {
          _customerTyping = false;
          _messages.add(_WChatMsg(
            text: text,
            isMine: role == 'worker',
            time: DateTime.tryParse(data['ts']?.toString() ?? '') ??
                DateTime.now(),
          ));
        });
        _jumpToEnd();
      });
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  /// Offline demo: seed one inbound message + local reply brain.
  void _simulateReply() {
    _demoSub?.cancel();
    setState(() => _customerTyping = true);
    Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      const replies = [
        'Ok, please come to the main gate.',
        'Sure, take your time.',
        'Thank you! Please also check the switch board.',
        'Noted 👍',
      ];
      setState(() {
        _customerTyping = false;
        _messages.add(_WChatMsg(
          text: replies[math.Random().nextInt(replies.length)],
          isMine: false,
          time: DateTime.now(),
        ));
      });
      _jumpToEnd();
    });
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.lightImpact();

    final sentLive = _socket != null && _connected;
    if (sentLive) {
      _socket!.emit('chat_message', {
        'booking_id': widget.bookingId,
        'message': trimmed,
        'sender_role': 'worker',
        'ts': DateTime.now().toIso8601String(),
      });
    }

    setState(() {
      _messages.add(_WChatMsg(
          text: trimmed, isMine: true, time: DateTime.now()));
      if (!sentLive) {
        // Demo fallback reply after a short "typing" pause.
        Timer(const Duration(milliseconds: 400), () {
          if (mounted) _simulateReply();
        });
      }
      _input.clear();
    });
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _demoSub?.cancel();
    try {
      _socket?.emit('leave_booking', {'booking_id': widget.bookingId});
      _socket?.dispose();
    } catch (_) {}
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.gold.withValues(alpha: 0.14),
              child: Text(
                _initials(widget.customerName),
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.customerName,
                      style: GoogleFonts.sora(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    !_connected
                        ? 'Demo mode'
                        : (_customerTyping ? 'typing…' : 'Customer'),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: _customerTyping
                          ? AppColors.success
                          : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            // Live/demo connection chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (_connected ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _connected
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _connected ? 'LIVE' : 'DEMO',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: _connected
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _emptyThread()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    itemCount:
                        _messages.length + (_customerTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_customerTyping && i == _messages.length) {
                        return _typingBubble(reducedMotion);
                      }
                      return _bubble(_messages[i],
                          animateIn:
                              !reducedMotion && i >= _messages.length - 1);
                    },
                  ),
          ),

          // Quick replies
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: kWQuickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final chip = kWQuickReplies[i];
                return ActionChip(
                  label: Text(chip,
                      style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.indigo)),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                      color: AppColors.indigo.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  onPressed: () => _send(chip),
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 1,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _send,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Message $_firstName…',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13.5, color: AppColors.inkFaint),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        filled: true,
                        fillColor: AppColors.bg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(
                              color: AppColors.indigo, width: 1.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration:
                        Duration(milliseconds: reducedMotion ? 1 : 180),
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _input.text.trim().isEmpty
                          ? null
                          : AppColors.indigoGradient,
                      color: _input.text.trim().isEmpty
                          ? AppColors.surfaceAlt
                          : null,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.send_rounded,
                        size: 19,
                        color: _input.text.trim().isEmpty
                            ? AppColors.inkFaint
                            : Colors.white,
                      ),
                      onPressed: _input.text.trim().isEmpty
                          ? null
                          : () => _send(_input.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyThread() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.indigo.withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 34, color: AppColors.indigo),
            ),
            const SizedBox(height: 14),
            Text('No messages yet',
                style: GoogleFonts.sora(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Say hello or share your arrival status — messages stay private between you and $_firstName.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_WChatMsg m, {required bool animateIn}) {
    final alignRight = m.isMine;
    Widget bubble = Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: alignRight ? 56 : 0,
        right: alignRight ? 0 : 56,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: alignRight ? AppColors.indigoDeep : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(alignRight ? 18 : 5),
          bottomRight: Radius.circular(alignRight ? 5 : 18),
        ),
        border: alignRight ? null : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.text,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.35,
              color: alignRight ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _clock(m.time),
            style: GoogleFonts.inter(
              fontSize: 9.5,
              color: alignRight
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
    if (animateIn) {
      bubble = bubble
          .animate()
          .fade(duration: 220.ms)
          .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
    }
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

  Widget _typingBubble(bool reducedMotion) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: const Radius.circular(5),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: reducedMotion
            ? const Text('…', style: TextStyle(color: AppColors.inkSoft))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: const BoxDecoration(
                        color: AppColors.inkFaint, shape: BoxShape.circle),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.25, end: 1,
                          delay: (i * 150).ms, duration: 450.ms);
                }),
              ),
      ),
    );
  }

  String get _firstName => widget.customerName.split(' ').first;

  String _clock(DateTime t) =>
      '${((t.hour + 11) % 12) + 1}:${t.minute.toString().padLeft(2, '0')} '
      '${t.hour < 12 ? 'AM' : 'PM'}';

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .map((e) => e[0])
      .take(2)
      .join()
      .toUpperCase();
}
