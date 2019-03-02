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
      http --check-status --ignore-stdin --headers \
           --auth "$USER:$TOKEN" "$verb" "$API/$endpoint" "$@"
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

    # Crear el repositorio.
    post orgs/fiubatps/repos name:="\"$repo\""   \
                             private:=true       \
                             has_wiki:=false     \
                             allow_squash_merge:=false \
                             allow_rebase_merge:=false

    # Dar permisos al equipo docente. (En el futuro, si hay múltiples
    # correctores, otorgar a este equipo acceso "push" en lugar de
    # "admin", y crear un sub-equipo separado para administradores.)
    put "teams/$TEAM_ID/repos/fiubatps/$repo" permission:='"admin"'

    # Enviar el esqueleto.
    git push "$url" origin/alu_readme:refs/heads/master

    # Enviar la invitación.
    put "repos/fiubatps/$repo/collaborators/$user"
done < repos_beta1.txt
