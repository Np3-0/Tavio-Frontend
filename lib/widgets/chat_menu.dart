import 'package:flutter/material.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

class ChatMenu extends StatelessWidget {
  const ChatMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 24),
          Text('Chat', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            'Voice-chat with our AI-assistant.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 0,
              shadowColor: Colors.transparent,
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: 4,
                        itemBuilder: (BuildContext context, int index) {
                          if (index % 2 == 1) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.all(8.0),
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.Ocean,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  'Hello',
                                  style: theme.textTheme.bodyLarge!.copyWith(
                                    color: AppColors.Alabaster,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.all(8.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: AppColors.Ocean,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                'Hi!',
                                style: theme.textTheme.bodyLarge!.copyWith(
                                  color: AppColors.Alabaster,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.Ocean,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              // add voice input
                            },
                            icon: Icon(
                              Icons.mic,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            // add code here
                          },
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
