WARNING! MONITOR THE SIZE OF TWO (two) .LOG FILES (dont remember custom_list.log or similar)

WARNING! AFTER THE LAST COMMIT (OR SERIES OF) METHOD PARAMS HAVE BEEN TURNED OF, ONLY RETURN TYPES/VALUES ARE HANDLED. THIS IS BECAUSE METHOD PARAMS ARE LAGGING BEHIND WITH SOME FEATURES. You can turn them on ofcourse easily.
Danno Script (Dart Annotation Script) - an independent meta programming language implemented via dart annotations, lints (custom_lint) and macros. Very early development. Initially created to improve working with types adding such a feature like for example, allowing to call a method with an argument that can be of int or String.
Caution! You can consider some examples unreasonable - the examples are to point you what is possible and how little limitations it has but you probably in 90% cases will use this like this:
if a method argument one is null then an argument two must be not null.
This solution makes implementing method overloading (making more than one method declaration with the same method name) unnecessary

[Edit:] Good to know that it is to be much more precise pintpointing to types and values for example (from my memory to be verified again) in dart when an expression is like this staticallyunknowncondition? 'abc' : 5; the type of the entire expression is the closest to the both values so it is Object for staticallyunknowncondition? 5.5 : 5 it is num not Object, but the danno types for the first example staticallyunknowncondition? 'abc' : 5 sees the expression can be String or int, for the second example staticallyunknowncondition? 5.5 : 5 it recognises it is double or int. it takes into account sub conditional expressions getting to the ultimate non conditional possible-to-be-used-at-runtime-time expressions/values/types. 

[HIGHLIGHTS FROM LAST SERIES OF COMMITS:] 
Json-encode-friendly Data-classes-like feature with handling nesting or requirements f.e list in a list, list in a map, map in a list with a record value in a map - all meeting your requirements or showing lint error etc. you may allow some parts of it to be const or mutable (assigned only once in lifetime cycle (f.e. int abc = 10; or abc = 10; but not assigned twice or more) but modified afterwards):
Just added a game changing feature for now for return values only:
A json encode friendly nested $() calls on constructor-like calls which involves syntax like abc(1,2), [1,2], {1,2}, {'a':'b'} (1, b:2)
What's the point you can require a return value (later variable declaration, assignment, method/constructor param, etc.) to be exactly like this (or show lint error):
```dart
{   
    const [
    1,
    const [6, 8] 
  ]
}
```
and you can write f.e. a extension type/ macro, etc for Set/List/Value that converts it to json string.
for example (read comments) (a full printscreen showing lint errors, involving different cases later in code under the specs probably):
```dart
  @$(
      $M({
        [
          1,
          $([6, $(double, 8)])
        ]
      }) someMethod() {
   return 
        { // entire Set passes - it can be not const ($M) but has must have const list
          const [
            1, // the first element must be "1" and it is
            const [6, 8] // passes because must be const list and has nested $(call which requires the value to be of double type or value 8) the last element can be eight
          ]
        } ??
        {
          const [
            1,
            const [6, 8.5] // passes because the last element is of double
          ]
        } ??
        // ! THIS IS THE ONLY SIMILAR SET THAT DOESN'T PASS - READ IT'S COMMENTS
        {
          const [
            1,
            const [6, 9] // entire Set doesn't pass because 9 is not 8 and isn't double
          ]
        }      
      }
```

TODO: 
1. Some explanation how it works, but it can be understood from analisis the following code and image with lint results. 
2. Add annotation requiring not overriding or overriding the method param $() annotation with the same == $() object.
3. Implement constructor.
4. Try to implement the return value like method/constructor params.
5. Adding better handling expressions to work as good as variable/const pointers (value passed with variable name): It is better to use variables like const abc = 'abc $some name' than literal expressions like 'abc', f.e. for string only simple strings without variables are now handled but complex strings with variables passed via variable name/pointer should work well.
6. Not necessary but adding math operations - see 5 - you could still use variable names that were declared with math operation/formula.
   
Known issues:
1. In the @$(...) Types are handled/implemented but values like 0.25, 'normal non param name string', non-syntax object Object() are ignored 
2. if you add another jack methodOne2 calls (like 5 to 20) to the present in the main() the plugin probably may stop working. 
3. The same if you try to enhance the packages/danno_script/lib/lint_rules/danno_script_lints.dart just by increasing the file by several lines may cause this to stop working. Because of this the original code was leaned much but the functionality for now works as expected.
4. It might but doesn't have to occasionally not run. Not sure of that but like something happened too early from time to time. Maybe that's not the case.
   
Specification (some example prinscreen[s]? below with breaking down why yes/no lint error): none normal available but an intuitive example serves as a specification:
```dart
class User {
  // seek danno_script_lints.dart
  //return [
  //    unsomment this line too for handling method arguments //DannoScriptLintsMethod(),
  //    //DannoScriptLintsReturn(), // this doesn nothing now
  //    //DannoScriptLintsConstructor(), // this does nothing now
  //    /*this handles return types for now*/DannoScriptLintsDiscoveryLab()
  //  ];

  // [Edit:] new feature, nested $() calls, f.e @$(TestClass(1, $('abcdefsqqqhf213342334571', $R('^a.*2\$'))) see explanations elsewhere in the document
  // record type return return not yet implemented see the following method2() return type - there's something implemented
  // dummy f.e. if return is "abc" ?? 5.3 - means "abc" would be ok, 5.3 not - because of $NOT
  // $M and $N added to make instances, list, map (+ more) literals more useful in the non-static-analysis runtime time world.
  // $M - mutable means return value must be declared or assigned only once after declaration but can be changed later with a property change for object or or adding/removing element for list, map, etc.
  // So for $M call an object passed as param has params or emtpy params call, and they (or elements of a list/map etc.) at the moment of declaration is sort of signature making the object recognizable
  // for static analysis tool for it to know. Again it is to make this danno script more useful.  
  // $N - nullable means that return element must be not null but also must be a pointer to a variable (var abc=10) that was declared as with null sign f.e. var int? abc = 10; is ok. (It is necessary it solves one possible problem)
  // $R means a return element is ok if it matches the regex pattern (you can use more $R() params like for RegEXp constructor)
  // $B - between - return type for $B(1, 4, true, false, true) , 2 is ok, 3 is ok, 4 is ok, 1 is not, 1.2 is not, 2.2 is not. first bool means element must be num/int/double but with integer value, next bool - includes left limit value - here false 1 is not accepted, last bool includes right value - 4 is ok because we have true here.
  //5. something works something not: Adding better handling expressions to work as good as variable/const pointers (value passed with variable name): It is better to use variables like const abc = 'abc $some name' than literal expressions like //'abc', f.e. for string only simple strings without variables are now handled but complex strings with variables passed via variable name/pointer should work well.
  //6. something works something not: Not necessary but adding math operations - see 5 - you could still use variable names that were declared with math operation/formula.
  @$(num, String, /* record type: */(int, String), abc(), [1,2], /* record instance: */(1, null), Null, $R('^a..d\$'), $M($N([0, 1])), $B(1, 2), $NOT, int, 5.3)
  methodOne2(
         // WARNING! FOR NOW METHOD ARGUMENTS MUST BE UPDATED TO MATCH THE FEATURES WERE ADDED TO RETURN TYPES/INSTANCES - SORRY - WHAT YOU SEE SHOULD WORK, INSTANCES, $M, $N, ETC. SHOULDN'T FOR NOW
          [@$(
              String,
              num,
              Null,
              $NOT,
              int,
              $IF(
                  num,
                  $NOT,
                  int,
                  3.50,
                  $IF('anotherMethodParam', double),
                  $IF('anotherMethodParam2', String, num, $NOT, int),
                  $THEN('anotherMethodParam3', Null, String),
                  $THEN('anotherMethodParam4', String, num, $NOT, int)),
              $IF(
                  String,
                  Null,
                  $NOT,
                  $IF('anotherMethodParam', String),
                  $IF('anotherMethodParam2', String, num, $NOT, int, 5.20),
                  $THEN('anotherMethodParam3', Null),
                  // Another independent subcycle baset on thetop level $IF
                  $IF('anotherMethodParam2', String, num, $NOT, int, 5.20),
                  $THEN('anotherMethodParam4', String, num, $NOT, int, 2.20),
                  $IF('anotherMethodParamNonexistent', String, num, $NOT, int,
                      5.20),
                  $THEN('anotherMethodParam4', String, num, $NOT, int, 2.20)))
          Object? anotherMethodParam = 50.3,
          @$(
            String,
            num,
            Null,
            $NOT,
            int,
            $IF(num, $NOT, int, 3.50, $IF('anotherMethodParam', String),
                $THEN('anotherMethodParam', Null)),
          )
          Object? anotherMethodParam2 = 52.3,
          Object? anotherMethodParam3 = 53,
          Object? anotherMethodParam4]) =>
      null;
}
```
[Edit 20241117:] let's focus on first on the currently best implemented return value of a method and try to break the stuff down under the following printscreen:

![image](https://raw.githubusercontent.com/brilliapps/danno_script/main/assets/example_1.jpg)

```dart

  static const tretretretertert = $({'abe', 'erw'});
  static const sourceOf$InstanceRecord = $((2, tretretretertert));
  static const werwerwerwerwerwer = (2, ({'abe', 'erw'}));
  static const correspondingSimpleValueForSourceOf$InstanceRecord =
      (2, werwerwerwerwerwer);

  static const sourceOf$InstanceMap = $({'abc': 'cde'});
  static const correspondingSimpleValueForSourceOf$InstanceMap =
      (2, (2, ({'abc': 'cde'})));

  @$(
      num, // can be a value of type num
      TestClass, // can be an instance of type TestClass
      {'abc': (2, sourceOf$InstanceRecord)}, // can be const set like this (const because not in $M() instance)
      $M({
        [
          1,
          $([6, $(double, 8)]) // nested $() call with complex requirements for the second element of the list
            // the list inside $() can be [6, 5.5] [6, 8], not [6, 9] see examples
        ]
      }), // can be set like this not const because in $M (not const - assigned with value only once in a lifetime but later the set changed freely)
      List, // can be any list (List<dynami, dynamic> so List<Object, Stream> too)
      {'wer', 'r'}, // this set but const
      $NOT, // !!! NOW WE ARE CHANGING INTO WHAT IT CAN'T BE
      $M(TestClass(1, $('abcdefsqqqhf213342334571', $R('^a.*2\$')))), // See explanations to return values like: TestClass(...)
      int, // see $NOT earlier so can't be int (but can be num - see the num at the beginning of "num")
      $M([
        1,
        $([6])
      ]), // see examples - exercise what you expect: you should already imagine 
      5.3, // See $NOT earlier so: can't be 5.3 value - already know that can be num, can't be int so can be double, but with no 5.3 value
      $M([2, 3]) // can be not const list [2, 3] 
      )
  methodOne4Simple(
      [@$(num, String, Null, $NOT, int, 5.3) abcd = someInt ??
          someInt ??
          (someInt == 10
              ? someInt
              : someInt == 10
                  ? (10, 'Some string.')
                  : null) ??
          345.43]) {
    return const {'abc': correspondingSimpleValueForSourceOf$InstanceRecord} ??
        // no error because is num is not int and is not 5.8
        5.8 ??
        { // entire Set passes - it can be NOT const (inside $M()) but has must have const list
          const [
            1, // the first element must be "1" and it is
            const [6, 8] // passes because must be const list and has nested $(call which requires the value to be of double type or value 8) the last element can be eight
          ]
        } ??
        {
          const [
            1,
            const [6, 8.5] // passes because the last element is of double
          ]
        } ??
        // ! THIS IS THE ONLY SIMILAR SET THAT DOESN'T PASS - READ IT'S COMMENTS
        {
          const [
            1,
            const [6, 9] // entire Set doesn't pass because 9 is not 8 and isn't double
          ]
        }      
      }
         ??
         // the following is errror lint because it matches but is after the $NOT clause (means: it can't be)
        [ // entire list matches because it doesn't have t obe mutable
          1, // must have value 1 - it has
          const [6] // must be immutable const list (it is not inside $M()), has value "6"
        ] ?? // try to focus now: 
        // lets try to break down the following - it matches two rules from the @$() annotation call this part:
        // first before the $NOT - there is ... TestClass, ... which would mean that there would be no lint error 
        // because the TestClass() instance creationg call is of type TestClass - no constructor arguments are important
        // following?
        // But there it matches the second rule after the $NOT instruction which tells you what something cannot be:
        // the rule from @$ annotation call it matches is:
        // $M(TestClass(1, $('abcdefsqqqhf213342334571', $R('^a.*2\$'))))
        // so it is a TestClass() call and it is not a const Object, but because it is in $M(TestClass...) it doesn't have to be const
        // the first param inside constructor params must be value 1 and it is
        // the second param requirement is a nested $() call so it must one of the following values:
        // 'abcdefsqqqhf213342334571' - it isn't - it has the "2" at the end of sring - you would have to remove the "2"            
        // but it matches the second value exactly a regular expression requirement inside $R() call (btw. $B for numbers - betweend) - the regex rule says the string must start with a and and with 2 and it does.
        // so the following call matches but is after $NOT instruction was places in the @$() annotation call so this is a lint error.
        // BUT if the @$ rule was not inside $M() - just by this the following TestClass call wouldn't batch and there would be no lint error, difficult?
        TestClass(1, 'abcdefsqqqhf2133423345712') ??
        // following shows lint error: is num, but after $NOT there is int so it cannot be int
        5 ??
        5.5 ??
        // following shows lint error: is num, and after $NOT there is int but the value is not int but after $NOT there is also 5.3 value and it matches it so it can't be 5.3 so shows lint error
        5.3 ??
        // tired of explaining, excercise - why no lint error
        // SEE IT IS AGAIN RETURNED IN THE FOLLOWING FANCY CIRCUMSTANCES :)
        const {
          'abc': (2, (2, {'abe', 'erw'}))
        } ??
        // AND SPECIAL TREAT, danno_type goes comprehensively and handles at least dome function calls - don't remember what
        () {
          // So this is not lint error AS IN THE previous exactly the same return
          return const {
            'abc': (2, (2, {'abe', 'erw'}))
          };
          // why this is dead code this shows lint error why 
          // it matches after $NOT (can't be but it is) the rule $M([2, 3]) // can be: not const list [2, 3] and it is not const list ...
          return [2, 3];
        }();
  }
```

SOME OLDER STUFF, I PROPOSE NOT TO THINK OF IT MUCH NOW.

![image](https://raw.githubusercontent.com/brilliapps/danno_script/main/assets/danno_script_1.jpg)

Here is the example lint undersores with red meaning errors, especially under an argument to a function or if an argument was not found then under a method name.

![image](https://raw.githubusercontent.com/brilliapps/danno_script/main/assets/danno_script_1.jpg)

First, should work on dart 3.5, 3.6 on windows. Maybe the following package itself is not significant, but for me the recently discovered rule behind it for me is a game changer. We can put an annotation before a param declaration like this:
```dart
// a method declaration of a class:
void methodOne2(@$(int, Map<List<int?>, int>, List<Map<int, int>>) abcd) => null;
```
And that's it. abcd is dynamic when not preceded, but for now you can place there any type with the Object? most recommended for now, BUT the annotation causes an error to be shown error in the place the method is called.
With the incoming macros, f.e. applied to a library/entire dart file, you can generate what's missing. Also possibly find a creative way for the macro to load errors produced by the custom_lint package, and the macro throw an Exception if any is found. An exception thrown by the macro as i understand is not only lint error but also an error during compilation time.
This (and like this) is rather a temporary solution that cannot replace Dart features like the incoming Union Types implementation or possible conditions if/else inside method param list or constructor param list (it seems as i remember someone told there may be plans for such a feature (not quoting, just from my foggy memory)).
[Edit: retest again]: Tested on a couple of strange type inheritation rules, but not everything was tested.

Also the annotations accept not only types but literals, const objects, etc. However currently i was not able to read evaluated method invokation params so couldn't handle it correctly (did recently an issue/feature request about it for the custom_lint package exactly for this reason). I won't go even deeper into analyzer/custom_lint related stuff.

While a @$ annotation could be applied to a variable declaration, but for now i wasn't able to find a way to read each assignment of a new value to a given variable. By this i could read the type of the assigned value detected during analysis (must be const-like). Such an assignment would need to point also to the declaration of the variable to be able to read the @$ annotation settings.

Here is what you should be able to see (it may time for the package to proces it):

![image](https://github.com/brilliapps/anno_types/blob/main/readmeasset/screenshotpart.png)
