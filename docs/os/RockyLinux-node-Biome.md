# Node Biome VSCode 설치 및 설정 가이드

**Biome**을 VSCode에서 **저장 시 자동 린트/포맷**하도록 설정합니다. ESLint + Prettier 완전 대체! [biomejs](https://biomejs.dev)

## 1. Biome 설치 (pnpm + mise)

### 프로젝트 설정 (.mise.toml)

```toml
[tools]
node = "22"
"npm:pnpm" = "9"
biome = "latest"

[hooks]
postinstall = "corepack enable pnpm"
```

### 설치 실행

```bash
mise trust
mise install
pnpm add -D @biomejs/biome
npx @biomejs/biome init  # biome.json 생성
```

## 2. VSCode 확장 설치

```
Extensions (Ctrl+Shift+X):
✅ Biome (biomejs.biome)  # 공식 확장
✅ TypeScript Importer     # 자동 import
❌ ESLint / Prettier       # 삭제 권장
```

## 3. VSCode 설정 (.vscode/settings.json)

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit",
    "source.organizeImports": "explicit",
    "source.addMissingImports": "explicit"
  },

  "[javascript][javascriptreact][typescript][typescriptreact][json][jsonc]": {
    "editor.defaultFormatter": "biomejs.biome",
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit"
    }
  }
}
```

## 4. biome.json 설정 (프로젝트 루트)

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9/config.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "style": { "noNonNullAssertion": "error" }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "lineWidth": 100,
    "formatWithErrors": true
  }
}
```

## 5. package.json 스크립트

```json
{
  "scripts": {
    "biome:check": "biome check .",
    "biome:fix": "biome check --write .",
    "biome:format": "biome format .",
    "biome:ci": "biome ci ."
  }
}
```

## 6. pre-commit 훅 (.pre-commit-config.yaml)

```yaml
repos:
  - repo: https://github.com/biomejs/biome
    rev: 1.9.7
    hooks:
      - id: biome_check
      - id: biome_format
```

## 7. 테스트 워크플로우

```text
1. Ctrl+Shift+P → Reload Window
2. 파일 생성 → 자동 포맷 확인
3. 저장(Ctrl+S) → 린트 + import 정리
4. 문제탭 → 오류 실시간 표시
```

## 🔍 동작 확인 체크리스트

- [ ] 저장 시 자동 포맷
- [ ] 빨간선 실시간 오류
- [ ] `Ctrl+.` 자동 수정 제안
- [ ] `Ctrl+Space` 자동완성
- [ ] import 자동 제안

## 🆚 기존 설정 비교

```text
이전 ❌
├── ESLint (500MB, 2초)
├── Prettier (100MB, 500ms)
├── 10개 설정파일
└── 충돌 발생

이후 ✅
├── Biome (20MB, 10ms)
├── biome.json 1개
└── 충돌 ZERO
```

## 🚀 mise + Biome 완성 워크플로우

```bash
cd frontend
mise trust           # Node 22 + Biome 자동
pnpm install         # 의존성
# VSCode 저장 → 즉시 린트/포맷!
pnpm biome ci .      # CI 통과
```

**완료!** **저장 = 완벽 코드** 환경 구축! 🎉
