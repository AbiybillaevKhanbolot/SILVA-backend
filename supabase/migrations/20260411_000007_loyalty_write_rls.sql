-- Начисление баллов с клиента после оплаты (incrementLoyaltyPointsAfterPayment).
drop policy if exists "loyalty_accounts_own_insert" on public.loyalty_accounts;
create policy "loyalty_accounts_own_insert"
on public.loyalty_accounts for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "loyalty_accounts_own_update" on public.loyalty_accounts;
create policy "loyalty_accounts_own_update"
on public.loyalty_accounts for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "loyalty_transactions_own_insert" on public.loyalty_transactions;
create policy "loyalty_transactions_own_insert"
on public.loyalty_transactions for insert to authenticated
with check (user_id = auth.uid());
