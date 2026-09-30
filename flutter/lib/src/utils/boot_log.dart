import 'package:flutter/foundation.dart';

final Stopwatch _bootClock = Stopwatch()..start();

void bootLog(
  String scope,
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  if (!kDebugMode) return;

  final elapsed = _bootClock.elapsedMilliseconds.toString().padLeft(5);
  debugPrint('[FamilyShareBoot][$scope][+$elapsed ms] $message');
  if (error != null) {
    debugPrint('[FamilyShareBoot][$scope] error: $error');
  }
  if (stackTrace != null) {
    debugPrintStack(
      label: '[FamilyShareBoot][$scope] stack trace',
      stackTrace: stackTrace,
    );
  }
}
