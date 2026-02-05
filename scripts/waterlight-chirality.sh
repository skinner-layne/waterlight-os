#!/bin/sh
# Wrapper: invokes the chirality mode switching tool
exec "$(dirname "$0")/../src/chirality/waterlight-chirality.sh" "$@"
