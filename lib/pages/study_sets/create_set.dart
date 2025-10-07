import 'package:flutter/material.dart';
import 'package:study_application/manager/studysets_manager.dart';
import 'package:study_application/model/study_set.dart';
import 'package:study_application/services/pocketbase_service.dart';

Future<CreateStudySetResult?> openCreateStudySetDialog(
    BuildContext context) async {
  final result = await showModalBottomSheet<CreateStudySetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _CreateStudySetSheet(),
  );

  return result;
}

class CreateStudySetResult {
  final String name;
  final String? subject;
  final String? description;
  final bool isPrivate;
  final StudySet studySet;

  const CreateStudySetResult({
    required this.name,
    this.subject,
    this.description,
    required this.isPrivate,
    required this.studySet,
  });
}

class _CreateStudySetSheet extends StatefulWidget {
  const _CreateStudySetSheet();

  @override
  State<_CreateStudySetSheet> createState() => _CreateStudySetSheetState();
}

class _CreateStudySetSheetState extends State<_CreateStudySetSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isPrivate = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final currentState = _formKey.currentState;
    if (currentState == null) return;
    if (!currentState.validate()) {
      return;
    }

    setState(() => _submitting = true);

    final name = _nameController.text.trim();
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      final StudySet createdSet = await StudySetManager.createStudySet(
        name: name,
        subject: subject.isEmpty ? null : subject,
        description: description.isEmpty ? null : description,
        isPrivate: _isPrivate,
      );

      if (!mounted) return;

      Navigator.of(context).pop(CreateStudySetResult(
        name: createdSet.title,
        subject: subject.isEmpty ? null : subject,
        description: description.isEmpty ? null : description,
        isPrivate: _isPrivate,
        studySet: createdSet,
      ));
    } on PocketBaseServiceException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create study set: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      'Create a new study set',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Study set name',
                        hintText: 'e.g. Biology Chapter 1',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name for your study set.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subjectController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Subject (optional)',
                        hintText: 'e.g. Biology',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 3,
                      minLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile.adaptive(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        title: const Text(
                          'Keep this study set private',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Only you will be able to see this set when enabled.',
                        ),
                        value: _isPrivate,
                        onChanged: (value) =>
                            setState(() => _isPrivate = value),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: const Text('Create set'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
