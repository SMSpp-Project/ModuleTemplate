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

The packages of SMS++ name a module by its acronym, as the vcpkg feature
`smspp[<acr>]` or the conda-forge package `libsmspp-<acr>` (e.g. `bkb` for
BinaryKnapsackBlock): `--acronym` gives it, by default the lowercase name.
With `--umbrella` the module also becomes a feature of the smspp port in the
`vcpkg-registry` of the umbrella, needing the features of its dependencies,
to which its external dependencies are then to be added by hand. In the
conda-forge `smspp-project` feedstock, the module is one line of the table of
`recipe/gen_meta.py`, which regenerates `recipe/meta.yaml`.

With `--push` it pushes both the `develop` branch and a stable `master` one,
as in every SMS++ module. Create the remote project **empty** (do not let the
host initialize it with a README): pushing `develop` first then makes it the
default branch automatically, with no `main` stub to rename.

`--gitlab` does what is left of the project setup, and what the web UI would
otherwise be needed for: it protects `develop` and `master` at the Maintainer
level, gives the project the description of `--desc`, ending with a full stop
as every other SMS++ module does, and copies the CI/CD variables the pipeline
needs, the Gurobi WLS license and the deploy key, from an existing module
(`--reference`, by default `smspp/binaryknapsackblock`). The variables are
copied rather than kept here: they are secrets, and GitLab is the only place
they belong to. It needs the
[`glab`](https://gitlab.com/gitlab-org/cli) CLI, authenticated with a
Maintainer of both projects. Given alone, in a checkout of an existing module,
it does only this, taking the description already there when `--desc` is not
given, which is how a module created before this option is brought up to
standard:

```bash
cd MyOlderBlock && /path/to/init.sh --gitlab
```

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

The module has no version until it is released: a release is a `git tag
x.y.z` on `develop`, which the CMake build reads as the version of the module,
once the Unreleased section of `CHANGELOG.md` has become the section of
`x.y.z`.

## License

This template is provided free of charge under the [GNU Lesser General
Public License version 3.0](https://opensource.org/licenses/lgpl-3.0.html) -
see the [LICENSE](LICENSE) file for details; the generated module carries the
same license.
