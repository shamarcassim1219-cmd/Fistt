import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/secure_screen_mixin.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> with SecureScreenMixin {
  bool _loading = true;
  int? _ticketId;
  String _ticketStatus = 'open';
  List<dynamic> _messages = [];
  bool _hasLoadedOnce = false;
  final Set<int> _typewriterIndices = {};
  Timer? _pollTimer;
  Timer? _typingDebounce;
  bool _adminTyping = false;
  String _handledBy = 'bot';
  bool _botConfused = false;
  bool _transferring = false;
  bool _closing = false;
  final _msgCtrl = TextEditingController();
  File? _pendingImage;
  final _startCtrl = TextEditingController();
  bool _sending = false;
  bool _starting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkActiveTicket();
    _msgCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    _msgCtrl.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_msgCtrl.text.trim().isEmpty || _ticketId == null) return;
    if (_typingDebounce?.isActive ?? false) return;
    _typingDebounce = Timer(const Duration(seconds: 3), () {});
    ApiService.sendLiveChatTyping(_ticketId!);
  }

  Future<void> _checkActiveTicket() async {
    setState(() => _loading = true);
    try {
      final ticket = await ApiService.getActiveChatTicket();
      if (!mounted) return;
      if (ticket != null) {
        setState(() {
          _ticketId = ticket['id'];
          _loading = false;
        });
        _loadMessages();
        _startPolling();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  Future<void> _loadMessages() async {
    if (_ticketId == null) return;
    try {
      final data = await ApiService.getLiveChatMessages(_ticketId!);
      if (!mounted) return;
      final oldCount = _messages.length;
      final newMessages = data['messages'] as List<dynamic>;
      setState(() {
        _messages = newMessages;
        _ticketStatus = data['status'];
        _handledBy = data['handledBy'] ?? 'bot';
        _botConfused = data['botConfused'] == true;
        _adminTyping = data['adminTyping'] == true;

        if (_hasLoadedOnce && newMessages.length > oldCount) {
          for (int i = oldCount; i < newMessages.length; i++) {
            if (newMessages[i]['isAdmin'] == true) {
              _typewriterIndices.add(i);
            }
          }
        }
        _hasLoadedOnce = true;
      });
    } catch (_) {}
  }

  Future<void> _startChat() async {
    if (_startCtrl.text.trim().isEmpty) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final ticketId = await ApiService.startLiveChat(_startCtrl.text.trim());
      _startCtrl.clear();
      if (!mounted) return;
      setState(() => _ticketId = ticketId);
      _loadMessages();
      _startPolling();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    if (_ticketId == null) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    final imageToSend = _pendingImage;
    setState(() => _pendingImage = null);
    try {
      String? imageUrl;
      if (imageToSend != null) {
        imageUrl = await ApiService.uploadImage(imageToSend);
      }
      await ApiService.sendLiveChatMessage(_ticketId!, text, imageUrl: imageUrl);
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    if (_sending) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _pendingImage = File(picked.path));
  }

  Future<void> _transferToOperator() async {
    if (_ticketId == null || _transferring) return;
    setState(() => _transferring = true);
    try {
      await ApiService.transferChatToOperator(_ticketId!);
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  Future<void> _closeChat() async {
    if (_ticketId == null || _closing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Close this chat?', style: TextStyle(color: Colors.white)),
        content: const Text('You can start a new chat anytime.', style: TextStyle(color: AppColors.hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close Chat')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _closing = true);
    try {
      await ApiService.closeLiveChat(_ticketId!);
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  void _startNewChat() {
    _pollTimer?.cancel();
    setState(() {
      _ticketId = null;
      _messages = [];
      _ticketStatus = 'open';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text((_handledBy == 'human' && _ticketId != null) ? 'Help Center — Ticket #$_ticketId' : 'Help Center'),
        actions: _ticketId != null && _ticketStatus == 'open'
            ? [
                IconButton(
                  icon: _closing
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.close),
                  tooltip: 'Close chat',
                  onPressed: _closing ? null : _closeChat,
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _ticketId == null
              ? _buildStartForm()
              : _buildChat(),
    );
  }

  Widget _buildStartForm() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.support_agent, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Start a conversation', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Describe your issue and our team will respond as soon as possible. You\'ll get a ticket number to track your conversation.',
              style: TextStyle(color: AppColors.hint, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _startCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Type your message...'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _starting ? null : _startChat,
                child: _starting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Start Chat', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat() {
    final isClosed = _ticketStatus != 'open';
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('Starting conversation...', style: TextStyle(color: AppColors.hint, fontSize: 12)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final isAdmin = m['isAdmin'] == true;
                    final shouldAnimate = _typewriterIndices.contains(i);
                    final imageUrl = m['imageUrl'] as String?;
                    final hasText = (m['content'] ?? '').toString().trim().isNotEmpty;
                    return Align(
                      key: ValueKey('msg_$i'),
                      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(imageUrl != null && !hasText ? 4 : 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppColors.fieldFill : AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: InteractiveViewer(child: Image.network(imageUrl)),
                                      ),
                                    );
                                  },
                                  child: Image.network(imageUrl, width: 200, fit: BoxFit.cover),
                                ),
                              ),
                            if (hasText)
                              Padding(
                                padding: EdgeInsets.only(top: imageUrl != null ? 6 : 0),
                                child: shouldAnimate
                                    ? _TypewriterText(
                                        key: ValueKey('typewriter_$i'),
                                        text: m['content'] ?? '',
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      )
                                    : Text(m['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (!isClosed && _handledBy != 'human' && _botConfused)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _transferring ? null : _transferToOperator,
                icon: _transferring
                    ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.support_agent, size: 16),
                label: const Text('Transfer to Operator', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),
        if (!isClosed && (_adminTyping || (_sending && _handledBy != 'human')))
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TypingBubble(),
            ),
          ),
        if (isClosed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                const Text('This chat has been closed', style: TextStyle(color: AppColors.hint, fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _startNewChat, child: const Text('Start New Chat')),
                ),
              ],
            ),
          )
        else
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pendingImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_pendingImage!, height: 80, width: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                              onPressed: () => setState(() => _pendingImage = null),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image_outlined, color: AppColors.hint),
                        onPressed: _sending ? null : _pickImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(hintText: _pendingImage != null ? 'Add a caption (optional)...' : 'Type a message...'),
                        ),
                      ),
                      IconButton(
                        icon: _sending
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send, color: AppColors.primary),
                        onPressed: _sending ? null : _sendMessage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotOffset(double t, double delay) {
    final local = ((t - delay) % 1.0 + 1.0) % 1.0;
    if (local < 0.5) {
      return -6 * (local / 0.5);
    } else {
      return -6 * (1 - (local - 0.5) / 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(_dotOffset(t, 0.0)),
              const SizedBox(width: 4),
              _dot(_dotOffset(t, 0.15)),
              const SizedBox(width: 4),
              _dot(_dotOffset(t, 0.3)),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(double offsetY) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: AppColors.hint, shape: BoxShape.circle),
      ),
    );
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _TypewriterText({super.key, required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _visibleChars = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    // Scale speed with message length so long replies don't take forever,
    // but cap it so short replies still feel natural.
    final totalMs = (widget.text.length * 12).clamp(300, 2000);
    final perCharMs = (totalMs / (widget.text.length == 0 ? 1 : widget.text.length)).clamp(6, 40).round();

    _timer = Timer.periodic(Duration(milliseconds: perCharMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleChars++;
      });
      if (_visibleChars >= widget.text.length) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _visibleChars.clamp(0, widget.text.length));
    return Text(shown, style: widget.style);
  }
}
