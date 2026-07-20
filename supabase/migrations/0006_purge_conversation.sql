-- ============================================================================
-- 0006 — purge_conversation_with
-- Deletes all DMs between the caller and another member (both directions).
-- Used by live block → dissolve → removeConversation (Guideline 1.2).
-- RLS only allows senders to delete their own rows; this SECURITY DEFINER
-- RPC is required so a block clears received messages too.
-- ============================================================================

create or replace function public.purge_conversation_with(other_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  n int := 0;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  if other_user_id is null or other_user_id = me then
    return 0;
  end if;

  delete from public.messages
  where (sender_id = me and recipient_id = other_user_id)
     or (sender_id = other_user_id and recipient_id = me);

  get diagnostics n = row_count;
  return n;
end;
$$;

revoke all on function public.purge_conversation_with(uuid) from public;
grant execute on function public.purge_conversation_with(uuid) to authenticated;

comment on function public.purge_conversation_with(uuid) is
  'Authenticated member purges the full DM history with other_user_id (block/report UX).';
