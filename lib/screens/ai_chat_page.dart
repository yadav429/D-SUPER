import 'package:flutter/material.dart';

import '../services/ai_brain_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, required this.hindi});

  final bool hindi;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final AiBrainService _brain = AiBrainService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _busy = false;

  bool get hindi => widget.hindi;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: hindi
          ? 'नमस्ते! मैं D-SUPER AI हूँ। Internet उपलब्ध होने पर Online Brain और बिना Internet के Offline मदद दूँगा।'
          : 'Hello! I am D-SUPER AI. I use the online brain when configured and provide basic help offline.',
      fromUser: false,
      online: false,
    ));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _busy = true;
    });
    _scrollToBottom();

    final reply = await _brain.ask(text, hindi: hindi);
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(
        text: reply.text,
        fromUser: false,
        online: reply.online,
      ));
      _busy = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _brain.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D-SUPER AI Brain'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Chip(
                avatar: const Icon(Icons.hub, size: 16),
                label: Text(hindi ? 'Hybrid AI' : 'Hybrid AI'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length + (_busy ? 1 : 0),
              itemBuilder: (context, index) {
                if (_busy && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final item = _messages[index];
                return Align(
                  alignment: item.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: item.fromUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.text),
                        if (!item.fromUser) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.online
                                ? 'ONLINE AI'
                                : 'OFFLINE AI',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: hindi ? 'अपना सवाल लिखें...' : 'Ask anything...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send),
                    tooltip: hindi ? 'भेजें' : 'Send',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromUser,
    this.online = false,
  });

  final String text;
  final bool fromUser;
  final bool online;
}
