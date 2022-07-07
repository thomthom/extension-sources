# Developer Notes

## Reset Preferences

To reset the preferences in order to test with a clean environment:

Windows: `%LocalAppData%\SketchUp\SketchUp 2022\SketchUp\PrivatePreferences.json`

Remove:
- `"This Computer Only"/WebCommonDialog_TT_ExtensionSourcesDialog`
- `"This Computer Only"/WebCommonDialog_TT_ExtensionSourcesScannerDialog`

## Size Dialog for Screenshots

```rb
d = TT::Plugins::ExtensionSources.app.open_extension_sources_dialog
wd = d.instance_variable_get(:@dialog)
wd.set_size(870, 500) # EW screenshot size
```

```rb
d = ObjectSpace.each_object(TT::Plugins::ExtensionSources::ExtensionSourcesScannerDialog).first
wd = d.instance_variable_get(:@dialog)
wd.set_size(870, 500) # EW screenshot size
```
