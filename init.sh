#!/usr/bin/env bash
##############################################################################
################################# init.sh ####################################
##############################################################################
#                                                                            #
#   Bootstrap script of ModuleTemplate                                       #
#                                                                            #
#   Turns a fresh clone of ModuleTemplate into a fully initialized SMS++    #
#   module: renames the stub TemplateBlock class and every occurrence of     #
#   the module name in the build files, CI and docs, sets the make macro     #
#   prefix, wires the declared SMS++ module dependencies (CMake, package     #
#   config and CI flags, with their transitive closure), re-creates the      #
#   git history and, on request, registers the module as a submodule of      #
#   the SMS++ umbrella project.                                              #
#                                                                            #
##############################################################################

set -euo pipefail

usage() {
 cat <<EOF
Usage: ./init.sh --name <ModuleName> [options]

Options:
  --name <ModuleName>    name of the new module (CamelCase, e.g. FooBlock
                         or FooSolver); mandatory
  --author <name>        author shown in file headers and README
                         (default: git config user.name)
  --desc <text>          one-line project description
                         (default: "SMS++ <ModuleName> module")
  --prefix <PFX>         make macro prefix, e.g. BKBk for
                         BinaryKnapsackBlock (default: the capitals of
                         <ModuleName> followed by 'k')
  --deps <A,B,...>       comma-separated SMS++ modules this one depends on,
                         e.g. MILPSolver,BundleSolver (default: none)
  --url <url>            project homepage
                         (default: https://gitlab.com/smspp/<lowercase name>)
  --remote <git-url>     set this as the git remote 'origin'
  --push                 push the initial commit to 'origin' (implies
                         --remote or an already-configured origin); pushes
                         'develop' and a stable 'master'. Create the remote
                         project EMPTY (no README) so 'develop' becomes the
                         default branch automatically, with no 'main' stub
  --gitlab               after pushing, set the GitLab project up the way
                         every SMS++ module is: protect 'develop' and
                         'master', give it the description of --desc, ending
                         with a full stop as every other one does, and copy
                         the CI/CD variables (the Gurobi WLS license and the
                         deploy key the CI needs) from --reference. Needs the
                         'glab' CLI, authenticated with a Maintainer of both
                         projects. Given alone, in a checkout of an existing
                         module, it does only this, taking the description
                         already there if --desc is not given
  --reference <path>     project the CI/CD variables are copied from
                         (default: smspp/binaryknapsackblock)
  --umbrella <path>      path to a checkout of the SMS++ umbrella project:
                         registers the module there (git submodule add +
                         CMakeLists.txt patches); the module must be
                         reachable at its remote URL, so use it with --push
                         (or after having pushed)
  -h, --help             show this help

Everything is done locally except --push; nothing is ever committed in the
umbrella checkout, review and commit those changes yourself.
EOF
}

die() { echo "init.sh: $*" >&2 ; exit 1 ; }

# ----- GitLab project setup ---------------------------------------------------
# What every SMS++ module has and what a fresh project has not: 'develop' and
# 'master' protected, and the CI/CD variables the pipeline needs, i.e. the
# Gurobi WLS license and the deploy key. The variables are copied from an
# existing module rather than kept anywhere here: they are secrets, and the
# only place they belong to is GitLab itself.

gitlab_setup() {
 command -v glab >/dev/null 2>&1 || \
  die "--gitlab needs the 'glab' CLI (https://gitlab.com/gitlab-org/cli)"

 # the <group>/<project> path, whatever form the remote URL has
 local url project encoded reference
 url=$( git remote get-url origin )
 project=$( printf '%s' "$url" | sed -E 's#^[^@]+@[^:]+:##; s#^https?://[^/]+/##; s#\.git$##' )
 encoded=$( printf '%s' "$project" | sed 's#/#%2F#g' )
 reference=$( printf '%s' "$REFERENCE" | sed 's#/#%2F#g' )

 echo "Setting up $project on GitLab:"

 # 40 = Maintainer, the level every SMS++ module protects its branches at
 local branch
 for branch in develop master ; do
  if glab api --method POST "projects/$encoded/protected_branches" \
       --raw-field "name=$branch" --field "push_access_level=40" \
       --field "merge_access_level=40" >/dev/null 2>&1 ; then
   echo "  protected '$branch'"
  else
   echo "  could not protect '$branch' (already protected?)"
  fi
 done

 # the description of the project, i.e. what the GitLab project page shows
 # under its name: it is the one of --desc, or the one already there when
 # this is run on an existing module, and it ends with a full stop, as the
 # description of every SMS++ module does
 local description
 description=${DESC:-$( glab api "projects/$encoded" |
   python3 -c 'import json,sys; print( json.load( sys.stdin )[ "description" ]
                                       or "" )' )}

 if [ -n "$description" ]; then
  case "$description" in *. ) ;; * ) description="$description." ;; esac

  if glab api --method PUT "projects/$encoded" \
       --raw-field "description=$description" >/dev/null 2>&1 ; then
   echo "  described as \"$description\""
  else
   echo "  could not set the description"
  fi
 fi

 # the variables are read one at a time, so that no secret is ever written
 # anywhere but into the API call that carries it
 local keys key value protected masked raw
 keys=$( glab api "projects/$reference/variables" |
         python3 -c 'import json,sys; print("\n".join(v["key"] for v in json.load(sys.stdin)))' ) \
  || die "cannot read the CI/CD variables of $REFERENCE"

 for key in $keys ; do
  # the flags first, one per line, then the value: it is the only one that
  # may contain anything at all, newlines included, hence it comes last and
  # NUL-terminated
  { read -r protected ; read -r masked ; read -r raw
    IFS= read -r -d '' value ; } < <( glab api \
     "projects/$reference/variables/$key" | python3 -c '
import json, sys
v = json.load( sys.stdin )
for field in ( "protected" , "masked" , "raw" ):
    print( str( v[ field ] ).lower() )
sys.stdout.write( v[ "value" ] + "\0" )
' )

  if glab api --method POST "projects/$encoded/variables" \
       --raw-field "key=$key" --raw-field "value=$value" \
       --field "protected=$protected" --field "masked=$masked" \
       --field "raw=$raw" >/dev/null 2>&1 ; then
   echo "  copied the CI/CD variable '$key' from $REFERENCE"
  else
   echo "  could not copy '$key' (already there?)"
  fi
  unset value
 done

 }  # end( gitlab_setup )


# ----- argument parsing -----------------------------------------------------

NAME= AUTHOR= DESC= PFX= DEPS= URL= REMOTE= PUSH=0 UMBRELLA=
GITLAB=0 REFERENCE=smspp/binaryknapsackblock

while [ $# -gt 0 ]; do
 case "$1" in
  --name )     NAME=$2 ; shift 2 ;;
  --author )   AUTHOR=$2 ; shift 2 ;;
  --desc )     DESC=$2 ; shift 2 ;;
  --prefix )   PFX=$2 ; shift 2 ;;
  --deps )     DEPS=$2 ; shift 2 ;;
  --url )      URL=$2 ; shift 2 ;;
  --remote )   REMOTE=$2 ; shift 2 ;;
  --push )     PUSH=1 ; shift ;;
  --gitlab )   GITLAB=1 ; shift ;;
  --reference ) REFERENCE=$2 ; shift 2 ;;
  --umbrella ) UMBRELLA=$2 ; shift 2 ;;
  -h|--help )  usage ; exit 0 ;;
  * ) die "unknown option '$1' (see --help)" ;;
 esac
done

# --gitlab given alone, in a checkout of an existing module, does only that:
# it is how a module created before this option is brought up to standard
if [ "$GITLAB" = 1 ] && [ -z "$NAME" ]; then
 git rev-parse --git-dir >/dev/null 2>&1 || \
  die "--gitlab alone must be run in a checkout of the module"
 gitlab_setup
 exit 0
fi

[ -n "$NAME" ] || { usage ; exit 1 ; }
[[ "$NAME" =~ ^[A-Z][A-Za-z0-9]*$ ]] || \
 die "--name must be a CamelCase identifier, got '$NAME'"
[ -f include/TemplateBlock.h ] || \
 die "run me from the root of a fresh ModuleTemplate clone"

LOWER=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
[ -n "$AUTHOR" ] || AUTHOR=$(git config user.name 2>/dev/null || true)
[ -n "$AUTHOR" ] || die "no --author given and no git user.name configured"
[ -n "$DESC" ]   || DESC="SMS++ $NAME module"
[ -n "$PFX" ]    || PFX="$(echo "$NAME" | tr -cd '[:upper:]')k"
[ -n "$URL" ]    || URL="https://gitlab.com/smspp/$LOWER"
TODAY=$(date +%F)

# the SMS++ inter-module dependency map (mirrors the "Handle dependencies"
# section of the umbrella CMakeLists.txt), used to close the CI build flags
declare -A DEP_MAP=(
 [MMCFBlock]="MCFBlock BinaryKnapsackBlock"
 [InvestmentBlock]="SDDPBlock UCBlock"
 [TwoStageStochasticBlock]="StochasticBlock"
 [MultiStageStochasticBlock]="TwoStageStochasticBlock StochasticBlock"
 [SDDPBlock]="StochasticBlock"
 [StochasticBlock]="CapacitatedFacilityLocationBlock"
 [CapacitatedFacilityLocationBlock]="MCFBlock BinaryKnapsackBlock"
 [BundleSolver]="MILPSolver"
 [MCFClassSolver]="MCFBlock"
 [MCFLemonSolver]="MCFBlock"
)

# direct dependencies as an array
IFS=',' read -r -a DIRECT_DEPS <<< "${DEPS:-}"

# transitive closure of the dependencies (BFS over DEP_MAP)
closure() {
 local -A seen=()
 local queue=( "$@" ) out=()
 while [ ${#queue[@]} -gt 0 ]; do
  local d=${queue[0]} ; queue=( "${queue[@]:1}" )
  [ -n "$d" ] || continue
  [ -n "${seen[$d]:-}" ] && continue
  seen[$d]=1 ; out+=( "$d" )
  for e in ${DEP_MAP[$d]:-} ; do queue+=( "$e" ) ; done
 done
 echo "${out[@]:-}"
}
ALL_DEPS=$(closure "${DIRECT_DEPS[@]:-}")

echo "Initializing module '$NAME'"
echo "  author : $AUTHOR"
echo "  prefix : $PFX"
echo "  deps   : ${DEPS:-none}${ALL_DEPS:+ (closure: $ALL_DEPS)}"
echo "  url    : $URL"

# ----- text substitutions ---------------------------------------------------

# every text file of the template, excluding the git dir and this script
files() {
 find . -type f ! -path './.git/*' ! -name init.sh ! -name '.gitkeep'
}

files | while read -r f ; do
 sed -i \
  -e "s/TemplateBlock/$NAME/g" \
  -e "s/templateblock/$LOWER/g" \
  -e "s/TmpBk/$PFX/g" \
  -e "s/Template Author/$AUTHOR/g" \
  -e "s/@date@/$TODAY/g" \
  "$f"
done

# project description and homepage in CMakeLists.txt
sed -i -e "s|DESCRIPTION \"SMS++ $NAME module\"|DESCRIPTION \"$DESC\"|" \
       -e "s|HOMEPAGE_URL https://gitlab.com/smspp/$LOWER|HOMEPAGE_URL $URL|" \
 CMakeLists.txt

# ----- re-align the comment boxes -------------------------------------------
# after the renames the '#   ...   #' banner boxes (CMake files are 79
# columns wide, makefiles 78) and the '/*--- ... ---*/' C++ rule boxes (78)
# are off: re-pad left-aligned lines and re-center centered ones

fix_hash_box() { # $1 = file, $2 = width
 awk -v W="$2" '
  /^#.*#$/ && length($0) != W {
   inner = substr($0, 2, length($0) - 2)      # what is between the two #
   text = inner
   gsub(/^ +| +$/, "", text)
   pre = match(inner, /[^ ]/) - 1              # leading spaces
   if( text == "" || W - 2 - length(text) < pre ) { print ; next }
   if( pre >= 8 ) {           # centered line: re-center
    tot = W - 2 - length(text)
    l = int(tot / 2) ; r = tot - l
    printf "#%*s%s%*s#\n", l, "", text, r, ""
   } else {                   # left-aligned line: re-pad the tail
    printf "#%*s%s%*s#\n", pre, "", text, W - 2 - pre - length(text), ""
   }
   next
  }
  { print }
 ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

fix_cpp_box() { # $1 = file (width 78)
 awk -v W=78 '
  /^\/\*-+[^-].*[^-]-+\*\/$/ && length($0) != W {
   text = $0
   sub(/^\/\*-+/, "", text) ; sub(/-+\*\/$/, "", text)
   gsub(/^ +| +$/, "", text)
   tot = W - 4 - length(text) - 2
   l = int(tot / 2) ; r = tot - l
   d = "" ; for( i = 0 ; i < l ; i++ ) d = d "-"
   e = "" ; for( i = 0 ; i < r ; i++ ) e = e "-"
   print "/*" d " " text " " e "*/"
   next
  }
  { print }
 ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

fix_hash_box CMakeLists.txt 79
fix_hash_box test/CMakeLists.txt 79
for f in makefile makefile-c makefile-s test/makefile ; do
 fix_hash_box "$f" 78
done
for f in include/TemplateBlock.h src/TemplateBlock.cpp test/test.cpp ; do
 fix_cpp_box "$f"
done

# ----- renames ---------------------------------------------------------------

mv include/TemplateBlock.h "include/$NAME.h"
mv src/TemplateBlock.cpp "src/$NAME.cpp"
mv cmake/TemplateBlockConfig.h.in "cmake/${NAME}Config.h.in"
mv cmake/TemplateBlockConfig.cmake.in "cmake/${NAME}Config.cmake.in"
mv README.module.md README.md

# ----- dependency wiring ------------------------------------------------------

if [ -n "${DIRECT_DEPS[0]:-}" ]; then
 for d in "${DIRECT_DEPS[@]}" ; do
  # CMakeLists.txt: find_package() for standalone mode (before the marker,
  # so the order given in --deps is preserved)
  sed -i "/# <deps:find_package>/i\\    find_package($d REQUIRED)" \
   CMakeLists.txt
  # package config: find_dependency() for the installed package
  sed -i "/^find_dependency(SMS++)$/a find_dependency($d)" \
   "cmake/${NAME}Config.cmake.in"
 done
 # CMakeLists.txt: link the dependencies
 LINKS=""
 for d in "${DIRECT_DEPS[@]}" ; do LINKS="$LINKS \${modNamespace}::$d" ; done
 sed -i "s|^target_link_libraries(\${modName} PUBLIC \${modNamespace}::SMS++)$|target_link_libraries(\${modName} PUBLIC \${modNamespace}::SMS++$LINKS)|" \
  CMakeLists.txt
fi
# drop the (processed or unused) deps markers and their example lines
sed -i -e '/# <deps:find_package>/d' \
       -e '/#find_package(MILPSolver REQUIRED)/d' \
       -e '/# <deps:target_link_libraries>/,+1d' \
 CMakeLists.txt

# CI: the module and the closure of its dependencies
FLAGS="-DBUILD_$NAME=ON"
for d in $ALL_DEPS ; do FLAGS="$FLAGS -DBUILD_$d=ON" ; done
sed -i "s|-DBUILD_$NAME=ON|$FLAGS|" .gitlab-ci.yml

# ----- git history ------------------------------------------------------------

rm -rf .git
rm -f init.sh
git init -q -b develop
git add -A
git commit -q -m "initial module skeleton from ModuleTemplate"
echo "Created initial commit on branch 'develop'."

if [ -n "$REMOTE" ]; then
 git remote add origin "$REMOTE"
 echo "Remote 'origin' set to $REMOTE"
fi

if [ "$PUSH" = 1 ]; then
 # push 'develop' first: on an EMPTY project (created without a README) this
 # also makes it the default branch, so no manual GUI step is needed and no
 # spurious 'main' branch is ever created
 git push -u origin develop
 # SMS++ convention: a stable 'master' branch exists alongside 'develop'
 # (both carry the full module; master advances at each release)
 git push origin develop:refs/heads/master
 echo "Pushed branches 'develop' (default) and 'master' to origin."
 if [ "$GITLAB" = 1 ]; then gitlab_setup ; else
  echo "One-time GUI step left: protect 'develop' and 'master' and add the"
  echo "CI/CD variables (or re-run with --gitlab)."
 fi
elif [ -n "$REMOTE" ]; then
 echo "Push it yourself with:"
 echo "  git push -u origin develop && git push origin develop:refs/heads/master"
fi

# ----- umbrella registration ---------------------------------------------------

if [ -n "$UMBRELLA" ]; then
 [ -f "$UMBRELLA/CMakeLists.txt" ] && \
  grep -q "smspp_option" "$UMBRELLA/CMakeLists.txt" || \
  die "'$UMBRELLA' does not look like the SMS++ umbrella project"
 [ -e "$UMBRELLA/$NAME" ] && die "'$UMBRELLA/$NAME' already exists"

 # Blocks are registered in the Blocks groups, Solvers in the Solvers ones
 if [[ "$NAME" == *Solver ]] ; then KIND=Solver ; else KIND=Block ; fi

 python3 - "$UMBRELLA/CMakeLists.txt" "$NAME" "$KIND" "${DIRECT_DEPS[*]:-}" <<'PYEOF'
import re, sys
path, name, kind, deps = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
deps = deps.split() if deps else []
src = open(path).read()

# 1) smspp_option() in the Blocks or Solvers group of the options list
opt = f'smspp_option(BUILD_{name} "Build {name}")\n'
if kind == "Block":
    # after the last smspp_option before the "# Solvers" group
    m = re.search(r'(# Blocks\n(?:smspp_option\([^\n]*\n)+)', src)
else:
    m = re.search(r'(# Solvers\n(?:smspp_option\([^\n]*\n)+)', src)
assert m, "options group not found"
src = src[:m.end(1)] + opt + src[m.end(1):]

# 2) dependency auto-enable block in the "Handle dependencies" section
if deps:
    blk = f'if (BUILD_{name})\n'
    for d in deps:
        blk += f'    set(BUILD_{d} ON) # Requires {d}\n'
    blk += 'endif ()\n\n'
    anchor = ('# Solvers\n' if kind == "Block"
              else '# ----- Initialize submodules ')
    i = src.index('# ----- Handle dependencies ')
    j = src.index(anchor, i)
    src = src[:j] + blk + src[j:]

# 3) init_submodule() + add_subdirectory() in the Subprojects section
sub = (f'if (BUILD_{name})\n'
       f'    init_submodule({name})\n'
       f'    add_subdirectory({name})\n'
       f'    set(SMSPP_REQUIRED ON)\n'
       f'endif ()\n\n')
i = src.index('# ----- Subprojects ')
anchor = '# Solvers\n' if kind == "Block" else '# ----- Tools '
j = src.index(anchor, i)
src = src[:j] + sub + src[j:]

open(path, 'w').write(src)
print(f"Patched {path}")
PYEOF

 # register the git submodule (needs the module pushed to its remote)
 SUBURL="../$LOWER.git"
 if git -C "$UMBRELLA" submodule add "$SUBURL" "$NAME" ; then
  echo "Submodule '$NAME' added to the umbrella."
 else
  echo "WARNING: 'git submodule add $SUBURL $NAME' failed (module not"
  echo "pushed yet, or non-matching remote name). After pushing, run:"
  echo "  (cd $UMBRELLA && git submodule add $SUBURL $NAME)"
 fi

 echo
 echo "Review the umbrella changes and commit them yourself:"
 echo "  (cd $UMBRELLA && git diff CMakeLists.txt && git status)"
 echo "Remember to also mention the new module in the umbrella README.md."
fi

echo
echo "Module '$NAME' initialized. Next steps:"
echo "  - put your classes in include/ and src/ (extend the stub in place)"
echo "  - list any new source file in CMakeLists.txt (target_sources) and"
echo "    in the makefile (${PFX}OBJ / ${PFX}H)"
echo "  - describe the module in README.md and keep CHANGELOG.md updated"

########################### End of init.sh ###################################
