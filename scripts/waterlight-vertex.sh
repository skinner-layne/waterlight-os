#!/bin/sh
# Wrapper: invokes the vertex state management tool
exec "$(dirname "$0")/../src/vertex/waterlight-vertex.sh" "$@"
