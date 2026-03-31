import 'package:flutter/material.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

class ChatMenu extends StatelessWidget {
  const ChatMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text('Chat', style: theme.textTheme.headlineSmall)),
          const SizedBox(height: 8),
          Text('Ask questions about menus and allergies.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: 4,
                        itemBuilder: (_, i) => Align(
                          alignment: i % 2 == 1 ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: i % 2 == 1 ? AppColors.Ocean : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              i % 2 == 1 ? 'You said: Hello' : 'Assistant: Hi there',
                              style: TextStyle(
                                color: i % 2 == 1 ? Colors.white : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(16),
                            backgroundColor: AppColors.Ocean,
                          ),
                          child: const Icon(Icons.mic, color: AppColors.Alabaster),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Ask me anything',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.send, color: AppColors.Ocean),
                        ),
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
}
