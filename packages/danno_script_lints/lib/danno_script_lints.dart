import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'lint_rules/danno_script_lints.dart';

// Entrypoint of plugin
PluginBase createPlugin() => _DannoScriptLints();

// The class listing all the [LintRule]s and [Assist]s defined by our plugin
class _DannoScriptLints extends PluginBase {
  // Lint rules
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [DannoScriptLints()];
  }

  // Assists
  //@override
  //List<Assist> getAssists() => [];
}
