import 'package:flutter/material.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

class ChatMenu extends StatelessWidget {
  const ChatMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text('Assistant Chat', style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask for menu guidance and allergy-safe recommendations.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
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
                              child: Semantics(
                                label: 'You said: Hello',
                                child: Container(
                                  margin: const EdgeInsets.all(8.0),
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.Onyx,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    'Hello',
                                    style: theme.textTheme.bodyLarge!.copyWith(
                                      color: AppColors.Alabaster,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Semantics(
                              label: 'Assistant said: Hi',
                              child: Container(
                                margin: const EdgeInsets.all(8.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDDEAFF),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  'Hi!',
                                  style: theme.textTheme.bodyLarge!.copyWith(
                                    color: AppColors.Onyx,
                                  ),
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
                        Semantics(
                          button: true,
                          label: 'Start voice input',
                          child: FilledButton(
                            onPressed: () {
                              // add voice input
                            },
                            style: FilledButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(16),
                              backgroundColor: AppColors.Ocean,
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: AppColors.Alabaster,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            textField: true,
                            label: 'Message input',
                            hint: 'Type your question for the assistant',
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Type a message',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          button: true,
                          label: 'Send message',
                          child: IconButton(
                            onPressed: () {
                              // add code here
                            },
                            tooltip: 'Send message',
                            icon: const Icon(Icons.send, color: AppColors.Ocean),
                          ),
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
