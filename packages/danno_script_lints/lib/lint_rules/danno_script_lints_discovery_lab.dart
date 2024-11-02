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
import 'package:dart_eval/dart_eval_bridge.dart';

/// used by getUltimateNonConditionalNorSwitchExpressions(): when a value is returned,
/// f.e. a Map, depending on this enum value the List may be interpreted
/// as a Map literal (Expression) when UltimateValueType? == Map
/// or as a Map<ComparableUltimateValue, Object> of two optional values representing the same object instance (DartObject and Expression instance) when UltimateValueType.constructorInvokation
/// value origianlly was to be used for comparison with other value of of one of these two types
//enum UltimateValueType {
//  constructorInvokation, map, set,
//}

enum ComparableUltimateValue { dartObject, expression, simple }

class DannoScriptLintsDiscoveryLab extends DartLintRule {
  DannoScriptLintsDiscoveryLab() : super(code: _code);

  // if there were info or warning level messages they didn't display when there were also error level messages. This makes relevant messages error
  final bool msgDebugMode = true;

  static const _code = LintCode(
      name: 'anno_types_error',
      problemMessage: 'The ',
      errorSeverity: errors.ErrorSeverity.ERROR);

  /// this calls [getUltimateNonConditionalNorSwitchExpressions] in a way that the returned value by
  /// this getUltimateConstLikeExpressions method is null when a conditional expression exp?true : false was found
  /// or similar more o less advanced expressions that cannot produce one 100%-statically-known expression
  /// Warning! while expression like constructor invokation will be returned it will be checked if it has const constructor,
  /// the same is planned for list, set and map literals
  ({
    List<Expression> expressions,
    Expando<Identifier>? topLevelIdentifiersProducingExpressions,
    bool wasThereAnyEmptyReturnStatement,
    bool wasThereAnyEmptyFunctionBody,
  })? getUltimateConstLikeExpressions(
    ErrorReporter reporter,
    Map<dynamic, List<ReturnStatement>> returnStatements,
    Map<int, List<VariableDeclaration>> variableDeclarationsByElementId,
    Map<int, List<AssignmentExpression>> assignmentExpressionsByElementId,
    Expression expression,
    Expando<Identifier>? topLevelIdentifiersProducingExpressionsSupplied,
  ) {
    try {
      return getUltimateNonConditionalNorSwitchExpressions(
          reporter,
          returnStatements,
          variableDeclarationsByElementId,
          assignmentExpressionsByElementId,
          expression,
          topLevelIdentifiersProducingExpressionsSupplied,
          true);
    } catch (e) {
      return null;
    }
  }

  /// if throwOnConditionalLikeOrFunction == true (used only by [getUltimateConstLikeExpressions] which catches and returns null)
  /// then we want to get only results that has knows value - 2.8, 'abc', SomeConstructor(...) but not a functin/method call.
  /// but for default false we can get f.e. possible known/comparable return values that can be returned during runtime time not static code analysis time.
  /// null is returned if failOnConditional == true and and a conditional, binary,
  /// or function/method-like expression invokation was found which can't guarantee the const-like result (TODO: in future some difficult to implement exceptions could be added if time allows for the little-benefit implementation)
  /// Warning null means that the expression or in a tree of subexpressions there was a "return;" statement with void return;
  /// An expression can be condition?10:false - the possible ultimate expressions are 10: false and their types are 10 and int
  /// but condition?10:(condition2?false:'abc') is nested and possible values and types are 10/int, false/bool, 'abc'/String
  /// This method is not for getting the final types and computed const values (if they are computable).
  ({
    List<Expression> expressions,
    Expando<Identifier>? topLevelIdentifiersProducingExpressions,
    bool wasThereAnyEmptyReturnStatement,
    bool wasThereAnyEmptyFunctionBody,
  }) getUltimateNonConditionalNorSwitchExpressions(
      ErrorReporter reporter,
      Map<dynamic, List<ReturnStatement>> returnStatements,
      Map<int, List<VariableDeclaration>> variableDeclarationsByElementId,
      Map<int, List<AssignmentExpression>> assignmentExpressionsByElementId,
      Expression expression,
      [Expando<Identifier>? topLevelIdentifiersProducingExpressionsSupplied,
      // below param to be used only by getUltimateConstLikeExpressions
      bool throwOnConditionalLikeOrFunctionOrPossibleIdentifierMultipleAssignmentExpressions =
          false]) {
    Expando<Identifier> topLevelIdentifiersProducingExpressions =
        topLevelIdentifiersProducingExpressionsSupplied ??
            Expando<Identifier>();
    try {
      ParenthesizedExpression; // .expression;
      ConditionalExpression; // probably including version "??"" and with .thenExpression, .elseExpression
      SwitchExpression; // .cases which are NodeList<SwitchExpressionCase> .expression for a case;
      List<Expression> expressions = [];
      List<Expression> iterationExpressions = [expression.unParenthesized];
      bool wasThereAnyEmptyReturnStatement = false;
      bool wasThereAnyEmptyFunctionBody = false;
      while (true) {
        List<Expression> nextIterationExpressions = [];
        if (iterationExpressions.isEmpty) {
          break;
        }
        for (int i = 0; i < iterationExpressions.length; i++) {
          //if (iterationExpressions[i] is ParenthesizedExpression) {
          //  var subExpression = iterationExpressions[i];
          //  while (true) {
          //    subExpression =
          //        (subExpression as ParenthesizedExpression).expression;
          //    if (subExpression is! ParenthesizedExpression) {
          //      nextIterationExpressions.add(subExpression);
          //      break;
          //    }
          //  }
          //}

          if (iterationExpressions[i] is Identifier) {
            //topLevelIdentifiersProducingExpressions[assignmentExpression.unParenthesized]=iterationExpressions[i] as Identifier;
            Identifier? theTopLevelAncestorIdentifier =
                topLevelIdentifiersProducingExpressions[
                    iterationExpressions[i]];

            if (throwOnConditionalLikeOrFunctionOrPossibleIdentifierMultipleAssignmentExpressions) {
              // to remind you if more than one possible assigned values could be found for an identifier during it's lifetime
              // vlaue.valueHasBeenFound == false
              var value = getComparableValueFromExpressionOrDartObject(
                  reporter,
                  returnStatements,
                  assignmentExpressionsByElementId,
                  variableDeclarationsByElementId,
                  iterationExpressions[i]);
              if (!value.valueHasBeenFound ||
                  value.value == null ||
                  value.value!.isEmpty ||
                  value.value![ComparableUltimateValue.expression] == null) {
                throw Exception(
                    'getUltimateNonConditionalNorSwitchExpressions(), there is no need for this exception to be handled becuse it was originally to be used only by getUltimateConstLikeExpressions() method');
              } else {
                topLevelIdentifiersProducingExpressions[
                    value.value![ComparableUltimateValue.expression]
                        as Expression] = theTopLevelAncestorIdentifier ??
                    iterationExpressions[i] as Identifier;
                nextIterationExpressions.add(value
                    .value![ComparableUltimateValue.expression] as Expression);
              }
            } else {
              //var identifier = iterationExpressions[i] as Identifier;
              //identifier.
              //
              //nextIterationExpressions.add(
              //    (iterationExpressions[i] as ConditionalExpression)
              //        .thenExpression);
              //nextIterationExpressions.add(
              //    (iterationExpressions[i] as ConditionalExpression)
              //        .elseExpression);
              final Identifier expression =
                  iterationExpressions[i] as Identifier;
              DartObject? dartObject;
              String msg = '';
              dynamic element;
              if (expression.staticElement is VariableElement) {
                (expression.staticElement as VariableElement).declaration;
                var elem = (expression.staticElement as VariableElement);
                element = elem;
                msg +=
                    'getUltimateNonConditionalNorSwitchExpressions() VariableElement elema.id = ${elem.id}, elema.nonSynthetic.id = ${elem.nonSynthetic.id}';

                dartObject = (expression.staticElement as VariableElement)
                    .computeConstantValue();
              }

              if (expression.staticElement is PropertyAccessorElement) {
                var elem =
                    (expression.staticElement as PropertyAccessorElement);
                element = elem;
                var variable2 = elem.variable2;
                dartObject = variable2?.computeConstantValue();
                var variable2_variety = elem.variable2?.getter?.variable2;
                var dartObject_variety = variable2?.computeConstantValue();

                msg +=
                    'getUltimateNonConditionalNorSwitchExpressions() PropertyAccessorElement elema.id = ${elem.id}, elema.nonSynthetic.id = ${elem.nonSynthetic.id}';

                msg +=
                    'getUltimateNonConditionalNorSwitchExpressions() PropertyAccessorElement variable2=${variable2} getter = ${variable2?.getter}, variable2?.getter?.hasImplicitReturnType = ${variable2?.getter?.hasImplicitReturnType}, dartObject?.type = ${dartObject?.type} dartObject?.type?.isDartCoreInt = ${dartObject?.type?.isDartCoreInt} ${dartObject} ';
                msg +=
                    'getUltimateNonConditionalNorSwitchExpressions() PropertyAccessorElement variable2_variety=${variable2_variety} getter = ${variable2_variety?.getter}, variable2_variety?.getter?.hasImplicitReturnType = ${variable2_variety?.getter?.hasImplicitReturnType}, dartObject_variety?.type = ${dartObject_variety?.type} dartObject_variety?.type?.isDartCoreInt = ${dartObject_variety?.type?.isDartCoreInt} ${dartObject_variety} ';
                //if (elem.variable2.getter.hasImplicitReturnType) {
                //  //elem.variable2.
                //}
              }

              //variableDeclarationsByElementId[variableDeclaration.declaredElement!.id];

              //variableDeclarationsByElementId[
              //    variableDeclaration.declaredElement!.id];

              List<VariableDeclaration> variableDeclarations = [];
              if (element != null &&
                  variableDeclarationsByElementId[element.nonSynthetic.id] !=
                      null &&
                  variableDeclarationsByElementId[element.nonSynthetic.id]!
                      .isNotEmpty) {
                variableDeclarations =
                    variableDeclarationsByElementId[element.nonSynthetic.id]!;

                msg +=
                    'getUltimateNonConditionalNorSwitchExpressions() we\'ve found a declaraition for this variable, because if is allowed that this variable not to have have to be const, so we don\'t know which declaration/assigment with its expression was used for this variable and we must check all a declaration + assignments of this variable - each d/assigment\'s possible type(s) or/and values(s) allowed. variableDeclarations = ${variableDeclarations}';
              } else {
                msg +=
                    'getUltimateNonConditionalNorSwitchExpressions() we haven\'t found a declaraition for this variable, variableDeclarations = ${variableDeclarations}';
              }

              variableDeclarations
                  .forEach((VariableDeclaration variableDeclaration) {
                if (variableDeclaration.initializer == null) {
                  return;
                }
                // if a function/method was called with a not initialized variable dart has own error for that
                if (variableDeclaration.initializer != null)
                  nextIterationExpressions
                      .add(variableDeclaration.initializer!.unParenthesized);
                topLevelIdentifiersProducingExpressions[
                        variableDeclaration.initializer!.unParenthesized] =
                    theTopLevelAncestorIdentifier ??
                        iterationExpressions[i] as Identifier;
              });

              List<AssignmentExpression> assignmentExpressions = [];
              if (element != null &&
                  assignmentExpressionsByElementId[element.nonSynthetic.id] !=
                      null &&
                  assignmentExpressionsByElementId[element.nonSynthetic.id]!
                      .isNotEmpty) {
                assignmentExpressions =
                    assignmentExpressionsByElementId[element.nonSynthetic.id]!;
                msg +=
                    'getUltimateNonConditionalNorSwitchExpressions() we\'ve found all assignments (apart from a declaration) for this variable, because if is allowed that this variable not to have have to be const, so we don\'t know which assigment with its expression was used for this variable and we must check all assignments of this variable - each assigment\'s possible type(s) or/and values(s) allowed. assignmentExpressions = ${assignmentExpressions}';
              } else {
                msg +=
                    'getUltimateNonConditionalNorSwitchExpressions() we haven\'t found any assignments (added to a possible declaration if found) with optional assignments for this variable, assignmentExpressions = ${assignmentExpressions}';
              }

              assignmentExpressions
                  .forEach((AssignmentExpression assignmentExpression) {
                nextIterationExpressions
                    .add(assignmentExpression.unParenthesized);
                topLevelIdentifiersProducingExpressions[
                        assignmentExpression.unParenthesized] =
                    theTopLevelAncestorIdentifier ??
                        iterationExpressions[i] as Identifier;
              });

              addLintMessage(reporter, expression, errors.ErrorSeverity.INFO,
                  'getUltimateNonConditionalNorSwitchExpressions() msg = $msg, it is Identifier(). dartObject.type?.isDartCoreInt = ${dartObject?.type?.isDartCoreInt}, dartObject = ${dartObject}, ${expression.staticElement is VariableElement}, ${expression.runtimeType}, ${expression.staticElement?.runtimeType}, ${expression.staticElement}');
            }
          } else if (iterationExpressions[i] is ConditionalExpression) {
            if (throwOnConditionalLikeOrFunctionOrPossibleIdentifierMultipleAssignmentExpressions) {
              throw Exception(
                  'getUltimateNonConditionalNorSwitchExpressions(), there is no need for this exception to be handled becuse it was originally to be used only by getUltimateConstLikeExpressions() method');
            }
            //topLevelIdentifiersProducingExpressions[assignmentExpression.unParenthesized]=iterationExpressions[i] as Identifier;
            Identifier? theTopLevelAncestorIdentifier =
                topLevelIdentifiersProducingExpressions[
                    iterationExpressions[i]];
            if (theTopLevelAncestorIdentifier != null) {
              topLevelIdentifiersProducingExpressions[
                  (iterationExpressions[i] as ConditionalExpression)
                      .thenExpression
                      .unParenthesized] = theTopLevelAncestorIdentifier;
              topLevelIdentifiersProducingExpressions[
                  (iterationExpressions[i] as ConditionalExpression)
                      .elseExpression
                      .unParenthesized] = theTopLevelAncestorIdentifier;
            }

            nextIterationExpressions.add(
                (iterationExpressions[i] as ConditionalExpression)
                    .thenExpression
                    .unParenthesized);
            nextIterationExpressions.add(
                (iterationExpressions[i] as ConditionalExpression)
                    .elseExpression
                    .unParenthesized);
          } else if (iterationExpressions[i] is SwitchExpression) {
            //topLevelIdentifiersProducingExpressions[assignmentExpression.unParenthesized]=iterationExpressions[i] as Identifier;
            Identifier? theTopLevelAncestorIdentifier =
                topLevelIdentifiersProducingExpressions[
                    iterationExpressions[i]];
            if (throwOnConditionalLikeOrFunctionOrPossibleIdentifierMultipleAssignmentExpressions) {
              throw Exception(
                  'getUltimateNonConditionalNorSwitchExpressions(), there is no need for this exception to be handled becuse it was originally to be used only by getUltimateConstLikeExpressions() method');
            }
            var cases = (iterationExpressions[i] as SwitchExpression).cases;
            for (int k = 0; k < cases.length; k++) {
              if (theTopLevelAncestorIdentifier != null) {
                topLevelIdentifiersProducingExpressions[cases[k]
                    .expression
                    .unParenthesized] = theTopLevelAncestorIdentifier;
              }
              nextIterationExpressions.add(cases[k].expression.unParenthesized);
            }
          } else if (iterationExpressions[i] is InvocationExpression) {
            //topLevelIdentifiersProducingExpressions[assignmentExpression.unParenthesized]=iterationExpressions[i] as Identifier;
            Identifier? theTopLevelAncestorIdentifier =
                topLevelIdentifiersProducingExpressions[
                    iterationExpressions[i]];
            // it CAN'T (CAN'T) BE InstanceCreationExpression

            if (throwOnConditionalLikeOrFunctionOrPossibleIdentifierMultipleAssignmentExpressions) {
              throw Exception(
                  'getUltimateNonConditionalNorSwitchExpressions(), there is no need for this exception to be handled becuse it was originally to be used only by getUltimateConstLikeExpressions() method');
            }

            addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 1');
            if (iterationExpressions[i] is MethodInvocation) {
              addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                  'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 2');
              var methodInv = iterationExpressions[i] as MethodInvocation;
              if (methodInv.function is! MethodDeclaration) {
                addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                    'getUltimateNonConditionalNorSwitchExpressions() methodInv intuitively shouldn\'t be error here: error methodInv.function is! MethodDeclaration ${methodInv.function.runtimeType} ${methodInv.function.toString()} ${methodInv.function.toSource()}');
                continue;
              }
              var methodDeclaration = (methodInv.function as MethodDeclaration);
              int? id = (methodInv.function as MethodDeclaration)
                  .declaredElement
                  ?.declaration
                  .id;
              var returnStatementList = returnStatements[id];
              if (returnStatementList == null) {
                addLintMessage(
                    reporter,
                    expression,
                    errors.ErrorSeverity.WARNING,
                    'getUltimateNonConditionalNorSwitchExpressions() methodInv we are iteration through return expressions, in the return we don\'t have any ReturnStatement instances for this method. it is warning, but is it an error problem?');
              } else {
                addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                    'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 3');
                //[BlockFunctionBody] | [EmptyFunctionBody] | [ExpressionFunctionBody] | [NativeFunctionBody]
                if (methodDeclaration.body is ExpressionFunctionBody) {
                  addLintMessage(
                      reporter,
                      expression,
                      errors.ErrorSeverity.ERROR,
                      'getUltimateNonConditionalNorSwitchExpressions() methodInv returned value is ExpressionFunctionBody not a BlockFunctionBody with ReturnStatements, how much final expressions does the returned value?: ${getUltimateNonConditionalNorSwitchExpressions(reporter, returnStatements, variableDeclarationsByElementId, assignmentExpressionsByElementId, (methodDeclaration.body as ExpressionFunctionBody).expression)}');
                }
                for (int k = 0; k < returnStatementList.length; k++) {
                  if (returnStatementList[k].expression == null) {
                    addLintMessage(
                        reporter,
                        expression,
                        errors.ErrorSeverity.ERROR,
                        'getUltimateNonConditionalNorSwitchExpressions() methodInv we are iteration through return expressions, in the return logically should never be a void return call like return () {}(); rather (){}();return;, there must be an expression; such a situation should never happen but for now null is accepted, that at least one return was so.');
                  }
                  if (returnStatementList[k].expression != null) {
                    if (theTopLevelAncestorIdentifier != null) {
                      topLevelIdentifiersProducingExpressions[
                          returnStatementList[k]
                              .expression!
                              .unParenthesized] = theTopLevelAncestorIdentifier;
                    }
                    nextIterationExpressions.add(
                        returnStatementList[k].expression!.unParenthesized);
                  } else {
                    wasThereAnyEmptyReturnStatement = true;
                  }
                }
              }
            } else if (iterationExpressions[i]
                is FunctionExpressionInvocation) {
              //topLevelIdentifiersProducingExpressions[assignmentExpression.unParenthesized]=iterationExpressions[i] as Identifier;
              Identifier? theTopLevelAncestorIdentifier =
                  topLevelIdentifiersProducingExpressions[
                      iterationExpressions[i]];
              addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                  'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 5');

              var functionInv =
                  iterationExpressions[i] as FunctionExpressionInvocation;
              if (functionInv.function is! FunctionExpression) {
                addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                    'getUltimateNonConditionalNorSwitchExpressions() functionInv; intuitively shouldn\'t be error here: error methodInv.function is! FunctionDeclaration ${functionInv.function.runtimeType} ${(functionInv.function as FunctionExpression).declaredElement?.id} ${functionInv.function.toString()} ${functionInv.function.toSource()}  ${functionInv.staticElement?.declaration.source.contents.data}');
                continue;
              }
              addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                  'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 6');

              FunctionBody body =
                  (functionInv.function as FunctionExpression).body;
              addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                  'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 6.1');
              if (body is BlockFunctionBody) {
                addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                    'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 6.2');
                body.block.statements.forEach((Statement statement) {
                  addLintMessage(
                      reporter,
                      expression,
                      errors.ErrorSeverity.ERROR,
                      'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 6.3');
                  if (statement is ReturnStatement) {
                    addLintMessage(
                        reporter,
                        expression,
                        errors.ErrorSeverity.ERROR,
                        'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 6.4');
                    if (statement.expression != null) {
                      if (theTopLevelAncestorIdentifier != null) {
                        topLevelIdentifiersProducingExpressions[statement
                            .expression!
                            .unParenthesized] = theTopLevelAncestorIdentifier;
                      }
                      nextIterationExpressions
                          .add(statement.expression!.unParenthesized);
                    } else {
                      wasThereAnyEmptyReturnStatement = true;
                    }
                  }
                });
              } else if (body is ExpressionFunctionBody) {
                if (theTopLevelAncestorIdentifier != null) {
                  topLevelIdentifiersProducingExpressions[body.expression
                      .unParenthesized] = theTopLevelAncestorIdentifier;
                }
                nextIterationExpressions.add(body.expression.unParenthesized);
              } else if (body is EmptyFunctionBody) {
                wasThereAnyEmptyFunctionBody = true;
              }

              //int? id = functionInv.staticElement?.declaration.id;
              int? id = (functionInv.function as FunctionExpression)
                  .declaredElement
                  ?.id;
              addLintMessage(reporter, expression, errors.ErrorSeverity.ERROR,
                  'getUltimateNonConditionalNorSwitchExpressions() iterationExpressions[i] is InvocationExpression == true : 7, id = $id, returnStatements[id] = ${returnStatements[id]}');
              var returnStatementList = returnStatements[id];
              if (returnStatementList == null) {
                addLintMessage(
                    reporter,
                    expression,
                    errors.ErrorSeverity.WARNING,
                    'getUltimateNonConditionalNorSwitchExpressions() functionInv; id is ${(functionInv.function as FunctionExpression).declaredElement?.id}, we are iteration through return expressions, in the return we don\'t have any ReturnStatement instances for this method. it is warning, but is it an error problem?');
              } else {
                for (int k = 0; k < returnStatementList.length; k++) {
                  if (returnStatementList[k].expression == null) {
                    addLintMessage(
                        reporter,
                        expression,
                        errors.ErrorSeverity.ERROR,
                        'getUltimateNonConditionalNorSwitchExpressions() functionInv; we are iteration through return expressions, in the return logically should never be a void return call like return () {}(); rather (){}();return;, there must be an expression; such a situation should never happen but for now null is accepted, that at least one return was so.');
                  }
                  if (returnStatementList[k].expression != null) {
                    if (theTopLevelAncestorIdentifier != null) {
                      topLevelIdentifiersProducingExpressions[
                          returnStatementList[k]
                              .expression!
                              .unParenthesized] = theTopLevelAncestorIdentifier;
                    }
                    nextIterationExpressions.add(
                        returnStatementList[k].expression!.unParenthesized);
                  } else {
                    wasThereAnyEmptyReturnStatement = true;
                  }
                }
              }
            }
          } else if (iterationExpressions[i] is BinaryExpression) {
            //topLevelIdentifiersProducingExpressions[assignmentExpression.unParenthesized]=iterationExpressions[i] as Identifier;
            Identifier? theTopLevelAncestorIdentifier =
                topLevelIdentifiersProducingExpressions[
                    iterationExpressions[i]];
            if (throwOnConditionalLikeOrFunctionOrPossibleIdentifierMultipleAssignmentExpressions) {
              throw Exception(
                  'getUltimateNonConditionalNorSwitchExpressions(), there is no need for this exception to be handled becuse it was originally to be used only by getUltimateConstLikeExpressions() method');
            }
            // WARNING! Make sure else is after this "is BinaryExpression" condition
            var subExpression = iterationExpressions[i] as BinaryExpression;
            if (subExpression.operator.toString() == '??') {
              if (theTopLevelAncestorIdentifier != null) {
                topLevelIdentifiersProducingExpressions[subExpression
                    .leftOperand
                    .unParenthesized] = theTopLevelAncestorIdentifier;
              }
              if (theTopLevelAncestorIdentifier != null) {
                topLevelIdentifiersProducingExpressions[subExpression
                    .rightOperand
                    .unParenthesized] = theTopLevelAncestorIdentifier;
              }
              nextIterationExpressions
                  .add(subExpression.leftOperand.unParenthesized);
              nextIterationExpressions
                  .add(subExpression.rightOperand.unParenthesized);
            } else {
              expressions.add(iterationExpressions[i].unParenthesized);
            }
            addLintMessage(reporter, expression, errors.ErrorSeverity.WARNING,
                'Binary expression what we have = ${subExpression.leftOperand.toSource()} # ${subExpression.leftOperand is Identifier}, ${subExpression.leftOperand is IntegerLiteral}, ${subExpression.rightOperand is Identifier} ${subExpression.rightOperand is IntegerLiteral}, ${subExpression.leftOperand.staticType}, ${subExpression.rightOperand.staticType} ${subExpression.rightOperand.staticType} ${subExpression.leftOperand.runtimeType} ${subExpression.operator.toString()}, ${subExpression.operator.stringValue}, ${subExpression.operator.value().toString()}, ${subExpression.operator.keyword?.name}, ${subExpression.leftOperand.runtimeType} ${subExpression.rightOperand.toString()}');
          } else {
            addLintMessage(reporter, expression, errors.ErrorSeverity.WARNING,
                'which type of current expression = ${iterationExpressions[i].runtimeType}');
            // now probably wrongly assume that this expression is a returned value (not switch/conditional/parenthesis), but we need to start somewhere
            expressions.add(iterationExpressions[i].unParenthesized);
          }
        }
        iterationExpressions = nextIterationExpressions;
      }
      return (
        expressions: expressions,
        topLevelIdentifiersProducingExpressions:
            topLevelIdentifiersProducingExpressions,
        wasThereAnyEmptyReturnStatement: wasThereAnyEmptyReturnStatement,
        wasThereAnyEmptyFunctionBody: wasThereAnyEmptyFunctionBody
      );
    } catch (e, stackTrace) {
      addLintMessage(reporter, expression, errors.ErrorSeverity.INFO,
          'Lint plugin exception: $e $stackTrace');
      return (
        expressions: [],
        topLevelIdentifiersProducingExpressions: null,
        wasThereAnyEmptyReturnStatement: false,
        wasThereAnyEmptyFunctionBody: false
      );
    }
  }

  bool getComparableValueDartObjectInstanceShared(
      ErrorReporter reporter,
      Map<dynamic, List<ReturnStatement>> returnStatements,
      Map<int, List<AssignmentExpression>> assignmentExpressionsByElementId,
      Map<int, List<VariableDeclaration>> variableDeclarationsByElementId,
      DartObject? dartObject,
      Map<ComparableUltimateValue, Object?> valueMap,
      Expression? expression) {
    String msg = '';
    String mainName = '';
    Object? messageNode = expression ?? dartObject?.variable;
    if (messageNode != null) {
      addLintMessage(
          reporter,
          messageNode,
          msgDebugMode ? errors.ErrorSeverity.ERROR : errors.ErrorSeverity.INFO,
          'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() We\'ve entered another terrible method!');
    }
    if (expression is Identifier) {
      mainName = expression.name;
    } else {
      if (dartObject?.variable == null) {
        if (messageNode != null) {
          addLintMessage(reporter, messageNode, errors.ErrorSeverity.ERROR,
              'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() ERROR: unable to get name from dartObject, at this stage it is unexpected that the DartObject doesn\'t contain infor about name of the variable which is essential.');
        }
        addLintMessage(reporter, messageNode, errors.ErrorSeverity.ERROR,
            'getComparableValueFromExpressionOrDartObject() stage #T4 ERROR: probably object taken from annotation getField - dreamed of getting variable from it like from Identifier compure... DartObject. : dartObject = $dartObject, dartObject?.variable == ${dartObject?.variable}, dartObject?.type == ${dartObject?.type} , dartObject?.type?.element == ${dartObject?.type?.element}');
        if (dartObject != null) {
          /// We assume that for the below conditions like dartObject.toBoolValue() must not be null
          if (dartObject.isNull) {
            valueMap[ComparableUltimateValue.simple] = null;
            return true;
          } else if (dartObject.type?.isDartCoreBool == true) {
            valueMap[ComparableUltimateValue.simple] = dartObject.toBoolValue();
            return true;
          } else if (dartObject.type?.isDartCoreInt == true) {
            valueMap[ComparableUltimateValue.simple] = dartObject.toIntValue();
            return true;
          } else if (dartObject.type?.isDartCoreDouble == true) {
            valueMap[ComparableUltimateValue.simple] =
                dartObject.toDoubleValue();
            return true;
          } else if (dartObject.type?.isDartCoreList == true) {
            valueMap[ComparableUltimateValue.simple] = dartObject.toListValue();
            return true;
          } else if (dartObject.type?.isDartCoreMap == true) {
            valueMap[ComparableUltimateValue.simple] = dartObject.toMapValue();
            return true;
          } else if (dartObject.type?.isDartCoreSet == true) {
            valueMap[ComparableUltimateValue.simple] = dartObject.toSetValue();
            return true;
          } else if (dartObject.type?.isDartCoreString == true) {
            valueMap[ComparableUltimateValue.simple] =
                dartObject.toStringValue();
            return true;
          } else if (dartObject.type?.isDartCoreFunction == true) {
            valueMap[ComparableUltimateValue.simple] =
                dartObject.toFunctionValue();
            return true;
          }
        }
        return false;
      } else {
        mainName = dartObject!.variable!.name;
      }
    }

    // includes initializer
    int assignmentExpressionsCounter = 0;
    // not else - a separate condition
    if (dartObject != null) {
      Expression? returnedExpression;
      //Element? declaration = expression.staticElement?.declaration;
      VariableElement? declaration = dartObject.variable?.declaration;
      bool declarationFound = false;
      if (messageNode != null) {
        // one declared variable with value but with no further assignments:
        // for the later - getter no getter versions if declared - how this behaves?
        // dartObject.variable?.id = 20439, == declaration.getter?.variable2?.id
        // FIXME: fixme? BUT ID DIDN'T CHECK (MAYBE NO NEED) declaration?.id supposedly also 20439
        // works: variableDeclarationsByElementId[declaration.getter?.variable2?.declaration.id]
        // works: variableDeclarationsByElementId[declaration.getter?.variable2?.id]
        // so should work:
        // works: assignmentExpressionsByElementId[declaration.getter?.variable2?.declaration.id]
        // works: assignmentExpressionsByElementId[declaration.getter?.variable2?.id]

        //addLintMessage(
        //    reporter,
        //    messageNode,
        //    msgDebugMode
        //        ? errors.ErrorSeverity.ERROR
        //        : errors.ErrorSeverity.INFO,
        //    '''getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(),
        //    dartObject.variable = ${dartObject.variable},
        //    dartObject.variable?.id = ${dartObject.variable?.id},
        //    declaration?.id = ${declaration?.id},
        //    declaration is VariableElement = ${declaration is VariableElement},
        //    declaration is PropertyInducingElement = ${declaration is PropertyInducingElement},
        //    declaration is FieldElement = ${declaration is FieldElement},
        //    declaration is FieldElement ? declaration.getter?.id : null = ${declaration is FieldElement ? declaration.getter?.id : null},
        //    declaration is FieldElement ? declaration.getter?.declaration.id : null = ${declaration is FieldElement ? declaration.getter?.declaration.id : null},
        //    declaration is FieldElement ? declaration.getter?.variable2?.id : null = ${declaration is FieldElement ? declaration.getter?.variable2?.id : null},
        //    declaration is FieldElement ? declaration.getter?.variable2?.declaration.id : null = ${declaration is FieldElement ? declaration.getter?.variable2?.declaration.id : null},
//
        //    declaration is FieldElement && declaration.getter !=null ? assignmentExpressionsByElementId[declaration.getter?.id] : null ${declaration is FieldElement && declaration.getter != null ? assignmentExpressionsByElementId[declaration.getter?.id] : null}                  ,
        //    declaration is FieldElement && declaration.getter !=null ? assignmentExpressionsByElementId[declaration.getter?.declaration.id] : null ${declaration is FieldElement && declaration.getter != null ? assignmentExpressionsByElementId[declaration.getter?.declaration.id] : null}                  ,
        //    declaration is FieldElement && declaration.getter?.variable2 != null ? assignmentExpressionsByElementId[declaration.getter?.variable2?.id] : null ${declaration is FieldElement && declaration.getter?.variable2 != null ? assignmentExpressionsByElementId[declaration.getter?.variable2?.id] : null}                  ,
        //    declaration is FieldElement && declaration.getter?.variable2 != null ? assignmentExpressionsByElementId[declaration.getter?.variable2?.declaration.id] : null ${declaration is FieldElement && declaration.getter?.variable2 != null ? assignmentExpressionsByElementId[declaration.getter?.variable2?.declaration.id] : null}                  ,
        //
        //    declaration is FieldElement && declaration.getter !=null ? variableDeclarationsByElementId[declaration.getter?.id] : null ${declaration is FieldElement && declaration.getter != null ? variableDeclarationsByElementId[declaration.getter?.id] : null}                  ,
        //    declaration is FieldElement && declaration.getter !=null ? variableDeclarationsByElementId[declaration.getter?.declaration.id] : null ${declaration is FieldElement && declaration.getter != null ? variableDeclarationsByElementId[declaration.getter?.declaration.id] : null}                  ,
        //    declaration is FieldElement && declaration.getter?.variable2 != null ? variableDeclarationsByElementId[declaration.getter?.variable2?.id] : null ${declaration is FieldElement && declaration.getter?.variable2 != null ? variableDeclarationsByElementId[declaration.getter?.variable2?.id] : null}                  ,
        //    declaration is FieldElement && declaration.getter?.variable2 != null ? variableDeclarationsByElementId[declaration.getter?.variable2?.declaration.id] : null ${declaration is FieldElement && declaration.getter?.variable2 != null ? variableDeclarationsByElementId[declaration.getter?.variable2?.declaration.id] : null}                  ,
        //
//
        //    declaration is TopLevelVariableElement = ${declaration is TopLevelVariableElement},
        //    declaration is VariableDeclaration = ${declaration is VariableDeclaration},
        //    declaration is FieldDeclaration = ${declaration is FieldDeclaration}
        //    dartObject.variable.runtimeType = ${dartObject.variable.runtimeType}''');
      }
      if (declaration != null) {
        //if (
        //
        //    /// FIXME: NEVER TRUE:
        //    declaration is FieldElement) {
        //isFinal, isConst
        declarationFound = true;
        //if (variableDeclaration.isFinal ||
        //    variableDeclaration.isConst) {
        final int? id = declaration is FieldElement
            ? declaration.getter?.variable2?.declaration.id
            : dartObject.variable?.id;
        //returnedExpression - also this could be used: variableDeclarationsByElementId[id]
        returnedExpression =
            variableDeclarationsByElementId[id]?.first.initializer;
        msg +=
            'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(), VariableDeclaration expression.name: ${mainName} FieldDeclaration - returned expression returnedExpression (can be null or Expression) - initializer has been found, expression = $returnedExpression';
        if (returnedExpression != null) {
          var ultimateExpressions =
              getUltimateNonConditionalNorSwitchExpressions(
                  reporter,
                  returnStatements,
                  variableDeclarationsByElementId,
                  assignmentExpressionsByElementId,
                  returnedExpression);
          assignmentExpressionsCounter +=
              ultimateExpressions.expressions.length;
          if (assignmentExpressionsCounter > 1) {
            if (messageNode != null) {
              addLintMessage(reporter, messageNode, errors.ErrorSeverity.ERROR,
                  'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(), VariableDeclaration ERROR #1: more than one expression extracted from Identifier() (any variable may have a declaration initializer expression and/or possibly many assignments) expression has been found. In this case a variable must have known ultimate value expression');
            }
            return false;
          } else if (ultimateExpressions.expressions.length == 1) {
            msg +=
                'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(), VariableDeclaration id = $id found at least one assignment expression assignmentExpressionsByElementId[id]';
            valueMap[ComparableUltimateValue.expression] =
                ultimateExpressions.expressions.first;
          }
        }
        if (assignmentExpressionsByElementId[id] != null &&
            assignmentExpressionsByElementId[id]!.isNotEmpty) {
          for (AssignmentExpression assignmentExpression
              in assignmentExpressionsByElementId[id]!) {
            var ultimateExpressions =
                getUltimateNonConditionalNorSwitchExpressions(
                    reporter,
                    returnStatements,
                    variableDeclarationsByElementId,
                    assignmentExpressionsByElementId,
                    assignmentExpression.rightHandSide);
            assignmentExpressionsCounter +=
                ultimateExpressions.expressions.length;
            if (assignmentExpressionsCounter > 1) {
              if (messageNode != null) {
                addLintMessage(
                    reporter,
                    messageNode,
                    errors.ErrorSeverity.ERROR,
                    'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(), VariableDeclaration ERROR #2: more than one expression extracted from Identifier() (any variable may have a declaration initializer expression and/or possibly many assignments) expression has been found. In this case a variable must have known ultimate value expression');
              }
              return false;
            } else if (ultimateExpressions.expressions.length == 1) {
              msg +=
                  'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(), VariableDeclaration id = $id found at least one assignment expression assignmentExpressionsByElementId[id]';
              valueMap[ComparableUltimateValue.expression] =
                  ultimateExpressions.expressions.first;
            }
          }
        } else {
          msg +=
              'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(), VariableDeclaration id = $id  couldn\'t find found at least one assignment expression assignmentExpressionsByElementId[id]';
        }
        //} else {
        //  msg +=
        //      'getComparableValueFromExpressionOrDartObject() case Identifier(),  VariableDeclaration expression can\'t be use because it is not final nor const';
        //}
//        }

        // (expression.staticElement.declaration as FieldDeclaration).fields.variables.first.initializer;
        // ((inv.argumentList.arguments.first.staticParameterElement?.metadata.first.element?.declaration as ClassMember) as FieldDeclaration).fields.variables.first.initializer;

        if (declarationFound == false) {
          if (messageNode != null) {
            addLintMessage(reporter, messageNode, errors.ErrorSeverity.ERROR,
                'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(),  ERROR: no declaration not found IT IS EXPECTED TO BE FOUND ALWAYS');
          }
        }
      } else {
        if (messageNode != null) {
          addLintMessage(reporter, messageNode, errors.ErrorSeverity.ERROR,
              'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(),  ########## ERROR: DECLARATION IS EXPECTED TO BE ALWAYS FOUND ##############');
        }
      }

      valueMap[ComparableUltimateValue.dartObject] = dartObject;

      /// We assume that for the below conditions like dartObject.toBoolValue() must not be null
      if (dartObject.isNull) {
        valueMap[ComparableUltimateValue.simple] = null;
      } else if (dartObject.type?.isDartCoreBool == true) {
        valueMap[ComparableUltimateValue.simple] = dartObject.toBoolValue();
      } else if (dartObject.type?.isDartCoreInt == true) {
        valueMap[ComparableUltimateValue.simple] = dartObject.toIntValue();
      } else if (dartObject.type?.isDartCoreDouble == true) {
        valueMap[ComparableUltimateValue.simple] = dartObject.toDoubleValue();
      } else if (dartObject.type?.isDartCoreList == true) {
        valueMap[ComparableUltimateValue.simple] = dartObject.toListValue();
      } else if (dartObject.type?.isDartCoreMap == true) {
        valueMap[ComparableUltimateValue.simple] = dartObject.toMapValue();
      } else if (dartObject.type?.isDartCoreSet == true) {
        valueMap[ComparableUltimateValue.simple] = dartObject.toSetValue();
      } else if (dartObject.type?.isDartCoreString == true) {
        valueMap[ComparableUltimateValue.simple] = dartObject.toStringValue();
      } else if (dartObject.type?.isDartCoreFunction == true) {
        valueMap[ComparableUltimateValue.simple] = dartObject.toFunctionValue();
      }
    }

    if (messageNode != null) {
      addLintMessage(
          reporter,
          messageNode,
          msgDebugMode ? errors.ErrorSeverity.ERROR : errors.ErrorSeverity.INFO,
          'getComparableValueFromExpressionOrDartObject() getComparableValueDartObjectInstanceShared() case Identifier(), possibly more to be printed in the getComparableValueDartObjectInstanceShared() body but the current msg = $msg');
    }
    return true;
  }

  // when isValueTakenFromLiteral == null means that a returned value is universal
  // isThisMap was added because literal has only SetOrMapLiteral(), true = is Map, false is Set, null - none of the both
  // if isValueTakenFromLiteral == false the returned value is DartObject with and as tested it can be compared with another DartObject (as i tested)
  // if isValueTakenFromLiteral == true the value is taken from Literal with not tested chance to compare with the same (List, Map, instance) object that is also taken from litera.
  // like 0.5 double value taken from literal is computed to something normal - double type value not DartCoreDouble or something like that.
  // but for record or List you can compare two values (assuming so - to test yet) only when bothw compared values are taken from Identifier or a ListLiteral or RecordLiteral
  ({
    bool valueHasBeenFound,
    Map<ComparableUltimateValue, Object?>? value,
//      UltimateValueType? ultimateValueType
  }) getComparableValueFromExpressionOrDartObject(
      ErrorReporter reporter,
      Map<dynamic, List<ReturnStatement>> returnStatements,
      Map<int, List<AssignmentExpression>> assignmentExpressionsByElementId,
      Map<int, List<VariableDeclaration>> variableDeclarationsByElementId,
      Expression? expression,
      [DartObject? dartObjectParam,
      Object? msgNode]) {
    DartObject? dartObject = dartObjectParam;
    if (dartObject == null) {
      if (expression != null) {
        addLintMessage(
            reporter,
            expression,
            msgDebugMode
                ? errors.ErrorSeverity.ERROR
                : errors.ErrorSeverity.INFO,
            'getComparableValueFromExpressionOrDartObject(), expression is not null.');
        switch (expression) {
          // FIXME: not fixme - to turn your attention: an expression may be conditional binary, f.e. abc ?? cde, abc + cde - this by nature doesn't produce 100% result - is too difficult now to implement calculation maybe later with dart_eval.
          // it shoudn't be identifier as a declaration and optional further assignemts are broke down into ultimate expressions
          case Identifier():
            // here becaue it says CommentReferableExpression covers this, but actually SimpleIdentifier is of CommentReferableExpression.
            // WARNING: SEE THERE IS RecordLiteral()
            // for this you may have to finde expression for this identifier that produces RecordLiteral()
            // and assuming that both instances are comparable as to if they are equal you may use them
            // FIXME: FIXME:
            // the identifier maybe const or have constant like assigned value after declaration.
            // let's focus on const
            // maybe if we find the assignment we can get the rightHand or similar exprssion
            // if we have expression that is RecordLiteral, Listliteral... no what if there are references to some things literals.
            // basically uncomparable this way :(
            // Conclusion, possibly the only reliable way to compare objects is via
            // DartObject way.

            String msg = '';
            if (expression.staticElement is VariableElement) {
              (expression.staticElement as VariableElement).declaration;
              var elem = (expression.staticElement as VariableElement);
              msg +=
                  'getComparableValueFromExpressionOrDartObject() case Identifier(),  VariableElement elema.id = ${elem.id}, elema.id = ${elem.nonSynthetic.id}, elem.context.declaredVariables = ${elem.context.declaredVariables}, elem.nonSynthetic.context.declaredVariables = ${elem.nonSynthetic.context.declaredVariables}';

              dartObject = (expression.staticElement as VariableElement)
                  .computeConstantValue();
            }

            if (expression.staticElement is PropertyAccessorElement) {
              var elem = (expression.staticElement as PropertyAccessorElement);
              var variable2 = elem.variable2;
              dartObject = variable2?.computeConstantValue();
              var variable2_variety = elem.variable2?.getter?.variable2;
              var dartObject_variety = variable2?.computeConstantValue();
              dartObject = dartObject_variety;
              msg +=
                  'getComparableValueFromExpressionOrDartObject() case Identifier(),  VariableElement elema.id = ${elem.id}, elema.id = ${elem.nonSynthetic.id}, elem.context.declaredVariables = ${elem.context.declaredVariables}, elem.nonSynthetic.context.declaredVariables = ${elem.nonSynthetic.context.declaredVariables}';

              msg +=
                  'getComparableValueFromExpressionOrDartObject() case Identifier(),  PropertyAccessorElement variable2=${variable2} getter = ${variable2?.getter}, variable2?.getter?.hasImplicitReturnType = ${variable2?.getter?.hasImplicitReturnType}, dartObject?.type = ${dartObject?.type} dartObject?.type?.isDartCoreInt = ${dartObject?.type?.isDartCoreInt} ${dartObject} ';
              msg +=
                  'getComparableValueFromExpressionOrDartObject() case Identifier(),  PropertyAccessorElement variable2_variety=${variable2_variety} getter = ${variable2_variety?.getter}, variable2_variety?.getter?.hasImplicitReturnType = ${variable2_variety?.getter?.hasImplicitReturnType}, dartObject_variety?.type = ${dartObject_variety?.type} dartObject_variety?.type?.isDartCoreInt = ${dartObject_variety?.type?.isDartCoreInt} ${dartObject_variety} ';
              //if (elem.variable2.getter.hasImplicitReturnType) {
              //  //elem.variable2.
              //}
            }

            //PropertyAccessorElementImpl_ImplicitGetter

            Map<ComparableUltimateValue, Object?> valueMap = {};
            if (getComparableValueDartObjectInstanceShared(
                    reporter,
                    returnStatements,
                    assignmentExpressionsByElementId,
                    variableDeclarationsByElementId,
                    dartObject,
                    valueMap,
                    expression) ==
                false) {
              return (
                valueHasBeenFound: false,
                value: null,
              );
            }

            ({
              bool valueHasBeenFound,
              Map<ComparableUltimateValue, Object?>? value,
              // UltimateValueType? ultimateValueType
            }) record;
            if (valueMap.isNotEmpty) {
              msg +=
                  'getComparableValueFromExpressionOrDartObject() case Identifier(), return value has been found';
              record = (
                valueHasBeenFound: true,
                value: valueMap,
              );
            } else {
              msg +=
                  'getComparableValueFromExpressionOrDartObject() case Identifier(), return value hasn\'t been found';
              record = (
                valueHasBeenFound: false,
                value: null,
              );
            }

            addLintMessage(reporter, expression, errors.ErrorSeverity.INFO,
                'getComparableValueFromExpressionOrDartObject() case Identifier(),  msg = $msg, it is Identifier(). dartObject.type?.isDartCoreInt = ${dartObject?.type?.isDartCoreInt}, dartObject = ${dartObject}, ${expression.staticElement is VariableElement}, ${expression.runtimeType}, ${expression.staticElement?.runtimeType}, ${expression.staticElement}');

            return record;

          // will the following ever be used?
          //case CommentReferableExpression():
          //  // [ConstructorReference] | [FunctionReference] | [PrefixedIdentifier] | [PropertyAccess] | [SimpleIdentifier] | [TypeLiteral]
          //  // and possibly more
          //  switch (expression) {
          //    case ConstructorReference(): // not constructor invokation
          //      break;
          //    case PropertyAccess():
          //      break;
          //  }
          case IntegerLiteral():
            // it sees it is IntegerLiteral but .value might be null - i don't understand it;
            // it seems inconsistent with its corresponding similar DoubleLiteral which can't be null
            if (expression.value != null) {
              return (
                valueHasBeenFound: true,
                value: {ComparableUltimateValue.simple: expression.value!},
                //ultimateValueType: null
              );
            }
            break;
          case NullLiteral():
            // it sees it is IntegerLiteral but .value might be null - i don't understand it;
            return (
              valueHasBeenFound: true,
              value: {ComparableUltimateValue.simple: null},
              //ultimateValueType: null
            );
          case DoubleLiteral():
            return (
              valueHasBeenFound: true,
              value: {ComparableUltimateValue.simple: expression.value},
              //ultimateValueType: null
            );
          //case RecordLiteral():
          //  // we don't have a value like for Integer literal but have probably difficult .fields with expression of more or less easy computable values.
          //  // but if it fails there is NO IN "case Identifier()" toRecordValue() , BUT .variable is computable and objects can be compared with this.
          //  // it sees it is IntegerLiteral but .value might be null - i don't understand it;
          //
          //  // return (valueHasBeenFound: true, value: null);
          //  return (
          //    valueHasBeenFound: true,
          //    value: {ComparableUltimateValue.expression: expression},
          //    //ultimateValueType: null
          //  );
          case StringLiteral():
            switch (expression) {
              case SimpleStringLiteral():
                if (expression.stringValue != null) {
                  return (
                    valueHasBeenFound: true,
                    value: {
                      ComparableUltimateValue.simple: expression.stringValue
                    },
                    //ultimateValueType: null
                  );
                }
                break;
              case StringInterpolation(): // Difficult to handle - for the later.
                return (
                  valueHasBeenFound: false,
                  value: null,
                );
                break;
              case _: // AdjacentStrings() ignored
                return (
                  valueHasBeenFound: false,
                  value: null,
                );
                break;
            }
            break;
          case RecordLiteral():
            return (
              valueHasBeenFound: true,
              value: {ComparableUltimateValue.expression: expression},
              //ultimateValueType: null
            );
          case ListLiteral():
            return (
              valueHasBeenFound: true,
              value: {ComparableUltimateValue.expression: expression},
              //ultimateValueType: null
            );
          case SetOrMapLiteral():
            return (
              valueHasBeenFound: true,
              value: {ComparableUltimateValue.expression: expression},
              //ultimateValueType: expression.isMap ? UltimateValueType.map : UltimateValueType.set
            );
          //case InvocationExpression():
          //  switch (expression) {
          //    case MethodInvocation():
          //      return (
          //        valueHasBeenFound: true,
          //        value: {ComparableUltimateValue.expression: expression},
          //        //ultimateValueType: expression.isMap ? UltimateValueType.map : UltimateValueType.set
          //      );
          //    case FunctionExpressionInvocation():
          //      return (
          //        valueHasBeenFound: true,
          //        value: {ComparableUltimateValue.expression: expression},
          //        //ultimateValueType: expression.isMap ? UltimateValueType.map : UltimateValueType.set
          //      );
          //  }
          //  break;
          case InstanceCreationExpression():
            // doesnt get you a DartObject but
            // having DartObject (now don't remember how here) you can
            // ExecutableElement? .toFunctionValue and this as docs says:
            // maybe null means function was not const or constructor too.
            // or even if it wasn't const was not computable or something
            // !!! can be: ConstructorElement or FunctionElement or MethodElement ...
            // possibly two such FunctionElement could be compared
            // 1. abc(1) == abc(1) two executable elements produced from this might be equal (or it doesn't work this way)
            // 2. abc(1) != abc(1) might not.
            //
            // We have to compare it as is in the method comparing
            return (
              valueHasBeenFound: true,
              value: {ComparableUltimateValue.expression: expression},
            );
          default:
            addLintMessage(reporter, expression, errors.ErrorSeverity.INFO,
                'getComparableValueFromExpressionOrDartObject() an expression is not handled by the switch(expression) statement (this is default: clause) message.');

            return (
              valueHasBeenFound: false,
              value: null,
            );
        }
      }
    } else {
      String msg = '';
      Map<ComparableUltimateValue, Object?> valueMap = {};
      addLintMessage(
          reporter,
          dartObject.variable ?? msgNode,
          msgDebugMode ? errors.ErrorSeverity.ERROR : errors.ErrorSeverity.INFO,
          'getComparableValueFromExpressionOrDartObject()  dartObject supplied, stage #T1 dartObject = $dartObject, dartObject?.variable == ${dartObject?.variable}, dartObject?.type == ${dartObject?.type} , dartObject?.type?.element == ${dartObject?.type?.element}');
      if (getComparableValueDartObjectInstanceShared(
              reporter,
              returnStatements,
              assignmentExpressionsByElementId,
              variableDeclarationsByElementId,
              dartObject,
              valueMap,
              null) ==
          false) {
        addLintMessage(
            reporter,
            dartObject.variable ?? msgNode,
            msgDebugMode
                ? errors.ErrorSeverity.ERROR
                : errors.ErrorSeverity.INFO,
            'getComparableValueFromExpressionOrDartObject()  dartObject supplied, stage #T2');
        return (
          valueHasBeenFound: false,
          value: null,
        );
      } else {
        ({
          bool valueHasBeenFound,
          Map<ComparableUltimateValue, Object?>? value,
          // UltimateValueType? ultimateValueType
        }) record;
        if (valueMap.isNotEmpty) {
          msg +=
              'getComparableValueFromExpressionOrDartObject() dartObject supplied, return value has been found';
          record = (
            valueHasBeenFound: true,
            value: valueMap,
          );
        } else {
          msg +=
              'getComparableValueFromExpressionOrDartObject() dartObject supplied, return value hasn\'t been found';
          record = (
            valueHasBeenFound: false,
            value: null,
          );
        }
        if (dartObject.variable != null || msgNode != null) {
          addLintMessage(
              reporter,
              dartObject.variable ?? msgNode,
              msgDebugMode
                  ? errors.ErrorSeverity.ERROR
                  : errors.ErrorSeverity.INFO,
              'getComparableValueFromExpressionOrDartObject()  dartObject supplied,  msg = $msg, . dartObject.type?.isDartCoreInt = ${dartObject?.type?.isDartCoreInt}, dartObject = ${dartObject}');
        }
        return record;
      }
    }
    addLintMessage(
        reporter,
        expression ?? dartObject?.variable ?? msgNode,
        msgDebugMode ? errors.ErrorSeverity.ERROR : errors.ErrorSeverity.INFO,
        'getComparableValueFromExpressionOrDartObject() getComparableValueFromExpressionOrDartObject()  dartObject supplied, stage #T3');

    return (
      valueHasBeenFound: false,
      value: null,
    );
  }

  addLintMessage(ErrorReporter reporter, Object? node,
      errors.ErrorSeverity errorSeverity, String message) {
    if (node == null) return;
    try {
      if (node is Expression || node is AstNode) {
        reporter.atNode(
            node is Expression
                ? node as Expression
                : node as AstNode /*.parent!*/,
            LintCode(
              name: 'anno_types_warning',
              problemMessage: 'annotypes $message',
              errorSeverity: errorSeverity,
            ));
      } else if (node is Element) {
        reporter.atElement(
            node /*.parent!*/,
            LintCode(
              name: 'anno_types_warning',
              problemMessage: 'annotypes $message',
              errorSeverity: errorSeverity,
            ));
      }
    } catch (e) {}
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    int standardNumberOfFields = 100;

    /// WARNING! Based on the preliminary knowledge that parent node
    /// key is function or [MethodDeclaration] method declaration id;
    /// is always a [FunctionDeclaration] or [MethodDeclaration] - both are not extending or implementing each other.
    /// So because of this FunctionBody value in the key=>value pari is much better than a ...Declaration
    Map<dynamic, List<ReturnStatement>> returnStatements = {};
    Map<int, List<AssignmentExpression>> assignmentExpressionsByElementId = {};
    Map<int, List<VariableDeclaration>> variableDeclarationsByElementId = {};

    List<MethodDeclaration> methodDeclarations = [];
    Map<FunctionBody, MethodDeclaration> methodBodies = {};
    Set<bool> whatIsCalledFirst = {};

    /// warning: keep it compatible with checkingReturnTypesAndValues()
    /// returns null
    /// On error places lint error
    /// 1. when expression is in $N(expression) instance. so isNullableValue == true, but the to-be-returned final expression is not an Identifier(), because only Identifiers can have a type like int? not just int like the rest of sorts of expressions. conditions were not met, like $N(notAnIdentifierExpression)
    /// 2. When expression is Identifer but has type declaration not nullable - f.e int instead of int?
    ({Expression expression, bool isMutableValue})?
        getExpressionWithCustomComparisonRequirements(
            Expression expression, dynamic msgNode) {
      if (expression is! InstanceCreationExpression) {
        return (expression: expression, isMutableValue: false);
      } else {
        Expression finalExpression = expression;
        bool isMutableValue = false;
        bool isNullableValue = false;
        while (true) {
          if (finalExpression is InstanceCreationExpression) {
            switch (finalExpression.staticType?.getDisplayString()) {
              case "\$M":
                isMutableValue = true;
                finalExpression = expression.argumentList.arguments.first;
                continue;
              case "\$N":
                isNullableValue = true;
                finalExpression = expression.argumentList.arguments.first;
                continue;
            }
          }

          if (isNullableValue) {
            if (finalExpression is! Identifier) {
              addLintMessage(reporter, msgNode, errors.ErrorSeverity.ERROR,
                  'getExpressionWithCustomComparisonRequirements (like checkingReturnTypesAndValues() part) Error: Current expression was in the \$N(expression) so it must be Identifier() instance (int? abc = 10 - abc is Identifier() instance) with declared type that is nullable f.e. int? not int, List? not List');
              return null;
            } else {
              addLintMessage(
                  reporter,
                  msgNode,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  'getExpressionWithCustomComparisonRequirements (like checkingReturnTypesAndValues() part) isNullableValue == true hence Some data: (currentFieldExpression as Identifier).staticType?.nullabilitySuffix == ${(finalExpression as Identifier).staticType?.nullabilitySuffix} finalExpression.staticType == ${finalExpression?.staticType}');
              // FIXME: i expect this to contain info about nullabilitySuffix
              // if not you have to go to the declaration variable and get info about the type - left hand or writeElement dont remember now
              if ((finalExpression as Identifier)
                      .staticType
                      ?.nullabilitySuffix !=
                  NullabilitySuffix.question) {
                addLintMessage(reporter, msgNode, errors.ErrorSeverity.ERROR,
                    'getExpressionWithCustomComparisonRequirements (like checkingReturnTypesAndValues() part): Current expression was in the \$N(expression) and is Identifier() instance but it was not defined with a nullable type (int? abc = 10 - abc is Identifier() instance) with declared type that is nullable f.e. int? not int, List? not List. WARNING! Read doc // info above the place this message was defined, info on how to get the nullability info in different way if this was incorrect');
                return null;
              } else {}
            }
          }

          return (expression: finalExpression, isMutableValue: isMutableValue);
        }
      }
    }

    /// Warning! this method can't be called with $M() or $N() and of this exact purposed instances only non-functional expressions.
    /// Compares only a declared variable that had only one value assignment - on declaration or later. If expression(/2) is Identifier() and it returns more than one assignement expressions on calling getComparableValueFromExpressionOrDartObject (yskrn from declaration and/or from possible many assigments) a lint error is shown, but the code smoothly works and doesn't throw Exception.
    /// This means it is ensure that two values compared have no more that one value assignment so the value can be treated as const/final.
    /// Because of this if compareOneTimeAssignmentExpression == false all assignments are used for comparison from more than one element "expressions" sources (one expressions may be one assignment second many assignments or both can be many assignments)
    /// if one comparison fails - error is reported and false is returned
    /// It means on declaration (initializer expression), or on first assignment some time after declaration but with no second or more declarations.
    /// This is necessary to ensure the const/final like nature of the assignment - not neccessary const but you know the value is certain (in standard dart for a method call you can't use the value of the variable that was declared but not initialized with value).
    /// returns true if two computable values are equal like 2.8 == 2.8 or false otherwise.
    /// Warning: is it needed?: returns null if:
    /// 1. an expression is not handled
    /// 2. couldn't find two expressions of the same sort - we can compare two [DartObject]s but no one DartObject and one Expression,
    /// [Edit:] update, currently value for input DartObject returns f.e. DartObject, and expression/s with declaration and all assignments and if you require only one assignment on declaration or later then pass to this method compareOneTimeAssignmentExpression = true;
    /// 3. Possibly (may not be implemented yet) if a difficult expression like function doesn't produce non-null ExecutableElement (like FunctionElement) .staticElement which i guest may mean that any return type or expression was not computable.
    ///    to remind me: also DartObject .toFunctionValue() produces ExecutableElement - with casting or now to function or method element it might be compared too with ==
    bool? compareValueFromUltimateExpressionWithAnotherUltimateValue({
      Expression? expression,
      DartObject? dartObjectParam,
      bool expressionMustBeConst = true,
      Expression? expression2,
      DartObject? dartObjectParam2,
      Object? diagnosticMessageNode,
      bool expression2MustBeConst2 = true,
      // If present, to match conditions the expression param must represent simple value and [String] in this case and dartObjectParam2 which is "sort-of" staticly created $R "instance" is not null (not necessary to use expression2) and expression is checked if it matches the regexp
      bool isRegExp = false,
      // If present, If present, to match conditions the expression param must represent simple value and [num] in this case and dartObjectParam2 which is "sort-of" staticly created $B "instance" is not null (not necessary to use expression2) and expression is checked if it matches the $R range object values and other settings.
      bool isBetween = false,
    }) {
      if (expression != null ||
          expression2 != null ||
          diagnosticMessageNode != null) {
        addLintMessage(
            reporter,
            diagnosticMessageNode ?? expression ?? expression2!,
            msgDebugMode
                ? errors.ErrorSeverity.ERROR
                : errors.ErrorSeverity.WARNING,
            'compareValueFromUltimateExpressionWithAnotherUltimateValue(), WE ENTERED THIS TERRIBLE METHOD !');
      }
      if (expression == null &&
          dartObjectParam == null &&
          (diagnosticMessageNode != null || expression2 != null)) {
        addLintMessage(
            reporter,
            diagnosticMessageNode ?? expression2!,
            errors.ErrorSeverity.ERROR,
            'compareValueFromUltimateExpressionWithAnotherUltimateValue() Error: Can\'t both expression and dartObjectParam be null');
      }
      if (expression2 == null &&
          dartObjectParam2 == null &&
          (diagnosticMessageNode != null || expression != null)) {
        addLintMessage(
            reporter,
            diagnosticMessageNode ?? expression!,
            errors.ErrorSeverity.ERROR,
            'compareValueFromUltimateExpressionWithAnotherUltimateValue() Error: Can\'t both expression2 and dartObjectParam2 be null');
      }

      // ??? We need to provide two ultimate objects ready to be compared whatever they might be.
      // If in the following a key 1: or 2: will could'nt has been found an expression for a given key couldn't for now a way to translated into something easy to compare has been found.
      // now in theory we can compare values starting from easy ones.
      var value = getComparableValueFromExpressionOrDartObject(
          reporter,
          returnStatements,
          assignmentExpressionsByElementId,
          variableDeclarationsByElementId,
          expression,
          dartObjectParam,
          diagnosticMessageNode ?? expression ?? expression2);
      var value2 = getComparableValueFromExpressionOrDartObject(
          reporter,
          returnStatements,
          assignmentExpressionsByElementId,
          variableDeclarationsByElementId,
          expression2,
          dartObjectParam2,
          diagnosticMessageNode ?? expression ?? expression2);

      if (expression != null ||
          expression2 != null ||
          diagnosticMessageNode != null) {
        addLintMessage(
            reporter,
            diagnosticMessageNode ?? expression ?? expression2!,
            msgDebugMode
                ? errors.ErrorSeverity.ERROR
                : errors.ErrorSeverity.INFO,
            '''compareValueFromUltimateExpressionWithAnotherUltimateValue(), we have the following info about compared values:
            expression = ${expression?.toSource()},
            expression?.staticType = ${expression?.staticType}
            expression.runtimeType = ${expression.runtimeType}
            dartObjectParam = $dartObjectParam,
            value = ${value},
            dartObjectParam.variable = ${dartObjectParam?.variable}
            expression2 = ${expression2?.toSource()},
            expression2?.staticType = ${expression2?.staticType}
            expression2.runtimeType = ${expression2.runtimeType}
            dartObjectParam2 = $dartObjectParam2
            dartObjectParam2.variable = ${dartObjectParam2?.variable}
            value2 = ${value2}
        ''');
      }

      if (value.valueHasBeenFound &&
              (value2.valueHasBeenFound ||
                  (!value2.valueHasBeenFound && (isRegExp || isBetween)))
          // FIXME: WHILE FOR value2.isValueTakenFromLiteral producing DartObject, etc. this is reliable as i tested to some degree...
          // BUT FOR OBJECT PRODUCED FROM LITERALS value.isValueTakenFromLiteral = false (NOT NULL!!!) it is yet to be tested and doubtfull it will work unfailingly
          ) {
        if ((isRegExp || isBetween) &&
            value.value?.keys.contains(ComparableUltimateValue.simple) ==
                true) {
          if (isBetween) {
            // final num t1; // left limit value
            // final num t2; // right limit value
            // final bool t3; // must be int-like (may be type double but integer - to enforce can't be double use f.e. @$(num $B(...) $NOT double))
            // final bool t4; // includes left limit value
            // final bool t5; // includes right limit value
            num leftLimitValue =
                dartObjectParam2!.getField('t1')!.toDoubleValue() ??
                    dartObjectParam2.getField('t1')!.toIntValue()!;
            num rightLimitValue =
                dartObjectParam2.getField('t2')!.toDoubleValue() ??
                    dartObjectParam2.getField('t2')!.toIntValue()!;

            if (leftLimitValue >= rightLimitValue) {
              return null;
            }
            bool mustBeInt = dartObjectParam2.getField('t3')!.toBoolValue()!;
            bool includesLeftLimitValue =
                dartObjectParam2.getField('t4')!.toBoolValue()!;
            bool includesRightLimitValue =
                dartObjectParam2.getField('t5')!.toBoolValue()!;
            // if null, not a number, may be double type with int value:
            num? number = value.value![ComparableUltimateValue.simple] is num
                ? value.value![ComparableUltimateValue.simple] as num
                : null;

            if (number == null) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  errors.ErrorSeverity.ERROR,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() error, number is null, error while checking if a simple number taken from expression is between range @\$(... \$B(1, 10, ...))');
              return null;
            }
            bool isIntValue = number == number.roundToDouble() ? true : false;
            addLintMessage(
                reporter,
                diagnosticMessageNode ?? expression ?? expression2!,
                msgDebugMode
                    ? errors.ErrorSeverity.ERROR
                    : errors.ErrorSeverity.INFO,
                'compareValueFromUltimateExpressionWithAnotherUltimateValue() isBetween = true, leftLimitValue = $leftLimitValue, rightLimitValue = $rightLimitValue, mustBeInt = $mustBeInt, includesLeftLimitValue = $includesLeftLimitValue, includesRightLimitValue = $includesRightLimitValue, isIntValue = $isIntValue, mustBeInt && !isIntValue = ${mustBeInt && !isIntValue} ');
            if (mustBeInt && !isIntValue) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  errors.ErrorSeverity.ERROR,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() error, \$B() settings require that number taken from expression (simple value) can be of type double but must have int value, error while checking if a simple number taken from expression is between range @\$(... \$B(1, 10, ...))');
              return null;
            }
            return number > leftLimitValue && number < rightLimitValue ||
                includesLeftLimitValue && number == leftLimitValue ||
                includesRightLimitValue && number == rightLimitValue;
          } else if (isRegExp) {
            // final String t1; // source
            // final bool t2; // multiline
            // final bool t3; // case sensitive
            // final bool t4; // unicode
            // final bool t5; // isdotall

            String regexString =
                dartObjectParam2!.getField('t1')!.toStringValue()!;
            bool isMultiline = dartObjectParam2.getField('t2')!.toBoolValue()!;
            bool isCaseSensitive =
                dartObjectParam2.getField('t3')!.toBoolValue()!;
            bool isUnicode = dartObjectParam2.getField('t4')!.toBoolValue()!;
            bool isDotAll = dartObjectParam2.getField('t5')!.toBoolValue()!;
            String? string =
                value.value![ComparableUltimateValue.simple] is String
                    ? value.value![ComparableUltimateValue.simple] as String
                    : null;
            if (string == null) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  errors.ErrorSeverity.ERROR,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() error, string is null, error while checking if a string taken from expression matches RegExp conditions stipulated in the @\$(... \$R()...) instance');
            }
            RegExp regex = RegExp(regexString,
                multiLine: isMultiline,
                caseSensitive: isCaseSensitive,
                unicode: isUnicode,
                dotAll: isDotAll);
            return regex.hasMatch(string!);
          }
        } else if (value.value?.keys.contains(ComparableUltimateValue.simple) ==
                true &&
            value2.value?.keys.contains(ComparableUltimateValue.simple) ==
                true) {
          addLintMessage(
              reporter,
              diagnosticMessageNode ?? expression ?? expression2!,
              msgDebugMode
                  ? errors.ErrorSeverity.ERROR
                  : errors.ErrorSeverity.INFO,
              'compareValueFromUltimateExpressionWithAnotherUltimateValue() Comparing two simple values value.value is null ${value.value == null} value2.value is null ${value2.value == null} ,value.value![ComparableUltimateValue.simple] == value2.value![ComparableUltimateValue.simple] it is: ${value.value?[ComparableUltimateValue.simple] == value2.value?[ComparableUltimateValue.simple]}');
          return value.value![ComparableUltimateValue.simple] ==
              value2.value![ComparableUltimateValue.simple];
        } else if (value.value?.keys
                    .contains(ComparableUltimateValue.dartObject) ==
                true &&
            value2.value?.keys.contains(ComparableUltimateValue.dartObject) ==
                true) {
          return value.value![ComparableUltimateValue.dartObject] ==
              value2.value![ComparableUltimateValue.dartObject];
        } else if (value.value?.keys
                    .contains(ComparableUltimateValue.expression) ==
                true &&
            value2.value?.keys.contains(ComparableUltimateValue.expression) ==
                true) {
          // DartObject docs: Returns a representation of the value of this variable, forcing the value to be computed if it had not previously been computed, or null if either this variable was not declared with the 'const' modifier or if the value of this variable could not be computed because of errors.
          // !!! so computeConstantValue doesn't argument doesn't have to be const but the last assignment of the value must be computable

          Expression? expressionF =
              value.value?[ComparableUltimateValue.expression] as Expression?;
          Expression? expressionF2 =
              value2.value?[ComparableUltimateValue.expression] as Expression?;

          if (expressionF is InstanceCreationExpression &&
              expressionF2 is InstanceCreationExpression) {
            // Now we could compare parameters of both and know if they are equal.

            // FIXME: Read not perfectly clear desc of .isConst and expressionF.inConstantContext
            // for now based on an assumption simply that .isConst guaratees calling const constructor anyway.
            if ((expressionMustBeConst && !expressionF.isConst) ||
                (expression2MustBeConst2 && !expressionF2.isConst)) {
              // TODO: FIXME:
              // TODO: FIXME:
              // TODO: FIXME:
              // JUST TO DO :) for constructor invokations add special instance $MUTABLE() (or default is mutable and add $CONST() instead) (maybe $STATE) where a constructor invokation (expression or variable) or variable doesn't have to be const internally but one (min and max at the same time) known assignment is required as it already is. Which means a constructor expression declared with the same constructor params that can be changed or not internally.
              // then no const is required and is ignored
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() expressionMustBeConst == ${expressionMustBeConst} expression2MustBeConst2 == ${expression2MustBeConst2}, at least one constructor of constructor invokation is not const constructor. Some const info: expressionF.isConst = ${expressionF.isConst} expressionF2.isConst = ${expressionF2.isConst} expressionF.inConstantContext == ${expressionF.inConstantContext} expressionF.inConstantContext == ${expressionF2.inConstantContext}               
                    expressionF.constructorName.staticElement?.isConst == ${expressionF.constructorName.staticElement?.isConst}    
                    expressionF.constructorName.staticElement?.declaration.isConst = ${expressionF.constructorName.staticElement?.declaration.isConst}
                    expressionF2.constructorName.staticElement?.isConst == ${expressionF2.constructorName.staticElement?.isConst}    
                    expressionF2.constructorName.staticElement?.declaration.isConst = ${expressionF2.constructorName.staticElement?.declaration.isConst}
                    ''');
              return null;
            } else if (expressionF.constructorName.name !=
                expressionF2.constructorName.name) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() two compared constructor name do not mach: expressionF.constructorName.name == ${expressionF.constructorName.name}, expressionF2.constructorName.name == ${expressionF2.constructorName.name} ');
              return null;
            }

            ConstructorElement? constructorDeclaration =
                expressionF.constructorName.staticElement?.declaration;

            bool isConstConstructor = true;
            //if (expressionF.argumentList.arguments.length != 0) {
            //  constructorDeclaration = expressionF.argumentList.arguments.first
            //      .staticParameterElement?.declaration.enclosingElement;
            //} else if (expressionF2.argumentList.arguments.length != 0) {
            //  constructorDeclaration = expressionF2.argumentList.arguments.first
            //      .staticParameterElement?.declaration.enclosingElement;
            //}
            //if (constructorDeclaration != null) {
            //  if (constructorDeclaration is! ConstructorDeclaration) {
            //    addLintMessage(
            //        reporter,
            //        diagnosticMessageNode ?? expression ?? expression2!,
            //        msgDebugMode
            //            ? errors.ErrorSeverity.ERROR
            //            : errors.ErrorSeverity.INFO,
            //        'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() #G4 ');
            //    constructorDeclaration =
            //        constructorDeclaration.enclosingElement;
            //    if (constructorDeclaration is! ConstructorDeclaration) {
            //      addLintMessage(
            //          reporter,
            //          diagnosticMessageNode ?? expression ?? expression2!,
            //          msgDebugMode
            //              ? errors.ErrorSeverity.ERROR
            //              : errors.ErrorSeverity.INFO,
            //          'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() #G5 ');
            //      constructorDeclaration =
            //          constructorDeclaration?.enclosingElement;
            //    }
            //    if (constructorDeclaration is ConstructorDeclaration) {
            //      addLintMessage(
            //          reporter,
            //          diagnosticMessageNode ?? expression ?? expression2!,
            //          msgDebugMode
            //              ? errors.ErrorSeverity.ERROR
            //              : errors.ErrorSeverity.INFO,
            //          'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() #G6 ');
            //      isConstConstructor =
            //          (constructorDeclaration as ConstructorDeclaration)
            //                  .constKeyword !=
            //              null;
            //    }
            //  }
            //}
            if (!isConstConstructor) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  errors.ErrorSeverity.ERROR,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() Error: isConstConstructor == false');
            }
            List<ParameterElement?>? declarationParameterElements;
            if (constructorDeclaration is ConstructorElement) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() #G7 ');
              declarationParameterElements =
                  (constructorDeclaration as ConstructorElement).parameters;
              if (declarationParameterElements == null) {
                addLintMessage(
                    reporter,
                    diagnosticMessageNode ?? expression ?? expression2!,
                    errors.ErrorSeverity.ERROR,
                    'compareValueFromUltimateExpressionWithAnotherUltimateValue() #G8 part InstanceCreationExpression() Error: This is unexpected for the declarationParameterElements to be null not a List<ParameterElement?>');
                return null;
              }
            } else {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  errors.ErrorSeverity.ERROR,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() #G9 part InstanceCreationExpression() Error: constructorDeclaration is! ConstructorDeclaration');
            }

            // declaration

            //({
            //    List<Expression> expressions,
            //    bool wasThereAnyEmptyReturnStatement,
            //    bool wasThereAnyEmptyFunctionBody,
            //  })? getUltimateConstLikeExpressions(
            if (declarationParameterElements != null) {
              for (int i = 0; i < declarationParameterElements.length; i++) {
                String name = declarationParameterElements[i]!.name;
                Expression? expressionFCorrespondingParam;
                Expression? expressionF2CorrespondingParam2;
                addLintMessage(
                    reporter,
                    diagnosticMessageNode ?? expression ?? expression2!,
                    msgDebugMode
                        ? errors.ErrorSeverity.ERROR
                        : errors.ErrorSeverity.INFO,
                    'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() #G71 declarationParameterElements[i]!.name = ${declarationParameterElements[i]!.name}, declarationParameterElements[i]!.name = ${declarationParameterElements[i]!.name}, ${declarationParameterElements[i]!.displayName}, ${declarationParameterElements[i]!.getDisplayString()}, ${declarationParameterElements[i]!.declaration.name}, ${declarationParameterElements[i]!.declaration.displayName}, expressionF.argumentList.arguments.length = ${expressionF.argumentList.arguments.length} expressionF2.argumentList.arguments.length = ${expressionF2.argumentList.arguments.length}');

                for (int k = 0;
                    k < expressionF.argumentList.arguments.length;
                    k++) {
                  if (name ==
                      expressionF.argumentList.arguments[k]
                          .staticParameterElement?.name) {
                    //addLintMessage(
                    //    reporter,
                    //    diagnosticMessageNode ?? expression ?? expression2!,
                    //    msgDebugMode
                    //        ? errors.ErrorSeverity.ERROR
                    //        : errors.ErrorSeverity.INFO,
                    //    'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() #G72 expressionF.argumentList.arguments[k].staticParameterElement?.declaration.name = ${expressionF.argumentList.arguments[k].staticParameterElement?.declaration.name} expressionF.argumentList.arguments[k].staticParameterElement?.name = ${expressionF.argumentList.arguments[k].staticParameterElement?.name} expressionF.argumentList.arguments[k].unParenthesized = ${expressionF.argumentList.arguments[k].unParenthesized}, expressionF.argumentList.arguments[k] = ${expressionF.argumentList.arguments[k]}');
                    expressionFCorrespondingParam =
                        expressionF.argumentList.arguments[k].unParenthesized;
                  }
                }
                for (int k = 0;
                    k < expressionF2.argumentList.arguments.length;
                    k++) {
                  //addLintMessage(
                  //    reporter,
                  //    diagnosticMessageNode ?? expression ?? expression2!,
                  //    msgDebugMode
                  //        ? errors.ErrorSeverity.ERROR
                  //        : errors.ErrorSeverity.INFO,
                  //    'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() #G73 expressionF2.argumentList.arguments[k].staticParameterElement?.declaration.name = ${expressionF2.argumentList.arguments[k].staticParameterElement?.declaration.name} expressionF2.argumentList.arguments[k].staticParameterElement?.name = ${expressionF2.argumentList.arguments[k].staticParameterElement?.name} expressionF2.argumentList.arguments[k].unParenthesized = ${expressionF2.argumentList.arguments[k].unParenthesized}, expressionF2.argumentList.arguments[k] = ${expressionF2.argumentList.arguments[k]}');
                  if (name ==
                      expressionF2.argumentList.arguments[k]
                          .staticParameterElement?.name) {
                    expressionF2CorrespondingParam2 =
                        expressionF2.argumentList.arguments[k].unParenthesized;
                  }
                }

                if (expressionFCorrespondingParam == null &&
                    expressionF2CorrespondingParam2 == null) {
                  continue;
                } else if (expressionFCorrespondingParam != null &&
                        expressionF2CorrespondingParam2 == null ||
                    expressionFCorrespondingParam == null &&
                        expressionF2CorrespondingParam2 != null) {
                  addLintMessage(
                      reporter,
                      diagnosticMessageNode ?? expression ?? expression2!,
                      errors.ErrorSeverity.ERROR,
                      'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() Error: at least one expression to be compared was null but the other not null, so the top level values are not equal. expressionFCorrespondingParam = ${expressionFCorrespondingParam}, expressionF2CorrespondingParam2 = $expressionF2CorrespondingParam2');
                  return null;
                }

                bool? comparisonResult =
                    compareValueFromUltimateExpressionWithAnotherUltimateValue(
                  expression: expressionFCorrespondingParam,
                  expressionMustBeConst: expressionMustBeConst,
                  expression2: expressionF2CorrespondingParam2,
                  diagnosticMessageNode:
                      diagnosticMessageNode ?? expression ?? expression2!,
                  expression2MustBeConst2: expression2MustBeConst2,
                );

                addLintMessage(
                    reporter,
                    diagnosticMessageNode ?? expression ?? expression2!,
                    msgDebugMode
                        ? errors.ErrorSeverity.ERROR
                        : errors.ErrorSeverity.INFO,
                    'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() comparisonResult = $comparisonResult of expressionFCorrespondingParam = $expressionFCorrespondingParam, expressionF2CorrespondingParam2 = $expressionF2CorrespondingParam2  ');

                if (comparisonResult == null || comparisonResult == false) {
                  addLintMessage(
                      reporter,
                      diagnosticMessageNode ?? expression ?? expression2!,
                      errors.ErrorSeverity.ERROR,
                      'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() Error: comparisonResult = ${comparisonResult} comparisonResult == null||comparisonResult==false Two expression compared: expression = ${expression}, expression2 = ${expression2}');
                  return comparisonResult;
                }
              }
            }
            addLintMessage(
                reporter,
                diagnosticMessageNode ?? expression ?? expression2!,
                errors.ErrorSeverity.ERROR,
                'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() success: return true comparisonResult == null||comparisonResult==false Two expression compared: expression = ${expression}, expression2 = ${expression2}, declarationParameterElements?.length = ${declarationParameterElements?.length} declarationParameterElements = $declarationParameterElements');
            return true;
          } else if (expressionF is SetOrMapLiteral &&
              expressionF2 is SetOrMapLiteral) {
            if ((expressionMustBeConst && !expressionF.isConst) ||
                (expression2MustBeConst2 && !expressionF2.isConst)) {
              // TODO: FIXME:
              // TODO: FIXME:
              // TODO: FIXME:
              // JUST TO DO :) for constructor invokations add special instance $MUTABLE() (or default is mutable and add $CONST() instead) (maybe $STATE) where a constructor invokation (expression or variable) or variable doesn't have to be const internally but one (min and max at the same time) known assignment is required as it already is. Which means a constructor expression declared with the same constructor params that can be changed or not internally.
              // then no const is required and is ignored
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part SetOrMapLiteral() expressionMustBeConst == ${expressionMustBeConst} expression2MustBeConst2 == ${expression2MustBeConst2} at least one SetOrMapLiteral expression is not const. Some const info: expressionF.isConst = ${expressionF.isConst} expressionF2.isConst = ${expressionF2.isConst} expressionF.inConstantContext == ${expressionF.inConstantContext} expressionF.inConstantContext == ${expressionF2.inConstantContext}''');
              return null;
            }

            addLintMessage(
                reporter,
                diagnosticMessageNode ?? expression ?? expression2!,
                msgDebugMode
                    ? errors.ErrorSeverity.ERROR
                    : errors.ErrorSeverity.INFO,
                '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part SetOrMapLiteral() at least one SetOrMapLiteral expression is not const. Some const info: expressionF.isConst = ${expressionF.isConst} expressionF2.isConst = ${expressionF2.isConst} expressionF.inConstantContext == ${expressionF.inConstantContext} expressionF.inConstantContext == ${expressionF2.inConstantContext}''');
            if (expressionF.isMap != expressionF2.isMap) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part SetOrMapLiteral() one of the elmeents is Map but the other is Set expressionF.isMap == ${expressionF.isMap}, expressionF2.isMap == ${expressionF2.isMap}''');
              return null;
            }
            if (expressionF.elements.length != expressionF2.elements.length) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part SetOrMapLiteral() the number of elements in each list is not equal so the two ListLiterals (a class representing a least) are not equal: expressionF.elements.length == ${expressionF.elements.length} expressionF2.elements.length == ${expressionF2.elements.length}''');
              return false;
            }
            for (int i = 0; i < expressionF.elements.length; i++) {
              bool? comparisonResult =
                  compareValueFromUltimateExpressionWithAnotherUltimateValue(
                expression: expressionF.isSet
                    ? expressionF.elements[i] as Expression
                    : (expressionF.elements[i] as MapLiteralEntry).value,
                expressionMustBeConst: expressionMustBeConst,
                expression2: expressionF2.isSet
                    ? expressionF2.elements[i] as Expression
                    : (expressionF2.elements[i] as MapLiteralEntry).value,
                diagnosticMessageNode:
                    diagnosticMessageNode ?? expression ?? expression2!,
                expression2MustBeConst2: expression2MustBeConst2,
              );

              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() comparisonResult = $comparisonResult of ');

              bool? comparisonResult2;
              if (expressionF.isMap) {
                comparisonResult2 =
                    compareValueFromUltimateExpressionWithAnotherUltimateValue(
                  expression: (expressionF.elements[i] as MapLiteralEntry).key,
                  expressionMustBeConst: expressionMustBeConst,
                  expression2:
                      (expressionF2.elements[i] as MapLiteralEntry).key,
                  diagnosticMessageNode:
                      diagnosticMessageNode ?? expression ?? expression2!,
                  expression2MustBeConst2: expression2MustBeConst2,
                );

                addLintMessage(
                    reporter,
                    diagnosticMessageNode ?? expression ?? expression2!,
                    msgDebugMode
                        ? errors.ErrorSeverity.ERROR
                        : errors.ErrorSeverity.INFO,
                    'compareValueFromUltimateExpressionWithAnotherUltimateValue() part InstanceCreationExpression() comparisonResult = $comparisonResult ');
              }

              if (comparisonResult == null ||
                  comparisonResult == false ||
                  (expressionF.isMap &&
                      (comparisonResult2 == null ||
                          comparisonResult2 == false))) {
                addLintMessage(
                    reporter,
                    diagnosticMessageNode ?? expression ?? expression2!,
                    errors.ErrorSeverity.ERROR,
                    'compareValueFromUltimateExpressionWithAnotherUltimateValue() part SetOrMapLiteral() Error: comparisonResult = ${comparisonResult} comparisonResult == null||comparisonResult==false Two expression compared: expression = ${expression}, expression2 = ${expression2}');
                return comparisonResult;
              }
            }
            addLintMessage(
                reporter,
                diagnosticMessageNode ?? expression ?? expression2!,
                errors.ErrorSeverity.ERROR,
                'compareValueFromUltimateExpressionWithAnotherUltimateValue() part ListLiteral() success: return true comparisonResult == null||comparisonResult==false Two expression compared: expression = ${expression}, expression2 = ${expression2}');
            return true;
          } else if (expressionF is ListLiteral &&
              expressionF2 is ListLiteral) {
            if ((expressionMustBeConst && !expressionF.isConst) ||
                (expression2MustBeConst2 && !expressionF2.isConst)) {
              // TODO: FIXME:
              // TODO: FIXME:
              // TODO: FIXME:
              // JUST TO DO :) for constructor invokations add special instance $MUTABLE() (or default is mutable and add $CONST() instead) (maybe $STATE) where a constructor invokation (expression or variable) or variable doesn't have to be const internally but one (min and max at the same time) known assignment is required as it already is. Which means a constructor expression declared with the same constructor params that can be changed or not internally.
              // then no const is required and is ignored
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part ListLiteral() expressionMustBeConst == ${expressionMustBeConst} expression2MustBeConst2 == ${expression2MustBeConst2} at least one ListLiteral expression is not const. Some const info: expressionF.isConst = ${expressionF.isConst} expressionF2.isConst = ${expressionF2.isConst} expressionF.inConstantContext == ${expressionF.inConstantContext} expressionF.inConstantContext == ${expressionF2.inConstantContext}''');
              return null;
            }

            addLintMessage(
                reporter,
                diagnosticMessageNode ?? expression ?? expression2!,
                msgDebugMode
                    ? errors.ErrorSeverity.ERROR
                    : errors.ErrorSeverity.INFO,
                '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part ListLiteral() Some const info: expressionMustBeConst == ${expressionMustBeConst} expression2MustBeConst2 == ${expression2MustBeConst2} expressionF.isConst = ${expressionF.isConst} expressionF2.isConst = ${expressionF2.isConst} expressionF.inConstantContext == ${expressionF.inConstantContext} expressionF.inConstantContext == ${expressionF2.inConstantContext}''');
            if (expressionF.elements.length != expressionF2.elements.length) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part ListLiteral() the number of elements in each list is not equal so the two ListLiterals (a class representing a least) are not equal: expressionF.elements.length == ${expressionF.elements.length} expressionF2.elements.length == ${expressionF2.elements.length}''');
              return false;
            }
            for (int i = 0; i < expressionF.elements.length; i++) {
              if (expressionF.elements[i] is! Expression ||
                  expressionF2.elements[i] is! Expression) {
                addLintMessage(
                    reporter,
                    diagnosticMessageNode ?? expression ?? expression2!,
                    msgDebugMode
                        ? errors.ErrorSeverity.ERROR
                        : errors.ErrorSeverity.INFO,
                    '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part ListLiteral() at leasst one of CollectionElement instance is not an Expression instance expressionF.elements[i] is Expression == ${expressionF.elements[i] is Expression} expressionF2.elements[i] is Expression == ${expressionF2.elements[i] is Expression}''');
                return null;
              }

              bool? comparisonResult =
                  compareValueFromUltimateExpressionWithAnotherUltimateValue(
                expression: expressionF.elements[i] as Expression,
                expressionMustBeConst: expressionMustBeConst,
                expression2: expressionF2.elements[i] as Expression,
                diagnosticMessageNode:
                    diagnosticMessageNode ?? expression ?? expression2!,
                expression2MustBeConst2: expression2MustBeConst2,
              );

              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() part ListLiteral() comparisonResult = $comparisonResult');

              if (comparisonResult == null || comparisonResult == false) {
                addLintMessage(
                    reporter,
                    diagnosticMessageNode ?? expression ?? expression2!,
                    errors.ErrorSeverity.ERROR,
                    'compareValueFromUltimateExpressionWithAnotherUltimateValue() part ListLiteral() Error: comparisonResult = ${comparisonResult} comparisonResult == null||comparisonResult==false Two expression compared: expression = ${expression}, expression2 = ${expression2}');
                return comparisonResult;
              }
            }
            addLintMessage(
                reporter,
                diagnosticMessageNode ?? expression ?? expression2!,
                errors.ErrorSeverity.ERROR,
                'compareValueFromUltimateExpressionWithAnotherUltimateValue() part ListLiteral() success: return true comparisonResult == null||comparisonResult==false Two expression compared: expression = ${expression}, expression2 = ${expression2}');
            return true;
          } else if (expressionF is RecordLiteral &&
              expressionF2 is RecordLiteral) {
            // 1. RecordType (not literal Expreesion) has namedFields and Positional fields so you need to compare type of each in the == "Type" part
            // not difficult to implement.
            // 2. But here RecordLiteral has fields - list of expressions like list or set
            // Supposedly for enum you don't need to do anything as i can see there is no something special for enum (there is but seems not immediately needed but useful elsewhere)
            // then you will use InstanceCreationExpression and just type comparison enum abc {...} use abc in $(abc, abc.cde) .cde means constructor call InstanceCreationExpression

            if ((expressionMustBeConst && !expressionF.isConst) ||
                (expression2MustBeConst2 && !expressionF2.isConst)) {
              // TODO: FIXME:
              // TODO: FIXME:
              // TODO: FIXME:
              // JUST TO DO :) for constructor invokations add special instance $MUTABLE() (or default is mutable and add $CONST() instead) (maybe $STATE) where a constructor invokation (expression or variable) or variable doesn't have to be const internally but one (min and max at the same time) known assignment is required as it already is. Which means a constructor expression declared with the same constructor params that can be changed or not internally.
              // then no const is required and is ignored
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part RecordLiteral() expressionMustBeConst == ${expressionMustBeConst} expression2MustBeConst2 == ${expression2MustBeConst2} at least one RecordLiteral expression is not const. Some const info: expressionF.isConst = ${expressionF.isConst} expressionF2.isConst = ${expressionF2.isConst} expressionF.inConstantContext == ${expressionF.inConstantContext} expressionF.inConstantContext == ${expressionF2.inConstantContext}''');
              return null;
            }

            addLintMessage(
                reporter,
                diagnosticMessageNode ?? expression ?? expression2!,
                msgDebugMode
                    ? errors.ErrorSeverity.ERROR
                    : errors.ErrorSeverity.INFO,
                '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part RecordLiteral() at least one RecordLiteral expression is not const. Some const info: expressionF.isConst = ${expressionF.isConst} expressionF2.isConst = ${expressionF2.isConst} expressionF.inConstantContext == ${expressionF.inConstantContext} expressionF.inConstantContext == ${expressionF2.inConstantContext}''');
            if (expressionF.fields.length != expressionF2.fields.length) {
              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part RecordLiteral() the number of elements in each list is not equal so the two ListLiterals (a class representing a least) are not equal: expressionF.elements.length == ${expressionF.fields.length} expressionF2.elements.length == ${expressionF2.fields.length}''');
              return false;
            }
            for (int i = 0; i < expressionF.fields.length; i++) {
              if (expressionF.fields[i] is! Expression ||
                  expressionF2.fields[i] is! Expression) {
                addLintMessage(
                    reporter,
                    diagnosticMessageNode ?? expression ?? expression2!,
                    msgDebugMode
                        ? errors.ErrorSeverity.ERROR
                        : errors.ErrorSeverity.INFO,
                    '''compareValueFromUltimateExpressionWithAnotherUltimateValue() part RecordLiteral() at leasst one of CollectionElement instance is not an Expression instance expressionF.elements[i] is Expression == ${expressionF.fields[i] is Expression} expressionF2.elements[i] is Expression == ${expressionF2.fields[i] is Expression}''');
                return null;
              }

              bool? comparisonResult =
                  compareValueFromUltimateExpressionWithAnotherUltimateValue(
                expression: expressionF.fields[i],
                expressionMustBeConst: expressionMustBeConst,
                expression2: expressionF2.fields[i],
                diagnosticMessageNode:
                    diagnosticMessageNode ?? expression ?? expression2!,
                expression2MustBeConst2: expression2MustBeConst2,
              );

              addLintMessage(
                  reporter,
                  diagnosticMessageNode ?? expression ?? expression2!,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  'compareValueFromUltimateExpressionWithAnotherUltimateValue() part RecordLiteral() comparisonResult = $comparisonResult of ');

              if (comparisonResult == null || comparisonResult == false) {
                addLintMessage(
                    reporter,
                    diagnosticMessageNode ?? expression ?? expression2!,
                    errors.ErrorSeverity.ERROR,
                    'compareValueFromUltimateExpressionWithAnotherUltimateValue() part RecordLiteral() Error: comparisonResult = ${comparisonResult} comparisonResult == null||comparisonResult==false Two expression compared: expression = ${expression}, expression2 = ${expression2}');
                return comparisonResult;
              }
            }
            addLintMessage(
                reporter,
                diagnosticMessageNode ?? expression ?? expression2!,
                errors.ErrorSeverity.ERROR,
                'compareValueFromUltimateExpressionWithAnotherUltimateValue() part RecordLiteral() success: return true comparisonResult == null||comparisonResult==false Two expression compared: expression = ${expression}, expression2 = ${expression2}');
            return true;
          }
        }

        if (expression != null ||
            expression2 != null ||
            diagnosticMessageNode != null) {
          addLintMessage(
              reporter,
              diagnosticMessageNode ?? expression ?? expression2!,
              msgDebugMode
                  ? errors.ErrorSeverity.ERROR
                  : errors.ErrorSeverity.INFO,
              'compareValueFromUltimateExpressionWithAnotherUltimateValue() are values compared equal?: value == value2: ${value == value2}');
        }
        return null;
        return value == value2;
      } else {
        if (expression != null ||
            expression2 != null ||
            diagnosticMessageNode != null) {
          addLintMessage(
              reporter,
              diagnosticMessageNode ?? expression ?? expression2!,
              msgDebugMode
                  ? errors.ErrorSeverity.ERROR
                  : errors.ErrorSeverity.INFO,
              'compareValueFromUltimateExpressionWithAnotherUltimateValue() the two values compared are of instances that can\' be compared. The two values related record with all info look like this: value: $value, value2: $value2');
        }
        return null;
      }
    }

    checkingReturnTypesAndValues(
        MethodDeclaration methodDeclaration,
        List<Expression> expressions,
        Expando<Identifier>? topLevelIdentifiersProducingExpressions) {
      addLintMessage(
          reporter,
          methodDeclaration,
          msgDebugMode ? errors.ErrorSeverity.ERROR : errors.ErrorSeverity.INFO,
          'checkingReturnTypesAndValues: Entered stage #0 expressions.length = ${expressions.length} expressions = ${expressions}');
      for (int k = 0; k < expressions.length; k++) {
        final Expression expression = expressions[k];
        Expression messageNode = expression;
        addLintMessage(
            reporter,
            methodDeclaration,
            msgDebugMode
                ? errors.ErrorSeverity.ERROR
                : errors.ErrorSeverity.INFO,
            'checkingReturnTypesAndValues: Entered stage #1');
        addLintMessage(
            reporter,
            expression,
            msgDebugMode
                ? errors.ErrorSeverity.ERROR
                : errors.ErrorSeverity.INFO,
            'checkingReturnTypesAndValues: Entered stage #2');
        try {
          // the below line will throw if there is no element at all (so the last one too isn't);
          methodDeclaration.declaredElement?.metadata.last;
        } catch (e) {
          return;
        }
        try {
          if (methodDeclaration.declaredElement == null) {
            continue;
          }
          final List<ElementAnnotation>? metad =
              methodDeclaration.declaredElement!.metadata;

          addLintMessage(
              reporter,
              methodDeclaration,
              msgDebugMode
                  ? errors.ErrorSeverity.ERROR
                  : errors.ErrorSeverity.INFO,
              'checkingReturnTypesAndValues: Entered stage #3');
          addLintMessage(
              reporter,
              expression,
              msgDebugMode
                  ? errors.ErrorSeverity.ERROR
                  : errors.ErrorSeverity.INFO,
              'checkingReturnTypesAndValues: Entered stage #3');
          if (metad != null &&
              metad.isNotEmpty &&
              metad.last.element?.displayName == "\$") {
            /// You never expect this to be null
            //NodeList<Expression>? metaAnnotationObjectArguments =
            //    $AnnotationsByElementId[metad.last.element?.id]
            //        ?.arguments
            //        ?.arguments;
            //if (metaAnnotationObjectArguments == null) {
            //  //addLintMessage(
            //  //    reporter,
            //  //    expression,
            //  //    msgDebugMode
            //  //        ? errors.ErrorSeverity.ERROR
            //  //        : errors.ErrorSeverity.INFO,
            //  //    'checkingReturnTypesAndValues: Entered stage #4.5 metaAnnotationObjectArguments can\'t be null');
            //}

            bool hasBeenExceptionForTheCurrentNode = false;

            DartObject? computedMetaObject = metad.last.computeConstantValue();
            if (computedMetaObject == null) continue;
            bool hasConditionSwitchedTo$NOT = false;
            bool hasConditionSwitchedTo$Nullable = false;
            bool hasConditionSwitchedTo$Mutable = false;
            bool theParamMatchesAtLeastOneTypeOrValueRequirements = false;
            bool
                thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition =
                false;
            bool
                theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition =
                false;
            bool? is$ = computedMetaObject.getField('is\$')?.toBoolValue();
            if (is$ != null && is$) {
              addLintMessage(
                  reporter,
                  expression,
                  msgDebugMode
                      ? errors.ErrorSeverity.ERROR
                      : errors.ErrorSeverity.INFO,
                  'checkingReturnTypesAndValues: Entered stage #5');
              TypeSystem typeSystem =
                  methodDeclaration.declaredElement!.library.typeSystem;

              for (int i = 1; i <= standardNumberOfFields; i++) {
                DartObject? currentField = computedMetaObject.getField('t$i');
                Expression? currentFieldExpression;
                if (!currentField!.isNull) {
                  // if would be null a param would has been passed to the constructor so the argument wouln't be available.
                  // even if null was passed the expression would be created, if so it wouldn't be used so ok anyway
                  currentFieldExpression = methodDeclaration
                      .metadata[methodDeclaration.metadata.length - 1]
                      .arguments
                      ?.arguments[i - 1];
                }
                if (currentField.isNull) {
                  break;
                } else if (currentField.type.toString() != "Type") {
                  theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition =
                      true;

                  /// $M(any qualifying expression, not Identifier only) not type but value/instance/literal, etc.
                  bool isMutableValue =
                      false; // const is not required, f.e. a List eee = ['abc'] on declaration or (not and) first-and-the-only assignment is required but you can eee.add();
                  /// not type but value/instance/literal, etc.
                  /// $N(someIdentifier) also the final expression must be of Identifier with declared f.e. not int type but int?
                  bool isNullableValue = false;
                  bool isBetween = false;
                  bool isRegExp = false;

                  addLintMessage(
                      reporter,
                      expression,
                      msgDebugMode
                          ? errors.ErrorSeverity.ERROR
                          : errors.ErrorSeverity.INFO,
                      'checkingReturnTypesAndValues: Entered stage #5.3, just before the while loop: currentFieldExpression == $currentFieldExpression, currentFieldExpression is InstanceCreationExpression == ${currentFieldExpression is InstanceCreationExpression}, currentFieldExpression.runtimeType == ${currentFieldExpression.runtimeType}, currentField?.type == ${currentField?.type} currentField?.type?.getDisplayString() == ${currentField?.type?.getDisplayString()} ');

                  /// TODO: KEEP IT/LOGIC COMPATIBLE WITH getExpressionWithCustomComparisonRequirements
                  /// related to isMutableValue and isNullableValue and possibly more in the future
                  /// the only reason for this loop is that there may be an instance $N, $M and possibly more in the future
                  /// and the $M $N instances are carriers of the real type or value
                  /// $M(any qualifying expression, not Identifier only) not type but value/instance/literal, etc.
                  /// $N(someIdentifier) also the final expression must be of Identifier with declared f.e. not int type but int?
                  /// when $M or $N like instance the variables like isMutable isNullable defined above this loop get their values
                  /// and because nesting is allowed for $N($M(someDeclaredVariable)) the continue mutableNullable: may repeat up to several times
                  /// untile the real compared currentField and currentFieldExpression expression is reached.
                  /// if no continue mutableNullable; is called at the end break mutableNullable; forcing the loop not to iterate twice
                  while (true) {
                    if (currentField == null ||
                        currentField!.isNull ||
                        currentField!.type.toString() == "Type") {
                      addLintMessage(
                          reporter,
                          methodDeclaration,
                          errors.ErrorSeverity.ERROR,
                          'checkingReturnTypesAndValues() Error: at this stage only instance objects are allowed no Types, null values carried by currentField or a currentField that is null not DartObject.');
                      break;
                    } else {
                      setUpNewFields() {
                        currentField = currentField!.getField('t1');
                        if (currentField != null) {
                          currentFieldExpression = (currentFieldExpression
                                  as InstanceCreationExpression)
                              .argumentList
                              .arguments
                              .first;
                        } else {
                          currentFieldExpression = null;
                        }
                      }

                      addLintMessage(
                          reporter,
                          expression,
                          msgDebugMode
                              ? errors.ErrorSeverity.ERROR
                              : errors.ErrorSeverity.INFO,
                          'checkingReturnTypesAndValues: Entered stage #5.5, currentFieldExpression == $currentFieldExpression, currentFieldExpression is InstanceCreationExpression == ${currentFieldExpression is InstanceCreationExpression}, currentFieldExpression.runtimeType == ${currentFieldExpression.runtimeType}, currentField?.type == ${currentField?.type} currentField?.type?.getDisplayString() == ${currentField?.type?.getDisplayString()} ');

                      switch (currentField?.type?.getDisplayString()) {
                        case "\$M":
                          isMutableValue = true;
                          setUpNewFields();
                          continue;
                        case "\$N":
                          isNullableValue = true;
                          setUpNewFields();
                          continue;
                        case "\$B":
                          isBetween = true;
                          break;
                        case "\$R":
                          isRegExp = true;
                          break;
                      }
                    }
                    break;
                  }
                  if (isNullableValue || hasConditionSwitchedTo$Nullable) {
                    Identifier? theTopLevelAncestorIdentifier =
                        topLevelIdentifiersProducingExpressions?[expression];
                    if (theTopLevelAncestorIdentifier == null) {
                      addLintMessage(
                          reporter,
                          methodDeclaration,
                          errors.ErrorSeverity.ERROR,
                          'checkingReturnTypesAndValues() Error: theTopLevelAncestorIdentifier = ${theTopLevelAncestorIdentifier} Current expression == $expression, expression is expected to belong to an Indentifier instance but the indentifier was not found as the \$N(somerequiredexpressionOrIdentifierHavingExpression) need to work with identifiers and the identifier instance (int? abc = 10 - abc is Identifier() instance) with declared type that is nullable f.e. int? not int, List? not List. And in this particlular case (\$N(...)). But the expression inside \$N() will be matched with the current expression not with the ancestor Identifier');
                    } else {
                      addLintMessage(
                          reporter,
                          methodDeclaration,
                          msgDebugMode
                              ? errors.ErrorSeverity.ERROR
                              : errors.ErrorSeverity.INFO,
                          'checkingReturnTypesAndValues: theTopLevelAncestorIdentifier = ${theTopLevelAncestorIdentifier} isNullableValue == true but is the identifier defined as nullable type?: theTopLevelAncestorIdentifier.staticType?.nullabilitySuffix == NullabilitySuffix.question == ${theTopLevelAncestorIdentifier.staticType?.nullabilitySuffix == NullabilitySuffix.question} hence Some data: currentFieldExpression is! Identifier == ${currentFieldExpression is! Identifier} ${currentFieldExpression is! Identifier ? currentFieldExpression?.staticType : (currentFieldExpression as Identifier).staticType?.nullabilitySuffix} == ${currentFieldExpression is! Identifier ? currentFieldExpression?.staticType : (currentFieldExpression as Identifier).staticType?.nullabilitySuffix} currentFieldExpression.staticType == ${currentFieldExpression?.staticType}');
                      // FIXME: i expect this to contain info about nullabilitySuffix
                      // if not you have to go to the declaration variable and get info about the type - left hand or writeElement dont remember now
                      if (theTopLevelAncestorIdentifier
                              .staticType?.nullabilitySuffix !=
                          NullabilitySuffix.question) {
                        addLintMessage(
                            reporter,
                            methodDeclaration,
                            errors.ErrorSeverity.ERROR,
                            'checkingReturnTypesAndValues() Error: Current expression which was to be mached against the \$N(somerequiredexpressionAlsoMayBeIdentifier) has it\'s own closest ancestor Identifier() instance but the ancestor identifier was not defined with a nullable type (int? abc = 10 - abc is Identifier() instance) with declared type that is nullable f.e. int? not int, List? not List. WARNING! Read doc // info above the place this message was defined, info on how to get the nullability info in different way if this was incorrect');
                      }
                    }
                  }

                  // TODO: we can try to get expression instead of DartObject to be able compare constructors, list, maps and sets not only DartObjects or simple type values like 2.8, "abc"
                  // ((inv.argumentList.arguments.first.staticParameterElement?.metadata.first.element?.declaration as ClassMember) as FieldDeclaration).fields.variables.first.initializer;
                  bool wasUsedComparisonResult2 = false;
                  bool? comparisonResult;
                  bool? comparisonResult2;
                  try {
                    //addLintMessage(
                    //    reporter,
                    //    methodDeclaration,
                    //    msgDebugMode
                    //        ? errors.ErrorSeverity.ERROR
                    //        : errors.ErrorSeverity.INFO,
                    //    'checkingReturnTypesAndValues: the expression represents value. methodDeclaration.metadata.length = ${methodDeclaration.metadata.length}');
                    //addLintMessage(
                    //    reporter,
                    //    messageNode,
                    //    msgDebugMode
                    //        ? errors.ErrorSeverity.ERROR
                    //        : errors.ErrorSeverity.INFO,
                    //    'checkingReturnTypesAndValues: the expression represents value. ');
                    comparisonResult =
                        compareValueFromUltimateExpressionWithAnotherUltimateValue(
                            expression: expression,
                            expressionMustBeConst: !(isMutableValue ||
                                hasConditionSwitchedTo$Mutable),
                            dartObjectParam2: currentField,
                            expression2MustBeConst2:
                                false, // currentField doesn't have to be const but on first and only value assignment calculable/readable final values must repeat for constructor, list/map/set/record literals,,
                            isBetween: isBetween,
                            isRegExp: isRegExp);

                    if (!isBetween &&
                            !isRegExp &&
                            comparisonResult == null &&
                            currentFieldExpression != null
                        //&& methodDeclaration.metadata.length > 0 &&
                        //methodDeclaration
                        //    .metadata[methodDeclaration.metadata.length - 1]
                        //    .arguments
                        //    ?.arguments
                        //    .length is int &&
                        //methodDeclaration
                        //        .metadata[methodDeclaration.metadata.length - 1]
                        //        .arguments!
                        //        .arguments
                        //        .length >=
                        //    i - 1 &&
                        //methodDeclaration
                        //        .metadata[methodDeclaration.metadata.length - 1]
                        //        .arguments
                        //        ?.arguments[i - 1] !=
                        //    null
                        ) {
                      wasUsedComparisonResult2 = true;
                      addLintMessage(
                          reporter,
                          methodDeclaration,
                          msgDebugMode
                              ? errors.ErrorSeverity.ERROR
                              : errors.ErrorSeverity.INFO,
                          'checkingReturnTypesAndValues: comparing with comparisonResult2 : expression: ${methodDeclaration.metadata[methodDeclaration.metadata.length - 1].arguments?.arguments[i - 1]}');
                      addLintMessage(
                          reporter,
                          messageNode,
                          msgDebugMode
                              ? errors.ErrorSeverity.ERROR
                              : errors.ErrorSeverity.INFO,
                          'checkingReturnTypesAndValues: comparing with comparisonResult2 : expression: ${methodDeclaration.metadata[methodDeclaration.metadata.length - 1].arguments?.arguments[i - 1]}');

                      comparisonResult2 =
                          compareValueFromUltimateExpressionWithAnotherUltimateValue(
                              expression: expression,
                              expressionMustBeConst: !(isMutableValue ||
                                  hasConditionSwitchedTo$Mutable),
                              expression2:
                                  currentFieldExpression // to remind you in the previous method call getField was used but it failed so we use this corresponding expression
                              ,
                              expression2MustBeConst2:
                                  false, // expression corresponding to getField doesn't have to be const but on first and only value assignment calculable/readable final values must repeat for constructor, list/map/set/record literals,
                              //isBetween: isBetween,
                              //isRegExp: isRegExp
                              diagnosticMessageNode: methodDeclaration);
                    }
                  } catch (e, stackTrace) {
                    addLintMessage(
                        reporter,
                        methodDeclaration,
                        msgDebugMode
                            ? errors.ErrorSeverity.ERROR
                            : errors.ErrorSeverity.INFO,
                        'checkingReturnTypesAndValues() catched error: i==$i (meta = i but Annotation argument has index i-1) e = $e, stackTrace $stackTrace');
                    addLintMessage(
                        reporter,
                        messageNode,
                        msgDebugMode
                            ? errors.ErrorSeverity.ERROR
                            : errors.ErrorSeverity.INFO,
                        'checkingReturnTypesAndValues() catched error: i==$i (meta = i but Annotation argument has index i-1) e = $e, stackTrace $stackTrace');
                    //'checkingReturnTypesAndValues() catched error: metaAnnotationObjectArguments= ${metaAnnotationObjectArguments}, e = $e, stackTrace $stackTrace');
                    rethrow;
                  }

                  addLintMessage(
                      reporter,
                      methodDeclaration,
                      msgDebugMode
                          ? errors.ErrorSeverity.ERROR
                          : errors.ErrorSeverity.INFO,
                      'checkingReturnTypesAndValues() INFO WHAT WE HAVE` expressions compared: $expression, $currentField. comparisonResult = ${comparisonResult}, comparisonResult2 = ${comparisonResult2}, wasUsedComparisonResult2 = $wasUsedComparisonResult2, isBetween: $isBetween, isRegExp: $isRegExp');
                  addLintMessage(
                      reporter,
                      messageNode,
                      msgDebugMode
                          ? errors.ErrorSeverity.ERROR
                          : errors.ErrorSeverity.INFO,
                      'checkingReturnTypesAndValues() INFO WHAT WE HAVE` expressions compared: $expression, $currentField. comparisonResult = ${comparisonResult}, comparisonResult2 = ${comparisonResult2}, wasUsedComparisonResult2 = $wasUsedComparisonResult2, isBetween: $isBetween, isRegExp: $isRegExp');

                  if (comparisonResult == null && comparisonResult2 == null) {
                    return;
                  }

                  // FIXME: When using the code from danno_script_lints_discovery_lab.dart (or danno_script_lints_discovery_lab.dart?) somewhere else take into account that
                  // "syntax" instances $IF() $THEN() don't allow for thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition = true;
                  // which is reserved for normal values - literals, variables
                  // but there maybe $BETWEEN(5, 10) IMPLEMENTED IN THE FUTURE it won't be "syntax" instance
                  if (!hasConditionSwitchedTo$NOT) {
                    thereWasAtLeastOneConditionElementBefore$NOTOr$IFOrEndOfTheCondition =
                        true;
                  }
                  if (comparisonResult == true) {
                    addLintMessage(
                        reporter,
                        messageNode,
                        msgDebugMode
                            ? errors.ErrorSeverity.ERROR
                            : errors.ErrorSeverity.INFO,
                        'checkingReturnTypesAndValues() comparisonResult the expression is not type so it should be a value to be compared like 0.345 or an instance of some class SomeClass()');
                    if (hasConditionSwitchedTo$NOT) {
                      addLintMessage(
                          reporter,
                          messageNode,
                          msgDebugMode
                              ? errors.ErrorSeverity.ERROR
                              : errors.ErrorSeverity.INFO,
                          'checkingReturnTypesAndValues() comparisonResult the expression matches value (not type) at least one \$() NOT CONDITION (after \$NOT)');
                      theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition =
                          true;
                    } else {
                      addLintMessage(
                          reporter,
                          messageNode,
                          msgDebugMode
                              ? errors.ErrorSeverity.ERROR
                              : errors.ErrorSeverity.INFO,
                          'checkingReturnTypesAndValues() comparisonResult the expression matches value (not type) at least one \$() NORMAL (not after \$NOT) CONDITION');
                      theParamMatchesAtLeastOneTypeOrValueRequirements = true;
                    }
                  } else if (comparisonResult2 == true) {
                    addLintMessage(
                        reporter,
                        messageNode,
                        msgDebugMode
                            ? errors.ErrorSeverity.ERROR
                            : errors.ErrorSeverity.INFO,
                        'checkingReturnTypesAndValues() comparisonResult2 the expression is not type so it should be a value to be compared like 0.345 or an instance of some class SomeClass()');
                    if (hasConditionSwitchedTo$NOT) {
                      addLintMessage(
                          reporter,
                          messageNode,
                          msgDebugMode
                              ? errors.ErrorSeverity.ERROR
                              : errors.ErrorSeverity.INFO,
                          'checkingReturnTypesAndValues() comparisonResult2 the expression matches value (not type) at least one \$() NOT CONDITION (after \$NOT)');
                      theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition =
                          true;
                    } else {
                      addLintMessage(
                          reporter,
                          messageNode,
                          msgDebugMode
                              ? errors.ErrorSeverity.ERROR
                              : errors.ErrorSeverity.INFO,
                          'checkingReturnTypesAndValues() the expression matches value (not type) at least one \$() NORMAL (not after \$NOT) CONDITION');
                      theParamMatchesAtLeastOneTypeOrValueRequirements = true;
                    }
                  } else {
                    addLintMessage(
                        reporter,
                        messageNode,
                        errors.ErrorSeverity.ERROR,
                        'checkingReturnTypesAndValues() comparisonResult = ${comparisonResult}, comparisonResult2 = ${comparisonResult2}, wasUsedComparisonResult2 = $wasUsedComparisonResult2, comparisonResult == null||comparisonResult==false which means for null the result was not comparable because of Expression types not handled yet (not implemented, or "impossible" to handle), or expressions are of different types, or if == false two expressions/objects were compared successfuly but not equal. Old (maybe not up to date) error info: Sort of Syntax Error due to the difficulty with implementing all features, to avoid this problem use only variable names (maybe required to be const (verify)) instead of direct values like [10, 20], but you can use 10, 2.5, \'abc\' not \'abc\$name wer\'. Also try to check out if some other types like the mentioned [10, 20] - handling them havent\'t been in the incoming versions, implemented At least one value hasn\'t been found or both values were found but one of them was received from Instance() object but te second from a DartObject?, while for a values like int it is not a problem, but for List or SomeClass() instance at the time of writig this message the two objects are represented by two different class instances. It is practical to temporary set up theParamMatchesAtLeastOneTypeOrValueRequirementsOf\$NOTPartOfTheCondition = true; how to fixit? expression causing problem: $expression, $currentField.');

                    /// ??? was: theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition = true;
                  }
                } else {
                  // .valueHasBeenFound == null changes the meaning of potential null of value.value below:
                  // isTheValueOfExpressionNull is null when not set up at all becaue the first if statement (hasExpressionTypeNullabilitySuffix)
                  // Why it is not a problem when the value was not found value.value value is not calculable,
                  // only for value.value == null it is always calculable;
                  // we know that because HERE we work on ultimate non-conditional final expressions where there is a type known:
                  // such an non-ultimate expression looks like this:
                  // int? abc = 20 + unknownNonConstantValue;
                  // abc ?? cde == null? null:2.5;
                  // the ultimate expressions we work here is abc, null and 2.5
                  // getting the null will never fail.
                  // 2.5 we know it is double but we don't need it's computed value.
                  // abc is uncalculable but we know it is int as 20 + anything is always int
                  // also unknownNonConstantValue + 20 is not null but as the declared type of abc is int? we know it must be int because you if unknownNonConstantValue == null then you can't add null + 20
                  // FIXME:
                  // [Last edit:] The final decision must be:
                  // the each ultimate expression (List<[ultimate]Expression)) from a variable must be taken.
                  // Types: Both for const and and variable. Because the declared num? might be be null, int, double but $($NOT double) says it all,
                  // Values: it doesn't matter
                  // [Edit:] not sufficient sleep: the below is not a problem as all variables have calculated value
                  // because of that you know if the value is null value or something else
                  // if something else it is calculated and get the underlying type
                  // but while it is true you can't get it's underlying type? to be compared here? guite a puzzle.
                  // FIXME: FIXME: PROBABLY FOUND THE BEST WAY TO SOLVE THE PROBLEM:
                  // LITERALS USE FOR F.E. LIST AND MAP also CollectionElement IT TURNS OUT Expression is implementing CollectionElement
                  // and while collection element might be ForElement and more only non expression element classes
                  // but literal probably it is only [Expression].
                  // SO IS there a CHANCE TO COMPARE IT WITH Itendtifier() BECAUSE
                  // Identifier() has .elements here each has [CollectionElement] and each rather "must" have Expression.
                  // But as i see two the same looking expressions might produce different values if a const [const1, const2] or variable with the same name produces different values
                  // !!! No? Possibly if you have NodeList<CollectionElement> for Identifier and ListLiteral
                  // !!! No? you might try to compare it with eqal ==
                  // what of instance of SomeClass()?
                  // we have InstanceCreationExpression(): f.e. expression.unParenthesized;
                  // then we have Itentifier which has elements CollectionElements (assuming is also Expression)
                  // it might be one element (can be more?)
                  // BUT WE CANNOT COMPUTE IT AS WITH LIST AND MAP AND SET WE CAN'T
                  // SO PROBABLY IT'S A MESS.
                  // THE ONLY WAY IT COULD BE DONE IS
                  // WHEN ALL COLLECTION ELEMENTS ARE CALCULATE LIKE [10, 2.8, 'some stRING', $constValueMaybeAAAAAAAAAAAAAAAAaa, SomeOtherClass()] (MAYBE LATER "STRING $a"),
                  // possibly also constructors with params like SomeClass(10, 2.8, 'some stRING', $constValueMaybe) (MAYBE LATER "STRING $a"),
                  // SomeClass(10, 2.8, 'some stRING', constValueMaybeAAAAAAAAAAAAAAAAaa, SomeOtherClass())
                  // SomeClass(10, 2.8, 'some stRING', constValueMaybeBBBBBBBBBBBBBBBBBBB, SomeOtherClass())
                  // constValueMaybeAAAAAAAAAAAAAAAAaa....computeConstantValue()! == $constValueMaybeBBBBBBBBBBBBBBBBBBB....computeConstantValue()!
                  // probably no need to check .isNull but make sure it returns for DartObject the same for isDartCoreInt for example like for non-typically-handled values.
                  // HOW COULD IT BE DONE FOR EACH COLLECTION ELEMENT:
                  // getUltimateNonConditionalNorSwitchExpressions GETS YOU EXPRESSIONS IN A UNIQUE ORDER
                  // SO BOTH COMARABLE each collectoin element expression must be equal if it is SomceClass(...) then the params are like collection elements so the list of returned expressions from the constructor must be comparable with other object - in the right order.
                  // SO WE KINDA VERY CLOSE TO SOLVE THE PROBLEM.
                  // IT COULD BE SO BECAUSE such constructed instances procuce always the same object (our value) exactly of the same class (class name must agree - dont know if cast as is a problem.).
                  // Also instances don't have to be created like const SomeClass - it is important that the constructor declaration is preceded with const.
                  // ======================
                  // I just noticed then that you may or may not have to calculate the the non-null type of unknownNonConstantValue;
                  // of course not simple int? but maybe Object? but it is String or List or SomeClass
                  // we haven't broke it down, did we?
                  // this is the only spot where we have to ignore declared type like Object?
                  // and get the final type of expression itself to get closer types
                  //
                  // REVISE IT AGAIN
                  // FIXME: END.
                  // so analyzer does it for you but this is breaking down the logic
                  // So the final expression is not null so the following correct:

                  String typeValueString =
                      currentField!.toTypeValue()!.getDisplayString();
                  // null when not set up:
                  bool? isTheValueOfExpressionNull;

                  if (typeValueString == "Null") {
                    // we have to check if it is just null, and fortunatelly you can calculate it whether it is Itentifier or BooleanLiteral (Literal)
                    var value = getComparableValueFromExpressionOrDartObject(
                        reporter,
                        returnStatements,
                        assignmentExpressionsByElementId,
                        variableDeclarationsByElementId,
                        expression);
                    if (value.valueHasBeenFound && value.value == null) {
                      isTheValueOfExpressionNull = true;
                    } else {
                      isTheValueOfExpressionNull == false;
                    }
                  }

                  //typeSystem.promoteToNonNull();
                  addLintMessage(
                      reporter,
                      messageNode,
                      errors.ErrorSeverity.INFO,
                      'checkingReturnTypesAndValues meta param value is Type. isTheValueOfExpressionNull = $isTheValueOfExpressionNull, typeSystem.isSubtypeOf(expression.staticType!, currentField.toTypeValue()!) = ${typeSystem.isSubtypeOf(expression.staticType!, currentField!.toTypeValue()!)} , expression.staticType = ${expression.staticType}, currentField.toTypeValue() = ${currentField!.toTypeValue()}');
                  if (expression.staticType == null) {
                    addLintMessage(
                        reporter,
                        messageNode,
                        errors.ErrorSeverity.ERROR,
                        'checkingReturnTypesAndValues Error: it is unexpected that expression.staticType == null');
                    continue;
                  }
                  if (typeValueString == '\$NOT') {
                    hasConditionSwitchedTo$NOT = true;
                    hasConditionSwitchedTo$Nullable = false;
                    hasConditionSwitchedTo$Mutable = false;
                  } else if (typeValueString == '\$N') {
                    hasConditionSwitchedTo$Nullable = true;
                  } else if (typeValueString == '\$M') {
                    hasConditionSwitchedTo$Mutable = true;
                  } else if ((typeValueString == "Null" &&
                          isTheValueOfExpressionNull == true) ||
                      typeSystem.isSubtypeOf(expression.staticType!,
                          currentField!.toTypeValue()!)) {
                    if (hasConditionSwitchedTo$NOT) {
                      theParamMatchesAtLeastOneTypeOrValueRequirementsOf$NOTPartOfTheCondition =
                          true;
                      addLintMessage(
                          reporter,
                          messageNode,
                          errors.ErrorSeverity.INFO,
                          'info: after \$NOT matches: expression = ${expression}, currentField.type = ${currentField!.type}');
                    } else {
                      addLintMessage(
                          reporter,
                          messageNode,
                          errors.ErrorSeverity.INFO,
                          'info: before \$NOT matches: expression = ${expression}, currentField.type = ${currentField!.type}');
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
                addLintMessage(
                    reporter,
                    messageNode,
                    errors.ErrorSeverity.ERROR,
                    'Error: A return statement expression/value is not of required type nor value, if expression is complex with possible multiple ulitmate possible value returns i means that at least one of the sub values is not meeting the expectations of a returned value: expression = ${expression.toSource()}');
              }
            }
          }
        } catch (e, stackTrace) {
          addLintMessage(
              reporter,
              methodDeclaration,
              errors.ErrorSeverity.ERROR,
              'Lint plugin exception: $e $stackTrace');
        }
      }
    }

    ({
      List<Expression> expressions,
      Expando<Identifier> topLevelIdentifiersProducingExpressions,
      bool wasThereAnyEmptyReturnStatement,
      bool wasThereAnyEmptyFunctionBody
    }) getAllExpressionsInfoFromFunctionBody(FunctionBody body,
        [Expando<Identifier>?
            topLevelIdentifiersProducingExpressionsSupplied]) {
      bool wasThereAnyEmptyReturnStatement = false;
      bool wasThereAnyEmptyFunctionBody = false;
      List<Expression> expressions = [];
      Expando<Identifier> topLevelIdentifiersProducingExpressions =
          topLevelIdentifiersProducingExpressionsSupplied ??
              Expando<Identifier>();
      if (body is BlockFunctionBody) {
        // DOESN'T WORK! DONE DIFFERENTLY
        // THE PROBLEM WAS THAT THE RETURN STATEMENTS MUST BE IMMEDIATE CHILDREN
        // NOT SOMETHING IN NESTED STUFF
        //body.block.statements.forEach((Statement statement) {
        //  if (statement is ReturnStatement) {
        //    if (statement.expression != null) {
        //      expressions.addAll(getUltimateNonConditionalNorSwitchExpressions(
        //              statement.expression!)
        //          .expressions);
        //    } else {
        //      wasThereAnyEmptyReturnStatement = true;
        //    }
        //  }
        //});
        if (returnStatements[body.parent] != null) {
          for (ReturnStatement returnStatement
              in returnStatements[body.parent]!) {
            if (returnStatement.expression != null) {
              expressions.addAll(getUltimateNonConditionalNorSwitchExpressions(
                      reporter,
                      returnStatements,
                      variableDeclarationsByElementId,
                      assignmentExpressionsByElementId,
                      returnStatement.expression!,
                      topLevelIdentifiersProducingExpressions)
                  .expressions);
            } else {
              wasThereAnyEmptyReturnStatement = true;
            }
          }
        }
      } else if (body is ExpressionFunctionBody) {
        expressions = getUltimateNonConditionalNorSwitchExpressions(
                reporter,
                returnStatements,
                variableDeclarationsByElementId,
                assignmentExpressionsByElementId,
                body.expression,
                topLevelIdentifiersProducingExpressions)
            .expressions;
      } else if (body is EmptyFunctionBody) {
        wasThereAnyEmptyFunctionBody = true;
      }
      return (
        expressions: expressions,
        topLevelIdentifiersProducingExpressions:
            topLevelIdentifiersProducingExpressions,
        wasThereAnyEmptyReturnStatement: wasThereAnyEmptyReturnStatement,
        wasThereAnyEmptyFunctionBody: wasThereAnyEmptyFunctionBody
      );
    }

    /// Any funtion like declaration has //[BlockFunctionBody] | [EmptyFunctionBody] | [ExpressionFunctionBody] | [NativeFunctionBody]
    /// this handles all except BlockFunctionBody, BlockFunctionBody has ReturnStatements the rest no.
    /// this is called form constext.registry.addMethodDeclaration it is handling all method declaration that have no [FunctionBlockBody] but the rest like empty, or expression
    /// Compare with handlingMethodDeclarationForFunctionBlockBodyReturnStatement which is for the rest of situations.
    handlingMethodDeclarationForNonFunctionBlockBody(
        MethodDeclaration methodDeclaration) {}

    /// Any funtion like declaration has //[BlockFunctionBody] | [EmptyFunctionBody] | [ExpressionFunctionBody] | [NativeFunctionBody]
    /// this handles only BlockFunctionBody with it's ReturnStatements
    /// this is not called form constext.registry.addMethodDeclaration but is called from addReturnStatement
    /// Compare with handlingMethodDeclarationForNonFunctionBlockBody which is for the rest of situations.
    handlingFunctionLikeDeclaration(dynamic declaration) {
      FunctionBody body;
      if (declaration is MethodDeclaration) {
        body = declaration.body;
      } else if (declaration is FunctionDeclaration) {
        body = declaration.functionExpression.body;
      } else if (declaration is FunctionExpression) {
        body = declaration.body;
      } else {
        // because the declaration param is dynamic we need to inform, and throw - never should happen in production so it is of diagnostic nature during initial steges of development
        String message =
            'handlingFunctionLikeDeclaration error: declaration param is not of the required function-like types because the declaration param is dynamic we need to inform, and throw - never should happen in production so it is of diagnostic nature during initial steges of development';
        addLintMessage(
            reporter, declaration, errors.ErrorSeverity.ERROR, message);
        throw Exception(message);
      }

      try {
        final (
          :expressions,
          :topLevelIdentifiersProducingExpressions,
          :wasThereAnyEmptyReturnStatement,
          :wasThereAnyEmptyFunctionBody
        ) = getAllExpressionsInfoFromFunctionBody(body);

        addLintMessage(reporter, declaration, errors.ErrorSeverity.WARNING,
            'handlingFunctionLikeDeclaration: wasThereAnyEmptyReturnStatement = $wasThereAnyEmptyReturnStatement, wasThereAnyEmptyFunctionBody = $wasThereAnyEmptyFunctionBody, expressions.length ${expressions.length}, expressions: ${expressions}');
        if (declaration is MethodDeclaration) {
          addLintMessage(reporter, declaration, errors.ErrorSeverity.WARNING,
              'handlingFunctionLikeDeclaration: calling checkingReturnTypesAndValues WARNING WARNING - PROBABLY FunctionDeclaration could be used as param for the method, but now focusing on MethodDeclaration. At the same time FunctionExpression is not allowed here expressions.length=${expressions.length}');
          try {
            checkingReturnTypesAndValues(declaration, expressions,
                topLevelIdentifiersProducingExpressions);
          } catch (e, stackTrace) {
            addLintMessage(reporter, declaration, errors.ErrorSeverity.ERROR,
                'handlingFunctionLikeDeclaration: error: e = $e, stackTrace = $stackTrace');
          }
        } else {
          addLintMessage(reporter, declaration, errors.ErrorSeverity.WARNING,
              'handlingFunctionLikeDeclaration: NOT calling checkingReturnTypesAndValues');
        }
      } catch (e, stackTrace) {
        addLintMessage(reporter, declaration, errors.ErrorSeverity.WARNING,
            'handlingFunctionLikeDeclaration: CATCHED ERROR: e = $e, stackTrace = $stackTrace');
      }
      return;

      //whatIsCalledFirst.add(false);
      //methodDeclarations.add(methodDeclaration);
      //try {
      //  methodBodies[methodDeclaration.body] = methodDeclaration;
      //  //BlockFunctionBody] | [EmptyFunctionBody] | [ExpressionFunctionBody] | [NativeFunctionBody
      //  if (methodDeclaration.body is ExpressionFunctionBody) {
      //    var expression =
      //        (methodDeclaration.body as ExpressionFunctionBody).expression;
      //    // condition ? int : double; == num , condition ? String : double; Object
      //    ParenthesizedExpression; // .expression;
      //    ConditionalExpression; // probably including version "??"" and with .thenExpression, .elseExpression
      //    SwitchExpression; // .cases which are NodeList<SwitchExpressionCase> .expression for a case;
      //    addLintMessage(reporter,
      //        expression,
      //        errors.ErrorSeverity.WARNING,
      //        'addMethodDeclaration: whatIsCalledFirst = $whatIsCalledFirst , This is ExpressionFunctionBody expression runtimeType = ${expression.runtimeType} expression.type = ${expression.staticType} ${getUltimateNonConditionalNorSwitchExpressions(
      //          expression,
      //        ).expressions.length}');
      //
      //    NodeList<FormalParameter>? parameters =
      //        methodDeclaration.parameters?.parameters;
      //    if (parameters != null) {
      //      for (int i = 0; i < parameters.length; i++) {
      //        FormalParameterList;
      //        FormalParameter;
      //        NormalFormalParameter; // required
      //        DefaultFormalParameter; // having defaultvalue so not required [Expression]? get defaultValue;
      //        if (parameters[i] is DefaultFormalParameter) {
      //          var param = parameters[i] as DefaultFormalParameter;
      //          addLintMessage(reporter,param, errors.ErrorSeverity.WARNING,
      //              'addMethodDeclaration: This is parameter defaultValue, i: $i expression = ${param.defaultValue?.toSource()}, number of elements extracted: ${param.defaultValue != null ? getUltimateNonConditionalNorSwitchExpressions(param.defaultValue!).expressions.length : '... no element? Really? At least one should be.'}');
      //        }
      //      }
      //    }
      //  }
      //} catch (e, stackTrace) {
      //  addLintMessage(reporter,methodDeclaration, errors.ErrorSeverity.INFO,
      //      'Lint plugin exception: $e $stackTrace');
      //}
    }

    context.registry
        .addMethodDeclaration(handlingMethodDeclarationForNonFunctionBlockBody);

    /// Any funtion like declaration has //[BlockFunctionBody] | [EmptyFunctionBody] | [ExpressionFunctionBody] | [NativeFunctionBody]
    /// this handles all except BlockFunctionBody, BlockFunctionBody has ReturnStatements the rest no.
    /// this is called form constext.registry.addMethodDeclaration it is handling all method declaration that have no [FunctionBlockBody] but the rest like empty, or expression
    /// Compare with handlingMethodDeclarationForFunctionBlockBodyReturnStatement which is for the rest of situations.
    handlingFunctionExpressionForNonFunctionBlockBody(
        FunctionExpression functionExpression) {}

    /// Any funtion like declaration has //[BlockFunctionBody] | [EmptyFunctionBody] | [ExpressionFunctionBody] | [NativeFunctionBody]
    /// this handles only BlockFunctionBody with it's ReturnStatements
    /// this is not called form constext.registry.addMethodDeclaration but is called from addReturnStatement
    /// Compare with handlingMethodDeclarationForNonFunctionBlockBody which is for the rest of situations.
    handlingFunctionExpressionForFunctionBlockBodyReturnStatement(
        FunctionExpression functionExpression) {
      final (
        :expressions,
        :topLevelIdentifiersProducingExpressions,
        :wasThereAnyEmptyReturnStatement,
        :wasThereAnyEmptyFunctionBody
      ) = getAllExpressionsInfoFromFunctionBody(functionExpression.body);

      addLintMessage(reporter, functionExpression, errors.ErrorSeverity.WARNING,
          'handlingFunctionExpressionForFunctionBlockBodyReturnStatement: wasThereAnyEmptyReturnStatement = $wasThereAnyEmptyReturnStatement, wasThereAnyEmptyFunctionBody = $wasThereAnyEmptyFunctionBody, expressions.length ${expressions.length}, expressions: ${expressions}, topLevelIdentifiersProducingExpressions == ${topLevelIdentifiersProducingExpressions}');
      return;
    }

    context.registry.addFunctionExpression(
        handlingFunctionExpressionForNonFunctionBlockBody);

    handleReturnStatement(ReturnStatement returnStatement) {
      whatIsCalledFirst.add(true);
      AstNode? parentNode = returnStatement.parent;
      addLintMessage(reporter, returnStatement, errors.ErrorSeverity.INFO,
          'Return statement. Entered the method.');
      BlockFunctionBody;
      EmptyFunctionBody;
      NativeFunctionBody; // ignoring now, we want to be cross-platform for now
      ExpressionFunctionBody;
      // function, clause, method declarations:
      // .parent leads as (should) to:
      MethodDeclaration; // not the same or is as FunctionDeclaration, FunctionExpression;
      FunctionDeclaration; // local or top level, not the same or is as MethodDeclaration, FunctionExpression;
      // [!!!! EDIT: we have three of them FunctionExpression is this with no function/method name]
      /* expression gets you */ FunctionExpression; // and this gets you known .parameters
      // WARNING It might be that for clauses you get eighter FunctionDeclaration or FunctionExpression;
      // LOGICALLY SHLOULD BE FunctionDeclaration;
      // Also the following invokation classes as you see occur not in the third form FunctionExpression
      FunctionExpression; // equivalent of above declarations and not implemening MethodDeclaration, FunctionDeclaration;
      InvocationExpression; // The invocation of a function or method.
      // !!!!!! context.registry.addInvocationExpression();
      // !!! This will !!! either be a [FunctionExpressionInvocation] or a [MethodInvocation].
      /* one */ FunctionExpressionInvocation;
      /* two */ MethodInvocation;

      while (parentNode != null) {
        if (parentNode is FunctionBody) {
          int? id;
          if (parentNode.parent is MethodDeclaration) {
            id = (parentNode.parent as MethodDeclaration)
                .declaredElement
                ?.declaration
                .id;

            addLintMessage(
                reporter,
                returnStatement,
                errors.ErrorSeverity.ERROR,
                '.addReturnStatement parentNode is MethodDeclaration, id = $id');
          } else if (parentNode.parent is FunctionExpression) {
            id = (parentNode.parent as FunctionExpression).declaredElement?.id;
            addLintMessage(
                reporter,
                returnStatement,
                errors.ErrorSeverity.ERROR,
                '.addReturnStatement parentNode is FunctionExpression, id = $id');
          } else if (parentNode.parent is FunctionDeclaration) {
            id = (parentNode.parent as FunctionDeclaration)
                .declaredElement
                ?.declaration
                .id;
            addLintMessage(
                reporter,
                returnStatement,
                errors.ErrorSeverity.ERROR,
                '.addReturnStatement parentNode is FunctionDeclaration, id = $id');
          }
          if (id == null) {
            addLintMessage(
                reporter,
                returnStatement,
                errors.ErrorSeverity.ERROR,
                '.addReturnStatement We never expect id == null');
            break;
          }

          /// below not needed probably
          if (returnStatements[id] == null) {
            returnStatements[id] = [];
            returnStatements[parentNode.parent] = [];
          }
          returnStatements[id]!.add(returnStatement);
          returnStatements[parentNode.parent]!.add(returnStatement);
          if (parentNode is ExpressionFunctionBody) {
            var expression = parentNode.expression;
            addLintMessage(
                reporter,
                returnStatement,
                errors.ErrorSeverity.WARNING,
                'This is ExpressionFunctionBody expression.type = ${expression.staticType}');
          }

          addLintMessage(reporter, returnStatement, errors.ErrorSeverity.INFO,
              'We\'ve found the method declaration for this return statement. is MethodDeclaration ${parentNode.parent is MethodDeclaration}, is FunctionDeclaration ${parentNode.parent is FunctionDeclaration}, current returnStatement object for this id returnStatements[id] = ${returnStatements[id]}');
          return;
        }
        parentNode = parentNode.parent;
      }
    }

    context.registry.addReturnStatement(handleReturnStatement);

    // [FunctionExpressionInvocation]: "Invocations of methods and other forms of functions are represented by MethodInvocation nodes."
    // so method is to be also for normal declared functions so it would be inconsistent with existing three not two
    // addMethodDeclaration addFunctionDeclaration addFunctionExpression
    context.registry
        .addFunctionExpressionInvocation((FunctionExpressionInvocation inv) {});

    // See the addMethodInvocation description above
    context.registry.addMethodInvocation((MethodInvocation inv) {
      inv.argumentList.arguments.first.staticParameterElement
          ?.computeConstantValue();
      // FIXME: not fixme just to grab your (mine - for me but different people can learn from it) attention.
      // TO SUM UP;
      // can work with arg that is simple literals like arg is DoubleLiteral
      // double, int, String, but it is SimpleStringLiteral not StringInterpolation
      // ====================
      // FIXME: after implementing all the rest i could return to StringInterpolation as i understand the calculation
      // of the expressions better. Cannot 100% calculate method/function or function expression invokaiton
      // ====================
      // FIXME: like with function like,
      // DartObject .toFunctionValue returns ExecutableElement? - not executed but description
      // Also
      // var functionInv = someobject as FunctionExpressionInvocation;
      // functionInv.staticElement; is also ExecutableElement?
      // it might be that it is not null when the result was computed (or no)
      // Comparing two instances of ExecutableElement might be with the following rule.
      // suggest it might be sort of the result so abc(1) == abc(1) but abc(1) != abc(2) - mean not params but RESULT of this might be comparable like other.
      // ====================
      // you might try (read for however), ${arg.name}, ${arg.staticElement?.id} ${arg.staticElement?.declaration}
      // This must be VariableElement, (FIXME: warning when it is checked for metadata of VariableElement it threw catchable error - it is about when metadata had no .last element - it must but possibly internal problem. see how i wrote the code not to throw - check if metadata.length > 0 and don't use .last for now)
      // we have computeConstantValue (DartObject or null if failed) - we have two options check if two DartObject's are == equal
      // #If it is not that simple# we can still evaluate them to toBoolValue, but also toListValue so the only way we could use Lists.
      // Also works with custom objects like a custom class instance.
      // How a DartObject compares to another DartObject == ?
      // SUCCESS for complicated const instances!!!
      // it compares it correctly as below where in main.dart we have method definition and comparing with first method param annotation @$(...) instance
      // methodOne3(@$(num, String, Null, $NOT, int, 5.3) abcd)
      // when you create constant like below only jack.methodOne3(oneDollar); is true as twoDollar has 5.2 as last element.
      //// the same like methodOne3 @$ annotation
      //const oneDollar = $(num, String, Null, $NOT, int, 5.3);
      //// ALMOST the same like methodOne3 @$ annotation - last element not 5.3 but 5.2
      //const twoDollar = $(num, String, Null, $NOT, int, 5.2);
      //// compare see lint message
      //jack.methodOne3(oneDollar); true
      //jack.methodOne3(twoDollar); false

      final List<ElementAnnotation>? metad =
          inv.argumentList.arguments.first.staticParameterElement?.metadata;
      DartObject? exampleDollarInstanceToCompare;

      if (metad != null &&
          metad.isNotEmpty &&
          metad.last.element?.displayName == "\$") {
        if (inv.argumentList.arguments.first.staticType == null) {
          // throw?
          // Alternative usage:
          //((inv.argumentList.arguments.first.staticParameterElement?.metadata.first.element?.declaration as ClassMember) as FieldDeclaration).fields.variables.first.initializer;
        }
        bool hasBeenExceptionForTheCurrentNode = false;
        if (inv.argumentList.arguments.first.staticParameterElement?.declaration
                .library ==
            null) {
          exampleDollarInstanceToCompare = metad.last.computeConstantValue();

          // throw?
        }
      }
      DartObject? computedMetaObject =
          metad?.last.computeConstantValue() as DartObject?;
      DartObject? computedMetaObject2 =
          metad?.last.computeConstantValue() as DartObject?;

      Expression? arg = inv.argumentList.arguments.first;
      addLintMessage(reporter, inv, errors.ErrorSeverity.WARNING,
          '''Param 1: Expression: but is it of any type?: ${() {
        return (arg is CommentReferableExpression
                ? 'CommentReferableExpression and ${arg is ConstructorReference ? 'ConstructorReference' : arg is PropertyAccess ? 'PropertyAccess' : 'none additional of interest'}'
                : 'It is not CommentReferableExpression with other related implementers/extenders') +
            '\n\n' +
            (arg is DoubleLiteral
                ? 'DoubleLiteral ${arg.value}'
                : arg is IntegerLiteral
                    ? 'IntegerLiteral ${arg.value}'
                    : arg is StringLiteral
                        ? 'StringLiteral value:  ${arg.stringValue}, # sort of:${arg is SimpleStringLiteral ? 'SimpleStringLiteral' : arg is StringInterpolation ? 'StringInterpolation ${arg.firstString} ${arg.lastString} ${() {
                            String data = 'Gathering some info: ';
                            for (int i = 0; i < arg.elements.length; i++) {
                              if (arg.elements[i] is InterpolationExpression) {
                                data +=
                                    'i:$i is InterpolationExpression: nothing like .value ${(arg.elements[i] as InterpolationExpression).expression} ${(arg.elements[i] as InterpolationExpression).expression.runtimeType}';
                              } else if (arg.elements[i]
                                  is InterpolationString) {
                                data +=
                                    'i:$i is InterpolationString: ${(arg.elements[i] as InterpolationString).value}';
                              } else {
                                data +=
                                    'i:$i is none: InterpolationExpression nor InterpolationString';
                              }
                            }
                            return data;
                          }()}' : 'none important here'}'
                        : arg is ListLiteral
                            ? 'ListLiteral ([Edit: String \'Some \$abc wer\' is seen \'Some \$abc wer\' so you can\'t convert it so the same with everything - no useful] ast so astNode - if you try to get an AstNode to compare then maybe == would work) ${arg.elements.first} ${arg.elements}'
                            : arg is Identifier
                                ? 'Identifier can\'t compute, but have something  ${arg.name}, ${arg.staticElement?.id}, ${arg.staticElement?.nonSynthetic.id} ${arg.staticElement?.declaration?.id}, ${arg.staticElement?.nonSynthetic.declaration?.id}, is VariableElement ${arg.staticElement is VariableElement}, has declaration VariableElement ${arg.staticElement?.declaration is VariableElement} computeConstantValue: ${() {
                                    var computedValue =
                                        (arg.staticElement as VariableElement)
                                            .computeConstantValue();
                                    String whattoreturn = arg.staticElement
                                            is VariableElement
                                        ? computedValue.toString()
                                        : 'not VariableElement so cannot compute.';

                                    whattoreturn +=
                                        'computed meta object - f.e. first param @\$(...) annotation of the called method\'s method declaration looks like this $computedMetaObject , How do two objects compare with == ? computedMetaObject == computedValue : ${computedMetaObject == computedValue} ${computedMetaObject == computedMetaObject2}';

                                    return whattoreturn;
                                  }()} ${() {
                                    if (arg.staticElement?.declaration
                                                ?.metadata !=
                                            null &&
                                        arg.staticElement!.declaration!.metadata
                                                .length >
                                            0) {
                                      return arg.staticElement!.declaration!
                                          .metadata[arg.staticElement!
                                              .declaration!.metadata.length -
                                          1];
                                    }
                                  }()}'
                                : 'nothing found');
      }()}''');
    });

    context.registry
        .addVariableDeclaration((VariableDeclaration variableDeclaration) {
      if (variableDeclaration.declaredElement?.nonSynthetic.id != null) {
        if (variableDeclarationsByElementId[
                variableDeclaration.declaredElement!.nonSynthetic.id] ==
            null) {
          variableDeclarationsByElementId[
              variableDeclaration.declaredElement!.nonSynthetic.id] = [];
        }
        variableDeclarationsByElementId[
                variableDeclaration.declaredElement!.nonSynthetic.id]!
            .add(variableDeclaration);
        addLintMessage(reporter, variableDeclaration, errors.ErrorSeverity.INFO,
            'addVariableDeclaration, expression has been added: variableDeclaration.declaredElement!.id ${variableDeclaration.declaredElement!.id} variableDeclaration.declaredElement!.nonSynthetic.id ${variableDeclaration.declaredElement!.nonSynthetic.id}');
      } else {
        // diagnostic error message
        addLintMessage(
            reporter,
            variableDeclaration,
            errors.ErrorSeverity.ERROR,
            'addVariableDeclaration, variableDeclaration.declaredElement?.id == null which is unexpected situation');
      }
    });

    context.registry
        .addAssignmentExpression((AssignmentExpression assignmentExpression) {
      var readElement = assignmentExpression.readElement;
      var writeElement = assignmentExpression.writeElement;

      if (writeElement?.id != null) {
        if (assignmentExpressionsByElementId[writeElement!.id] == null) {
          assignmentExpressionsByElementId[writeElement.id] = [];
        }
        assignmentExpressionsByElementId[writeElement.id]!
            .add(assignmentExpression);
        addLintMessage(
            reporter,
            assignmentExpression,
            errors.ErrorSeverity.INFO,
            'addAssignmentExpression, expression has been added: writeElement?.id ${writeElement.nonSynthetic.id}, writeElement?.id ${writeElement.nonSynthetic.id} ');
      } else {
        // diagnostic error message
        addLintMessage(
            reporter,
            assignmentExpression,
            errors.ErrorSeverity.ERROR,
            'addAssignmentExpression, writeElement?.id == null which is unexpected situation');
      }

      if (readElement is LocalVariableElement) {
      } else if (readElement is ParameterElement) {
      } else if (readElement is ParameterElement) {}
      if (readElement != null) {
        reporter.atElement(
            readElement /*.parent!*/,
            LintCode(
                name: 'anno_types_warning',
                problemMessage: 'Here we are readElement',
                errorSeverity: errors.ErrorSeverity.WARNING));
      }
      if (writeElement is LocalVariableElement) {
      } else if (writeElement is ParameterElement) {}
      if (writeElement != null) {
        reporter.atElement(
            writeElement /*.parent!*/,
            LintCode(
                name: 'anno_types_warning',
                problemMessage:
                    'Here we are writeElement ${writeElement.metadata}',
                errorSeverity: errors.ErrorSeverity.WARNING));
      }

      /// MOST PROBABLY WE WONT IMPLEMENT VALUES BU TYPES IN EVERYTHING AS IT IS NOW.
      Identifier; // Expression as Identifier for method-invokation (the method's) invokation arguments .
      // .staticElement: The element associated with this identifier based on static type information,
      // if it is VariableElement i you can compute value, get declaration, isConst
      // you may try with LocalElement An element that can be (but is not required to be) defined within a method or function
      // ParameterElement probably implements both LocalElement and the mentioned VariableElement
      // You can try https://pub.dev/documentation/analyzer/6.8.0/dart_element_element/Element-class.html
      // if element is of any of the interfaces mentioned there on the page.
      // possibly could hope htat method(const [1, 2]) can be calculated as VariableElement or LocalElement - or not
      // but identifier method(identifierone) has greater chances to be resolved.
      //
      //[Edit: will be handled by a function/method:writeElement
      Expression; // can also be:
      ParenthesizedExpression; // .expression;
      ConditionalExpression; // probably including version "??"" and with .thenExpression, .elseExpression
      SwitchExpression; // .cases which are NodeList<SwitchExpressionCase> .expression for a case;

      //]

      Identifier;
      /*derived from*/ Expression;
      // the below is possibilities - maybe ListLiteral helps
      BooleanLiteral; // .value bool
      DoubleLiteral; // .value double
      IntegerLiteral; // similarly
      ListLiteral; // FIXME: - CANNOT COMPUTE, DOUBLE MAYBE EVEN STRING I COULD f.e. cannot compute value but have elements NodeList<CollectionElement> but cannot compute value of them
      NullLiteral;
      SetOrMapLiteral;
      RecordLiteral; // and more
      // now string literals
      StringLiteral; // .stringValue docs mentions both const settings but also null if the string isn't a constant string [?! the following:] without any string interpolation. May mean that string has no const features (not neccesary declared const), but if the string isn't const but has interpolation it is not null so looks like mistaken documentation because i would think of a string that cannot be const and can be const but without interpolation.
      // from StringLiteral
      SimpleStringLiteral;
      AdjacentStrings;
      StringInterpolation;
      addLintMessage(
          reporter,
          assignmentExpression,
          errors.ErrorSeverity.WARNING,
          'addAssignmentExpression, readElement?.id: ${readElement?.id}, writeElement?.id: ${writeElement?.id} writeElement?.nonSynthetic.id: ${writeElement?.nonSynthetic.id} leftHandSide: readElement.name ${readElement?.name} writeElement.name ${writeElement?.name} This is ExpressionFunctionBody assignmentExpression.leftHandSide.staticParameterElement: ${assignmentExpression.leftHandSide.staticParameterElement}, assignmentExpression.leftHandSide.unParenthesized.toString(): ${assignmentExpression.leftHandSide.unParenthesized.toString()}');
      addLintMessage(
          reporter,
          assignmentExpression,
          errors.ErrorSeverity.WARNING,
          'addAssignmentExpression, readElement?.id: ${readElement?.id}, writeElement?.id: ${writeElement?.id} writeElement?.nonSynthetic.id: ${writeElement?.nonSynthetic.id} rightHandSide: This is ExpressionFunctionBody assignmentExpression.rightHandSide.unParenthesized.toString() = ${assignmentExpression.rightHandSide.unParenthesized.toString()} ');
    });

    List<dynamic> functionLikeDeclarations = [];
    context.registry
        .addMethodDeclaration((MethodDeclaration methodDeclaration) {
      methodDeclaration.parameters?.parameterElements.first
          ?.computeConstantValue();
      functionLikeDeclarations.add(methodDeclaration);
    });
    context.registry
        .addFunctionDeclaration((FunctionDeclaration functionDeclaration) {
      functionLikeDeclarations.add(functionDeclaration);
    });
    context.registry
        .addFunctionExpression((FunctionExpression functionExpression) {
      functionLikeDeclarations.add(functionExpression);
    });

    context.addPostRunCallback(() {
      //for (List<ReturnStatement> value in returnStatements.values) {
      //  for (ReturnStatement statement in value) {
      //    addLintMessage(reporter,statement, errors.ErrorSeverity.WARNING,
      //        'addPostRunCallback: was called for this return statement');
      //  }
      //}

      for (dynamic declaration
          in functionLikeDeclarations /*returnStatements.keys*/) {
        if (declaration is int) {
          continue;
        }
        handlingFunctionLikeDeclaration(declaration);
      }
    });
  }

  @override
  List<Fix> getFixes() => [];
}
