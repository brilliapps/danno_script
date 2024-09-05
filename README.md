The Union Types based mostly on custom_lint. First, the required version of Dart IS NOT 3.5 OR 3.6 BUT 3.4 (like 3.4.4). Maybe the following package itself is not significant, but for me the recently discovered rule behind it for me is a game changer. We can put an annotation before a param declaration like this:
```dart
// a method declaration of a class:
void methodOne2(@$(int, Map<List<int?>, int>, List<Map<int, int>>) abcd) => null;
```
And that's it. abcd is dynamic when not preceded, but for now you can place there any type with the Object? most recommended for now, BUT the annotation causes an error to be shown error in the place the method is called.
With the incoming macros, f.e. applied to a library/entire dart file, you can generate what's missing. Also possibly find a creative way for the macro to load errors produced by the custom_lint package, and the macro throw an Exception if any is found. An exception thrown by the macro as i understand is not only lint error but also an error during compilation time.
This (and like this) is a temporary solution that cannot replace the incoming Union Types implementation.
Tested on a couple of strange type inheritation rules, but not everything was tested.

Warning! Still don't know why my development version (not this repo package) stops after several or more minutes.
But this package is a place to start from or to get inspired.

Also The annotations accept not only types but literals, const objects, etc. However currently i was not able to read evaluated method invokation params so couldn't handle it correctly (did recently an issue/feature request about it for the custom_lint package exactly for this reason). I won't go even deeper into analyzer/custom_lint related stuff.

While a @$ annotation could be applied to a variable declaration, but for now i wasn't able to find a way to read each assignment of a new value to a given variable. By this i could read the type of the assigned value detected during analysis (must be const-like). Such an assignment would need to point also to the declaration of the variable to be able to read the @$ annotation settings.

Here is what you should be able to see (it may time for the package to proces it):

![image](https://github.com/brilliapps/anno_types/blob/main/readmeasset/screenshotpart.png)

Here is the link for the leaned version of the original workshop-package:

[Link to the anno_types repo](https://github.com/brilliapps/anno_types)
