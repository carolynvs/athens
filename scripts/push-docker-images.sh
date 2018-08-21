#!/bin/bash

# Push our docker images to a registry
set -xeuo pipefail

# Manually set the registry to a docker registry where you have push access to test this script.
REGISTRY=${REGISTRY:-gomods/}

# Try to use the travis variables before hitting git because travis does shallow clones for performance reasons.
VERSION=${VERSION:-$TRAVIS_TAG}
if [[ -z "$VERSION" ]]; then
    echo "defaulting VERSION using git..."
    VERSION=`git describe --tags --abbrev=7 --dirty`
fi

BRANCH=${BRANCH:-$TRAVIS_BRANCH}
if [[-z "$BRANCH" ]]; then
    echo "defaulting BRANCH using git..."
    BRANCH=`git rev-parse --abbrev-ref HEAD`
    if [[ "$BRANCH" == "HEAD" ]]; then
        BRANCH=${VERSION} # Make our branch var work like travis_branch
    fi
fi

# mutable tag is the docker image tag that we will reuse between pushes, it is not a stable tag like a SHA or version.
MUTABLE_TAG=${MUTABLE_TAG:-} # defaulted below based on the branch
if [[ -z "$MUTABLE_TAG" ]]; then
    # tagged build
    if [[ "$VERSION" == "$BRANCH" ]]; then
        MUTABLE_TAG="latest"
    # master build
    elif [[ "$BRANCH" == "master" ]]; then
        MUTABLE_TAG="canary"
    # branch build
    else
        MUTABLE_TAG=${BRANCH}
    fi
fi

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )/"

docker build -t ${REGISTRY}proxy:${VERSION} -f ${REPO_DIR}cmd/proxy/Dockerfile ${REPO_DIR}
docker build -t ${REGISTRY}olympus:${VERSION} -f ${REPO_DIR}cmd/olympus/Dockerfile ${REPO_DIR}

# Apply the mutable tag to the immutable version
docker tag ${REGISTRY}proxy:${VERSION} ${REGISTRY}proxy:${MUTABLE_TAG}
docker tag ${REGISTRY}olympus:${VERSION} ${REGISTRY}olympus:${MUTABLE_TAG}

docker push ${REGISTRY}proxy:${VERSION}
docker push ${REGISTRY}proxy:${MUTABLE_TAG}
docker push ${REGISTRY}olympus:${VERSION}
docker push ${REGISTRY}olympus:${MUTABLE_TAG}
