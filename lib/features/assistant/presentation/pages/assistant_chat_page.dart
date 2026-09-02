import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/presentation/pages/edit_product_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../providers/ai_assistant_provider.dart';

class AssistantChatPage extends StatefulWidget {
  const AssistantChatPage({super.key});

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(InventoryProvider inventory, AiAssistantProvider assistant) async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    _questionController.clear();
    final settings = inventory.settings;
    await assistant.sendQuestion(
      question,
      baseUrl: settings.effectiveAssistantBaseUrl,
      apiKey: settings.effectiveAssistantApiKey,
    );
    _scrollToBottom();
  }

  Future<void> _syncNow(InventoryProvider inventory, AiAssistantProvider assistant) async {
    final settings = inventory.settings;
    final ok = await assistant.syncCatalog(
      inventory.products,
      baseUrl: settings.effectiveAssistantBaseUrl,
      apiKey: settings.effectiveAssistantApiKey,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Catalog synced (${inventory.products.length} products)' : (assistant.errorMessage ?? 'Sync failed')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        final settings = inventory.settings;

        if (!settings.effectiveAssistantEnabled) {
          return Scaffold(
            appBar: AppBar(title: const Text('AI Assistant')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'The AI Assistant is not enabled yet.\nSet it up in Settings first.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      ),
                      child: const Text('Go to Settings'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Consumer<AiAssistantProvider>(
          builder: (context, assistant, _) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('AI Assistant'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: 'Sync Now',
                    onPressed: assistant.isLoading ? null : () => _syncNow(inventory, assistant),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: assistant.messages.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Ask about product availability, location, price, or compatible accessories.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: assistant.messages.length,
                            itemBuilder: (context, index) => _MessageBubble(message: assistant.messages[index]),
                          ),
                  ),
                  if (assistant.isLoading) const LinearProgressIndicator(minHeight: 2),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _questionController,
                              decoration: const InputDecoration(
                                hintText: 'Ask a question...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onSubmitted: (_) => _send(inventory, assistant),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            icon: const Icon(Icons.send),
                            onPressed: assistant.isLoading ? null : () => _send(inventory, assistant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: message.isError
              ? Colors.red.shade50
              : (isUser ? Colors.blue.shade600 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isError ? Colors.red.shade900 : (isUser ? Colors.white : Colors.black87),
              ),
            ),
            if (message.referencedProducts.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Referenced products:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.referencedProducts.map((p) {
                  return ActionChip(
                    label: Text('${p.name} · ${p.locationCode} · ${p.currency} ${p.price.toStringAsFixed(2)}'),
                    onPressed: () => _openProduct(context, p.id),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openProduct(BuildContext context, String productId) {
    final inventory = context.read<InventoryProvider>();
    final product = inventory.allProducts.where((p) => p.id == productId).firstOrNull;
    if (product == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductPage(product: product)));
  }
}
