## **“스포커 Git 커밋 컨벤션 가이드라인”**

# 🧩 SpoKer Git Commit Convention Guide

> SpoKer 프로젝트의 커밋 메시지는 코드의 역사와 품질을 유지하기 위한 중요한 기록입니다.  
> 이 문서는 팀 내 커밋 메시지 작성 규칙을 정의합니다.  
> **기준: Conventional Commits v1.0.0**

## 🧱 기본 형식


```html

<type>(<scope>): <subject>

<body>

<footer>

```

### 예시

``` 

feat(auth): add Google login button
fix(reward): prevent null pointer on reward box
chore: update Flutter SDK version

```

## 📘 type (커밋 유형)

| Type         | 설명                 | 예시                                              |
| ------------ | ------------------ | ----------------------------------------------- |
| **feat**     | 새로운 기능 추가          | `feat(reward): add seed reward feature`         |
| **fix**      | 버그 수정              | `fix(ui): fix leaderboard scroll glitch`        |
| **refactor** | 코드 리팩토링 (기능 변화 없음) | `refactor(hive): simplify cache initialization` |
| **style**    | 포맷팅, 세미콜론, 들여쓰기 등  | `style: reformat firestore service`             |
| **docs**     | 문서 수정              | `docs: update setup guide for Firebase CLI`     |
| **test**     | 테스트 코드 추가/수정       | `test(auth): add token refresh tests`           |
| **chore**    | 빌드, 설정, 의존성 관리     | `chore: upgrade dependencies`                   |
| **perf**     | 성능 개선              | `perf: optimize step count stream handling`     |
| **ci**       | CI/CD 설정 변경        | `ci: update GitHub Actions deploy pipeline`     |

## 🧭 scope (적용 범위)

* 변경이 발생한 기능/모듈/디렉토리를 명시합니다.
* 괄호 안에 작성하며 선택사항이지만 명확한 히스토리를 위해 권장합니다.

예시:

```
feat(auth): add login with Google
fix(reward): correct Firestore reward path
refactor(ui): extract common modal widget
```

## ✍️ subject (제목)

* **명령형(Imperative)** 으로 작성 (Add / Fix / Remove 등)
* 50자 이내, 마침표( . ) 사용 금지
* 첫 글자는 소문자, 간결하게 작성

✅ 좋은 예:

```
feat: add leaderboard screen
```

❌ 나쁜 예:

```
Added new leaderboard screen.
```

## 🧠 body (본문, 선택)

* 변경의 **이유(why)** 중심으로 작성
* 한 줄당 72자 이내
* 코드나 명령어 대신 **의도와 목적** 설명

예시:

```
feat(reward): add roulette animation and seed probability

- integrated Lottie animation for spin effect
- added Cloud Function call to fetch reward
- improved error handling for missing user ID
```

## 🏷 footer (선택)

* **BREAKING CHANGE:** 또는 **issue reference** (`Closes #42`) 명시할 때 사용

예시:

```
BREAKING CHANGE: changed Firestore reward schema to /users/{uid}/rewards
Closes #25
```

## ✅ 커밋 메시지 예시 모음

| 변경 내용                    | 커밋 메시지                                                          |
| ------------------------ | --------------------------------------------------------------- |
| Firebase Firestore 구조 변경 | `refactor(firestore): normalize reward subcollection structure` |
| Hive 캐시 기능 추가            | `feat(hive): implement local reward caching`                    |
| 보상 룰렛 애니메이션 버그 수정        | `fix(ui): fix rotation reset after spin`                        |
| README에 개발환경 추가          | `docs: add FlutterFire CLI setup instructions`                  |
| 배포 스크립트 수정               | `chore(ci): update firebase deploy workflow`                    |

## ⚙️ 커밋 메시지 자동 검사 설정 (선택)

### 1. 패키지 설치

```bash
npm install --save-dev @commitlint/{config-conventional,cli} husky
```

### 2. 설정 파일 추가

`.commitlintrc.json`

```json
{
  "extends": ["@commitlint/config-conventional"]
}
```

### 3. 훅 추가

```bash
npx husky add .husky/commit-msg "npx --no-install commitlint --edit $1"
```

→ 잘못된 형식의 커밋 메시지를 자동으로 차단합니다.

## 🧩 커밋 예시 (스포커 실제 워크플로우 기준)

| 시점    | 메시지                                           |
| ----- | --------------------------------------------- |
| 기능 추가 | `feat(reward): add roulette reward animation` |
| 버그 수정 | `fix(auth): prevent crash when token expired` |
| 코드 정리 | `refactor(hive): separate box init logic`     |
| 문서 보강 | `docs: update team setup and commit guide`    |
| 설정 변경 | `chore(ci): update github action workflow`    |

## 📜 참고

* [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
* [Commitlint Documentation](https://commitlint.js.org)
* [Angular Commit Message Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)

**팀 규칙 요약**

```
1️⃣ 형식: <type>(<scope>): <subject>
2️⃣ subject는 명령형, 50자 이내
3️⃣ body는 “무엇을, 왜” 중심
4️⃣ issue나 breaking change는 footer에 명시
```

