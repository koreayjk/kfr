# Supabase 비용 줄이기 — 여러 앱을 무료 프로젝트 하나로 통합하기

## 왜 비용이 나왔나

Supabase 무료 플랜은 **조직(Organization)당 무료 프로젝트 2개까지**만 허용합니다.
서로 다른 앱을 각각 별도 프로젝트로 만들면 2개를 넘는 순간 유료 전환이 필요해져
프로젝트마다 요금이 붙습니다.

→ 해결책: **앱들을 Supabase 프로젝트 1개 안에 모으고, 앱마다 별도 `schema`로 분리**합니다.
프로젝트는 1개(무료)지만 데이터는 앱끼리 섞이지 않습니다.

| | 통합 전 | 통합 후 |
|---|---|---|
| 프로젝트 수 | 앱마다 1개 (요금 발생) | 1개 (무료) |
| 데이터 분리 | 프로젝트로 분리 | `schema`로 분리 (`kfr`, `app2`, …) |
| 용량 | — | 무료 500MB 안에 전부 들어감 |

---

## 한눈에 보는 순서

1. 통합으로 쓸 **메인 프로젝트 1개**를 정한다 (남길 무료 프로젝트).
2. 메인 프로젝트에 각 앱용 **스키마**를 만든다 (kfr은 `supabase/kfr_consolidated_schema.sql` 실행).
3. 메인 프로젝트 설정에서 **Exposed schemas**에 새 스키마 이름을 추가한다.
4. 옛 프로젝트들의 **데이터를 메인 프로젝트로 옮긴다**.
5. 각 앱 코드의 **URL/KEY/스키마**를 메인 프로젝트 값으로 바꾼다.
6. 잘 되는지 확인하고, 더 이상 안 쓰는 **유료 프로젝트를 삭제**한다 → 요금 0.

---

## kfr 앱 상세 절차

### 1단계 — 스키마 만들기
- 메인 프로젝트 → **SQL Editor** → `supabase/kfr_consolidated_schema.sql` 내용을 붙여넣고 **Run**.
- `kfr` 스키마와 7개 테이블(`branches`, `menus`, `kit_items`, `closings`, `kit_orders`, `expenses`, `app_settings`)이 생성됩니다.

### 2단계 — 스키마 노출(중요!)
- 메인 프로젝트 → **Project Settings → API → Exposed schemas**
- 기존 `public, graphql_public` 옆에 **`kfr`** 를 추가하고 저장.
- 이걸 빼먹으면 브라우저에서 `kfr` 스키마에 접근이 안 됩니다 (가장 흔한 실수).

### 3단계 — 데이터 옮기기
옛 kfr 프로젝트(public 스키마) → 메인 프로젝트(kfr 스키마)로 이동합니다.

**방법 A — CSV (간단, 추천)**
1. 옛 프로젝트 → **Table Editor** → 테이블마다 우측 메뉴 **Export → CSV** 로 7개 모두 내려받기.
2. 메인 프로젝트 → Table Editor → 좌측 상단 **schema 드롭다운을 `kfr`로 변경**.
3. 같은 이름 테이블을 골라 **Import data → CSV** 로 올리기.
4. 순서 주의: `branches`를 **먼저** 넣어야 합니다(다른 테이블이 branch_id로 참조).
5. CSV로 `id`를 그대로 가져온 테이블(`closings`, `kit_orders`, `expenses`)은 자동증가 번호를
   맞춰줘야 합니다. SQL Editor에서 한 번 실행:
   ```sql
   select setval(pg_get_serial_sequence('kfr.closings','id'),   coalesce(max(id),1)) from kfr.closings;
   select setval(pg_get_serial_sequence('kfr.kit_orders','id'), coalesce(max(id),1)) from kfr.kit_orders;
   select setval(pg_get_serial_sequence('kfr.expenses','id'),   coalesce(max(id),1)) from kfr.expenses;
   ```

**방법 B — pg_dump (한 번에, 터미널 사용 가능자)**
```bash
# 옛 프로젝트에서 public 스키마 데이터만 덤프
pg_dump "옛_프로젝트_연결문자열" --data-only --schema=public \
  -t public.branches -t public.menus -t public.kit_items \
  -t public.closings -t public.kit_orders -t public.expenses -t public.app_settings \
  > kfr_data.sql

# public. → kfr. 로 치환한 뒤 메인 프로젝트로 적재
sed 's/public\./kfr./g' kfr_data.sql | psql "메인_프로젝트_연결문자열"
```
(연결 문자열은 각 프로젝트 → Settings → Database → Connection string 에서 확인)

### 4단계 — 코드 전환
`index.html` 상단 3개 값만 바꿉니다(테이블 이름은 그대로 둠):
```js
const SUPABASE_URL    = "https://<메인프로젝트>.supabase.co";  // 메인 프로젝트 값
const SUPABASE_ANON_KEY = "<메인프로젝트 anon key>";            // 메인 프로젝트 값
const SUPABASE_SCHEMA = "kfr";   // "public" → "kfr" 로 변경
```
> `SUPABASE_SCHEMA`만 `public`으로 두면 통합 전과 100% 동일하게 동작합니다.
> 따라서 위 3줄을 **데이터 이전이 끝난 뒤 한 번에** 바꾸세요.

### 5단계 — 확인 & 정리
- 앱을 열어 로그인 → 마감/주문/지출 화면이 정상인지 확인.
- 문제 없으면 옛 kfr 프로젝트는 한동안 보관 후 삭제.
- 유료로 묶여 있던 프로젝트를 모두 메인으로 옮겨 삭제하면 **요금이 0**이 됩니다.

---

## 다른 앱들도 똑같이
앱마다 `kfr` 대신 자기 이름의 스키마(예: `app2`, `pos`)를 만들고 위 절차를 반복하면 됩니다.
각 앱 코드는 **같은 URL/KEY**를 쓰되 **자기 스키마**만 가리키게 하면, 무료 프로젝트 1개로 전부 운영됩니다.

## 보안 한 가지
한 프로젝트의 anon 키는 그 프로젝트에 **노출된 모든 스키마**에 닿을 수 있습니다.
지금 kfr은 원래도 anon 전체 허용(자체 PIN 로그인) 방식이라 보안 수준은 통합 전과 동일합니다.
더 엄격히 막고 싶다면 `kfr_consolidated_schema.sql`의 `using (true)` 정책을
지점/역할 기반 RLS 조건으로 바꾸면 됩니다.
