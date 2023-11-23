#!/usr/bin/bash
set -e

D=$(realpath $(dirname $(dirname .)))

docker build -t mailcalf-dev -f dev.Dockerfile
exec docker run -it --rm -v $D/:/usr/local/src/mailcalf/ --name=mailcalf-dev -p 4000:4000 mailcalf-dev iex -S mix phx.server
