/// Represents the status of a journey step.
enum StepStatus {
  completed,
  inProgress,
  pending;

  static StepStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'COMPLETED':
        return StepStatus.completed;
      case 'IN_PROGRESS':
        return StepStatus.inProgress;
      case 'PENDING':
        return StepStatus.pending;
      default:
        return StepStatus.pending;
    }
  }
}

/// A single step in the finance journey.
class JourneyStep {
  final String id;
  final String title;
  StepStatus stepStatus;
  bool isEvaluating;
  final Map<String, dynamic> context;

  JourneyStep({
    required this.id,
    required this.title,
    required this.stepStatus,
    this.isEvaluating = false,
    this.context = const {},
  });

  JourneyStep copyWith({
    String? id,
    String? title,
    StepStatus? stepStatus,
    bool? isEvaluating,
    Map<String, dynamic>? context,
  }) {
    return JourneyStep(
      id: id ?? this.id,
      title: title ?? this.title,
      stepStatus: stepStatus ?? this.stepStatus,
      isEvaluating: isEvaluating ?? this.isEvaluating,
      context: context ?? this.context,
    );
  }
}

/// Client-driven journey container holding the standard steps.
class Journey {
  final List<JourneyStep> steps;
  final bool complete;

  const Journey({
    required this.steps,
    required this.complete,
  });

  JourneyStep? get inProgressStep {
    try {
      return steps.firstWhere((s) => s.stepStatus == StepStatus.inProgress);
    } catch (_) {
      return null;
    }
  }
}
