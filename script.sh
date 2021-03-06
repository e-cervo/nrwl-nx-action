#!/bin/bash

set -euo pipefail

echo "::group::Ensuring @nrwl/cli is installed"
NX="$(yarn bin)/nx"

if [[ ! -x "$NX" ]]
then
    echo "::error::Could not found nx, have you ran npm/yarn before?"
    exit 1
fi

echo "Found Nx at $NX."
echo "::endgroup::"

NX_ARGS="$INPUT_ARGS"

if [[ "$INPUT_PARALLEL" == "true" ]]
then
    NX_ARGS="--parallel $NX_ARGS"
fi

function runNx {
    command="$NX $@"
    echo -e "\e[34m$command\e[0m"
    $command
}

if [[ "$INPUT_PROJECTS" != "" ]]
then
    for project in $(echo $INPUT_PROJECTS | sed "s/,/ /g")
    do
        for target in $(echo $INPUT_TARGETS | sed "s/,/ /g")
        do
            runNx $target $project $NX_ARGS
        done
    done
elif [[ "$INPUT_ALL" == "true" ]] || [[ "$INPUT_AFFECTED" == "false" ]]
then
    for target in $(echo $INPUT_TARGETS | sed "s/,/ /g")
    do
        runNx run-many --target=$target --all $NX_ARGS
    done
else
    if [[ $PR_BASE_REF_SHA ]]
    then
        export NX_BASE=$PR_BASE_REF_SHA
        export NX_HEAD=$PR_HEAD_REF_SHA
    else
        export NX_BASE=$(git rev-parse HEAD~1)
        export NX_HEAD=$(git rev-parse HEAD)
    fi

    echo "Will run Nx with:"
    echo "- Base: $NX_BASE ($GITHUB_BASE_REF)"
    echo "- Head: $NX_HEAD ($GITHUB_HEAD_REF)"

    for target in $(echo $INPUT_TARGETS | sed "s/,/ /g")
    do
        runNx affected --target=$target --base=$NX_BASE --head=$NX_HEAD $NX_ARGS
    done
fi
