#!/bin/bash
#
# Resulta que low-level programming era hacer REST desde un shell script. /o\

set -eu

ORG="fiubatps"
API="https://api.github.com"

# El identificador numérico de un equipo "eqx" se puede obtener con:
#   http -a ... $API/orgs/$ORG/teams | jq '.[] | select(.slug == "eqx") | .id'
TEAM_ID=3141587
TEAM_SLUG="orga"

# Autenticación (con API token) para el bot de la administración.
API_TOKEN=$(< ~/.fiubatps.tok)

# Otras variables.
CHECK_ID="autograder"

api() {
      local verb="$1"; shift
      local endpoint="$1"; shift
      # apt install httpie
      http --check-status --ignore-stdin --headers \
           --auth ":$API_TOKEN" "$verb" "$API/$endpoint" "$@"
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
    url="https://github.com/$ORG/$repo"

    # Crear el repositorio.
    post "orgs/$ORG/repos" name:="\"$repo\""   \
                           private:=true       \
                           has_wiki:=false     \
                           allow_squash_merge:=false \
                           allow_rebase_merge:=false

    # Dar permisos al equipo docente.
    put "teams/$TEAM_ID/repos/$ORG/$repo" permission:='"admin"'

    # Enviar el esqueleto.
    git push "$url" origin/skel_master:refs/heads/master \
                    origin/skel_entregas:refs/heads/entregas

    # Proteger la rama entregas.
    put "repos/$ORG/$repo/branches/entregas/protection" \
         enforce_admins:=false                    \
         restrictions:="$entregas_push"           \
         required_status_checks:="$status_checks" \
         required_pull_request_reviews:="$pull_requests"

    # Enviar la invitación.
    put "repos/$ORG/$repo/collaborators/$user"
done < repos_beta1.txt
