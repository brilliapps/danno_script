import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:danno_script_lints/lint_rules/danno_script_lints_discovery_lab.dart';
import 'package:danno_script_lints/lint_rules/danno_script_lints_return.dart';
import 'package:danno_script_lints/lint_rules/danno_script_lints_constructor.dart';
import 'lint_rules/danno_script_lints_method.dart';

// Entrypoint of plugin
PluginBase createPlugin() => _DannoScriptLints();

// The class listing all the [LintRule]s and [Assist]s defined by our plugin
class _DannoScriptLints extends PluginBase {
  // Lint rules
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      //DannoScriptLintsMethod(),
      //DannoScriptLintsReturn(),
      //DannoScriptLintsConstructor(),
      DannoScriptLintsDiscoveryLab()
    ];
  }

  // Assists
  //@override
  //List<Assist> getAssists() => [];
}
