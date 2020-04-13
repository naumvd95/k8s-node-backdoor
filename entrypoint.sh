#!/bin/bash
set -ex
nodebackdoor forward-ssh --auth-keys=$AUTHORIZED_KEYS_PATH $@
