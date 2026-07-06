-- ════════════════════════════════════════════════════════════════
--  지급 장부(payouts) 테이블 — 밀키트 대금 지급 기록
--  Supabase → SQL Editor 에 붙여넣고 실행하세요. (kfr 스키마)
--  · 밀키트 주문 관리에서 "지급 수락"을 누르면 이 표에 한 줄씩 쌓입니다.
--  · 금액/지급완료/비고는 관리자가 지급 장부 화면에서 직접 수정합니다.
-- ════════════════════════════════════════════════════════════════
create table if not exists kfr.payouts (
  id         bigint generated always as identity primary key,
  branch_id  text not null,
  order_id   bigint,                                  -- 연결된 밀키트 주문(있으면)
  date       date not null,                           -- 주문(정산) 날짜
  items      jsonb not null default '[]'::jsonb,      -- [{name, qty}] 스냅샷
  qty        int not null default 0,                  -- 총 수량
  amount     numeric not null default 0,              -- 금액(관리자 입력)
  paid       boolean not null default false,          -- 지급 완료
  note       text default '',                         -- 비고
  created_at timestamptz not null default now()
);
create index if not exists idx_kfr_payouts_branch_date on kfr.payouts(branch_id, date);

-- 브라우저(anon)에서 접근 권한 (기존 테이블과 동일한 허용형)
grant usage on schema kfr to anon, authenticated;
grant all on kfr.payouts to anon, authenticated;
grant all on all sequences in schema kfr to anon, authenticated;

alter table kfr.payouts enable row level security;
drop policy if exists allow_all on kfr.payouts;
create policy allow_all on kfr.payouts for all using (true) with check (true);
