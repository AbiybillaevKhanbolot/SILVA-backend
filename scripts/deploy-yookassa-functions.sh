#!/usr/bin/env bash
# Одноразово: npx supabase@latest login
# Или: export SUPABASE_ACCESS_TOKEN=sbp_... (https://supabase.com/dashboard/account/tokens)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
REF="${SUPABASE_PROJECT_REF:-siqvswjrhmckufuaomhy}"
npx --yes supabase@latest link --project-ref "$REF"
npx --yes supabase@latest functions deploy yookassa-create-payment --no-verify-jwt
npx --yes supabase@latest functions deploy yookassa-payment-status --no-verify-jwt
echo "Edge Functions deployed for project ref: $REF"
