#!/usr/bin/env bash
set -e

MISE="$HOME/.local/bin/mise"
# Trust first, activating reads mise.local.toml too
"$MISE" trust
eval "$("$MISE" activate bash)"
"$MISE" install
sudo chmod 666 /ssh-agent

[ ! -f package.json ] || "$MISE" exec -- npm install
"$MISE" exec -- bundle install
"$MISE" exec -- bin/rails db:prepare
