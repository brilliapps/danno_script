class $<T, U> implements Type {
  final bool is$ = true;
  final dynamic t1;
  final dynamic t2;
  final dynamic t3;
  final dynamic t4;
  final dynamic t5;
  final dynamic t6;
  final dynamic t7;
  final dynamic t8;
  final dynamic t9;
  final dynamic t10;
  final dynamic t11;
  final dynamic t12;
  final dynamic t13;
  final dynamic t14;
  final dynamic t15;
  final dynamic t16;
  final dynamic t17;
  final dynamic t18;
  final dynamic t19;
  final dynamic t20;
  final dynamic t21;
  final dynamic t22;
  final dynamic t23;
  final dynamic t24;
  final dynamic t25;
  final dynamic t26;
  final dynamic t27;
  final dynamic t28;
  final dynamic t29;
  final dynamic t30;
  final dynamic t31;
  final dynamic t32;
  final dynamic t33;
  final dynamic t34;
  final dynamic t35;
  final dynamic t36;
  final dynamic t37;
  final dynamic t38;
  final dynamic t39;
  final dynamic t40;
  final dynamic t41;
  final dynamic t42;
  final dynamic t43;
  final dynamic t44;
  final dynamic t45;
  final dynamic t46;
  final dynamic t47;
  final dynamic t48;
  final dynamic t49;
  final dynamic t50;
  final dynamic t51;
  final dynamic t52;
  final dynamic t53;
  final dynamic t54;
  final dynamic t55;
  final dynamic t56;
  final dynamic t57;
  final dynamic t58;
  final dynamic t59;
  final dynamic t60;
  final dynamic t61;
  final dynamic t62;
  final dynamic t63;
  final dynamic t64;
  final dynamic t65;
  final dynamic t66;
  final dynamic t67;
  final dynamic t68;
  final dynamic t69;
  final dynamic t70;
  final dynamic t71;
  final dynamic t72;
  final dynamic t73;
  final dynamic t74;
  final dynamic t75;
  final dynamic t76;
  final dynamic t77;
  final dynamic t78;
  final dynamic t79;
  final dynamic t80;
  final dynamic t81;
  final dynamic t82;
  final dynamic t83;
  final dynamic t84;
  final dynamic t85;
  final dynamic t86;
  final dynamic t87;
  final dynamic t88;
  final dynamic t89;
  final dynamic t90;
  final dynamic t91;
  final dynamic t92;
  final dynamic t93;
  final dynamic t94;
  final dynamic t95;
  final dynamic t96;
  final dynamic t97;
  final dynamic t98;
  final dynamic t99;
  final dynamic t100;
  const $([
    this.t1,
    this.t2,
    this.t3,
    this.t4,
    this.t5,
    this.t6,
    this.t7,
    this.t8,
    this.t9,
    this.t10,
    this.t11,
    this.t12,
    this.t13,
    this.t14,
    this.t15,
    this.t16,
    this.t17,
    this.t18,
    this.t19,
    this.t20,
    this.t21,
    this.t22,
    this.t23,
    this.t24,
    this.t25,
    this.t26,
    this.t27,
    this.t28,
    this.t29,
    this.t30,
    this.t31,
    this.t32,
    this.t33,
    this.t34,
    this.t35,
    this.t36,
    this.t37,
    this.t38,
    this.t39,
    this.t40,
    this.t41,
    this.t42,
    this.t43,
    this.t44,
    this.t45,
    this.t46,
    this.t47,
    this.t48,
    this.t49,
    this.t50,
    this.t51,
    this.t52,
    this.t53,
    this.t54,
    this.t55,
    this.t56,
    this.t57,
    this.t58,
    this.t59,
    this.t60,
    this.t61,
    this.t62,
    this.t63,
    this.t64,
    this.t65,
    this.t66,
    this.t67,
    this.t68,
    this.t69,
    this.t70,
    this.t71,
    this.t72,
    this.t73,
    this.t74,
    this.t75,
    this.t76,
    this.t77,
    this.t78,
    this.t79,
    this.t80,
    this.t81,
    this.t82,
    this.t83,
    this.t84,
    this.t85,
    this.t86,
    this.t87,
    this.t88,
    this.t89,
    this.t90,
    this.t91,
    this.t92,
    this.t93,
    this.t94,
    this.t95,
    this.t96,
    this.t97,
    this.t98,
    this.t99,
    this.t100,
  ]);

  methodabc() => null;
}

/// You can use this class like this:
/// $($IF......), $($IF()......),
/// but extending classes must call a constructor like this:
/// $($CUSTOMIFINSTANCE())
/// this is because i don't know any other way to get to know if it is the $IF super class also than by using getField('is$IF')?.toBoolValue();
/// The same for the $, $then, etc. and all will be related to the myCustomGetCustomLint method
/// Decided to implemented now - having no time because this $IF... feature may will not be implemented (it was mentioned by a core dart developer in 2022 or 2023) - it is not on the dart-team list to be implemented probably, but the union types themselves are on the list but couting from 2024 they may not arrive in the following year as it's been on the waiting like f.e. 7 years already.
/// WARNING! $IF... It could get even more verbose and not to match the real life scenario needs, and also never be implemented by this.
/// So the $IF... is really much reasonably.
/// The real life scenario - if an element has no null value then other must be null or not null
/// It may involve a couple of elements.
/// When possible vis custom_lint package in the future
/// then this value ready (means value of Type) solution will handle f.e. Strings - if a param is int or "Hello!"
/// [$IF] CAN BE EXTENDED.
/// and it is simple to get that no $ORTHEN is needed
/// FIRST GOES TYPES FOR THE PARAM
/// THEN A CONDITION $IF $THEN
/// OR A SEQUENCE OF CONDITIONS
/// Conditional: when before a param in a method declaration or constructor declaration the $ constructor or extending the $ class constructor:
/// @$($IF, int, $THEN, 'someParamName', NULL, 'Hello!')
/// @$($IF, int, $ANDIF 'someParamName2', String, $THEN, 'someParamName', NULL, 'Hello!')
/// @$(
///   $IF, int,
///   $ANDIF 'someParamName2', String,
///   $THEN, 'someParamName', NULL, 'Hello!'
///   $ANDTHEN 'someParamName3', int
/// )
/// It means when an invoked/called method/constructor is called with an int value then the param named 'someParamName' must have type null or be String "Hello"
/// (FIXME: Warning, values like "abc" are allowed but only types not values of certain types are implemented)
/// @$($IF, int, $THEN, 'someParamName', NULL, 'Hello!')
/// not used:If the type is not int when 'someParamName' must be null nor 'Hello!';
/// not used: @$($IF, int, $THEN, 'someParamName', NULL, 'Hello!')
/// If the type is not int when 'someParamName' can't be null nor 'Hello!';
/// And finally A FULL example of a sequence of conditions (just syntax - it doesn't need to be logical)
/// So bear in mind some conditions may be constradicting each other.
/// replaced by the changed syntax for not parts with $NOT: the old not valid example was: @$(int, 'Hello, hello' $IF, int, $THEN, 'someParamName', NULL, 'Hello!', $IFNOT, INT, $THENNOT, 'someParamName', NULL, 'Hello!')
/// ======================================
/// FIXME: FIXME IS USED TO TURN MY ATTENTION TO FOCUS AND TO REMIND ME NOT TO MISS SOMETHING DURING THE IMPLEMENTATION OF THIS ALL.
/// FIXME: TODO: UPDATE: CURRENT SYNTAX IS:
/// FIXME: because a t50 like proeprty can be null value which means it is not used,
/// then to ensure that an object can have the null value you have to use Null type instead - both for Type and instance/value that a  param is checked against
/// Remember - first if in a cycle is for the current method param it is applied for so no name is required
/// but if inside if is a condition that must be met for a different param (more ifs can be) so the name is reguired
/// then means what a different maybe some third or some four param must be or must NOT be if all related ifs are met.
/// $NOT switches further checking after it so that it means that the method/constructor param can't be of the types/values listed (of course if $IF is met it is instruction/condition not a regular type or value)
/// The situation the $NOT can be needed is if a tree stemming from a class is accepted
/// but you want to exclude some descending classes (or branches of descending classes)
/// or you want to exclude some values/instances of the class like you accept String, but it can't be "Hello".
/// Interesting thing noticed: Union Types with overloading methods (two or more declaration of a method with the same name)
/// is all you need.
/// But with condition $IF/$THEN overloading methods are in practice compeletely not needed.
/// FIXME: After fixing all the below problems START IMPLEMENTING $THEN because it is depending on the below.
/// FIXME: NOOOOOW! if before $NOT there is no type/value theParamMatchesAtLeastOneTypeOrValueRequirements ..2, ..3 stays fasle which causes error. but it should be true or think it over. See if it is correct for the opposite logic (?) of theParamMatchesAtLeastOneTypeOrValueRequirementsOf ...2, ...3
/// FIXME: THE third loop wrongly checks params NOT of the current invokation param but a different one.
/// FIXME: Seek this - there is some fixme/todo there - quite shouting piece of code: for (int t=0;t<inv.argumentList.arguments.length;t++)
/// TODO: [Edit: probably not needed - the generic type param definition like this: @$(int, String) T abc, but possibly useful in conditions but in very, very rare situations] Add handling generic types
/// TODO: Handle also return types with record return type, for example: (@$(num, String, Null, $NOT, int, 5.3) dynamic abc, int)? methodOne3... There is some path to do this in run() in context.registry.addReturnStatement body docs.
/// No num? is allowed, only num, Null, again: no null value is allowed - any null stops further params checking.
@$(
    // No num? is allowed, only num, Null, again: no null value is allowed - any null stops further params checking.
    num,
    Null,
    $NOT,
    int,
    $IF(
        num,
        $NOT,
        int,
        3.50,
        $IF('anotherMethodParam', Null),
        $IF('anotherMethodParam2', String, num, $NOT, int),
        $THEN('anotherMethodParam3', Null, String),
        $THEN('anotherMethodParam4', String, num, $NOT, int)),
    $IF(
        String,
        $NOT,
        $IF('anotherMethodParam', Null),
        $IF('anotherMethodParam2', String, num, $NOT, int, 5.20),
        $THEN('anotherMethodParam3', Null),
        // Another independent subcycle baset on thetop level $IF
        $IF('anotherMethodParam2', String, num, $NOT, int, 5.20),
        $THEN('anotherMethodParam4', String, num, $NOT, int, 2.20)))
class $IF {
  /// This property is because in static alalysis i don't know any other way to read if an extending class is also $IF descendant
  /// but the getField method of DartObject works.
  /// extending this base class could be implemented later. - see the important [myCustomGetCustomLint] method
  final bool is$IF = true;

  final dynamic t1;
  final dynamic t2;
  final dynamic t3;
  final dynamic t4;
  final dynamic t5;
  final dynamic t6;
  final dynamic t7;
  final dynamic t8;
  final dynamic t9;
  final dynamic t10;
  final dynamic t11;
  final dynamic t12;
  final dynamic t13;
  final dynamic t14;
  final dynamic t15;
  final dynamic t16;
  final dynamic t17;
  final dynamic t18;
  final dynamic t19;
  final dynamic t20;
  final dynamic t21;
  final dynamic t22;
  final dynamic t23;
  final dynamic t24;
  final dynamic t25;
  final dynamic t26;
  final dynamic t27;
  final dynamic t28;
  final dynamic t29;
  final dynamic t30;
  final dynamic t31;
  final dynamic t32;
  final dynamic t33;
  final dynamic t34;
  final dynamic t35;
  final dynamic t36;
  final dynamic t37;
  final dynamic t38;
  final dynamic t39;
  final dynamic t40;
  final dynamic t41;
  final dynamic t42;
  final dynamic t43;
  final dynamic t44;
  final dynamic t45;
  final dynamic t46;
  final dynamic t47;
  final dynamic t48;
  final dynamic t49;
  final dynamic t50;
  final dynamic t51;
  final dynamic t52;
  final dynamic t53;
  final dynamic t54;
  final dynamic t55;
  final dynamic t56;
  final dynamic t57;
  final dynamic t58;
  final dynamic t59;
  final dynamic t60;
  final dynamic t61;
  final dynamic t62;
  final dynamic t63;
  final dynamic t64;
  final dynamic t65;
  final dynamic t66;
  final dynamic t67;
  final dynamic t68;
  final dynamic t69;
  final dynamic t70;
  final dynamic t71;
  final dynamic t72;
  final dynamic t73;
  final dynamic t74;
  final dynamic t75;
  final dynamic t76;
  final dynamic t77;
  final dynamic t78;
  final dynamic t79;
  final dynamic t80;
  final dynamic t81;
  final dynamic t82;
  final dynamic t83;
  final dynamic t84;
  final dynamic t85;
  final dynamic t86;
  final dynamic t87;
  final dynamic t88;
  final dynamic t89;
  final dynamic t90;
  final dynamic t91;
  final dynamic t92;
  final dynamic t93;
  final dynamic t94;
  final dynamic t95;
  final dynamic t96;
  final dynamic t97;
  final dynamic t98;
  final dynamic t99;
  final dynamic t100;

  const $IF([
    this.t1,
    this.t2,
    this.t3,
    this.t4,
    this.t5,
    this.t6,
    this.t7,
    this.t8,
    this.t9,
    this.t10,
    this.t11,
    this.t12,
    this.t13,
    this.t14,
    this.t15,
    this.t16,
    this.t17,
    this.t18,
    this.t19,
    this.t20,
    this.t21,
    this.t22,
    this.t23,
    this.t24,
    this.t25,
    this.t26,
    this.t27,
    this.t28,
    this.t29,
    this.t30,
    this.t31,
    this.t32,
    this.t33,
    this.t34,
    this.t35,
    this.t36,
    this.t37,
    this.t38,
    this.t39,
    this.t40,
    this.t41,
    this.t42,
    this.t43,
    this.t44,
    this.t45,
    this.t46,
    this.t47,
    this.t48,
    this.t49,
    this.t50,
    this.t51,
    this.t52,
    this.t53,
    this.t54,
    this.t55,
    this.t56,
    this.t57,
    this.t58,
    this.t59,
    this.t60,
    this.t61,
    this.t62,
    this.t63,
    this.t64,
    this.t65,
    this.t66,
    this.t67,
    this.t68,
    this.t69,
    this.t70,
    this.t71,
    this.t72,
    this.t73,
    this.t74,
    this.t75,
    this.t76,
    this.t77,
    this.t78,
    this.t79,
    this.t80,
    this.t81,
    this.t82,
    this.t83,
    this.t84,
    this.t85,
    this.t86,
    this.t87,
    this.t88,
    this.t89,
    this.t90,
    this.t91,
    this.t92,
    this.t93,
    this.t94,
    this.t95,
    this.t96,
    this.t97,
    this.t98,
    this.t99,
    this.t100,
  ]);

  /// TODO: ALMOST CAN'T BE IMPLEMENTED BECAUSE dart_eval is in conflict with analyzer or custom lint
  /// used by the $IF function and   /// TODO: To be implemented later probably with the dart_eval package
  static ($AnnoTypesTypeOfLintReport lintReport, String lintMessage)?
      getCustomLintFor$IFCondition([
    initialDefaultEvaluation,
    /*Expression*/ dynamic paramNode,
    /*NodeList<Expression>*/ dynamic allParamNodes,
    // rather avoid using the following
    /*CustomLintResolver*/ dynamic resolver,
    /*ErrorReporter*/ dynamic reporter,
    /*CustomLintContext*/ dynamic context,
  ]) {
    print(true);
    return null;
  }

  /// TODO: To be implemented later probably with the dart_eval package
  /// like with the [$] - if returns null - ignored. if not null the returned value is more important than the default evaluation
  /// The default evaluation is in the first param initialDefaultEvaluation
  //final ($AnnoTypesTypeOfLintReport lintReport, String lintMessage)? Function() getCustomLint = myCustomGetCustomLint;

  void call() => null;
}

// Can only be used as a first parameter of @$($NOT, ...) annotation. not the same as is$IFNOT, etc. See $NOT, $IF, $ const classes.
final class $NOT {
  const $NOT();
}

class CUSTOMFANCYIFEXAMPLE extends $IF {
  const CUSTOMFANCYIFEXAMPLE();
}

// See the $IF description first then the $ - related to extending this class which has also to do with the is$THEN property but also [getCustomLint].
// like with the [$] - if returns null - ignored.
// This class and $THENNOT are not to be extended - to be used as is.
final class $THEN {
  /// This property is because in static alalysis i don't know any other way to read if an extending class is also $IF descendant
  /// but the getField method of DartObject works.
  /// extending this base class could be implemented later. - see the important [myCustomGetCustomLint] method
  final bool is$THEN = true;
  final dynamic t1;
  final dynamic t2;
  final dynamic t3;
  final dynamic t4;
  final dynamic t5;
  final dynamic t6;
  final dynamic t7;
  final dynamic t8;
  final dynamic t9;
  final dynamic t10;
  final dynamic t11;
  final dynamic t12;
  final dynamic t13;
  final dynamic t14;
  final dynamic t15;
  final dynamic t16;
  final dynamic t17;
  final dynamic t18;
  final dynamic t19;
  final dynamic t20;
  final dynamic t21;
  final dynamic t22;
  final dynamic t23;
  final dynamic t24;
  final dynamic t25;
  final dynamic t26;
  final dynamic t27;
  final dynamic t28;
  final dynamic t29;
  final dynamic t30;
  final dynamic t31;
  final dynamic t32;
  final dynamic t33;
  final dynamic t34;
  final dynamic t35;
  final dynamic t36;
  final dynamic t37;
  final dynamic t38;
  final dynamic t39;
  final dynamic t40;
  final dynamic t41;
  final dynamic t42;
  final dynamic t43;
  final dynamic t44;
  final dynamic t45;
  final dynamic t46;
  final dynamic t47;
  final dynamic t48;
  final dynamic t49;
  final dynamic t50;
  final dynamic t51;
  final dynamic t52;
  final dynamic t53;
  final dynamic t54;
  final dynamic t55;
  final dynamic t56;
  final dynamic t57;
  final dynamic t58;
  final dynamic t59;
  final dynamic t60;
  final dynamic t61;
  final dynamic t62;
  final dynamic t63;
  final dynamic t64;
  final dynamic t65;
  final dynamic t66;
  final dynamic t67;
  final dynamic t68;
  final dynamic t69;
  final dynamic t70;
  final dynamic t71;
  final dynamic t72;
  final dynamic t73;
  final dynamic t74;
  final dynamic t75;
  final dynamic t76;
  final dynamic t77;
  final dynamic t78;
  final dynamic t79;
  final dynamic t80;
  final dynamic t81;
  final dynamic t82;
  final dynamic t83;
  final dynamic t84;
  final dynamic t85;
  final dynamic t86;
  final dynamic t87;
  final dynamic t88;
  final dynamic t89;
  final dynamic t90;
  final dynamic t91;
  final dynamic t92;
  final dynamic t93;
  final dynamic t94;
  final dynamic t95;
  final dynamic t96;
  final dynamic t97;
  final dynamic t98;
  final dynamic t99;
  final dynamic t100;
  const $THEN([
    this.t1,
    this.t2,
    this.t3,
    this.t4,
    this.t5,
    this.t6,
    this.t7,
    this.t8,
    this.t9,
    this.t10,
    this.t11,
    this.t12,
    this.t13,
    this.t14,
    this.t15,
    this.t16,
    this.t17,
    this.t18,
    this.t19,
    this.t20,
    this.t21,
    this.t22,
    this.t23,
    this.t24,
    this.t25,
    this.t26,
    this.t27,
    this.t28,
    this.t29,
    this.t30,
    this.t31,
    this.t32,
    this.t33,
    this.t34,
    this.t35,
    this.t36,
    this.t37,
    this.t38,
    this.t39,
    this.t40,
    this.t41,
    this.t42,
    this.t43,
    this.t44,
    this.t45,
    this.t46,
    this.t47,
    this.t48,
    this.t49,
    this.t50,
    this.t51,
    this.t52,
    this.t53,
    this.t54,
    this.t55,
    this.t56,
    this.t57,
    this.t58,
    this.t59,
    this.t60,
    this.t61,
    this.t62,
    this.t63,
    this.t64,
    this.t65,
    this.t66,
    this.t67,
    this.t68,
    this.t69,
    this.t70,
    this.t71,
    this.t72,
    this.t73,
    this.t74,
    this.t75,
    this.t76,
    this.t77,
    this.t78,
    this.t79,
    this.t80,
    this.t81,
    this.t82,
    this.t83,
    this.t84,
    this.t85,
    this.t86,
    this.t87,
    this.t88,
    this.t89,
    this.t90,
    this.t91,
    this.t92,
    this.t93,
    this.t94,
    this.t95,
    this.t96,
    this.t97,
    this.t98,
    this.t99,
    this.t100,
  ]);

  /// TODO: ALMOST CAN'T BE IMPLEMENTED BECAUSE dart_eval is in conflict with analyzer or custom lint
  /// TODO: ALMOST CAN'T BE IMPLEMENTED BECAUSE dart_eval is in conflict with analyzer or custom lint
  /// like with $IF: /// TODO: To be implemented later probably with the dart_eval package
  // like with the [$] - if returns null - ignored. if not null the returned value is more important than the default evaluation
  /// The default evaluation is in the first param initialDefaultEvaluation
  /// TODO: ALMOST CAN'T BE IMPLEMENTED BECAUSE dart_eval is in conflict with analyzer or custom lint
  static ($AnnoTypesTypeOfLintReport lintReport, String lintMessage)?
      getCustomLintFor$THENCondition([
    initialDefaultEvaluation,
    /*Expression*/ dynamic paramNode,
    /*NodeList<Expression>*/ dynamic allParamNodes,
    // rather avoid using the following
    /*CustomLintResolver*/ dynamic resolver,
    /*ErrorReporter*/ dynamic reporter,
    /*CustomLintContext*/ dynamic context,
  ]) {
    print(true);
    return null;
  }
}

/// means mutable - $M is used for shorter syntax and by this readability
final class $M {
  final dynamic t1;

  /// This property is because in static alalysis i don't know any other way to read if an extending class is also $IF descendant
  /// but the getField method of DartObject works.
  /// extending this base class could be implemented later. - see the important [myCustomGetCustomLint] method
  final bool is$MUTABLE = true;

  const $M(this.t1);
}

/// Normally $(String, int, Null) - accepts "abc", 10, null, but $(String, $N(int)) accepts 1: 'abc', but 2: 10/null which is declared as variable with int? type
/// Warnin (Warning! think over/work it out: String? variable will value null will not pass in, only null of int? variable) - not flexible rarely useful as for the f.e. returned value to match it can't have just detected type int or Null but must be variable name that was declared exactly as int? and return 10 or null for example.
final class $N {
  final dynamic t1;

  /// This property is because in static alalysis i don't know any other way to read if an extending class is also $IF descendant
  /// but the getField method of DartObject works.
  /// extending this base class could be implemented later. - see the important [myCustomGetCustomLint] method
  final bool is$TypeOrNullType = true;

  const $N(this.t1);
}

/// means Regexp - A string expression will be matched against this regex
final class $R {
  final String t1; // source
  final bool t2; // multiline
  final bool t3; // case sensitive
  final bool t4; // unicode
  final bool t5; // isdotall

  /// This property is because in static alalysis i don't know any other way to read if an extending class is also $IF descendant
  /// but the getField method of DartObject works.
  /// extending this base class could be implemented later. - see the important [myCustomGetCustomLint] method
  final bool is$REGEX = true;

  const $R(this.t1,
      [this.t2 = false, this.t3 = true, this.t4 = false, this.t5 = false]);
}

/// means Between - An expression representing number will be checked if it is in the grater - less zone with including or not the left and right limit values
final class $B {
  final num t1; // left limit value
  final num t2; // right limit value
  final bool
      t3; // must be int-like (may be type double but integer - to enforce can't be double use f.e. @$(num $B(...) $NOT double))
  final bool t4; // includes left limit value
  final bool t5; // includes right limit value

  /// This property is because in static alalysis i don't know any other way to read if an extending class is also $IF descendant
  /// but the getField method of DartObject works.
  /// extending this base class could be implemented later. - see the important [myCustomGetCustomLint] method
  final bool is$Between = true;

  const $B(this.t1, this.t2, [this.t3 = false, this.t4 = true, this.t5 = true]);
}

enum $AnnoTypesTypeOfLintReport {
  NONE,
  INFO,
  WARNING,
  ERROR,
  COMPILATION_TIME_ERROR,
}

class Custom$ extends $ {}

sealed class UserType {
  const UserType();
}

final class UserTypeOne extends UserType {
  final abc;
  const UserTypeOne([this.abc = 10]);
}

final class UserTypeTwo extends UserType {
  const UserTypeTwo();
}

final class UserTypeThree extends UserType {
  const UserTypeThree();
}

const someIntGlobal = 87;

class User {
  const User();

  static const int? someInt = 10;
  static const double? someDouble = 5.2;
  static const someString = 'some user instance string';
  static const someUserType = const UserTypeTwo();
  static const UserTypeOne? someUserTypeOne =
      UserTypeOne(UserTypeOne(UserTypeOne(12)));
  static const List<int>? someList = [10, 21];
  static const Map<int, String>? someMap = {10: "Abc", 21: "Cdef"};
  static const (int, String)? someRecord = (10, 'Rec');

  @$(num, String, Null, $R('^a..d\$'))
  methodOne4Simple(
          [@$(num, String, Null, $NOT, int, 5.3) abcd = someInt ??
              someInt ??
              (someInt == 10
                  ? someInt
                  : someInt == 10
                      ? (10, 'Some string.')
                      : null) ??
              345.43]) =>
      //const // const will pass this but we don't need this requirement, also $MUTABLE OR $CONST ADDING
      /*checkingReturnTypesAndValues() catched error: i==4 (meta = i but Annotation argument has index i-1) e = Null check operator used on a null value, stackTrace #0      DannoScriptLintsDiscoveryLab.run.compareValueFromUltimateExpressionWithAnotherUltimateValue 
      (package:danno_script_lints/lint_rules/danno_script_lints_discovery_lab.dart:1284:61) */
      'abcd';
}

class tta {
  num methodw([asdf = 10]) => 10;
}

class tta2 extends tta {
  int methodw([asdf = 10]) => 10;
}

class ExampleConstComputableInvokationParam {
  final int abc = 10;
  const ExampleConstComputableInvokationParam();
}

class ExampleAAA {
  double b, c = 10.1, e = 20.2;
  int a = 10;
  ExampleAAA();
}

void main() {
  const int a = 10;
  @$(num, String, $NOT, int)
  String abc = 'abc ${a} abc';
  final jack = User();
  abc = 'Example text';
  abc = 'Example text2asasas';

  return;
}
