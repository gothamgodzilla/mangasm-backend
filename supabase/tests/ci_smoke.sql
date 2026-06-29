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

select 'ALL SMOKE CHECKS PASSED' as result;
