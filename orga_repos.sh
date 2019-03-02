#!/bin/bash
#
# Resulta que low-level programming era hacer REST desde un shell script. /o\

set -eu

API=https://api.github.com

USER=adeobot
TOKEN=$(< ~/.adeobot.tok)
CHECK_ID=autograder
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

entregas_push='{"users": [], "teams": ["'"$TEAM_SLUG"'"]}'
status_checks='{"strict": false, "contexts": ["'"$CHECK_ID"'"]}'
pull_requests='{"dismiss_stale_reviews": true, "require_code_owner_reviews": true}'

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
    git push "$url" origin/skel_master:refs/heads/master \
                    origin/skel_entregas:refs/heads/entregas

    # Proteger la rama entregas.
    put "repos/fiubatps/$repo/branches/entregas/protection" \
         enforce_admins:=false                    \
         restrictions:="$entregas_push"           \
         required_status_checks:="$status_checks" \
         required_pull_request_reviews:="$pull_requests"

    # Enviar la invitación.
    put "repos/fiubatps/$repo/collaborators/$user"
done < repos_beta1.txt
