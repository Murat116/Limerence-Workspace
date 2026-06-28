# Limerence — три git-репозитория

Cursor root: **Limerence-Workspace** (`/Users/anmin/Limerence/Limerence-Workspace`).

## workspace

- **Содержит:** `docs/`, `supabase/`, `.cursor/`, `Makefile`, shared specs
- **Не содержит:** `mobile/`, `web/` (в `.gitignore`)
- **Branch:** `main`
- **GitHub:** https://github.com/Murat116/Limerence-Workspace

## mobile

- **Path:** `mobile/`
- **App:** React Native player (`mobile/src/`)
- **Branch:** `main`
- **GitHub:** https://github.com/Murat116/Limerence-RN

## web

- **Path:** `web/`
- **App:** `web/editor-app/` (constructor)
- **Branch:** `developer` (не `main`)
- **GitHub:** https://github.com/Murat116/Limerence-Author-Web-App

## Typical cross-cutting split

| Change | Repo |
|--------|------|
| Supabase migration + docs | workspace |
| Player paywall, entitlements, billing | mobile |
| Constructor monetization UI | web |
