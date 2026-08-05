# TRANSITIONAL -- deleted by the end of the migration.
#
# All that is left of the pre-dendritic wiring is `specialArgs`, still needed
# because the not-yet-migrated modules/_home tree reaches `inputs` as a module
# argument. Once those files become dendritic and close over `inputs`
# lexically, this file goes away entirely.
{ inputs, ... }:
{
  _module.args.legacy.specialArgs = { inherit inputs; };
}
