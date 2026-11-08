// Validate course details before returning a unique course label to the parent.
import 'package:flutter/material.dart';

class AddCourseDialog extends StatefulWidget {
  const AddCourseDialog({super.key, required this.courses});
  final List<String> courses;
  @override
  State<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Course'),
      content: SingleChildScrollView(
        child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: _code, maxLength: 20,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Course code', hintText: 'CSCI3101U'),
            validator: (String? value) {
              final String code = (value ?? '').trim().toUpperCase().replaceAll(' ', '');
              if (code.isEmpty) return 'Enter a course code';
              if (widget.courses.any((String course) => course.split(' - ').first.toUpperCase().replaceAll(' ', '') == code)) {
                return 'This course code already exists';
              }
              return null;
            }),
          TextFormField(controller: _name, maxLength: 80,
            decoration: const InputDecoration(labelText: 'Course name'),
            validator: (String? value) => (value ?? '').trim().isEmpty ? 'Enter a course name' : null),
        ])),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, '${_code.text.trim().toUpperCase()} - ${_name.text.trim()}');
        }, child: const Text('Save')),
      ],
    );
  }
}
