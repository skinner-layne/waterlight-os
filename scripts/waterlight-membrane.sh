#!/bin/sh
# Wrapper: invokes the membrane management tool
exec "$(dirname "$0")/../src/membrane/waterlight-membrane.sh" "$@"
