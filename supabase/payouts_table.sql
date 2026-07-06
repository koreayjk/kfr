-- ════════════════════════════════════════════════════════════════
--  지급 장부(payouts) 테이블 — 호점별 · 품목별
--  Supabase → SQL Editor 에 붙여넣고 실행하세요. (kfr 스키마)
--  · 밀키트 주문 관리에서 "지급 수락"을 누르면 주문의 품목이 한 줄씩 쌓입니다.
--  · 단가·지급확인·비고는 지급 장부 화면에서 직접 수정합니다.
--  ⚠️ 아래 drop 은 예전(주간 누적) 형식의 테스트 테이블을 새 형식으로 교체합니다.
--     실제 저장한 지급 기록이 있다면 실행 전에 백업하세요.
-- ════════════════════════════════════════════════════════════════
drop table if exists kfr.payouts cascade;
create table kfr.payouts (
  id         bigint generated always as identity primary key,
  branch_id  text not null,
  order_id   bigint,                                  -- 연결된 밀키트 주문(있으면)
  date       date not null,                           -- 주문 날짜
  item       text not null default '',                -- 품목
  unit_price numeric not null default 0,              -- 단가(관리자 입력)
  qty        int not null default 0,                  -- 수량
  paid       boolean not null default false,          -- 지급확인 (대기/완료)
  note       text default '',                         -- 비고
  created_at timestamptz not null default now()
);
create index if not exists idx_kfr_payouts_branch on kfr.payouts(branch_id);

grant usage on schema kfr to anon, authenticated;
grant all on kfr.payouts to anon, authenticated;
grant all on all sequences in schema kfr to anon, authenticated;

alter table kfr.payouts enable row level security;
drop policy if exists allow_all on kfr.payouts;
create policy allow_all on kfr.payouts for all using (true) with check (true);
