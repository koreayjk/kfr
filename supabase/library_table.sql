-- ================================================================
-- 자료실(library) — 홍보 / 메뉴 / 레시피 / 기타 공용 게시판
-- 사진/영상을 함께 올려 회사 기록으로 누적합니다. (관리자·호점 모두 열람/작성)
--
-- 실행 순서 (Supabase 대시보드):
--   1) 아래 [A] 블록을 SQL Editor 에 붙여넣고 Run  -> library 테이블 생성
--   2) Storage -> New bucket -> 이름 "library", Public 체크 -> 생성
--   3) 아래 [B] 블록을 SQL Editor 에 붙여넣고 Run  -> 업로드/열람 권한(스토리지 정책)
--
-- 주의: 각 블록을 "한 줄씩 잘라서" 말고, 블록 전체를 통째로 복사해 붙여넣으세요.
--       kfr 스키마를 쓰므로 Project Settings -> API -> Exposed schemas 에
--       kfr 가 들어가 있어야 합니다(기존 설정이면 그대로 OK).
-- ================================================================


-- [A] 테이블 ------------------------------------------------------
create table if not exists kfr.library (
  id         bigint generated always as identity primary key,
  category   text not null default '기타',              -- 홍보 | 메뉴 | 레시피 | 기타
  title      text not null,
  body       text default '',
  media      jsonb not null default '[]'::jsonb,         -- [{t:'img'|'vid'|'yt'|'drive'|'link', url, id?, name?}]
  author     text default '',                            -- 작성자 표시 이름 (본사 / 호점명)
  author_id  text,                                       -- 작성 계정 id ('0' = 본사)
  created_at timestamptz not null default now()
);
create index if not exists idx_kfr_library_cat     on kfr.library(category);
create index if not exists idx_kfr_library_created on kfr.library(created_at desc);

grant usage on schema kfr to anon, authenticated;
grant all on kfr.library to anon, authenticated;
grant all on all sequences in schema kfr to anon, authenticated;

alter table kfr.library enable row level security;
drop policy if exists allow_all on kfr.library;
create policy allow_all on kfr.library for all using (true) with check (true);


-- [B] 스토리지 정책 (버킷 "library" 를 Public 으로 만든 뒤 실행) ---
-- 앱은 자체 PIN 로그인만 쓰므로 anon 키로 올립니다 -> anon 에 허용.

drop policy if exists "library read" on storage.objects;
create policy "library read" on storage.objects
  for select using (bucket_id = 'library');

drop policy if exists "library insert" on storage.objects;
create policy "library insert" on storage.objects
  for insert to anon, authenticated with check (bucket_id = 'library');

drop policy if exists "library update" on storage.objects;
create policy "library update" on storage.objects
  for update to anon, authenticated using (bucket_id = 'library');

drop policy if exists "library delete" on storage.objects;
create policy "library delete" on storage.objects
  for delete to anon, authenticated using (bucket_id = 'library');


-- 저장공간 팁 (무료 플랜 500MB / egress 한도 고려) ----------------
--  - 사진은 앱이 올릴 때 1280px / JPEG 로 자동 압축합니다.
--  - 레시피 영상은 가능하면 유튜브(비공개/일부공개)/구글드라이브 '링크'로 올리세요.
--    링크는 저장공간을 쓰지 않고 영상은 유튜브/드라이브가 대신 호스팅합니다.
--  - 직접 올리는 영상 파일은 앱에서 50MB 이하만 받습니다.
