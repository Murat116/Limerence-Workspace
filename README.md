# Limerence Workspace

Umbrella-репозиторий экосистемы Limerence: мобильное приложение (React Native) и веб-конструктор для авторов.

## Структура

```
Limerence-Workspace/
├── mobile/          # Limerence-RN — nested git repo (gitignored)
├── web/             # Limerence-Author-Web-App — nested git repo (gitignored)
├── docs/            # Единая документация (specs, monetization, constructor)
├── supabase/        # Единая схема БД, migrations, edge functions
├── shared/          # Общий код (Supabase types, утилиты)
├── skills/          # Agent skills для Cursor
└── .cursor/rules/   # Cursor rules (common, mobile, web, scope)
```

## Как работать

1. Клонируй этот репозиторий и вложенные проекты:
   ```bash
   git clone https://github.com/Murat116/Limerence-Workspace.git
   cd Limerence-Workspace
   git clone https://github.com/Murat116/Limerence-RN.git mobile
   git clone https://github.com/Murat116/Limerence-Author-Web-App.git web
   ```
2. **Открывай `Limerence-Workspace` как root в Cursor** — rules и skills подхватятся автоматически.
3. `mobile/` и `web/` — независимые git-репозитории со своими remotes; umbrella их не трекает.

## Области задач

| Область | Пути |
|---------|------|
| Mobile | `mobile/src/**` |
| Web | `web/editor-app/**` |
| Shared | `docs/**`, `supabase/**`, `shared/**` |

Подробнее: `.cursor/rules/workspace-scope.mdc`
