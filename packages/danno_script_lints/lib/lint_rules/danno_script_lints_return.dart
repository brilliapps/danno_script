//import 'package:dart_eval/dart_eval.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation_dart.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' as errors;
import 'package:analyzer/error/listener.dart';

class DannoScriptLintsReturn extends DartLintRule {
  DannoScriptLintsReturn() : super(code: _code);

  static const _code = LintCode(
      name: 'anno_types_error',
      problemMessage: 'The ',
      errorSeverity: errors.ErrorSeverity.ERROR);

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    int standardNumberOfFields = 100;

    addLintMessage(
        AstNode node, errors.ErrorSeverity errorSeverity, String message) {
      reporter.atNode(
          node /*.parent!*/,
          LintCode(
              name: 'anno_types_warning',
              problemMessage: 'annotypes $message',
              errorSeverity: errorSeverity));
    }
  }

  @override
  List<Fix> getFixes() => [];
}
