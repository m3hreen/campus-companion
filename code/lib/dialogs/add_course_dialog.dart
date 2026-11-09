import 'package:flutter/material.dart';

// Lets the user add a course by entering its code and name.
class AddCourseDialog extends StatefulWidget {
  const AddCourseDialog({
    super.key,
    required this.courses,
  });

  // Use the existing courses to check for duplicate codes.
  final List<String> courses;

  @override
  State<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    // Ignore spaces and letter case when comparing course codes.
    final String code = (value ?? '').trim().toUpperCase().replaceAll(' ', '');

    if (code.isEmpty) return 'Enter a course code';

    final bool alreadyExists = widget.courses.any((course) {
      // Each course is stored as "CODE - Name". Compare only the code.
      final String existingCode =
      course.split(' - ').first.toUpperCase().replaceAll(' ', '');

      return existingCode == code;
    });

    return alreadyExists ? 'This course code already exists' : null;
  }

  void _save() {
    // Keep the dialog open if either field has an error.
    if (!_formKey.currentState!.validate()) return;

    final String code = _codeController.text.trim().toUpperCase();
    final String name = _nameController.text.trim();

    // Send the course label back so MainScreen can add it to the list.
    Navigator.pop(context, '$code - $name');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Course'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                maxLength: 20,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Course code',
                  hintText: 'CSCI3101U',
                ),
                validator: _validateCode,
              ),
              TextFormField(
                controller: _nameController,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Course name'),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Enter a course name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}