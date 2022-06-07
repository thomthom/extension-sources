# Extension Sources

[![Build status](https://ci.appveyor.com/api/projects/status/j5gcwy6ky3hgmww5/branch/main?svg=true)](https://ci.appveyor.com/project/thomthom/extension-sources/branch/main)

Manage additional sources to load extensions from.

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
