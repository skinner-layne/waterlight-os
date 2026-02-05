#!/bin/sh
# Wrapper: invokes the Alpha Frame init system
# In production, /sbin/init symlinks directly to the src version.
# This wrapper exists for development/testing.
exec "$(dirname "$0")/../src/alpha-frame/waterlight-init.sh" "$@"
