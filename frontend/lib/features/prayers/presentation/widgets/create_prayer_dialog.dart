import 'package:flutter/material.dart';

class CreatePrayerDialog extends StatefulWidget {
  const CreatePrayerDialog({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function({
    required String title,
    required String content,
    required String category,
    required String type,
    required bool isAnonymous,
  }) onSubmit;

  static const categories = [
    'General',
    'Health & Healing',
    'Family & Relationships',
    'Guidance & Wisdom',
    'Faith & Strength',
    'Gratitude & Praise',
    'Financial & Work',
  ];

  @override
  State<CreatePrayerDialog> createState() => _CreatePrayerDialogState();
}

class _CreatePrayerDialogState extends State<CreatePrayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = CreatePrayerDialog.categories.first;
  String _selectedType = 'request';
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        type: _selectedType,
        isAnonymous: _isAnonymous,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _dialogTitle {
    switch (_selectedType) {
      case 'prayer':
        return 'Share Written Prayer';
      case 'praise':
        return 'Share Praise Report';
      case 'request':
      default:
        return 'Share Prayer Request';
    }
  }

  String get _titleLabel {
    switch (_selectedType) {
      case 'prayer':
        return 'Prayer Title';
      case 'praise':
        return 'Praise Report Title';
      case 'request':
      default:
        return 'Request Title';
    }
  }

  String get _titleHint {
    switch (_selectedType) {
      case 'prayer':
        return 'e.g. Morning Prayer for Peace & Strength';
      case 'praise':
        return 'e.g. Thankful for answered prayer & recovery';
      case 'request':
      default:
        return 'e.g. Healing for my mother';
    }
  }

  String get _contentLabel {
    switch (_selectedType) {
      case 'prayer':
        return 'Written Prayer';
      case 'praise':
        return 'Praise / Testimony Details';
      case 'request':
      default:
        return 'Prayer Details';
    }
  }

  String get _contentHint {
    switch (_selectedType) {
      case 'prayer':
        return 'Write your prayer, blessing, or devotional words...';
      case 'praise':
        return 'Share what God has done with the community...';
      case 'request':
      default:
        return 'Share what you would like prayer for...';
    }
  }

  String get _buttonLabel {
    switch (_selectedType) {
      case 'prayer':
        return 'Post Prayer';
      case 'praise':
        return 'Post Praise Report';
      case 'request':
      default:
        return 'Post Prayer Request';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _selectedType == 'prayer'
                              ? Icons.auto_stories
                              : _selectedType == 'praise'
                                  ? Icons.star
                                  : Icons.volunteer_activism,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dialogTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Post Type Selector: Request | Prayer | Praise
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: 'request',
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('🙏 Request'),
                        ),
                      ),
                      ButtonSegment(
                        value: 'prayer',
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('📖 Prayer'),
                        ),
                      ),
                      ButtonSegment(
                        value: 'praise',
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('✨ Praise'),
                        ),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedType = newSelection.first;
                        // Suggest appropriate default category for praise
                        if (_selectedType == 'praise' && _selectedCategory == 'General') {
                          _selectedCategory = 'Gratitude & Praise';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: _titleLabel,
                      hintText: _titleHint,
                      border: const OutlineInputBorder(),
                    ),
                    maxLength: 100,
                    validator: (val) {
                      if (val == null || val.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: CreatePrayerDialog.categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: _contentLabel,
                      hintText: _contentHint,
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    validator: (val) {
                      if (val == null || val.trim().length < 10) {
                        return 'Please provide more details (at least 10 characters)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Post Anonymously'),
                    subtitle: const Text('Hide your name and profile picture'),
                    value: _isAnonymous,
                    onChanged: (val) => setState(() => _isAnonymous = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _buttonLabel,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
