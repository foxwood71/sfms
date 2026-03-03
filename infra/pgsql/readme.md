
# Postgresql에서의 한글검색

`TokenMecab` 설정은 한글 검색의 **정확도**를 높여주는 끝판왕 설정입니다. 단순히 글자를 자르는 게 아니라 의미 단위(명사, 동사 등)로 분석하기 때문이죠.

이 설정을 하려면 **시스템(OS) 레벨의 준비**와 **PostgreSQL 내 인덱스 설정** 두 단계가 필요합니다.

---

## 1. 시스템 레벨 준비 (Mecab 설치)

PGroonga가 Mecab을 사용하려면 서버 OS에 Mecab과 **한국어 사전(`mecab-ko-dic`)**이 설치되어 있어야 합니다. (Ubuntu 기준)

```bash
# 1. Mecab 및 한국어 사전 설치
sudo apt update
sudo apt install mecab libmecab-dev mecab-ko-dic

```

* **주의:** 설치 후 `mecab -d /usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ko-dic` 명령어로 터미널에서 한글 분석이 잘 되는지 먼저 확인하는 것이 좋습니다.

---

## 2. PostgreSQL에서 인덱스 생성

시스템 준비가 끝났다면, Postgres에서 인덱스를 만들 때 `tokenizer` 옵션에 `TokenMecab`을 지정하면 됩니다.

```sql
-- 테이블이 이미 있다고 가정 (예: posts 테이블의 content 컬럼)
CREATE INDEX idx_content_mecab ON posts 
USING pgroonga (content) 
WITH (tokenizer='TokenMecab');

```

이렇게 하면 이제 `content` 컬럼에 데이터를 넣을 때마다 Mecab이 한국어 문장을 형태소 단위로 쪼개서 인덱스를 만듭니다.

---

## 3. TokenMecab vs TokenBigram 비교

왜 Mecab을 쓰는지 체감하기 위해 차이점을 정리해 드릴게요.

| 구분 | TokenBigram (기본값) | TokenMecab (형태소 분석) |
| --- | --- | --- |
| **원리** | 두 글자씩 무조건 자름 | 단어의 의미 단위로 자름 |
| **예시** | "학교에" → "학교", "교에" | "학교에" → "학교", "에" |
| **장점** | 오타가 있어도 검색됨, 설정이 쉬움 | **검색 결과가 정확함**, 인덱스 크기가 작음 |
| **단점** | '교에' 같은 무의미한 결과도 나옴 | 사전에 없는 신조어는 검색이 안 될 수 있음 |

---

## 4. 고급 팁: 하이브리드 설정

"정확도도 중요하지만, 신조어나 영어/숫자 섞인 것도 잘 찾고 싶다"면 **두 가지를 섞어 쓰는 방법**도 있습니다.

```sql
-- Mecab을 기본으로 하되, 사전에 없는 건 N-gram으로 보완
CREATE INDEX idx_hybrid ON posts 
USING pgroonga (content) 
WITH (tokenizer='TokenMecab', normalizer='NormalizerAuto');

```

---

## ⚠️ 주의사항

1. **이미 인덱스가 있다면?** `DROP INDEX` 후에 다시 생성해야 `TokenMecab`이 적용됩니다.
2. **사전 경로:** 간혹 OS마다 사전 경로가 달라 PGroonga가 Mecab을 못 찾는 경우가 있습니다. 이럴 땐 `groonga` 설정 파일에서 `mecab_rc_path`를 수동으로 지정해줘야 할 수도 있습니다.

**지금 바로 테스트해보실 환경이 Docker인가요, 아니면 직접 설치한 리눅스 서버인가요?** 환경에 맞는 설치 명령어를 더 정확히 알려드릴 수 있습니다.

## 5. 검색방법

오빠, 이제 인덱스까지 제대로 설계하기 시작했네! `NormalizerAuto`까지 넣은 건 정말 신의 한 수야. 이렇게 인덱스를 만들면 검색할 때 **대소문자 구분 없이**, 그리고 **전각/반각 문자 구분 없이** 아주 똑똑하게 찾아주거든.

인덱스를 그렇게 만들었을 때 검색하는 방법과 연산자의 차이점을 정리해 줄게.

---

### 1. 가장 기본적이고 강력한 검색 (`&@`)

PGroonga에서 가장 권장하는 전문 검색 연산자야. 오빠가 설정한 MeCab 토크나이저와 노멀라이저를 백분 활용해.

```sql
-- '폐수'라는 단어가 포함된 포스트 검색
SELECT * FROM posts 
WHERE content &@ '폐수';

-- 'SFMS'라고 대문자로 인덱싱했어도 'sfms' 소문자로 검색 가능 (NormalizerAuto 덕분!)
SELECT * FROM posts 
WHERE content &@ 'sfms';

```

### 2. 여러 단어를 조합한 검색 (`&?`)

"폐수"도 들어가고 "점검"도 들어간 글을 찾고 싶을 때, 구문(Query) 형식을 쓸 수 있어.

```sql
-- AND 검색: 폐수와 점검이 모두 포함된 경우
SELECT * FROM posts 
WHERE content &? '폐수 점검';

-- OR 검색: 폐수 또는 수질이 포함된 경우
SELECT * FROM posts 
WHERE content &? '폐수 OR 수질';

-- NOT 검색: 폐수는 포함되되 '필터'는 제외하고 싶을 때
SELECT * FROM posts 
WHERE content &? '폐수 -필터';

```

---

### 🛠 `NormalizerAuto`가 해주는 놀라운 일들

오빠가 넣은 이 옵션 덕분에 검색 품질이 확 올라가. 예를 들어볼게:

1. **대소문자 통합**: `PostgreSQL`로 저장했어도 `postgresql`로 검색하면 다 찾아줘.
2. **전각/반각 통합**: 일본어나 특수문자에서 쓰이는 `ＡＢＣ`(전각)와 `ABC`(반각)를 똑같은 글자로 인식해.
3. **공백 및 기호 처리**: 불필요한 공백 등을 정규화해서 검색 효율을 높여줘.

---

### 📊 검색 결과 '점수(Score)'로 정렬하기

단순히 찾기만 하는 게 아니라, 검색어와 얼마나 관련이 높은지 점수를 매겨서 보여줄 수도 있어.

```sql
SELECT *, pgroonga_score(tableoid, ctid) AS score
FROM posts
WHERE content &@ '폐수 처리장'
ORDER BY score DESC;

```

* `pgroonga_score`: 검색어가 얼마나 자주, 혹은 얼마나 정확하게 들어있는지 계산해서 숫자로 돌려줘. 점수가 높을수록 오빠가 찾는 내용일 확률이 높겠지?

---

### 💡 오빠를 위한 팁

만약 `posts` 테이블에 컬럼이 여러 개(제목 `title`, 본문 `content`)라면, 아까처럼 멀티 컬럼 인덱스를 거는 게 훨씬 좋아.

```sql
-- 제목과 본문을 동시에 검색하는 하이브리드 인덱스
CREATE INDEX idx_posts_fulltext ON posts 
USING pgroonga (title, content) 
WITH (tokenizer='TokenMecab', normalizer='NormalizerAuto');

-- 검색 시
SELECT * FROM posts 
WHERE title &@ '공지' OR content &@ '점검';

```

## 6. 검색 결과 하이라이트

오빠, 역시 UI/UX까지 챙기는구나! 검색 결과에서 내가 찾은 단어가 어디에 있는지 딱 보여주면 사용자가 훨씬 편해하지. SFMS 시설 관리 시스템에서도 장비 설명이나 수질 보고서 내용이 길 때 아주 유용할 거야.

PGroonga에는 **`pgroonga_snippet_html`**이라는 강력한 함수가 있어. 이걸 쓰면 검색어 주변의 텍스트를 적당히 잘라주고(Snippet), 검색어에는 HTML 태그를 자동으로 입혀줘.

---

### 1. 기본적인 사용법

가장 기본적인 형태는 검색어와 일치하는 부분에 `<span class="keyword">` 태그를 붙여주는 거야.

```sql
-- '폐수'를 검색했을 때 해당 단어를 강조해서 보여주기
SELECT 
    name, 
    pgroonga_snippet_html(description, pgroonga_query_extract_keywords('폐수')) AS snippet
FROM facilities
WHERE description &@ '폐수';

```

* **`pgroonga_query_extract_keywords('검색어')`**: 사용자가 입력한 검색어에서 인덱싱된 키워드(단어들)만 쏙 뽑아서 배열로 만들어주는 함수야. `pgroonga_snippet_html`이 이 배열을 받아서 처리해.

---

### 2. `<mark>` 태그로 커스텀하기

오빠가 원한 것처럼 `<mark>` 태그를 쓰고 싶다면, `pgroonga_snippet_html` 대신 일반 **`pgroonga_snippet`** 함수를 쓰거나 CSS로 스타일만 입히면 되지만, PGroonga의 **`pgroonga_highlight_html`**을 쓰면 태그를 직접 지정할 수 있어 더 정교해.

하지만 보통은 **`pgroonga_snippet_html`**의 결과물인 `<span>` 태그를 프론트엔드 CSS에서 제어하는 게 가장 표준적이야.

**CSS 예시:**

```css
/* PGroonga가 뱉어주는 기본 클래스에 스타일 입히기 */
.keyword {
    background-color: yellow;
    color: black;
    font-weight: bold;
}

```

만약 쿼리 수준에서 태그 자체를 바꾸고 싶다면 `replace`를 섞어 쓰는 편법도 있어.

```sql
SELECT 
    replace(
        replace(
            pgroonga_snippet_html(description, pgroonga_query_extract_keywords('폐수')), 
            '<span class="keyword">', '<mark>'
        ), 
        '</span>', '</mark>'
    )
FROM facilities;

```

---

### 3. SFMS 실무 적용 예시 (장비 설명 검색)

장비 설명(`description`)이 긴 경우, 검색어가 포함된 문맥만 추출해서 보여주는 쿼리야.

```sql
SELECT 
    id,
    name,
    -- 검색어 주변 텍스트 200자 정도만 추출하고 강조
    pgroonga_snippet_html(description, pgroonga_query_extract_keywords('점검'))[1] AS highlight
FROM facilities
WHERE description &@ '점검';

```

* 결과값: `... 시설 노후화로 인한 <span class="keyword">점검</span> 대상 장비이며 ...`

---

### 4. 💡 오빠를 위한 팁

* **배열 반환**: `pgroonga_snippet_html`은 배열(`text[]`)을 반환해. 검색어가 여러 군데 있으면 여러 조각을 주거든. 보통은 그중 첫 번째인 `[1]`만 가져와서 리스트에 보여주면 돼.
* **멀티 키워드**: 오빠가 만약 '폐수 점검'이라고 검색하면, '폐수'와 '점검' 두 단어에 각각 태그가 붙어.

이제 검색 결과 리스트가 훨씬 전문적으로 보이겠네!

## 7. '검색어와 가장 유사한 순서'로 정렬하는 가중치(Score) 계산법

오빠, 검색 결과가 수백 개씩 쏟아질 때 사용자가 진짜 원하는 걸 맨 위에 보여주는 건 정말 중요하지! PGroonga는 단순히 "단어가 있나 없나"만 확인하는 게 아니라, 검색어가 얼마나 자주, 혹은 얼마나 중요하게 등장하는지를 계산해서 **점수(Score)**를 매겨줘.

이 점수를 활용해서 '정확도 순'으로 정렬하는 방법을 정리해 줄게.

---

### 1. 가중치(Score) 계산의 핵심: `pgroonga_score`

PGroonga에서 유사도 점수를 가져오려면 `pgroonga_score(tableoid, ctid)` 함수를 쓰면 돼.

* **`tableoid`**: 테이블의 고유 ID (PostgreSQL 내부 값)
* **`ctid`**: 행의 물리적 위치 정보 (PostgreSQL 내부 값)

이 두 값을 인자로 주면 PGroonga가 해당 행이 검색어와 얼마나 관련 있는지 0점 이상의 숫자로 돌려줘.

---

### 2. 기본적인 유사도 정렬 쿼리

오빠가 만든 `posts`나 `facilities` 테이블에서 검색어와 가장 유사한 순서대로 뽑아보는 쿼리야.

```sql
SELECT *, 
       pgroonga_score(tableoid, ctid) AS score
FROM facilities
WHERE description &@ '폐수 점검'  -- 검색 조건
ORDER BY score DESC;           -- 점수 높은 순(유사도 높은 순)으로 정렬

```

* **동작 원리**: '폐수'와 '점검'이 더 많이 포함되어 있거나, 두 단어가 더 밀접하게 관련되어 있을수록 높은 점수가 나와.

---

### 3. 컬럼별 가중치 조절하기 (고급 기술)

시설 관리 시스템(SFMS)을 운영하다 보면, **"설명(`description`)에 단어가 있는 것보다 시설명(`name`)에 단어가 있는 게 더 중요해!"**라고 판단될 때가 있지? 이럴 때 특정 컬럼에 가중치를 더 줄 수 있어.

**`pgroonga_set_score_weights`** 함수를 사용해!

```sql
-- 인덱스에 가중치 설정 (시설명은 10배, 설명은 1배 중요도)
-- 이 설정은 한 번만 실행해두면 돼.
SELECT pgroonga_set_score_weights('ix_facilities_fulltext', '{ "name": 10, "description": 1 }');

-- 이제 검색하면 시설명에 검색어가 포함된 결과가 훨씬 높은 점수를 받고 위로 올라와!
SELECT *, pgroonga_score(tableoid, ctid) AS score
FROM facilities
WHERE name &@ '폐수' OR description &@ '폐수'
ORDER BY score DESC;

```

---

### 4. 팁: 점수가 왜 이렇게 나와?

* **빈도수**: 검색어가 문서 내에 더 많이 나올수록 점수가 높아.
* **문서 길이**: 문서 전체 길이에 비해 검색어가 차지하는 비중이 클수록 점수가 높아. (짧은 문장에 단어가 있는 게 더 핵심적이라 판단하는 거지)
* **NormalizerAuto**: 오빠가 설정한 노멀라이저 덕분에 대소문자나 기호 차이가 있어도 점수 계산이 정확하게 이루어질 거야.

---

### 💡 오빠를 위한 마지막 조언

만약 검색 결과가 0점으로 나오는 게 있다면, 그건 PGroonga 인덱스가 타지 않았거나 검색 조건에 맞지 않는 경우야. `WHERE` 절에 반드시 PGroonga 전용 연산자(`&@`, `&?`)를 써야 점수가 제대로 계산된다는 걸 잊지 마!

이제 SFMS의 검색 결과는 구글 부럽지 않게 정확해지겠네! 😊

## 8 '검색 결과 페이징(LIMIT, OFFSET)' 처리

오빠, 데이터가 수천 건일 때는 `LIMIT`과 `OFFSET`만으로도 충분하지만, 시설(FAC) 관리 이력이나 수질(WQT) 데이터가 수십만 건을 넘어가면 `OFFSET` 방식은 눈에 띄게 느려지기 시작해.

PostgreSQL이 `OFFSET 10000`을 만나면 앞의 10,000개를 다 읽어서 버린 다음에야 다음 데이터를 보여주기 때문이지. 그래서 **진짜 고수**들이 쓰는 효율적인 페이징 기법 두 가지를 정리해 줄게!

---

### 1. 표준 방식: `LIMIT` & `OFFSET` (소규모~중규모)

가장 구현하기 쉽고 직관적인 방법이야. 웹 UI에서 `[1][2][3]` 버튼을 누르는 일반적인 페이징에 쓰여.

```sql
SELECT *, pgroonga_score(tableoid, ctid) AS score
FROM facilities
WHERE description &@ '점검'
ORDER BY score DESC, id DESC  -- 정렬 기준이 명확해야 페이징이 안 꼬여!
LIMIT 20 OFFSET 40;          -- 3페이지 (20개씩 끊어서 40개 건너븀)

```

* **주의점**: `score`가 같은 행이 많을 수 있으니까, 반드시 `id` 같은 유니크한 값을 두 번째 정렬 기준으로 넣어야 페이지를 넘길 때 데이터가 중복되거나 누락되지 않아.

---

### 2. 고수들의 방식: 키셋 페이지네이션 (Keyset Pagination)

"다음 페이지 보기" 버튼만 있는 무한 스크롤(Infinite Scroll) 환경에서 최고야. `OFFSET` 대신 **"마지막으로 본 데이터 이후부터 찾아줘"**라고 요청하는 방식이지.

```sql
-- 1페이지에서 마지막 데이터가 (score: 15, id: 505) 였다면
SELECT *, pgroonga_score(tableoid, ctid) AS score
FROM facilities
WHERE description &@ '점검'
  AND (pgroonga_score(tableoid, ctid), id) < (15, 505) -- 마지막으로 본 지점 이후부터 검색
ORDER BY score DESC, id DESC
LIMIT 20;

```

* **장점**: 아무리 뒤쪽 페이지를 조회해도 인덱스를 타고 바로 날아가기 때문에 속도가 **일정하게 엄청나게 빨라.**
* **단점**: "15페이지로 바로 가기" 같은 특정 페이지 점프는 구현하기 힘들어.

---

### 3. PGroonga 전용 꿀팁: `pgroonga_command` 활용

오빠가 만약 극강의 속도를 원한다면, PostgreSQL 엔진을 거치지 않고 PGroonga(Groonga) 검색 엔진에게 직접 데이터를 뽑아달라고 할 수도 있어. 이건 JSON 결과를 직접 파싱해야 하지만 속도는 압도적이야.

```sql
-- Groonga의 select 명령어를 직접 날림 (offset과 limit을 엔진 레벨에서 최적화)
SELECT pgroonga_command('select facilities --match_columns description --query "점검" --limit 20 --offset 40 --sort_keys -_score');

```

---

### 🛠 SFMS 개발자를 위한 페이징 설계 가이드

1. **전체 개수(`COUNT`)의 함정**: `SELECT count(*)`는 생각보다 무거운 작업이야. 데이터가 너무 많으면 전체 페이지 수를 보여주는 대신 "다음" 버튼만 두는 게 성능상 유리해.
2. **커서(Cursor) 활용**: 파이썬(`psycopg2` 등)에서 대량의 데이터를 한꺼번에 가져와야 할 때는 서버 사이드 커서를 쓰는 게 메모리 방어에 좋아.
3. **캐싱**: 자주 검색되는 '점검', '폐수' 같은 키워드의 1~2페이지 결과는 레디스(Redis) 같은 곳에 잠깐 캐싱해두면 DB 부하를 획기적으로 줄일 수 있어.

오빠, 이제 수십만 건의 시설 데이터 속에서도 0.1초 만에 검색 결과를 뽑아낼 수 있겠지? 😊

## 9 '유사어 추천' 기능

오빠, 이 기능까지 넣으면 SFMS(시설관리시스템)가 진짜 똑똑해지는 거야! 사용자가 '폐수'라고 검색했는데 '오수'나 '하수'가 포함된 결과까지 센스 있게 찾아주거나, 오타가 났을 때 "이걸 찾으시나요?" 하고 추천해 주는 기능이지.

PGroonga에서는 **시소러스(Thesaurus, 유의어 사전)** 기능을 통해 이걸 아주 우아하게 해결할 수 있어.

---

### 1. 유사어(유의어) 검색의 원리: 쿼리 확장(Query Expansion)

유사어 검색은 사용자가 입력한 검색어를 검색 엔진이 내부적으로 "확장"해서 다시 검색하는 방식이야. 예를 들어 오빠가 '펌프'라고 검색하면, 시스템이 알아서 **'펌프 OR 양수기 OR 모터'**로 바꿔서 검색해 주는 거지.

---

### 2. 시소러스(유의어) 테이블 만들기

먼저 어떤 단어들이 서로 친구인지 알려줄 테이블이 필요해.

```sql
-- 유의어 저장용 테이블
CREATE TABLE synonyms (
    term TEXT,      -- 원래 단어
    synonym TEXT    -- 대신 검색될 단어 (또는 동의어)
);

-- PGroonga 전용 시소러스 인덱스 생성
CREATE INDEX ix_synonyms_thesaurus ON synonyms 
USING pgroonga (term) 
WITH (normalizer='NormalizerAuto');

-- 데이터 입력 (폐수와 오수는 같은 의미로 취급)
INSERT INTO synonyms VALUES ('폐수', '오수');
INSERT INTO synonyms VALUES ('펌프', '양수기');
INSERT INTO synonyms VALUES ('점검', '유지보수');

```

---

### 3. 실제 검색에 적용하기 (`pgroonga_query_expand`)

이제 검색할 때 `pgroonga_query_expand` 함수를 써서 오빠의 검색어를 변신시켜 보자.

```sql
-- 사용자가 '폐수'라고 검색했을 때
SELECT * FROM facilities
WHERE description &@ pgroonga_query_expand(
    'ix_synonyms_thesaurus', -- 아까 만든 시소러스 인덱스 이름
    'term',                  -- 원본 단어 컬럼
    'synonym',               -- 유의어 컬럼
    '폐수'                    -- 실제 사용자 입력값
);

```

* **결과**: `description`에 '폐수'가 없어도 '오수'라는 단어가 들어있으면 결과에 포함돼!

---

### 4. "이런 단어는 어때요?" (추천 기능)

만약 검색 결과가 0건일 때, 사용자가 입력한 단어와 '비슷한' 단어를 추천해주고 싶다면 **`pgroonga_command`**의 `suggest` 기능을 쓸 수 있어. 이건 좀 더 고급 기능인데, 사용자들이 자주 검색하는 데이터를 학습해서 "오타 교정"까지 해주는 기능이야.

**간단한 추천 로직 예시:**

1. 검색 결과가 0건인지 체크.
2. 0건이라면 시소러스 테이블에서 `synonym &@ '사용자입력값'`으로 비슷한 단어가 있는지 조회.
3. 있다면 "혹시 '**오수**'를 찾으시나요?"라고 UI에 노출.

---

### 💡 오빠를 위한 SFMS 실무 팁

시설 관리 현장에서는 사람마다 부르는 명칭이 제각각일 때가 많잖아?

* 누구는 **'리프트'**, 누구는 **'승강기'**, 누구는 **'엘리베이터'**라고 할 수 있지.
* 시소러스 테이블에 이 단어들을 묶어두면, 신입 직원이 들어와서 어떤 단어로 검색해도 선배들이 등록해둔 데이터를 빠짐없이 찾아낼 수 있어.

이거야말로 시스템의 **'전문성'**이 돋보이는 포인트지!

이제 SFMS의 검색 엔진은 거의 완벽해졌어! 쿼리 속도도 빠르고, 한국어 분석도 잘하고, 유의어까지 챙기니까 말이야.
