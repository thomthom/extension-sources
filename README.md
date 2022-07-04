# Extension Sources

[![Build status](https://ci.appveyor.com/api/projects/status/j5gcwy6ky3hgmww5/branch/main?svg=true)](https://ci.appveyor.com/project/thomthom/extension-sources/branch/main)

Manage additional sources to load extensions from.

## Known Issues

### Drag and drop irregularities

In SketchUp 2017 - SketchUp 2022.0 the HTML Drag and Drop API isn't fully
working. In these versions workarounds has been applied which will exhibit some
deviant in the normal drag and drop behaviour. For instance, it's not possible
to cancel a drag and drop by pressing ESC. The drag and drop cursor might also
not reflect it's correct state. This is fixed in SketchUp 2022.1.

### Drag and drop target indicator

In SketchUp 2017 - SketchUp 2020 there is no visual indicator to exactly where
the item will be dropped. This is due to limitation (bug?) in these SketchUp
versions.

## Tests

```sh
bundle exec rake test
```

```sh
bundle exec rake test TEST=tests/standalone/model/extension_source_test.rb
```

```sh
bundle exec rake test TEST=tests/standalone/model/extension_source_test.rb TESTOPTS="--name=/test_enabled.*/ -v"
```

## Documentation

### List undocumented code

```sh
bundle exec rake undoc
```

```sh
bundle exec yard stats --list-undoc
```

## Architecture

The following graph visualizes the hierarchy of the various components.
Higher levels can depend on lower levels, unless limited by an direct-only
dependency indicator (arrow).

`app` only deals with `controller` and `system`.

`controller` coordinates `view` and `model`.

`utils` can be used by anything.

Anything below the dashed line marked `SketchUp` can be use outside of SketchUp.
The unit tests between these two layers are separated.

```
┌─────────────────┐
│       app       │
└─────────────────┘
         ↑
┌─────────────────┐
│ ┌─────────────┐ │ ┌─────────────┐
│ │ controller  │ ← │    view     │
│ └─────────────┘ │ └─────────────┘
│ ┌─────────────┐ │
│ │   system    │ │
│ └─────────────┘ │
└─────────────────┘
┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ SketchUp
┌─────────────────┐
│      model      │
└─────────────────┘
╔═════════════════╗
║      utils      ║
╚═════════════════╝
```
