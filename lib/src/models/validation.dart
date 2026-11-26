class Validation {
  final String id;
  final String name;
  final String? failureMessage;
  final bool passed;

  const Validation({
    required this.id,
    required this.name,
    this.failureMessage,
    required this.passed,
  });

  factory Validation.fromJson(Map<String, dynamic> json) {
    return Validation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      failureMessage: json['failureMessage'] as String?,
      passed: json['passed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'failureMessage': failureMessage,
      'passed': passed,
    };
  }
}

class ValidationResponse {
  final List<Validation> validations;

  const ValidationResponse({
    required this.validations,
  });

  factory ValidationResponse.fromJsonList(List<dynamic> list) {
    return ValidationResponse(
      validations: list
          .map((v) => Validation.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isSuccess =>
      validations.isNotEmpty && validations.every((v) => v.passed);

  List<Validation> get failedValidations =>
      validations.where((v) => !v.passed).toList();

  List<Validation> get passedValidations =>
      validations.where((v) => v.passed).toList();
}
