#!/usr/bin/bash
set -e

D=$(realpath $(dirname $(dirname .)))
mkdir -p $D/dev_storage

docker build -t mailcalf-dev -f dev.Dockerfile
docker run --rm -v $D/:/usr/local/src/mailcalf/ --name=mailcalf-dev mailcalf-dev mix deps.get
exec docker run -it --rm -v $D/:/usr/local/src/mailcalf/ --name=mailcalf-dev -p 4000:4000 mailcalf-dev iex -S mix phx.server
