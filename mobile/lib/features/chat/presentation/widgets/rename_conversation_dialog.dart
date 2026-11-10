import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class RenameConversationDialog extends StatefulWidget {
  final String currentTitle;

  const RenameConversationDialog({
    super.key,
    required this.currentTitle,
  });

  static Future<String?> show(BuildContext context, String currentTitle) {
    return showDialog<String>(
      context: context,
      builder: (context) => RenameConversationDialog(currentTitle: currentTitle),
    );
  }

  @override
  State<RenameConversationDialog> createState() => _RenameConversationDialogState();
}

class _RenameConversationDialogState extends State<RenameConversationDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.currentTitle.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final text = _controller.text.trim();
      Navigator.of(context).pop(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.edit_outlined, size: 22, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Rename Conversation',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 255,
          decoration: InputDecoration(
            hintText: 'Enter new title',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title cannot be empty';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

