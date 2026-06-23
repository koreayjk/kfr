-- ════════════════════════════════════════════════════════
-- 밀키트 주문 목록 교체 SQL
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 실행하세요.
-- ⚠️ unit_price(단가)는 가맹점 정산 계산에만 쓰입니다(호점 화면엔 안 보임).
--    지금은 0으로 넣어놨으니, 아래 숫자만 실제 단가로 바꿔서 실행하세요.
-- ⚠️ 기존 품목은 삭제됩니다. 과거 주문의 품목 이름 표시만 빈칸이 될 수 있습니다(데이터는 유지).
-- ════════════════════════════════════════════════════════

-- 1) 분류·영어명·정렬 컬럼 추가 (이미 있으면 무시)
alter table kit_items add column if not exists category text;
alter table kit_items add column if not exists name_en  text;
alter table kit_items add column if not exists sort     int;

-- 2) 기존 품목 전체 삭제
delete from kit_items;

-- 3) 새 주문 목록 입력
insert into kit_items (id, name, name_en, category, unit_price, sort) values
-- ── 코사마트 ──
('c1','불닭 오리지널','Buldak Black','COSA',0,1),
('c2','불닭 까르보','Buldak Carbo','COSA',0,2),
('c3','불닭 로제','Buldak Rose','COSA',0,3),
('c4','불닭 치즈','Buldak Cheese','COSA',0,4),
('c5','불닭 크림','Buldak Cream','COSA',0,5),
('c6','진라면','Jin Ramyeon','COSA',0,6),
('c7','신라면','Sin Ramyeon','COSA',0,7),
('c8','짜파게티','Chapagetti','COSA',0,8),
('c9','기타라면','Other Ramyeon','COSA',0,9),
('c10','김','Seaweed (Kim)','COSA',0,10),
('c11','김밥용 김','Kimbap Kim','COSA',0,11),
('c12','떡볶이 떡','Rice Cake','COSA',0,12),
('c13','오뎅','Fish Cakes','COSA',0,13),
('c14','만두','Dumplings','COSA',0,14),
('c15','김가루','Seaweed Powder','COSA',0,15),
-- ── 시장주문 ──
('m1','돈까스','Pork Cutlet','MARKET',0,16),
('m2','탕수육','Tangsuyuk','MARKET',0,17),
('m3','치킨','Chicken','MARKET',0,18),
('m4','삼겹살','Samgyeopsal','MARKET',0,19),
('m5','떡볶이 용기','Ttokbokki Bowl','MARKET',0,20),
('m6','도시락 용기','Lunch Boxes','MARKET',0,21),
('m7','음료수 컵','Beverage Cups','MARKET',0,22),
('m8','기타','Others','MARKET',0,23),
-- ── 이외 주문 물품 ──
('o1','가스','Gas','OTHER',0,24),
('o2','음료수','Carbonated Drinks','OTHER',0,25),
('o3','판매용 물','Bottle Water','OTHER',0,26),
('o4','아이스크림','Ice Cream','OTHER',0,27),
('o5','스팸','Spam','OTHER',0,28),
('o6','생수','Mineral Water','OTHER',0,29);
