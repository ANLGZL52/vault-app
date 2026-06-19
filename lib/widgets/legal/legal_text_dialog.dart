import 'package:flutter/material.dart';

Future<void> showLegalTextDialog({
  required BuildContext context,
  required String title,
  required String content,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog.fullscreen(
        backgroundColor: const Color(0xFF05070D),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: const Color(0xFF05070D),
                foregroundColor: Colors.white,
                title: Text(title),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                  child: Text(
                    content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFE8EAF0),
                      height: 1.55,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
