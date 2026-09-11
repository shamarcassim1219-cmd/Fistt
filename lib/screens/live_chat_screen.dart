import 'dart:async';
import 'package:flutter/material.dart';
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
  Timer? _pollTimer;
  final _msgCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  bool _sending = false;
  bool _starting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkActiveTicket();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
      setState(() {
        _messages = data['messages'];
        _ticketStatus = data['status'];
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
    if (_msgCtrl.text.trim().isEmpty || _ticketId == null) return;
    setState(() => _sending = true);
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();
    try {
      await ApiService.sendLiveChatMessage(_ticketId!, text);
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sending = false);
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
      appBar: AppBar(title: Text(_ticketId != null ? 'Live Chat — Ticket #$_ticketId' : 'Live Chat with Admin')),
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
                    return Align(
                      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppColors.fieldFill : AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    );
                  },
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Type a message...'),
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
            ),
          ),
      ],
    );
  }
}
