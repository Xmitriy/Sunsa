# Note

**Development has moved to https://github.com/OpenNefia/OpenNefia.git**. This repository is for an older prototype of OpenNefia that is no longer supported. The source code in this repository will be used as a reference for the final version of OpenNefia.

---

<p align="center">
<img height="256" src="https://github.com/Ruin0x11/OpenNefia/raw/master/src/data/icon1296.png" />
</p>

<h1 align="center">OpenNefia</h1>

*OpenNefia* is an open-source engine reimplementation of the Japanese roguelike RPG [Elona](http://ylvania.org/en/elona) using Lua and the LÖVE game engine.

It is not a variant of Elona, but a ground-up rewrite intended to vastly expand the support for modding in the game, allowing for game features that would have been impractical or impossible with the vanilla codebase.

It is also an experiment to see if a game can be written in an extensible manner, using a mod system and an extensive API.

Note that it is currently **alpha-quality** and massive breakage **will** occur when attempting to play through the game normally. *Nearly everything is still a work-in-progress.* If you would like a stable experience, then please play vanilla Elona or a variant like oomSEST instead.

See the [wiki](https://github.com/Ruin0x11/OpenNefia/wiki) for more information and a work-in-progress modding tutorial.

## Features
- Intended goal of being feature-compatible with Elona 1.22 (though still a work in progress).
- Ability to modify the flow of game logic using event hooks.
- Architecture based on APIs - mods can reuse pieces of functionality exposed by other mods.
- Quality-of-life features for developers like code hotloading and an in-game Lua REPL. Build things like new game UIs or features in an interactive manner.
- Supports Windows, macOS, and Linux.

## Running
If you're using Windows, install LÖVE from the [official website](https://love2d.org). (Make sure it's the 64-bit version.)

If you're using a Unix-like platform, ensure the `love` binary, `wget` and `unzip` are on your `PATH`.

Then, run `OpenNefia.bat` (Windows) or `OpenNefia` (Unix).

## Contributing
OpenNefia uses the [Gitflow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow). Please branch off of `develop` when developing new features or porting things. `master` will be reserved for stable releases and hotfixes only once the engine becomes stable enough to use.

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) for a high-level overview of the codebase.

## Credits
See [CREDITS.md](CREDITS.md) for third-party code information.
