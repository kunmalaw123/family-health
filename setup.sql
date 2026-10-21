-- แผนสุขภาพครอบครัว — ตั้งค่าฐานข้อมูล (รันครั้งเดียวใน SQL Editor)
create table if not exists public.households (
  code text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.households enable row level security;
-- ไม่มี policy = ไม่มีใครอ่านตารางตรง ๆ ได้ ต้องผ่านฟังก์ชัน 2 ตัวนี้เท่านั้น

create or replace function public.house_get(p_code text)
returns jsonb language sql security definer set search_path = public as $$
  select data from public.households where code = p_code;
$$;

create or replace function public.house_put(p_code text, p_data jsonb)
returns timestamptz language plpgsql security definer set search_path = public as $$
begin
  if p_code !~ '^[0-9]{6}$' then raise exception 'bad code'; end if;
  if pg_column_size(p_data) > 3000000 then raise exception 'too big'; end if;
  insert into public.households(code, data, updated_at) values (p_code, p_data, now())
  on conflict (code) do update set data = excluded.data, updated_at = now();
  return now();
end $$;

revoke all on function public.house_get(text) from public;
revoke all on function public.house_put(text, jsonb) from public;
grant execute on function public.house_get(text) to anon, authenticated;
grant execute on function public.house_put(text, jsonb) to anon, authenticated;
