-- ════════════════════════════════════════════════════════════════
--  kfr 앱을 "통합 Supabase 프로젝트" 안에 올리기 위한 스키마 설정
--  ----------------------------------------------------------------
--  목적: 여러 앱을 무료 프로젝트 1개로 합칠 때, 앱마다 데이터를
--        섞이지 않게 별도 schema 로 분리합니다. (이 파일은 kfr 전용)
--
--  실행 위치: 통합으로 쓸 Supabase 프로젝트 → SQL Editor 에 붙여넣고 실행
--  실행 후 반드시 해야 할 일:
--    Dashboard → Project Settings → API → "Exposed schemas" 에
--    public, graphql_public 옆에  kfr  을 추가하고 저장하세요.
--    (이걸 안 하면 브라우저에서 kfr 스키마에 접근할 수 없습니다.)
-- ════════════════════════════════════════════════════════════════

-- 1) kfr 전용 스키마 생성
create schema if not exists kfr;

-- 2) 테이블 (기존 public 테이블과 동일한 구조)
create table if not exists kfr.branches (
  id   text primary key,
  name text not null,
  type text not null default 'DIRECT',   -- DIRECT | FRANCHISE
  pin  text not null
);

create table if not exists kfr.menus (
  id       text primary key,
  name     text not null,
  name_en  text,
  price    numeric not null default 0,
  category text,
  sort     int,
  active   boolean not null default true
);

create table if not exists kfr.kit_items (
  id         text primary key,
  name       text not null,
  name_en    text,
  category   text,
  unit_price numeric not null default 0,
  sort       int
);

create table if not exists kfr.closings (
  id        bigint generated always as identity primary key,
  branch_id text not null references kfr.branches(id),
  date      date not null,
  items     jsonb not null default '[]'::jsonb,
  cash      numeric not null default 0,
  gcash     numeric not null default 0
);

create table if not exists kfr.kit_orders (
  id          bigint generated always as identity primary key,
  branch_id   text not null references kfr.branches(id),
  date        date not null,
  items       jsonb not null default '[]'::jsonb,
  status      text not null default 'REQUESTED',  -- REQUESTED|CONFIRMED|SHIPPING|DELIVERED
  settle_mode text not null default 'NET'
);

create table if not exists kfr.expenses (
  id        bigint generated always as identity primary key,
  branch_id text not null references kfr.branches(id),
  date      date not null,
  category  text,
  amount    numeric not null default 0
);

create table if not exists kfr.app_settings (
  key   text primary key,
  value text
);

-- 조회 성능용 인덱스 (날짜/지점 필터를 자주 쓰므로)
create index if not exists idx_kfr_closings_branch_date  on kfr.closings  (branch_id, date);
create index if not exists idx_kfr_expenses_branch_date  on kfr.expenses  (branch_id, date);
create index if not exists idx_kfr_kit_orders_branch     on kfr.kit_orders(branch_id);

-- 3) 브라우저(anon 키)에서 접근할 수 있도록 권한 부여
--    ⚠️ 현재 앱은 자체 PIN 로그인만 쓰고 Supabase Auth 는 안 씁니다.
--       그래서 기존과 동일하게 anon 에 전체 권한을 주는 "허용형" 설정입니다.
grant usage on schema kfr to anon, authenticated;
grant all on all tables    in schema kfr to anon, authenticated;
grant all on all sequences in schema kfr to anon, authenticated;
-- 앞으로 추가되는 테이블/시퀀스에도 자동 적용
alter default privileges in schema kfr grant all on tables    to anon, authenticated;
alter default privileges in schema kfr grant all on sequences to anon, authenticated;

-- 4) RLS(행 수준 보안) — 켜고, 기존과 같은 "전체 허용" 정책을 답니다.
--    (보안을 더 조이고 싶으면 아래 using(true) 부분을 지점/역할 조건으로 바꾸세요.)
do $$
declare t text;
begin
  foreach t in array array['branches','menus','kit_items','closings','kit_orders','expenses','app_settings']
  loop
    execute format('alter table kfr.%I enable row level security;', t);
    execute format('drop policy if exists allow_all on kfr.%I;', t);
    execute format('create policy allow_all on kfr.%I for all using (true) with check (true);', t);
  end loop;
end $$;

-- ════════════════════════════════════════════════════════════════
--  데이터 이전(옮기기)은 이 파일이 아니라 아래 방법으로 진행하세요.
--  CONSOLIDATION_GUIDE.md 의 "3단계: 데이터 옮기기" 참고.
-- ════════════════════════════════════════════════════════════════
