class AppError implements Exception {
  final String title;
  final String cause;
  final String fix;
  final String? technicalDetails;

  const AppError({
    required this.title,
    required this.cause,
    required this.fix,
    this.technicalDetails,
  });

  @override
  String toString() => '$title: $cause. Fix: $fix';
}
