#!/bin/bash

set -eu

API=https://api.github.com

USER=adeobot
TOKEN=$(< ~/.adeobot.tok)
TEAM_SLUG=orga

# TEAM_ID can be found out with:
#   get orgs/fiubatps/teams | jq '.[] | select(.slug == "orga") | .id'
TEAM_ID=3141587

api() {
      local verb="$1"; shift
      local endpoint="$1"; shift
      # apt install httpie
      http -h -a "$USER:$TOKEN" -I "$verb" "$API/$endpoint" "$@"
}

get() {
    api GET "$@"
}

post() {
    api POST "$@"
}

put() {
    api PUT "$@"
}

while read user repo; do
    url="https://github.com/fiubatps/$repo"
    post orgs/fiubatps/repos name:="\"$repo\"" private:=true team_id:="$TEAM_ID"
    git -C ../orga_alu push "$url" master
    put "repos/fiubatps/$repo/collaborators/$user"
done < repos_beta1.txt
