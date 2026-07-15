# ModuleTemplate

A ready-to-use skeleton for a new SMS++ module (a :Block and/or :Solver
repository), carrying everything a module must have in the standard SMS++
layout: the CMake build (standalone and under the umbrella), the hand-written
makefiles, the GitLab and GitHub CI, a factory-registered stub class, a smoke
test wired into CTest, and all the standard boilerplate (LICENSE,
CONTRIBUTING, CHANGELOG, .gitignore).

The stub module compiles and its test passes as generated: you then only have
to put your classes in `include/` and `src/` (extending the stub in place)
and list any new source file in `CMakeLists.txt` and `makefile`.

## Usage

```sh
git clone https://gitlab.com/smspp/moduletemplate.git MyNewBlock
cd MyNewBlock
./init.sh --name MyNewBlock --author "Jane Doe"
```

`init.sh` renames the stub class and every occurrence of the module name in
the build files, CI and docs, sets the make macro prefix, wires the declared
dependencies, re-creates the git history, and (with `--umbrella`) registers
the module in the SMS++ umbrella project. Run `./init.sh --help` for all the
options.

With `--push` it pushes both the `develop` branch and a stable `master` one,
as in every SMS++ module. Create the remote project **empty** (do not let the
host initialize it with a README): pushing `develop` first then makes it the
default branch automatically, with no `main` stub to rename and no manual step
in the web UI beyond protecting the two branches once.

After initialization the directory is a complete SMS++ module:

```
MyNewBlock/
├── include/MyNewBlock.h     stub :Block, registered in the Block factory
├── src/MyNewBlock.cpp
├── test/                    factory smoke test (CTest label = module name)
├── cmake/                   Config.cmake.in, Config.h.in, BuildType.cmake
├── CMakeLists.txt           dual-mode: standalone or under the umbrella
├── makefile, makefile-c, makefile-s
├── .gitlab-ci.yml           the only per-module CI bit: the -DBUILD_* flags
└── .github/workflows/ci.yml identical in every module, self-adapting
```

## License

This template is provided free of charge under the [GNU Lesser General
Public License version 3.0](https://opensource.org/licenses/lgpl-3.0.html) -
see the [LICENSE](LICENSE) file for details; the generated module carries the
same license.
