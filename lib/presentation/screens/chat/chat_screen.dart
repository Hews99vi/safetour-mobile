import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/message_provider.dart';
import '../../widgets/glass_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageProvider);
    ref.listen<ChatState>(messageProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        Future.microtask(() {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.midnight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected to Tourist Police',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ice,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonLime,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Online',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mist,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Semantics(
            label: 'Call Tourist Police',
            child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling Tourist Police (mock)')),
                );
              },
              icon: const Icon(Icons.call, color: AppColors.ice),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _Backdrop(),
          Column(
            children: [
              Expanded(
                child: state.messages.isEmpty && !state.isTyping
                    ? const _EmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount:
                            state.messages.length + (state.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (state.isTyping &&
                              index == state.messages.length) {
                            return const _TypingIndicator();
                          }
                          final message = state.messages[index];
                          return _MessageBubble(message: message);
                        },
                      ),
              ),
              _QuickReplies(
                onTap: (text) {
                  ref.read(messageProvider.notifier).sendMessage(text);
                },
              ),
              _Composer(
                controller: _controller,
                isSending: state.isSending,
                onSend: () {
                  ref
                      .read(messageProvider.notifier)
                      .sendMessage(_controller.text);
                  _controller.clear();
                },
                onAttach: () => _showAttachSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttachSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.my_location, color: AppColors.neonCyan),
                  title: const Text('Send My Location'),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref
                        .read(messageProvider.notifier)
                        .sendMessage('📍 My location: 37.7749, -122.4194');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.sender == ChatSender.user;
    final bubbleColor = isUser
        ? const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
          )
        : null;
    final bubbleDecoration = BoxDecoration(
      gradient: bubbleColor,
      color: isUser ? null : AppColors.glassFill,
      borderRadius: BorderRadius.circular(18),
      border: isUser ? null : Border.all(color: AppColors.glassStroke),
      boxShadow: [
        BoxShadow(
          color: (isUser ? AppColors.neonCyan : Colors.black)
              .withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );

    final failed = message.status == ChatMessageStatus.failed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 280),
            tween: Tween(begin: message.animateOnArrival ? 0.0 : 1.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              final offset = Offset(0, 12 * (1 - value));
              return Opacity(
                opacity: value,
                child: Transform.translate(offset: offset, child: child),
              );
            },
            child: Semantics(
              label:
                  '${isUser ? 'User' : 'Authority'} message: ${message.text}',
              child: Container(
                constraints: const BoxConstraints(maxWidth: 290),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: bubbleDecoration.copyWith(
                  border: failed
                      ? Border.all(color: AppColors.danger, width: 1.4)
                      : bubbleDecoration.border,
                ),
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            message.text,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isUser ? AppColors.midnight : AppColors.ice,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            ref
                                .read(messageProvider.notifier)
                                .translateMessage(message);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.translate,
                              size: 16,
                              color: isUser ? AppColors.midnight : AppColors.ice,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (message.isTranslating)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Translating...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isUser ? AppColors.midnight : AppColors.mist,
                              ),
                        ),
                      ),
                    if (message.translatedText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          message.translatedText!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isUser ? AppColors.midnight : AppColors.ice,
                              ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isUser ? AppColors.midnight : AppColors.mist,
                              ),
                        ),
                        if (failed) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(messageProvider.notifier)
                                  .retryMessage(message);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassStroke),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final dot1 = (t * 3).clamp(0.0, 1.0);
            final dot2 = ((t - 0.2) * 3).clamp(0.0, 1.0);
            final dot3 = ((t - 0.4) * 3).clamp(0.0, 1.0);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(opacity: dot1),
                const SizedBox(width: 6),
                _Dot(opacity: dot2),
                const SizedBox(width: 6),
                _Dot(opacity: dot3),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.mist.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.onAttach,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            border: Border.all(color: AppColors.glassStroke),
          ),
          child: Row(
            children: [
              Semantics(
                label: 'Attach options',
                child: IconButton(
                  onPressed: onAttach,
                  icon: const Icon(Icons.attach_file, color: AppColors.ice),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ice,
                      ),
                  decoration: InputDecoration(
                    hintText: 'Type message...',
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mist,
                        ),
                    filled: true,
                    fillColor: AppColors.deepSpace,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isSending ? null : onSend,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.4),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send, color: AppColors.midnight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          _Chip(label: 'I am lost', onTap: () => onTap('I am lost')),
          _Chip(label: 'I need help', onTap: () => onTap('I need help')),
          _Chip(
            label: 'Medical emergency',
            onTap: () => onTap('Medical emergency'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quick reply $label',
      child: ActionChip(
        onPressed: onTap,
        label: Text(label),
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.ice,
            ),
        backgroundColor: AppColors.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassStroke),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, color: AppColors.neonCyan),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ice,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F1A), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
