import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:innobils_one/screen/savedemployee.dart';

import '../service/employeestorage.dart';
import 'employeedetail.dart';

/// Builds a form at runtime from assets/employee_form.json.
/// Nothing in this file refers to a specific field (no "country", "spouse"...),
/// all behaviour comes from the JSON config.
class DynamicFormScreen extends StatefulWidget {
  const DynamicFormScreen({super.key});

  @override
  State<DynamicFormScreen> createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen> {
  static const _textTypes = [
    'text',
    'email',
    'phone',
    'password',
    'number',
    'textarea',
  ];

  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> fields = [];
  String formTitle = 'Dynamic Form';
  String submitLabel = 'Submit Form';
  bool isLoading = true;
  String? loadError;

  final Map<String, dynamic> values = {};
  final Map<String, TextEditingController> controllers = {};

  /// Errors for non-text fields (text fields use TextFormField validators).
  final Map<String, String> errors = {};

  @override
  void initState() {
    super.initState();
    loadForm();
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Supports both "id" (assignment JSON) and "name" as the field key.
  String _id(Map<String, dynamic> f) => (f['id'] ?? f['name']) as String;

  dynamic _initialValue(Map<String, dynamic> f) {
    final type = f['type'];
    if (_textTypes.contains(type)) return '';
    if (type == 'checkbox') return <String>[];
    if (type == 'switch' || type == 'checkbox_single') return false;
    if (type == 'slider') return ((f['min'] ?? 0) as num).toDouble();
    return null; // dropdown, radio, date, time, file, image
  }

  Future<void> loadForm() async {
    try {
      final jsonString =
      await rootBundle.loadString('assets/employee_form.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final loaded = (data['fields'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        formTitle = data['title'] ?? 'Dynamic Form';
        submitLabel = data['submitButton'] ?? 'Submit Form';
        fields = loaded;

        for (final f in fields) {
          final id = _id(f);
          values[id] = _initialValue(f);
          if (_textTypes.contains(f['type'])) {
            controllers[id] = TextEditingController();
          }
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint('JSON loading error: $e');
      setState(() {
        isLoading = false;
        loadError = 'Could not load form configuration';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------

  /// Single entry point for value changes. Resets dependent fields
  /// (fields with "dependsOn": id) and clears the field's error.
  void _setValue(String id, dynamic value, {bool rebuild = true}) {
    values[id] = value;
    errors.remove(id);

    for (final f in fields) {
      if (f['dependsOn'] == id) {
        values[_id(f)] = null;
        errors.remove(_id(f));
      }
    }
    if (rebuild) setState(() {});
  }

  /// True when another field depends on / is conditionally shown by [id].
  bool _isWatched(String id) => fields.any(
        (f) => f['dependsOn'] == id || f['visibleIf']?['field'] == id,
  );

  bool _same(dynamic value, dynamic target) {
    if (value is List) {
      return value.map((e) => e.toString()).contains(target.toString());
    }
    return value?.toString() == target?.toString();
  }

  /// visibleIf supports: equals, notEquals, in.
  bool isVisible(Map<String, dynamic> field) {
    final cond = field['visibleIf'];
    if (cond == null) return true;

    final watchedId = cond['field'] as String;

    // A field that depends on a hidden field is hidden too.
    for (final f in fields) {
      if (_id(f) == watchedId && !isVisible(f)) return false;
    }

    final v = values[watchedId];
    if (cond['equals'] != null && !_same(v, cond['equals'])) return false;
    if (cond['notEquals'] != null && _same(v, cond['notEquals'])) {
      return false;
    }
    if (cond['in'] is List &&
        !(cond['in'] as List).any((t) => _same(v, t))) {
      return false;
    }
    return true;
  }

  List<String> _optionsFor(Map<String, dynamic> field) {
    final map = field['optionsMap'];
    if (map is Map && field['dependsOn'] != null) {
      final parent = values[field['dependsOn']];
      return List<String>.from(map[parent] ?? const []);
    }
    return List<String>.from(field['options'] ?? const []);
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? validateField(String? value, Map<String, dynamic> field) {
    final text = value?.trim() ?? '';
    final type = field['type'];
    final label = field['label'] ?? 'This field';

    if (field['required'] == true && text.isEmpty) {
      return '$label is required';
    }
    if (text.isEmpty) return null;

    final minLength = (field['minLength'] as num?)?.toInt();
    final maxLength = (field['maxLength'] as num?)?.toInt();

    if (minLength != null && text.length < minLength) {
      return '$label must be at least $minLength characters';
    }
    if (maxLength != null && text.length > maxLength && type != 'phone') {
      return '$label must be at most $maxLength characters';
    }

    if (type == 'email' &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email';
    }

    if (type == 'phone' && !RegExp(r'^[6-9]\d{9}$').hasMatch(text)) {
      return 'Enter a valid 10-digit mobile number';
    }

    if (type == 'number') {
      final number = num.tryParse(text);
      if (number == null) return 'Enter a valid number';
      final min = field['min'] as num?;
      final max = field['max'] as num?;
      if (min != null && number < min) return 'Minimum value is $min';
      if (max != null && number > max) return 'Maximum value is $max';
    }

    // Optional custom regex support: "pattern" + "patternMessage".
    final pattern = field['pattern'] as String?;
    if (pattern != null && !RegExp(pattern).hasMatch(text)) {
      return field['patternMessage'] ?? '$label is not in the expected format';
    }

    return null;
  }

  /// Required-checks for non-text fields. Shows errors under each field.
  bool validateRequiredFields() {
    errors.clear();

    for (final field in fields) {
      if (!isVisible(field) || field['required'] != true) continue;

      final id = _id(field);
      final type = field['type'] as String;
      final label = field['label'];
      final v = values[id];

      if (_textTypes.contains(type)) continue; // handled by validators
      if (type == 'switch' || type == 'slider') continue;

      if (type == 'checkbox_single') {
        if (v != true) errors[id] = 'You must accept to continue';
      } else if (type == 'checkbox') {
        if (v == null || (v as List).isEmpty) {
          errors[id] = 'Select at least one option for $label';
        }
      } else if (v == null || v.toString().trim().isEmpty) {
        errors[id] = 'Please complete $label';
      }
    }

    setState(() {});
    return errors.isEmpty;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------------------------------------------------------------------
  // Field widgets
  // ---------------------------------------------------------------------------

  Widget _withError(String id, Widget child) {
    final error = errors[id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _labelOf(Map<String, dynamic> f) =>
      f['required'] == true ? '${f['label']} *' : '${f['label']}';

  Widget buildField(Map<String, dynamic> field) {
    if (!isVisible(field)) return const SizedBox.shrink();

    final id = _id(field);
    final type = field['type'] as String;
    final label = _labelOf(field);

    switch (type) {
      case 'text':
      case 'email':
      case 'phone':
      case 'password':
      case 'number':
      case 'textarea':
        final maxLength = (field['maxLength'] as num?)?.toInt();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: controllers[id],
            obscureText: type == 'password',
            keyboardType: type == 'email'
                ? TextInputType.emailAddress
                : type == 'phone'
                ? TextInputType.phone
                : type == 'number'
                ? TextInputType.number
                : type == 'textarea'
                ? TextInputType.multiline
                : TextInputType.text,
            inputFormatters: type == 'phone'
                ? [FilteringTextInputFormatter.digitsOnly]
                : type == 'number'
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                : null,
            maxLines: type == 'textarea' ? 4 : 1,
            maxLength: maxLength,
            validator: (value) => validateField(value, field),
            onChanged: (value) => _setValue(
              id,
              type == 'number' && value.isNotEmpty
                  ? num.tryParse(value)
                  : value,
              rebuild: _isWatched(id),
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: field['placeholder'],
              border: const OutlineInputBorder(),
              counterText: type == 'textarea' ? null : '',
            ),
          ),
        );

      case 'radio':
        final options = _optionsFor(field);
        return _withError(
          id,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              ...options.map(
                    (option) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  value: option,
                  groupValue: values[id] as String?,
                  onChanged: (v) => _setValue(id, v),
                ),
              ),
            ],
          ),
        );

      case 'dropdown':
        final options = _optionsFor(field);
        final parentId = field['dependsOn'] as String?;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            // Rebuild when the parent value changes so options refresh.
            key: ValueKey('$id-${parentId == null ? '' : values[parentId]}'),
            value: options.contains(values[id]) ? values[id] as String? : null,
            decoration: InputDecoration(
              labelText: label,
              hintText: options.isEmpty && parentId != null
                  ? 'Select a value above first'
                  : null,
              border: const OutlineInputBorder(),
            ),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            validator: (value) {
              if (field['required'] == true && value == null) {
                return 'Please select ${field['label']}';
              }
              return null;
            },
            onChanged: options.isEmpty ? null : (v) => _setValue(id, v),
          ),
        );

      case 'checkbox':
        final options = _optionsFor(field);
        final selected = List<String>.from(values[id] ?? const []);
        return _withError(
          id,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              ...options.map(
                    (option) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(option),
                  value: selected.contains(option),
                  onChanged: (checked) {
                    final next = List<String>.from(selected);
                    checked == true ? next.add(option) : next.remove(option);
                    _setValue(id, next);
                  },
                ),
              ),
            ],
          ),
        );

      case 'slider':
        final min = ((field['min'] ?? 0) as num).toDouble();
        final max = ((field['max'] ?? 10) as num).toDouble();
        final divisions = (field['divisions'] as num?)?.toInt();
        final current =
        ((values[id] as num?)?.toDouble() ?? min).clamp(min, max);
        return _withError(
          id,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label: ${current.round()}'),
              Slider(
                min: min,
                max: max,
                divisions: divisions,
                value: current,
                label: current.round().toString(),
                onChanged: (v) => _setValue(id, v),
              ),
            ],
          ),
        );

      case 'switch':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: values[id] == true,
          onChanged: (v) => _setValue(id, v),
        );

      case 'checkbox_single':
        return _withError(
          id,
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(label),
            value: values[id] == true,
            onChanged: (v) => _setValue(id, v ?? false),
          ),
        );

      case 'date':
        return _withError(
          id,
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(values[id]?.toString() ?? 'Select date'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                _setValue(
                  id,
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                );
              }
            },
          ),
        );

      case 'time':
        return _withError(
          id,
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(values[id]?.toString() ?? 'Select time'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                _setValue(
                  id,
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                );
              }
            },
          ),
        );

      case 'file':
        return _withError(
          id,
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(values[id]?.toString() ?? 'Choose file'),
            trailing: const Icon(Icons.attach_file),
            onTap: () async {
              final extensions =
              List<String>.from(field['allowedExtensions'] ?? const []);
              final result = await FilePicker.platform.pickFiles(
                type: extensions.isEmpty ? FileType.any : FileType.custom,
                allowedExtensions: extensions.isEmpty ? null : extensions,
              );
              if (result != null && result.files.isNotEmpty) {
                _setValue(id, result.files.single.name);
              }
            },
          ),
        );

      case 'image':
        return _withError(
          id,
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(values[id]?.toString() ?? 'Choose image'),
            trailing: const Icon(Icons.image),
            onTap: () async {
              final image =
              await ImagePicker().pickImage(source: ImageSource.gallery);
              if (image != null) _setValue(id, image.name);
            },
          ),
        );

      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          // child: Text('Unsupported field type: $type',
          child: Text('Dropdown',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Reset & submit
  // ---------------------------------------------------------------------------

  void resetForm() {
    _formKey.currentState?.reset();
    for (final c in controllers.values) {
      c.clear();
    }
    setState(() {
      errors.clear();
      for (final f in fields) {
        values[_id(f)] = _initialValue(f);
      }
    });
  }

  Future<void> submitForm() async {
    FocusScope.of(context).unfocus();

    // Run both so every error is shown at once.
    final textOk = _formKey.currentState!.validate();
    final othersOk = validateRequiredFields();
    if (!textOk || !othersOk) {
      showMessage('Please fix the highlighted fields');
      return;
    }

    // Collect only visible fields.
    final result = <String, dynamic>{};
    for (final field in fields) {
      if (!isVisible(field)) continue;
      // Passwords are never persisted or displayed.
      if (field['type'] == 'password') continue;
      result[_id(field)] = values[_id(field)];
    }

    try {
      await EmployeeStorageService.saveEmployee(result);
    } catch (e) {
      debugPrint('Save error: $e');
      if (!mounted) return;
      showMessage('Unable to save employee data');
      return;
    }

    if (!mounted) return;

    final shouldReset = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDetailsScreen(employeeData: result),
      ),
    );

    if (!mounted) return;
    if (shouldReset == true) {
      resetForm();
      showMessage('Form reset successfully');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(formTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Saved Employees',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SavedEmployeesScreen(),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : fields.isEmpty
          ? Center(child: Text(loadError ?? 'No fields in configuration'))
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...fields.map(buildField),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: submitForm,
              child: Text(submitLabel),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
