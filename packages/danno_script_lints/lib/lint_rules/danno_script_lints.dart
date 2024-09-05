//import 'package:dart_eval/dart_eval.dart';
import 'dart:async';
import 'dart:isolate';
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

class DannoScriptLints extends DartLintRule {
  DannoScriptLints() : super(code: _code);

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

    Map<MethodInvocation, Map<AstNode, Map<errors.ErrorSeverity, List<String>>>>
        lintMessages = {};

    addLintMessage(MethodInvocation inv, AstNode node,
        errors.ErrorSeverity errorSeverity, String message) {
      reporter.atNode(
          node /*.parent!*/,
          LintCode(
              name: 'anno_types_warning',
              problemMessage: 'annotypes $message',
              errorSeverity: errorSeverity));
    }

    Expression? getInvokationParamByName(MethodInvocation inv, String name) {
      int arglength = inv.argumentList.arguments.length;
      for (int t = 0; t < arglength; t++) {
        Expression? currentInvokationArgument = inv.argumentList.arguments[t];
        if (currentInvokationArgument.staticParameterElement?.name == name) {
          return currentInvokationArgument;
        }
      }
      return null;
    }

    messagePrinter(MethodInvocation inv, [AstNode? node]) {}
    bool testForIf2Part(
        MethodInvocation inv,
        dynamic messageNode,
        DartObject currentFieldOf$IF,
        TypeSystem typeSystem,
        bool is$THEN,
        List<ParameterElement> prms) {
      bool hasAnySubIfConditionFailedAndNo$THENCanBeEnforced = false;
      String ifThenPrefix = is$THEN ? "is\$IF " : "is\$THEN ";
      DartObject currentFieldOf$IF2;
      Expression? currentSecondParam;
      DartType? defaultValueType;
      bool hasConditionSwitchedTo$NOT3 = false;
      bool hasAnySubIfConditionAppeared3 = false;
      bool theParamMatchesAtLeastOneTypeOrValueRequirements3 = false;
      // if stays false (no condition given) then it is like [theParamMatchesAtLeastOneTypeOrValueRequirements3] == true without setting up [theParamMatchesAtLeastOneTypeOrValueRequirements3] to true;
      bool
          thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition3 =
          false;
      bool
          theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition3 =
          false;

      for (int p = 1; p <= standardNumberOfFields; p++) {
        currentFieldOf$IF2 = currentFieldOf$IF.getField('t$p')!;

        if (currentFieldOf$IF2.isNull) {
          break;
        } else if (p == 1 && currentFieldOf$IF2.type.toString() != "String") {
          // TODO: Here and elsewhere you may check if the string is proper param name with allowed chars.
          addLintMessage(inv, messageNode, errors.ErrorSeverity.ERROR,
              'First param of $ifThenPrefix instance ${is$THEN ? '' : ' that is inside another \$IF instance'} must be another param name: ${currentFieldOf$IF2.type}');
          break;
        } else {
          if (p == 1) {
            final String currentSecondParamName =
                currentFieldOf$IF2.toStringValue() as String;
            currentSecondParam =
                getInvokationParamByName(inv, currentSecondParamName);
            if (currentSecondParam == null) {
              if (defaultValueType == null) {
                for (int k = 0; k < prms.length; k++) {
                  if (currentSecondParamName == prms[k].name) {
                    defaultValueType = prms[k].computeConstantValue()?.type;
                    break;
                  }
                }
              }
              if (defaultValueType == null) {
                addLintMessage(inv, messageNode, errors.ErrorSeverity.ERROR,
                    '$ifThenPrefix: Couldn\'t have found the second param both invokation but also declaration), param named: $currentSecondParamName');
                return true;
              }
            }
          }

          if (currentFieldOf$IF2.type.toString() == "Type") {
            if (currentFieldOf$IF2.toTypeValue()!.getDisplayString() ==
                '\$NOT') {
              hasConditionSwitchedTo$NOT3 = true;
            } else if (typeSystem.isSubtypeOf(
                currentSecondParam != null
                    ? currentSecondParam.staticType!
                    : defaultValueType!,
                currentFieldOf$IF2.toTypeValue()!)) {
              if (hasConditionSwitchedTo$NOT3) {
                theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition3 =
                    true;
              } else {
                theParamMatchesAtLeastOneTypeOrValueRequirements3 = true;
              }
            } else {
              if (!hasConditionSwitchedTo$NOT3) {
                thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition3 =
                    true;
              }
            }
          }
        }
      }

      if ((!theParamMatchesAtLeastOneTypeOrValueRequirements3 &&
              thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition3) ||
          theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition3) {
        hasAnySubIfConditionFailedAndNo$THENCanBeEnforced = true;
      }
      return hasAnySubIfConditionFailedAndNo$THENCanBeEnforced;
    }

    Map<int, Map<String, List<ParameterElement>>> pm = {};
    context.registry.addClassDeclaration((ClassDeclaration cd) {
      //classDeclaration.declaredElement?.allSupertypes;
      // FIXME: very ineficient way!! HAD NO CHOICE FOR NOW.
      var c = cd.members;
      int? id = cd.declaredElement?.id;
      for (int i = 0; i < c.length; i++) {
        Element? n = c[i].declaredElement;
        if (n is MethodElement && id != null) {
          String dn = n.displayName.replaceAllMapped(
              RegExp(r'^(?:.*?[\n\t\s\t]+)?([$_a-zA-Z]?[$_a-zA-Z\d]*)$',
                  multiLine: true),
              (m) => '${m.group(1)}');
          if (dn != '') {
            if (pm[id] == null) {
              pm[id] = {};
            }
            if (pm[id]![dn] == null) {
              pm[id]![dn] = [];
            }
            pm[id]![dn] = n.parameters;
          }
        }
      }
    });

    context.registry.addMethodInvocation((MethodInvocation inv) {
      var ttElement = inv.target?.staticType?.element;
      int? tt = ttElement?.id;
      if (tt == null || pm[tt] == null) {
        return;
      }
      var prms = pm[tt]?[inv.methodName.name];
      if (prms == null || prms.isEmpty) {
        return;
      }

      for (int k = 0; k < prms.length; k++) {
        final Expression? currentInvokationParam =
            getInvokationParamByName(inv, prms[k].name);
        dynamic messageNode = currentInvokationParam ?? inv.function;
        try {
          final ParameterElement currentDeclarationParam = prms[k];
          DartObject? defaultValue =
              currentDeclarationParam.computeConstantValue();
          DartType ultimateInvokationArgumentType =
              currentInvokationParam?.staticType ??
                  defaultValue?.type as DartType;

          final List<ElementAnnotation>? metad =
              currentDeclarationParam.metadata;

          if (metad != null &&
              metad.isNotEmpty &&
              metad.last.element?.displayName == "\$") {
            if (inv.argumentList.arguments.first.staticType == null) {
              // throw?
            }
            bool hasBeenExceptionForTheCurrentNode = false;
            if (inv.argumentList.arguments.first.staticParameterElement
                    ?.declaration.library ==
                null) {
              // throw?
            }

            DartObject? computedMetaObject =
                metad.last.computeConstantValue() as DartObject?;
            if (computedMetaObject == null) continue;
            bool hasConditionSwitchedTo$NOT = false;
            bool hasAnySubIfConditionAppeared = false;
            bool theParamMatchesAtLeastOneTypeOrValueRequirements = false;
            bool
                thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition =
                false;
            bool
                theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition =
                false;
            bool? is$ = computedMetaObject.getField('is\$')?.toBoolValue();
            if (is$ != null && is$) {
              TypeSystem typeSystem =
                  currentDeclarationParam.declaration.library!.typeSystem;
              DartObject? currentField;
              for (int i = 1; i <= standardNumberOfFields; i++) {
                currentField = computedMetaObject.getField('t$i');
                if (currentField!.isNull) {
                  break;
                } else if (currentField.type.toString() != "Type") {
                  bool is$IF =
                      currentField.getField('is\$IF')?.toBoolValue() == null
                          ? false
                          : true;

                  if (is$IF) {
                    hasAnySubIfConditionAppeared = true;
                  }
                  bool is$THEN =
                      currentField.getField('is\$THEN')?.toBoolValue() == null
                          ? false
                          : true;
                  if (hasAnySubIfConditionAppeared && !is$IF && !is$THEN) {
                    addLintMessage(inv, messageNode, errors.ErrorSeverity.ERROR,
                        'Error because !is\$IF&&!is\$THEN&&hasAnySubIfConditionAppeared');
                    break;
                  }

                  if (is$IF) {
                    int m = 1;
                    DartObject? currentFieldOf$IF;
                    bool hasConditionSwitchedTo$NOT2 = false;
                    bool hasAnySubIfConditionAppeared2 = false;
                    bool theParamMatchesAtLeastOneTypeOrValueRequirements2 =
                        false;
                    bool
                        thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition2 =
                        false;
                    bool
                        theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition2 =
                        false;
                    bool exitTheWhileLoop = false;
                    while (!exitTheWhileLoop && m <= standardNumberOfFields) {
                      bool hasAnyThenConditionAppeared2 = false;
                      bool hasAnySubIfConditionFailedAndNo$THENCanBeEnforced =
                          false;
                      for (m; m <= standardNumberOfFields; m++) {
                        currentFieldOf$IF = currentField.getField('t$m');
                        if (currentFieldOf$IF!.type == null ||
                            currentFieldOf$IF!.type is Null ||
                            currentFieldOf$IF.type.toString() == "Null") {
                          exitTheWhileLoop = true;
                          break;
                        } else {
                          if (currentFieldOf$IF!.type.toString() != "Type") {
                            bool is$IF2 = currentFieldOf$IF
                                        .getField('is\$IF')
                                        ?.toBoolValue() ==
                                    null
                                ? false
                                : true;

                            if (is$IF2) {
                              hasAnySubIfConditionAppeared2 = true;

                              if (theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition2 ||
                                  (!theParamMatchesAtLeastOneTypeOrValueRequirements2 &&
                                      thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition2)) {
                                exitTheWhileLoop = true;
                                break;
                              }
                            }
                            bool is$THEN2 = currentFieldOf$IF
                                        .getField('is\$THEN')
                                        ?.toBoolValue() ==
                                    null
                                ? false
                                : true;

                            if (is$THEN2) {
                              hasAnyThenConditionAppeared2 = true;
                            }

                            if (hasAnyThenConditionAppeared2 && is$IF2) {
                              break;
                            }

                            if (hasAnySubIfConditionAppeared2 &&
                                !is$IF2 &&
                                !is$THEN2) {
                              addLintMessage(
                                  inv,
                                  messageNode,
                                  errors.ErrorSeverity.ERROR,
                                  '123TYPE: error because hasAnySubIfConditionAppeared2 && !is\$IF2 && !is\$THEN2');
                              return;
                            }

                            if (is$IF2) {
                              if (hasAnySubIfConditionFailedAndNo$THENCanBeEnforced ==
                                  true) {
                                addLintMessage(
                                    inv,
                                    messageNode,
                                    errors.ErrorSeverity.WARNING,
                                    'ISIF2 BEFORE: first param name: ${currentInvokationParam?.staticParameterElement?.name}, should-be-String-name second param name (?) = ${currentFieldOf$IF.getField('t1')?.toStringValue()}, ${inv.target?.staticType?.element?.name}, ${inv.target?.staticType?.element?.id}');
                                continue;
                              }
                              hasAnySubIfConditionFailedAndNo$THENCanBeEnforced =
                                  testForIf2Part(
                                      inv,
                                      currentInvokationParam,
                                      currentFieldOf$IF,
                                      typeSystem,
                                      false,
                                      prms);
                              addLintMessage(
                                  inv,
                                  messageNode,
                                  errors.ErrorSeverity.WARNING,
                                  'ISIF2 AFTER: first param name: ${currentInvokationParam?.staticParameterElement?.name}, should-be-String-name second param name (?) = ${currentFieldOf$IF.getField('t1')?.toStringValue()}, ${inv.target?.staticType?.element?.name}, ${inv.target?.staticType?.element?.id}');
                            } else if (is$THEN2 &&
                                !hasAnySubIfConditionFailedAndNo$THENCanBeEnforced) {
                              if (testForIf2Part(inv, currentInvokationParam,
                                  currentFieldOf$IF, typeSystem, true, prms)) {
                                addLintMessage(
                                    inv,
                                    messageNode,
                                    errors.ErrorSeverity.ERROR,
                                    'The error of \$IF(\$IF/\$THEN) condition: There was at least one \$THEN clause that hasn\'t fulfill the requirements stipulated in it. first param name: ${currentInvokationParam?.staticParameterElement?.name}, should-be-String-name second param name (?) = ${currentFieldOf$IF.getField('t1')?.toStringValue()}, ${inv.target?.staticType?.element?.name}, ${inv.target?.staticType?.element?.id}');
                              }
                            }
                          } else {
                            DartType? dartType =
                                currentFieldOf$IF.toTypeValue();
                            if (dartType == null) {
                              addLintMessage(
                                  inv,
                                  messageNode,
                                  errors.ErrorSeverity.ERROR,
                                  '123TYPE: diagnostic message, error: assuming that the element MUST be not null but DartType"}');
                              exitTheWhileLoop = true;
                              break;
                            }
                            if (dartType!.getDisplayString() == '\$NOT') {
                              hasConditionSwitchedTo$NOT2 = true;
                            } else if (typeSystem.isSubtypeOf(
                                ultimateInvokationArgumentType, dartType)) {
                              if (hasConditionSwitchedTo$NOT2) {
                                theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition2 =
                                    true;
                              } else {
                                theParamMatchesAtLeastOneTypeOrValueRequirements2 =
                                    true;
                              }
                            } else {
                              if (!hasConditionSwitchedTo$NOT2) {
                                thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition2 =
                                    true;
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                } else {
                  if (currentField.toTypeValue()!.getDisplayString() ==
                      '\$NOT') {
                    hasConditionSwitchedTo$NOT = true;
                  } else if (typeSystem.isSubtypeOf(
                      ultimateInvokationArgumentType,
                      currentField.toTypeValue()!)) {
                    if (hasConditionSwitchedTo$NOT) {
                      theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition =
                          true;
                    } else {
                      theParamMatchesAtLeastOneTypeOrValueRequirements = true;
                    }
                  } else {
                    if (!hasConditionSwitchedTo$NOT) {
                      thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition =
                          true;
                    }
                  }
                }
              }
              if (theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition ||
                  (!theParamMatchesAtLeastOneTypeOrValueRequirements &&
                      thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition)) {
                addLintMessage(inv, messageNode, errors.ErrorSeverity.ERROR,
                    'Error: A method was called with a param value (including default value) that is not of required type nor value: param name: ${prms[k].name}');
              }
            }
            if (!hasBeenExceptionForTheCurrentNode)
              messagePrinter(inv, currentInvokationParam);
          }
        } catch (e, stackTrace) {
          addLintMessage(inv, messageNode, errors.ErrorSeverity.INFO,
              'Lint plugin exception: $e $stackTrace');
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [];
}
