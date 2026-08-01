-- End-to-end smoke test run in CI after all migrations apply.
-- Any failed assertion raises and fails the job.
\set ON_ERROR_STOP on

-- Two members via the auth-user trigger.
insert into auth.users (id) values ('11111111-1111-1111-1111-111111111111');
insert into auth.users (id) values ('22222222-2222-2222-2222-222222222222');

do $$ begin
  if (select count(*) from public.profiles) <> 2 then
    raise exception 'trigger did not create profiles';
  end if;
  if (select count(*) from public.reputation_scores) <> 2 then
    raise exception 'trigger did not create reputation rows';
  end if;
end $$;

update public.profiles set handle='wolf',   location=st_makepoint(-118.49,34.01)::geography
  where id='11111111-1111-1111-1111-111111111111';
update public.profiles set handle='cipher', location=st_makepoint(-118.50,34.02)::geography
  where id='22222222-2222-2222-2222-222222222222';

-- Map RPC returns both within 5 miles.
do $$ begin
  if (select count(*) from public.users_within_radius(34.01,-118.49,8047)) < 1 then
    raise exception 'radius rpc returned no rows';
  end if;
end $$;

-- Token ledger: credit then debit, balance must reconcile, overdraw must fail.
insert into public.token_transactions(user_id,amount,type)
  values ('11111111-1111-1111-1111-111111111111', 100, 'earn_cam');
insert into public.token_transactions(user_id,amount,type)
  values ('11111111-1111-1111-1111-111111111111', -30, 'tip_sent');
do $$ begin
  if public.token_balance('11111111-1111-1111-1111-111111111111') <> 70 then
    raise exception 'token balance mismatch: expected 70';
  end if;
end $$;
do $$ begin
  insert into public.token_transactions(user_id,amount,type)
    values ('11111111-1111-1111-1111-111111111111', -1000, 'payout');
  raise exception 'overdraw should have been blocked';
exception when check_violation then null;  -- expected
end $$;

-- Video room occupancy.
insert into public.video_rooms(id,host_id,title) values
  ('33333333-3333-3333-3333-333333333333','11111111-1111-1111-1111-111111111111','Test Room');
insert into public.video_room_participants(room_id,user_id) values
  ('33333333-3333-3333-3333-333333333333','11111111-1111-1111-1111-111111111111'),
  ('33333333-3333-3333-3333-333333333333','22222222-2222-2222-2222-222222222222');
do $$ begin
  if public.room_occupancy('33333333-3333-3333-3333-333333333333') <> 2 then
    raise exception 'room occupancy expected 2';
  end if;
end $$;

-- pgvector taste vectors + match result.
insert into public.match_vectors(user_id, embedding) values
  ('11111111-1111-1111-1111-111111111111', ('[' || array_to_string(array_fill(0.1::real,'{128}'), ',') || ']')::vector),
  ('22222222-2222-2222-2222-222222222222', ('[' || array_to_string(array_fill(0.1::real,'{128}'), ',') || ']')::vector);
do $$ begin
  if (select mv1.embedding <=> mv2.embedding
      from public.match_vectors mv1, public.match_vectors mv2
      where mv1.user_id='11111111-1111-1111-1111-111111111111'
        and mv2.user_id='22222222-2222-2222-2222-222222222222') > 0.0001 then
    raise exception 'identical vectors should have ~0 cosine distance';
  end if;
end $$;

-- UGC safety (Guideline 1.2): flag content, action it, eject the author, audit.
insert into public.messages(id, sender_id, recipient_id, body) values
  ('44444444-4444-4444-4444-444444444444',
   '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'offending content');

insert into public.reports(id, reporter_id, reported_id, reason, content_type, content_id) values
  ('55555555-5555-5555-5555-555555555555',
   '22222222-2222-2222-2222-222222222222',
   '11111111-1111-1111-1111-111111111111',
   'harassment', 'message', '44444444-4444-4444-4444-444444444444');

-- Open report shows up in the moderation SLA queue.
do $$ begin
  if (select count(*) from public.reports_open_sla
      where id='55555555-5555-5555-5555-555555555555') <> 1 then
    raise exception 'open report missing from SLA queue';
  end if;
end $$;

-- Action it: content removed, author ejected, report resolved, action audited.
select public.action_report('55555555-5555-5555-5555-555555555555', 'remove_and_eject');
do $$ begin
  if exists (select 1 from public.messages where id='44444444-4444-4444-4444-444444444444') then
    raise exception 'offending message was not removed';
  end if;
  if not (select is_banned from public.profiles
          where id='11111111-1111-1111-1111-111111111111') then
    raise exception 'author was not ejected';
  end if;
  if (select status from public.reports
      where id='55555555-5555-5555-5555-555555555555') <> 'resolved' then
    raise exception 'report was not resolved';
  end if;
  if (select count(*) from public.moderation_actions
      where report_id='55555555-5555-5555-5555-555555555555') <> 1 then
    raise exception 'moderation action was not audited';
  end if;
end $$;

-- Terms acceptance is recorded (EULA gate).
insert into public.terms_acceptances(user_id, document, version) values
  ('22222222-2222-2222-2222-222222222222', 'eula', '1.0');
do $$ begin
  if (select count(*) from public.terms_acceptances
      where user_id='22222222-2222-2222-2222-222222222222') <> 1 then
    raise exception 'terms acceptance not recorded';
  end if;
end $$;

select 'ALL SMOKE CHECKS PASSED' as result;
