#!/usr/bin/env bash
set -euo pipefail

API="https://api.cloudflare.com/client/v4"

ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-}"
ZONE_NAME="${CLOUDFLARE_ZONE_NAME:-castalia.institute}"
HOSTNAME="${CLOUDFLARE_ACCESS_HOSTNAME:-world.castalia.institute}"
PROTECTED_PATH="${CLOUDFLARE_ACCESS_PATH:-/families/mcshan/*}"
APP_NAME="${CLOUDFLARE_ACCESS_APP_NAME:-Castalia Worldschool - McShan}"
POLICY_NAME="${CLOUDFLARE_ACCESS_POLICY_NAME:-Allow Castalia Google members}"
ALLOWED_EMAIL_DOMAIN="${CLOUDFLARE_ACCESS_EMAIL_DOMAIN:-castalia.institute}"
ALLOWED_EMAIL="${CLOUDFLARE_ACCESS_EMAIL:-}"
IDP_ID="${CLOUDFLARE_ACCESS_IDP_ID:-}"

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "error: set CLOUDFLARE_API_TOKEN with Zone DNS Edit and Zero Trust Access app/policy permissions" >&2
  exit 1
fi

if [[ -z "${ACCOUNT_ID}" ]]; then
  echo "error: set CLOUDFLARE_ACCOUNT_ID" >&2
  exit 1
fi

auth_args=(
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
  -H "Content-Type: application/json"
)

cf_get() {
  curl -fsS "${auth_args[@]}" "$@"
}

cf_send() {
  local method="$1"
  local url="$2"
  local body="$3"
  curl -fsS -X "${method}" "${auth_args[@]}" --data "${body}" "${url}"
}

echo "Resolving Cloudflare zone: ${ZONE_NAME}"
ZONE_ID="$(
  cf_get "${API}/zones?name=${ZONE_NAME}" |
    jq -r '.result[0].id // empty'
)"

if [[ -z "${ZONE_ID}" ]]; then
  echo "error: could not resolve zone ${ZONE_NAME}" >&2
  exit 1
fi

echo "Ensuring proxied DNS record: ${HOSTNAME} -> castaliainstitute.github.io"
DNS_RECORD_ID="$(
  cf_get "${API}/zones/${ZONE_ID}/dns_records?type=CNAME&name=${HOSTNAME}" |
    jq -r '.result[0].id // empty'
)"

DNS_BODY="$(
  jq -n \
    --arg type "CNAME" \
    --arg name "${HOSTNAME}" \
    --arg content "castaliainstitute.github.io" \
    '{type: $type, name: $name, content: $content, proxied: true, ttl: 1}'
)"

if [[ -n "${DNS_RECORD_ID}" ]]; then
  cf_send PUT "${API}/zones/${ZONE_ID}/dns_records/${DNS_RECORD_ID}" "${DNS_BODY}" >/dev/null
else
  cf_send POST "${API}/zones/${ZONE_ID}/dns_records" "${DNS_BODY}" >/dev/null
fi

APP_DOMAIN="${HOSTNAME}${PROTECTED_PATH}"
echo "Ensuring Access application: ${APP_DOMAIN}"

APP_ID="$(
  cf_get "${API}/accounts/${ACCOUNT_ID}/access/apps" |
    jq -r --arg domain "${APP_DOMAIN}" '.result[]? | select(.domain == $domain) | .id' |
    head -n 1
)"

if [[ -n "${IDP_ID}" ]]; then
  ALLOWED_IDPS_JSON="$(jq -n --arg idp "${IDP_ID}" '[$idp]')"
  AUTO_REDIRECT=true
else
  ALLOWED_IDPS_JSON="[]"
  AUTO_REDIRECT=false
fi

APP_BODY="$(
  jq -n \
    --arg name "${APP_NAME}" \
    --arg domain "${APP_DOMAIN}" \
    --arg session "24h" \
    --argjson allowed_idps "${ALLOWED_IDPS_JSON}" \
    --argjson auto_redirect "${AUTO_REDIRECT}" \
    '{
      type: "self_hosted",
      name: $name,
      domain: $domain,
      session_duration: $session,
      allowed_idps: $allowed_idps,
      auto_redirect_to_identity: $auto_redirect
    }'
)"

if [[ -n "${APP_ID}" ]]; then
  cf_send PUT "${API}/accounts/${ACCOUNT_ID}/access/apps/${APP_ID}" "${APP_BODY}" >/dev/null
else
  APP_ID="$(
    cf_send POST "${API}/accounts/${ACCOUNT_ID}/access/apps" "${APP_BODY}" |
      jq -r '.result.id'
  )"
fi

echo "Ensuring Access allow policy: ${POLICY_NAME}"
POLICY_ID="$(
  cf_get "${API}/accounts/${ACCOUNT_ID}/access/apps/${APP_ID}/policies" |
    jq -r --arg name "${POLICY_NAME}" '.result[]? | select(.name == $name) | .id' |
    head -n 1
)"

if [[ -n "${ALLOWED_EMAIL}" ]]; then
  INCLUDE_JSON="$(jq -n --arg email "${ALLOWED_EMAIL}" '[{email: {email: $email}}]')"
else
  INCLUDE_JSON="$(jq -n --arg domain "${ALLOWED_EMAIL_DOMAIN}" '[{email_domain: {domain: $domain}}]')"
fi

POLICY_BODY="$(
  jq -n \
    --arg name "${POLICY_NAME}" \
    --arg decision "allow" \
    --argjson include "${INCLUDE_JSON}" \
    '{
      name: $name,
      decision: $decision,
      include: $include,
      precedence: 1
    }'
)"

if [[ -n "${POLICY_ID}" ]]; then
  cf_send PUT "${API}/accounts/${ACCOUNT_ID}/access/apps/${APP_ID}/policies/${POLICY_ID}" "${POLICY_BODY}" >/dev/null
else
  cf_send POST "${API}/accounts/${ACCOUNT_ID}/access/apps/${APP_ID}/policies" "${POLICY_BODY}" >/dev/null
fi

cat <<EOF
Cloudflare Access configured.

Protected URL: https://${HOSTNAME}${PROTECTED_PATH}
Application:   ${APP_NAME}
Policy:        ${POLICY_NAME}
Allowed:       ${ALLOWED_EMAIL:-*@${ALLOWED_EMAIL_DOMAIN}}

If your Zero Trust account has multiple identity providers, set
CLOUDFLARE_ACCESS_IDP_ID to the Google provider id and rerun this script.
EOF
