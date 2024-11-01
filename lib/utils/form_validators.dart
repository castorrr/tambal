// File: utils/form_validators.dart

class FormValidators {
  // Validator for required fields
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Validator for stock (must be a positive integer)
  static String? positiveInteger(String? value) {
    if (value == null || value.isEmpty) {
      return 'Stock is required';
    }
    if (int.tryParse(value) == null || int.parse(value) <= 0) {
      return 'Stock must be a positive number';
    }
    return null;
  }
}
