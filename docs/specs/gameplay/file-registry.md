# Реестр файлов геймплея

Перечень файлов, участвующих в игровом цикле (от выбора книги до завершения главы).  
Общая логика: [Полное описание геймплея.md](./full-description.md).

Пути — относительно корня репозитория. Клик по ссылке открывает файл в IDE.

### Чеклист просмотра

В таблицах файлов колонка **✓** — отметка «уже отсмотрел»:

- `[ ]` — не смотрел
- `[x]` — отсмотрел

Поставить галочку: клик в preview (если поддерживается) или вручную заменить `[ ]` на `[x]` в исходнике. Прогресс хранится в этом файле в git.

### Аудит использования кода

**Дата оценки:** 2025-06-09. Метод: grep импортов и потребителей символов (не line-coverage).


| Колонка           | Смысл                                                                                                                                                                                                   |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **✓**             | Чекбокс просмотра (только в таблицах файлов ниже)                                                                                                                                                       |
| **Used%**         | Доля файла, задействованная в **рантайме** приложения. Мёртвые exports и неиспользуемые импорты снижают оценку. Для тестов и spec — см. примечание в ячейке.                                            |
| **Refactor 1–10** | Срочность рефакторинга: нарушение SRP, god-file, over-engineering, dead code, дублирование. **1–3** — ок; **4–6** — почистить exports / разнести; **7–8** — дробить; **9–10** — удалить или переписать. |


**Приоритет на чистку:** `QuestNavigationPopup`, `snapReanimated.ts`, `models/assetChange.ts`.  
**God-files:** `quest/thunks.ts`, `quest/slice.ts`, `mapper.ts`, `QuestGamePlayLogicManager.ts`.

---

## 1. Спецификация (контракт бизнес-логики)


| ✓   | Файл                                                                 | Назначение                                | Used% | Refactor |
| --- | -------------------------------------------------------------------- | ----------------------------------------- | ----- | -------- |
| [x] | [Полное описание геймплея.md](./full-description.md)     | Сводный документ: UX + техническая часть  | spec  | 4        |
| [x] | [Логика геймплея.md](./overview.md)                         | SceneFlow: старт главы, сцена, ending     | spec  | 4        |
| [x] | [Сущности/Книга.md](./entities/Книга.md)                             | Сущность Story                            | spec  | 3        |
| [x] | [Сущности/Глава.md](./entities/Глава.md)                             | Сущность Chapter                          | spec  | 3        |
| [x] | [Сущности/Сцена.md](./entities/Сцена.md)                             | Scene, типы, scene overlay                | spec  | 3        |
| [x] | [Сущности/Диалог.md](./entities/Диалог.md)                           | Dialog, DialogList, реплики               | spec  | 3        |
| [x] | [Сущности/Исход.md](./entities/Исход.md)                             | Variant, влияние на статы                 | spec  | 3        |
| [x] | [Сущности/Персонаж.md](./entities/Персонаж.md)                       | Person, слои, гардероб, prefetch          | spec  | 3        |
| [x] | [Сущности/РамкаДиалога.md](./entities/РамкаДиалога.md)               | DialogFrame, layout_data, SVG             | spec  | 3        |
| [x] | [Сущности/АудиоТрек.md](./entities/АудиоТрек.md)                     | BGM сцены, DialogAudioEvent               | spec  | 3        |
| [x] | [Сущности/Статы пользователя.md](./entities/Статы%20пользователя.md) | StatsUp, отображение статов               | spec  | 3        |
| [x] | [Сущности/BaseModel.md](./entities/BaseModel.md)                     | uuid у всех сущностей                     | spec  | 2        |
| [x] | [Техническая документация.md](../tech-architecture.md)      | Архитектура слоёв, Redux, персистентность | spec  | 4        |


---

## 2. Книга (Story)

### UI и вход в историю


| ✓   | Файл                                                                                                                                                           | Назначение                                    | Used% | Refactor |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- | ----- | -------- |
| [x] | [src/Feature/Home/HomeScreen.tsx](../../../mobile/src/Feature/Home/HomeScreen.tsx)                                                                                       | Каталог: карусель книг, переход к описанию    | 95    | 4        |
| [x] | [src/Feature/Stories/StoriesScreen.tsx](../../../mobile/src/Feature/Stories/StoriesScreen.tsx)                                                                           | Список всех историй                           | 95    | 4        |
| [x] | [src/Feature/MyStories/MyStoriesScreen.tsx](../../../mobile/src/Feature/MyStories/MyStoriesScreen.tsx)                                                                   | «Мои истории»                                 | 95    | 4        |
| [x] | [src/Feature/Story/StoryDescriptionScreen.tsx](../../../mobile/src/Feature/Story/StoryDescriptionScreen.tsx)                                                             | Карточка книги, кнопка «Читать», оглавление   | 95    | 5        |
| [x] | [src/Feature/Story/ChaptersScreen.tsx](../../../mobile/src/Feature/Story/ChaptersScreen.tsx)                                                                             | Список глав с статусами locked/available/read | 95    | 5        |
| [x] | [src/Feature/Story/components/ChapterListItem.tsx](../../../mobile/src/Feature/Story/components/ChapterListItem.tsx)                                                     | Ячейка главы в списке                         | 90    | 3        |
| [x] | [src/Feature/Story/screens/StoryGraphScreen/index.tsx](../../../mobile/src/Feature/Story/screens/StoryGraphScreen/index.tsx)                                             | Граф сюжета (Detroit-style)                   | 85    | 5        |
| [x] | [src/Feature/Story/screens/StoryGraphScreen/hooks/useStoryGraphData.ts](../../../mobile/src/Feature/Story/screens/StoryGraphScreen/hooks/useStoryGraphData.ts)           | Данные для графа сцен                         | 85    | 4        |
| [x] | [src/Feature/Story/screens/StoryGraphScreen/components/SceneNode.tsx](../../../mobile/src/Feature/Story/screens/StoryGraphScreen/components/SceneNode.tsx)               | Узел сцены на графе                           | 85    | 3        |
| [x] | [src/Feature/Story/screens/StoryGraphScreen/components/ChapterTabCell.tsx](../../../mobile/src/Feature/Story/screens/StoryGraphScreen/components/ChapterTabCell.tsx)     | Вкладка главы на графе                        | 85    | 3        |
| [x] | [src/Feature/Story/screens/StoryGraphScreen/components/DetroitGraphView.tsx](../../../mobile/src/Feature/Story/screens/StoryGraphScreen/components/DetroitGraphView.tsx) | Визуализация графа                            | 85    | 5        |
| [x] | [src/UIComponents/StoryCover.tsx](../../../mobile/src/UIComponents/StoryCover.tsx)                                                                                       | Обложка истории                               | 90    | 3        |
| [x] | [src/UIComponents/StoryProgressHeader.tsx](../../../mobile/src/UIComponents/StoryProgressHeader.tsx)                                                                     | Прогресс по главам на экране описания         | 90    | 3        |


### Redux / селекторы


| ✓   | Файл                                                                                                               | Назначение                         | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------------------------------------ | ---------------------------------- | ----- | -------- |
| [x] | [src/App/store/story/storiesSlice.ts](../../../mobile/src/App/store/story/storiesSlice.ts)                                   | Кеш книг, `fetchStoryById`, `byId` | 95    | 5        |
| [x] | [src/App/store/story/storySelectors.ts](../../../mobile/src/App/store/story/storySelectors.ts)                               | `selectStoryById`, текущая история | 90    | 4        |
| [x] | [src/App/store/story/index.ts](../../../mobile/src/App/store/story/index.ts)                                                 | Re-export story slice              | 95    | 3        |
| [x] | [src/App/store/story/storyCleanupThunks.ts](../../../mobile/src/App/store/story/storyCleanupThunks.ts)                       | Очистка state при выходе из квеста | 90    | 6        |
| [x] | [src/App/store/selectors/storyDescriptionSelectors.ts](../../../mobile/src/App/store/selectors/storyDescriptionSelectors.ts) | Состояние кнопки «Читать»          | 80    | 3        |


### Модели и Domain


| ✓   | Файл                                                                                                             | Назначение                        | Used% | Refactor |
| --- | ---------------------------------------------------------------------------------------------------------------- | --------------------------------- | ----- | -------- |
| [x] | [src/Common/models/story.tsx](../../../mobile/src/Common/models/story.tsx)                                                 | UI-модель Story                   | 95    | 3        |
| [x] | [src/Common/models/genre.tsx](../../../mobile/src/Common/models/genre.tsx)                                                 | Жанры книги                       | 85    | 2        |
| [x] | [src/Service/data/Domain/StoryDomain.ts](../../../mobile/src/Service/data/Domain/StoryDomain.ts)                           | Domain: книга + главы             | 95    | 4        |
| [x] | [src/Service/data/Domain/StoryStyleDomain.ts](../../../mobile/src/Service/data/Domain/StoryStyleDomain.ts)                 | Палитра истории (цвета UI)        | 90    | 3        |
| [x] | [src/Service/data/Domain/GenreDomain.ts](../../../mobile/src/Service/data/Domain/GenreDomain.ts)                           | Domain жанра                      | 85    | 2        |
| [x] | [src/Service/data/StoryStyleMapper.ts](../../../mobile/src/Service/data/StoryStyleMapper.ts)                               | DTO → StoryStyleDomain            | 90    | 3        |
| [x] | [src/Service/data/GenreMapper.ts](../../../mobile/src/Service/data/GenreMapper.ts)                                         | DTO → GenreDomain                 | 85    | 3        |
| [x] | [src/Service/Stories/StoriesService.ts](../../../mobile/src/Service/Stories/StoriesService.ts)                             | Фасад: книги, dialog frames       | 95    | 6        |
| [x] | [src/Service/Stories/Manager/StoriesManager.ts](../../../mobile/src/Service/Stories/Manager/StoriesManager.ts)             | Кеш историй в AsyncStorage        | 90    | 5        |
| [x] | [src/Service/Stories/Repository/StoriesRepository.ts](../../../mobile/src/Service/Stories/Repository/StoriesRepository.ts) | Supabase: список и детали историй | 90    | 5        |


---

## 3. Глава (Chapter)

### UI


| ✓   | Файл                                                                                                                                                                               | Назначение                                 | Used% | Refactor |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ | ----- | -------- |
| [x] | [src/Feature/Quest/screens/ChapterStartScreen/](../../../mobile/src/Feature/Quest/screens/ChapterStartScreen/)                                                                               | Старт главы: screen-as-folder              | 95    | 4        |
| [x] | [src/Feature/Quest/screens/ChapterStartScreen/ChapterStartScreen.tsx](../../../mobile/src/Feature/Quest/screens/ChapterStartScreen/ChapterStartScreen.tsx)                                   | Container: switch по `ChapterStartUIModel` | 95    | 3        |
| [x] | [src/Feature/Quest/screens/ChapterStartScreen/hooks/useChapterStartScreen.ts](../../../mobile/src/Feature/Quest/screens/ChapterStartScreen/hooks/useChapterStartScreen.ts)                   | Redux, effects, handlers, mapper           | 95    | 5        |
| [x] | [src/Feature/Quest/screens/ChapterStartScreen/models/chapterStartUIModel.ts](../../../mobile/src/Feature/Quest/screens/ChapterStartScreen/models/chapterStartUIModel.ts)                     | UI ViewModel типы, `ChapterStartViewKind`  | 95    | 2        |
| [x] | [src/Feature/Quest/screens/ChapterStartScreen/constants/chapterStartConstants.ts](../../../mobile/src/Feature/Quest/screens/ChapterStartScreen/constants/chapterStartConstants.ts)           | Тексты ошибок, шаги LoadingScreen          | 90    | 2        |
| [x] | [src/Feature/Quest/screens/ChapterStartScreen/mappers/chapterStartMapper.ts](../../../mobile/src/Feature/Quest/screens/ChapterStartScreen/mappers/chapterStartMapper.ts)                     | Domain/Story → UI ViewModel                | 95    | 4        |
| [x] | [src/Feature/Quest/screens/ChapterStartScreen/mappers/resolveChapterStartViewState.ts](../../../mobile/src/Feature/Quest/screens/ChapterStartScreen/mappers/resolveChapterStartViewState.ts) | Pure: выбор фазы UI по contentUpdate       | 95    | 2        |
| [x] | [src/Feature/Quest/screens/ChapterStartScreen/components/](../../../mobile/src/Feature/Quest/screens/ChapterStartScreen/components/)                                                         | Presentational subcomponents               | 90    | 3        |
| [x] | [TestQase/ChapterStart/](../../TestQase/ChapterStart/)                                                                                                                             | QA-сценарии начала главы для Qase          | QA    | 2        |
| [x] | [src/Feature/Quest/screens/ChapterEndingScreen.tsx](../../../mobile/src/Feature/Quest/screens/ChapterEndingScreen.tsx)                                                                       | Финал главы, статы, «Следующая глава»      | 95    | 4        |
| [x] | [src/Feature/Loading/LoadingScreen.tsx](../../../mobile/src/Feature/Loading/LoadingScreen.tsx)                                                                                               | Прогресс загрузки с цитатами               | 90    | 4        |
| [x] | [src/Feature/Loading/overlays/ContentUpdateOverlay.tsx](../../../mobile/src/Feature/Loading/overlays/ContentUpdateOverlay.tsx)                                                               | Overlay скачивания главы                   | 90    | 3        |


### Redux


| ✓   | Файл                                                                                                         | Назначение                                                                | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- | ----- | -------- |
| [x] | [src/App/store/chapter/types.ts](../../../mobile/src/App/store/chapter/types.ts)                                       | Контракт session cache: `currentChapter`, `currentStoryId`, loading/error | 90    | 2        |
| [x] | [src/App/store/chapter/chapterSlice.ts](../../../mobile/src/App/store/chapter/chapterSlice.ts)                         | Session cache одной подготовленной главы                                  | 95    | 4        |
| [x] | [src/App/store/chapter/chapterThunks.ts](../../../mobile/src/App/store/chapter/chapterThunks.ts)                       | `loadCurrentChapterForStory`                                              | 90    | 4        |
| [x] | [src/App/store/chapter/chapterSelectors.ts](../../../mobile/src/App/store/chapter/chapterSelectors.ts)                 | `selectDisplayChapterForStart`, `selectIsChapterDataLoaded`               | 90    | 4        |
| [x] | [src/App/store/chapter/chapterComputedSelectors.ts](../../../mobile/src/App/store/chapter/chapterComputedSelectors.ts) | `selectChaptersWithStatusFromStory` (каталог из `story.chapters`)         | 85    | 4        |
| [x] | [src/App/store/chapter/chapterHelpers.ts](../../../mobile/src/App/store/chapter/chapterHelpers.ts)                     | `enrichChapterWithStatus`, `chapterMetadataToDisplayDomain`               | 90    | 3        |
| [x] | [src/App/store/chapter/index.ts](../../../mobile/src/App/store/chapter/index.ts)                                       | Re-export chapter module                                                  | 90    | 2        |
| [x] | [src/App/store/chapterEnding/chapterEndingSlice.ts](../../../mobile/src/App/store/chapterEnding/chapterEndingSlice.ts) | Загрузка статов для ending screen                                         | 90    | 4        |
| [x] | [src/App/store/story/contentUpdateSlice.ts](../../../mobile/src/App/store/story/contentUpdateSlice.ts)                 | Фазы проверки/скачивания контента                                         | 95    | 5        |
| [x] | [src/App/store/story/contentUpdateThunks.ts](../../../mobile/src/App/store/story/contentUpdateThunks.ts)               | `checkChapterUpdateNeeded`, download                                      | 90    | 7        |


### Service


| ✓   | Файл                                                                                                       | Назначение                                               | Used% | Refactor |
| --- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | ----- | -------- |
| [x] | [src/Service/DataEstimationService.ts](../../../mobile/src/Service/DataEstimationService.ts)                         | Оценка объёма данных главы                               | 85    | 4        |
| [x] | [src/Service/Stories/chapterContentFreshness.ts](../../../mobile/src/Service/Stories/chapterContentFreshness.ts)     | Pure: `resolveChapterUpdateNeeded`, сравнение timestamps | 95    | 2        |
| [x] | [src/Service/Stories/ChapterUpdateCheckService.ts](../../../mobile/src/Service/Stories/ChapterUpdateCheckService.ts) | Свежесть кеша главы: QuestManager + `Chapter.updated_at` | 90    | 4        |


### Модели


| ✓   | Файл                                                                                       | Назначение                             | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------------ | -------------------------------------- | ----- | -------- |
| [x] | [src/Common/models/chapter.tsx](../../../mobile/src/Common/models/chapter.tsx)                       | UI-модель Chapter                      | 90    | 3        |
| [x] | [src/Service/data/Domain/ChapterDomain.ts](../../../mobile/src/Service/data/Domain/ChapterDomain.ts) | Domain: глава + scenes + projectAssets | 95    | 3        |


---

## 4. Сцена (Scene) — regular / cutscene / wardrobe

### UI — экраны


| ✓   | Файл                                                                                               | Назначение                                                          | Used% | Refactor |
| --- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- | ----- | -------- |
| [x] | [src/Feature/Quest/screens/QuestScreen.tsx](../../../mobile/src/Feature/Quest/screens/QuestScreen.tsx)       | Контейнер: Scene / Cutscene / Wardrobe по `sceneType`               | 95    | 6        |
| [x] | [src/Feature/Quest/screens/SceneScreen/](../../../mobile/src/Feature/Quest/screens/SceneScreen/)             | `regular`: UIModel + hook + ScenePlayingView; без loader/completing | 95    | 3        |
| [x] | [src/Feature/Quest/screens/CutsceneScreen.tsx](../../../mobile/src/Feature/Quest/screens/CutsceneScreen.tsx) | `cutscene`: только фон, тап → следующая сцена                       | 90    | 5        |
| [x] | [src/Feature/Quest/screens/WardrobeScreen.tsx](../../../mobile/src/Feature/Quest/screens/WardrobeScreen.tsx) | `wardrobe`: выбор внешности ГГ                                      | 90    | 5        |


### UI — фон и камера


| ✓   | Файл                                                                                                                                                 | Назначение                                                         | Used% | Refactor |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ | ----- | -------- |
| [x] | [src/Feature/Quest/components/SceneBackground.tsx](../../../mobile/src/Feature/Quest/components/SceneBackground.tsx)                                           | Фон сцены, tap handler, crossfade                                  | 95    | 6        |
| [x] | [src/Feature/Quest/components/sceneBackground/SceneBackgroundLayer.tsx](../../../mobile/src/Feature/Quest/components/sceneBackground/SceneBackgroundLayer.tsx) | Один слой фона (double-buffer)                                     | 95    | 4        |
| [x] | [src/Feature/Quest/components/sceneBackground/constants.ts](../../../mobile/src/Feature/Quest/components/sceneBackground/constants.ts)                         | Тайминги камеры и scene fade                                       | 95    | 2        |
| [x] | [src/Feature/Quest/components/SceneHeader.tsx](../../../mobile/src/Feature/Quest/components/SceneHeader.tsx)                                                   | Домой, гардероб, оглавление                                        | 90    | 4        |
| [x] | [src/Feature/Quest/components/SceneTransitionOverlay.tsx](../../../mobile/src/Feature/Quest/components/SceneTransitionOverlay.tsx)                             | Чёрный overlay при смене сцены                                     | 90    | 3        |
| [x] | [src/Feature/Quest/hooks/useBackgroundCrossfade.ts](../../../mobile/src/Feature/Quest/hooks/useBackgroundCrossfade.ts)                                         | Crossfade URL фона внутри сцены                                    | 90    | 4        |
| [x] | [src/Feature/Quest/hooks/useSceneBackgroundLayerStyles.ts](../../../mobile/src/Feature/Quest/hooks/useSceneBackgroundLayerStyles.ts)                           | Стили слоёв фона + camera pan                                      | 90    | 4        |
| [x] | [src/Feature/Quest/hooks/useSceneCameraPan.ts](../../../mobile/src/Feature/Quest/hooks/useSceneCameraPan.ts)                                                   | Pan фона по `camera_position_x`; orchestrated OUT + initial snap   | 90    | 5        |
| [x] | [src/Feature/Quest/hooks/cameraPanRunner.ts](../../../mobile/src/Feature/Quest/hooks/cameraPanRunner.ts)                                                       | Pure: `resolveOutCameraAction` (defer / snap / animate)            | 90    | 5        |
| [x] | [src/Feature/Quest/hooks/cameraPanAnimation.ts](../../../mobile/src/Feature/Quest/hooks/cameraPanAnimation.ts)                                                 | Reanimated helper: `runCameraPanAnimation`, re-export `snapShared` | 90    | 5        |
| [x] | [src/Feature/Quest/utils/effectiveCamera.ts](../../../mobile/src/Feature/Quest/utils/effectiveCamera.ts)                                                       | Наследование cameraX по DialogList                                 | 90    | 3        |
| [x] | [src/Feature/Quest/utils/sceneCoverLayout.ts](../../../mobile/src/Feature/Quest/utils/sceneCoverLayout.ts)                                                     | Layout cover-режима фона                                           | 90    | 3        |
| [x] | [src/Feature/Quest/utils/willAdvanceToNewScene.ts](../../../mobile/src/Feature/Quest/utils/willAdvanceToNewScene.ts)                                           | Предсказание: последняя реплика → новая сцена?                     | 85    | 3        |
| [x] | [src/Feature/Quest/utils/isGifUrl.ts](../../../mobile/src/Feature/Quest/utils/isGifUrl.ts)                                                                     | Проверка GIF для фона                                              | 80    | 2        |


### Redux — квест и cutscene


| ✓    | Файл                                                                                                         | Назначение                                                  | Used% | Refactor |
| ---- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------- | ----- | -------- |
| [x ] | [src/App/store/quest/slice.ts](../../../mobile/src/App/store/quest/slice.ts)                                           | Navigation session: scene, status, persons                  | 95    | 4        |
| [ x] | [src/App/store/quest/thunks.ts](../../../mobile/src/App/store/quest/thunks.ts)                                         | `initializeQuest`, `advanceQuest`, `handleSelectVariant`, … | 95    | 5        |
| [x ] | [src/App/store/quest/advanceQuestThunk.ts](../../../mobile/src/App/store/quest/advanceQuestThunk.ts)                   | Single orchestrator tap/variant advance                     | 95    | 3        |
| [x ] | [src/App/store/quest/questAdvanceLogic.ts](../../../mobile/src/App/store/quest/questAdvanceLogic.ts)                   | Pure plan: replica / list / scene / finished                | 95    | 2        |
| [ x] | [src/App/store/quest/resolveQuestStatus.ts](../../../mobile/src/App/store/quest/resolveQuestStatus.ts)                 | Pure `playing` / `finished`                                 | 95    | 2        |
| [ x] | [src/App/store/quest/applyQuestContext.ts](../../../mobile/src/App/store/quest/applyQuestContext.ts)                   | Context patch + visiblePersonId                             | 90    | 2        |
| [ ]  | [src/App/store/quest/resolveQuestResumePosition.ts](../../../mobile/src/App/store/quest/resolveQuestResumePosition.ts) | Resume checkpoint / BFS                                     | 90    | 3        |
| [ ]  | [src/App/store/quest/enterReplicaSession.ts](../../../mobile/src/App/store/quest/enterReplicaSession.ts)               | prefetch + prepare + audio                                  | 95    | 2        |
| [ ]  | [src/App/store/quest/persistReadingPosition.ts](../../../mobile/src/App/store/quest/persistReadingPosition.ts)         | Store glue → ReadingProgressService + updateLocalProgress   | 90    | 2        |
| [ ]  | [src/App/store/questCharacter/slice.ts](../../../mobile/src/App/store/questCharacter/slice.ts)                         | characterLayers, preparedReplica, visiblePersonId           | 95    | 3        |
| [ ]  | [src/App/store/questCharacter/actions.ts](../../../mobile/src/App/store/questCharacter/actions.ts)                     | setCharacterLayers, applyQuestSceneContext                  | 90    | 2        |
| [ ]  | [src/App/store/questCharacter/selectors.ts](../../../mobile/src/App/store/questCharacter/selectors.ts)                 | selectDisplayedCharacter, dialog frame                      | 90    | 3        |
| [ ]  | [src/App/store/dialogFrames/slice.ts](../../../mobile/src/App/store/dialogFrames/slice.ts)                             | Story dialog frames cache                                   | 90    | 2        |
| [ ]  | [src/App/store/dialogFrames/thunks.ts](../../../mobile/src/App/store/dialogFrames/thunks.ts)                           | `fetchDialogFrames`                                         | 90    | 2        |
| [ ]  | [src/App/store/quest/actions.ts](../../../mobile/src/App/store/quest/actions.ts)                                       | `resetQuest`                                                | 90    | 2        |
| [ ]  | [src/App/store/quest/selectors.ts](../../../mobile/src/App/store/quest/selectors.ts)                                   | `selectScene`, `selectCurrentReplica`, camera, character    | 90    | 6        |
| [ ]  | [src/App/store/quest/types.ts](../../../mobile/src/App/store/quest/types.ts)                                           | `QuestState`, `PreparedReplicaCharacter`                    | 95    | 3        |
| [ ]  | [src/App/store/quest/helpers.ts](../../../mobile/src/App/store/quest/helpers.ts)                                       | Условия доступности Scene / DialogList                      | 85    | 5        |
| [ ]  | [src/App/store/cutscene/slice.ts](../../../mobile/src/App/store/cutscene/slice.ts)                                     | Status transitioning катсцены                               | 90    | 4        |
| [ ]  | [src/App/store/cutscene/thunks.ts](../../../mobile/src/App/store/cutscene/thunks.ts)                                   | `handleCutsceneNext` → следующая сцена / ending             | 90    | 5        |
| [ ]  | [src/App/store/cutscene/selectors.ts](../../../mobile/src/App/store/cutscene/selectors.ts)                             | `selectCutsceneStatus`                                      | 85    | 2        |
| [ ]  | [src/App/store/cutscene/types.ts](../../../mobile/src/App/store/cutscene/types.ts)                                     | Типы cutscene slice                                         | 90    | 2        |


### Service — переходы между сценами


| ✓   | Файл                                                                                                   | Назначение                                   | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------------------------ | -------------------------------------------- | ----- | -------- |
| [ ] | [src/Service/Quest/SceneTransitionService.ts](../../../mobile/src/Service/Quest/SceneTransitionService.ts)       | Выбор next scene, `canAccessScene`, progress | 90    | 6        |
| [ ] | [src/Service/Quest/QuestGamePlayLogicManager.ts](../../../mobile/src/Service/Quest/QuestGamePlayLogicManager.ts) | `findNextScene`, `findNextDialogList`        | 90    | 8        |


### Модели и типы


| ✓   | Файл                                                                                   | Назначение                                 | Used% | Refactor |
| --- | -------------------------------------------------------------------------------------- | ------------------------------------------ | ----- | -------- |
| [ ] | [src/Common/models/scene.tsx](../../../mobile/src/Common/models/scene.tsx)                       | UI-модель Scene                            | 90    | 3        |
| [ ] | [src/Common/types/sceneTypes.ts](../../../mobile/src/Common/types/sceneTypes.ts)                 | `SceneType`: regular / cutscene / wardrobe | 90    | 2        |
| [ ] | [src/Service/data/Domain/SceneDomain.ts](../../../mobile/src/Service/data/Domain/SceneDomain.ts) | Domain сцены                               | 95    | 3        |


---

## 5. Диалог / DialogList / Реплика

### UI


| ✓   | Файл                                                                                                                             | Назначение                                         | Used% | Refactor |
| --- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- | ----- | -------- |
| [ ] | [src/Feature/Quest/components/DialogView.tsx](../../../mobile/src/Feature/Quest/components/DialogView.tsx)                                 | Оболочка: DialogFrameView или fallback             | 95    | 4        |
| [ ] | [src/Feature/Quest/components/DialogBuiltinFrameFallback.tsx](../../../mobile/src/Feature/Quest/components/DialogBuiltinFrameFallback.tsx) | Рамка по умолчанию без SVG истории                 | 90    | 4        |
| [ ] | [src/UIComponents/NotificationToast.tsx](../../../mobile/src/UIComponents/NotificationToast.tsx)                                           | Toast при выборе варианта (`variant.notification`) | 85    | 3        |


### Redux / логика реплик


| ✓   | Файл                                                                                                             | Назначение                               | Used% | Refactor |
| --- | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------- | ----- | -------- |
| [ ] | [src/App/store/quest/effectiveCameraState.ts](../../../mobile/src/App/store/quest/effectiveCameraState.ts)                 | `effectiveCameraXByIndex` per DialogList | 85    | 4        |
| [ ] | [src/App/store/quest/prepareReplicaCharacterState.ts](../../../mobile/src/App/store/quest/prepareReplicaCharacterState.ts) | Снимок персонажа **до** показа реплики   | 95    | 5        |


### Service / загрузка DialogList


| ✓   | Файл                                                                               | Назначение                                        | Used% | Refactor |
| --- | ---------------------------------------------------------------------------------- | ------------------------------------------------- | ----- | -------- |
| [ ] | [src/Service/Quest/QuestService.ts](../../../mobile/src/Service/Quest/QuestService.ts)       | `getDialogListById`, `getChapterDetails`, persons | 95    | 6        |
| [ ] | [src/Service/Quest/QuestRepository.ts](../../../mobile/src/Service/Quest/QuestRepository.ts) | Supabase: главы, диалоги, персонажи               | 90    | 7        |
| [ ] | [src/Service/Quest/QuestManager.ts](../../../mobile/src/Service/Quest/QuestManager.ts)       | Кеш глав и dialog lists на диске                  | 90    | 6        |


### Модели


| ✓   | Файл                                                                                             | Назначение                    | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------------------ | ----------------------------- | ----- | -------- |
| [ ] | [src/Common/models/dialog.tsx](../../../mobile/src/Common/models/dialog.tsx)                               | UI: `Dialog`, `DialogList`    | 95    | 3        |
| [ ] | [src/Common/models/dialogAudio.ts](../../../mobile/src/Common/models/dialogAudio.ts)                       | `DialogAudioEvent` на реплике | 90    | 3        |
| [ ] | [src/Service/data/Domain/DialogDomain.tsx](../../../mobile/src/Service/data/Domain/DialogDomain.tsx)       | Domain одной реплики          | 95    | 3        |
| [ ] | [src/Service/data/Domain/DialogListDomain.ts](../../../mobile/src/Service/data/Domain/DialogListDomain.ts) | Domain списка диалогов        | 95    | 3        |


---

## 6. Исход (Variant)


| ✓   | Файл                                                                                                                             | Назначение                                          | Used% | Refactor |
| --- | -------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | ----- | -------- |
| [ ] | [src/Feature/Quest/components/DialogFrameVariantsBlock.tsx](../../../mobile/src/Feature/Quest/components/DialogFrameVariantsBlock.tsx)     | Кнопки вариантов внутри рамки                       | 95    | 5        |
| [ ] | [src/Feature/Quest/dialogFrame/resolveDialogFrameVariants.ts](../../../mobile/src/Feature/Quest/dialogFrame/resolveDialogFrameVariants.ts) | Стили и layout вариантов из frame                   | 90    | 4        |
| [ ] | [src/App/store/quest/thunks.ts](../../../mobile/src/App/store/quest/thunks.ts)                                                             | `handleSelectVariant` → stats + `advanceDialogList` | 95    | 8        |
| [ ] | [src/App/store/storyProgress/progressThunks.ts](../../../mobile/src/App/store/storyProgress/progressThunks.ts)                             | `updateProgressWithVariant`, `updatePlayerStats`    | 90    | 6        |
| [ ] | [src/Common/models/variant.tsx](../../../mobile/src/Common/models/variant.tsx)                                                             | UI-модель Variant                                   | 90    | 3        |
| [ ] | [src/Service/data/Domain/VariantDomain.tsx](../../../mobile/src/Service/data/Domain/VariantDomain.tsx)                                     | Domain варианта                                     | 90    | 3        |


---

## 7. Персонаж (Person) и гардероб

### UI


| ✓   | Файл                                                                                                                           | Назначение                          | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------- | ----- | -------- |
| [ ] | [src/Feature/Quest/components/CharacterDisplay.tsx](../../../mobile/src/Feature/Quest/components/CharacterDisplay.tsx)                   | Composited спрайт из RenderLayer[]  | 95    | 4        |
| [ ] | [src/Feature/Quest/constants/characterLayout.ts](../../../mobile/src/Feature/Quest/constants/characterLayout.ts)                         | Константы layout scene/wardrobe     | 90    | 2        |
| [ ] | [src/Feature/Quest/utils/characterPosition.ts](../../../mobile/src/Feature/Quest/utils/characterPosition.ts)                             | left/center/right на сцене          | 85    | 3        |
| [ ] | [src/Feature/Quest/utils/characterSceneGeometry.ts](../../../mobile/src/Feature/Quest/utils/characterSceneGeometry.ts)                   | Геометрия contain-box 500×800       | 90    | 3        |
| [ ] | [src/Feature/Quest/utils/prefetchCharacterAssets.ts](../../../mobile/src/Feature/Quest/utils/prefetchCharacterAssets.ts)                 | Prefetch URL слоёв и asset_changes  | 85    | 4        |
| [ ] | [src/Feature/Quest/character/characterSceneTransition.ts](../../../mobile/src/Feature/Quest/character/characterSceneTransition.ts)       | Pure-логика fade персонажа          | 90    | 3        |
| [ ] | [src/Feature/Quest/character/useCharacterSceneTransition.ts](../../../mobile/src/Feature/Quest/character/useCharacterSceneTransition.ts) | Reanimated hook fade in/out спрайта | 90    | 5        |


### Redux — wardrobe


| ✓   | Файл                                                                                             | Назначение                                      | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------- | ----- | -------- |
| [ ] | [src/App/store/wardrobe/wardrobeSlice.ts](../../../mobile/src/App/store/wardrobe/wardrobeSlice.ts)         | Группы, temp selections, preview                | 90    | 5        |
| [ ] | [src/App/store/wardrobe/wardrobeThunks.ts](../../../mobile/src/App/store/wardrobe/wardrobeThunks.ts)       | `initializeWardrobe`, `completeWardrobeSession` | 90    | 5        |
| [ ] | [src/App/store/wardrobe/wardrobeSelectors.ts](../../../mobile/src/App/store/wardrobe/wardrobeSelectors.ts) | `makeSelectPreviewLayers`, groups               | 85    | 4        |
| [ ] | [src/App/store/wardrobe/index.ts](../../../mobile/src/App/store/wardrobe/index.ts)                         | Re-export wardrobe                              | 90    | 2        |


### Service — appearance


| ✓   | Файл                                                                                                             | Назначение                                   | Used% | Refactor |
| --- | ---------------------------------------------------------------------------------------------------------------- | -------------------------------------------- | ----- | -------- |
| [ ] | [src/Service/Character/CharacterServiceManager.ts](../../../mobile/src/Service/Character/CharacterServiceManager.ts)       | Singleton CharacterService per storyId       | 90    | 5        |
| [ ] | [src/Service/Character/CharacterStateService.ts](../../../mobile/src/Service/Character/CharacterStateService.ts)           | initForChapter, syncCharacter, managers      | 90    | 6        |
| [ ] | [src/Service/Character/CharacterAppearanceManager.ts](../../../mobile/src/Service/Character/CharacterAppearanceManager.ts) | Слои одного персонажа, `changeWardrobeAsset` | 90    | 5        |
| [ ] | [src/Common/Managers/CharacterStorageManager.ts](../../../mobile/src/Common/Managers/CharacterStorageManager.ts)           | Персистентность appearance в AsyncStorage    | 85    | 5        |


### Модели


| ✓   | Файл                                                                                                                     | Назначение                          | Used%    | Refactor |
| --- | ------------------------------------------------------------------------------------------------------------------------ | ----------------------------------- | -------- | -------- |
| [ ] | [src/Common/models/person.tsx](../../../mobile/src/Common/models/person.tsx)                                                       | UI-модель Person                    | 95       | 3        |
| [ ] | [src/Common/models/assetChange.ts](../../../mobile/src/Common/models/assetChange.ts)                                               | UI asset_changes на реплике         | **0**    | **8**    |
| [ ] | [src/Common/types/assetChange.ts](../../../mobile/src/Common/types/assetChange.ts)                                                 | Типы asset change                   | 90       | 3        |
| [ ] | [src/Common/types/assetChangeAction.ts](../../../mobile/src/Common/types/assetChangeAction.ts)                                     | Действия смены слоя                 | 85       | 2        |
| [ ] | [src/Common/types/characterScenePosition.ts](../../../mobile/src/Common/types/characterScenePosition.ts)                           | `left`                              | `center` | `right`  |
| [ ] | [src/Service/data/Domain/PersonDomain.tsx](../../../mobile/src/Service/data/Domain/PersonDomain.tsx)                               | Domain + RenderLayer                | 95       | 3        |
| [ ] | [src/Service/data/Domain/AssetChangeDomain.ts](../../../mobile/src/Service/data/Domain/AssetChangeDomain.ts)                       | Domain смены слоя                   | 90       | 3        |
| [ ] | [src/Service/data/Domain/CharacterAppearanceDomain.ts](../../../mobile/src/Service/data/Domain/CharacterAppearanceDomain.ts)       | Map appearance per person           | 85       | 3        |
| [ ] | [src/Service/data/Domain/CharacterScenePositionDomain.ts](../../../mobile/src/Service/data/Domain/CharacterScenePositionDomain.ts) | Domain позиции                      | 85       | 2        |
| [ ] | [src/Service/data/DTO/AssetChangeDTO.ts](../../../mobile/src/Service/data/DTO/AssetChangeDTO.ts)                                   | Wire format asset_changes           | 85       | 2        |
| [ ] | [src/Service/data/DTO/CharacterScenePositionDTO.ts](../../../mobile/src/Service/data/DTO/CharacterScenePositionDTO.ts)             | Wire format позиции                 | 85       | 2        |
| [ ] | [src/App/store/helpers/personBuilder.ts](../../../mobile/src/App/store/helpers/personBuilder.ts)                                   | Сборка Person UI из Domain + layers | 80       | 4        |


---

## 8. Рамка диалога (DialogFrame)


| ✓   | Файл                                                                                                                                       | Назначение                             | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------- | ----- | -------- |
| [ ] | [src/Feature/Quest/components/DialogFrameView.tsx](../../../mobile/src/Feature/Quest/components/DialogFrameView.tsx)                                 | Рендер рамки: author, text, variants   | 95    | 6        |
| [ ] | [src/Feature/Quest/components/dialogFrame/DialogFrameSvgLayer.tsx](../../../mobile/src/Feature/Quest/components/dialogFrame/DialogFrameSvgLayer.tsx) | SVG-слой подложки                      | 90    | 4        |
| [ ] | [src/Feature/Quest/dialogFrame/resolveDialogFrame.ts](../../../mobile/src/Feature/Quest/dialogFrame/resolveDialogFrame.ts)                           | frame_id реплики → DialogFrameDomain   | 75    | 4        |
| [ ] | [src/Feature/Quest/dialogFrame/resolveDialogFrameReplica.ts](../../../mobile/src/Feature/Quest/dialogFrame/resolveDialogFrameReplica.ts)             | Текст/контент реплики в рамке          | 90    | 3        |
| [ ] | [src/Feature/Quest/dialogFrame/resolveDialogFrameAuthor.ts](../../../mobile/src/Feature/Quest/dialogFrame/resolveDialogFrameAuthor.ts)               | Имя персонажа в author-блоке           | 90    | 3        |
| [ ] | [src/Feature/Quest/dialogFrame/getDialogFrameContainerStyle.ts](../../../mobile/src/Feature/Quest/dialogFrame/getDialogFrameContainerStyle.ts)       | Позиция рамки на экране                | 85    | 3        |
| [ ] | [src/Feature/Quest/dialogFrame/getPreparedDialogFrameSvg.ts](../../../mobile/src/Feature/Quest/dialogFrame/getPreparedDialogFrameSvg.ts)             | Подготовка SVG для рендера             | 90    | 3        |
| [ ] | [src/Feature/Quest/dialogFrame/prepareInlineDialogFrameSvg.ts](../../../mobile/src/Feature/Quest/dialogFrame/prepareInlineDialogFrameSvg.ts)         | Inline SVG processing                  | 85    | 3        |
| [ ] | [src/Feature/Quest/dialogFrame/hasRenderableDialogFrameLayout.ts](../../../mobile/src/Feature/Quest/dialogFrame/hasRenderableDialogFrameLayout.ts)   | Есть ли renderable layout              | 90    | 3        |
| [ ] | [src/Feature/Quest/dialogFrame/frameTextColor.ts](../../../mobile/src/Feature/Quest/dialogFrame/frameTextColor.ts)                                   | Цвет текста рамки                      | 85    | 3        |
| [ ] | [src/Feature/Quest/dialogFrame/dialogFrameTypography.ts](../../../mobile/src/Feature/Quest/dialogFrame/dialogFrameTypography.ts)                     | Типографика из layout                  | 85    | 3        |
| [ ] | [src/Feature/Quest/dialogFrame/dialogFrameAnimationConstants.ts](../../../mobile/src/Feature/Quest/dialogFrame/dialogFrameAnimationConstants.ts)     | Durations fade реплики                 | 95    | 2        |
| [ ] | [src/Feature/Quest/dialogFrame/dialogFrameTransition.ts](../../../mobile/src/Feature/Quest/dialogFrame/dialogFrameTransition.ts)                     | Утилиты transition рамки               | 85    | 4        |
| [ ] | [src/Feature/Quest/dialogFrame/useDialogFrameContentTransition.ts](../../../mobile/src/Feature/Quest/dialogFrame/useDialogFrameContentTransition.ts) | Fade out/in текста и высоты рамки      | 90    | 5        |
| [ ] | [src/Feature/Quest/dialogFrame/snapReanimated.ts](../../../mobile/src/Feature/Quest/dialogFrame/snapReanimated.ts)                                   | Мгновенный snap shared values          | **0** | **7**    |
| [ ] | [src/App/store/quest/thunks.ts](../../../mobile/src/App/store/quest/thunks.ts)                                                                       | `fetchDialogFrames(storyId)`           | 95    | 8        |
| [ ] | [src/Service/data/Domain/DialogFrameDomain.ts](../../../mobile/src/Service/data/Domain/DialogFrameDomain.ts)                                         | Domain рамки                           | 90    | 3        |
| [ ] | [src/Service/data/Domain/DialogFrameLayoutDomain.ts](../../../mobile/src/Service/data/Domain/DialogFrameLayoutDomain.ts)                             | layout_data: author, replica, variants | 90    | 3        |
| [ ] | [src/Service/data/DialogFrameMapper.ts](../../../mobile/src/Service/data/DialogFrameMapper.ts)                                                       | DTO → DialogFrameDomain                | 90    | 4        |
| [ ] | [src/Service/data/mapDialogFrameLayout.ts](../../../mobile/src/Service/data/mapDialogFrameLayout.ts)                                                 | Парсинг layout_data jsonb              | 90    | 3        |
| [ ] | [src/Service/data/DTO/DialogFrameLayoutDTO.ts](../../../mobile/src/Service/data/DTO/DialogFrameLayoutDTO.ts)                                         | Wire format layout                     | 85    | 2        |
| [ ] | [src/Common/types/dialogStyles.ts](../../../mobile/src/Common/types/dialogStyles.ts)                                                                 | Стили диалога (legacy/types)           | 90    | 4        |


---

## 9. Статы и прогресс пользователя


| ✓   | Файл                                                                                                       | Назначение                                                    | Used% | Refactor |
| --- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ----- | -------- |
| [ ] | [src/App/store/storyProgress/progressSlice.ts](../../../mobile/src/App/store/storyProgress/progressSlice.ts)         | `byStoryId`: chapter, scene, stats, variants                  | 95    | 5        |
| [ ] | [src/App/store/storyProgress/progressThunks.ts](../../../mobile/src/App/store/storyProgress/progressThunks.ts)       | `loadAllUserProgress`, `completeChapter`, `startStoryReading` | 90    | 6        |
| [ ] | [src/App/store/storyProgress/progressSelectors.ts](../../../mobile/src/App/store/storyProgress/progressSelectors.ts) | `selectPlayerStats`, `selectCompletedVariants`                | 85    | 4        |
| [ ] | [src/App/store/storyProgress/types.ts](../../../mobile/src/App/store/storyProgress/types.ts)                         | Типы storyProgress                                            | 85    | 2        |
| [ ] | [src/App/store/storyProgress/index.ts](../../../mobile/src/App/store/storyProgress/index.ts)                         | Re-export                                                     | 90    | 2        |
| [ ] | [src/Service/User/UserService.ts](../../../mobile/src/Service/User/UserService.ts)                                   | Фасад: stats, variants, scene viewed, chapter complete        | 95    | 6        |
| [ ] | [src/Service/User/ReadingProgressService.ts](../../../mobile/src/Service/User/ReadingProgressService.ts)             | Единый facade персиста позиции чтения                         | 95    | 3        |
| [ ] | [src/Service/User/readingPositionHandlers.ts](../../../mobile/src/Service/User/readingPositionHandlers.ts)           | Pure: kind → Redux updates                                    | 90    | 2        |
| [ ] | [src/Service/User/UserRepository.ts](../../../mobile/src/Service/User/UserRepository.ts)                             | Supabase RPC прогресса                                        | 90    | 5        |
| [ ] | [src/Service/User/UserManager.ts](../../../mobile/src/Service/User/UserManager.ts)                                   | Локальный кеш user data                                       | 85    | 5        |
| [ ] | [src/Service/User/ReadingCheckpointManager.ts](../../../mobile/src/Service/User/ReadingCheckpointManager.ts)         | AsyncStorage checkpoint позиции чтения                        | 85    | 4        |
| [ ] | [src/Service/User/dto.ts](../../../mobile/src/Service/User/dto.ts)                                                   | User DTO types                                                | 80    | 2        |
| [ ] | [src/Service/data/UserProgressMapper.ts](../../../mobile/src/Service/data/UserProgressMapper.ts)                     | DTO → UserProgressDomain                                      | 90    | 4        |
| [ ] | [src/Common/models/userStat.tsx](../../../mobile/src/Common/models/userStat.tsx)                                     | UI stat `{ uuid, value }`                                     | 85    | 3        |
| [ ] | [src/Common/models/stats.tsx](../../../mobile/src/Common/models/stats.tsx)                                           | StatsUp (улучшение)                                           | 85    | 3        |
| [ ] | [src/Service/data/Domain/UserProgressDomain.ts](../../../mobile/src/Service/data/Domain/UserProgressDomain.ts)       | Domain прогресса по истории                                   | 90    | 3        |
| [ ] | [src/Service/data/Domain/UserStatsDomain.tsx](../../../mobile/src/Service/data/Domain/UserStatsDomain.tsx)           | Domain статов                                                 | 90    | 3        |
| [ ] | [src/Service/data/Domain/StatsDomain.ts](../../../mobile/src/Service/data/Domain/StatsDomain.ts)                     | Определения статов истории                                    | 85    | 3        |


---

## 10. Аудио


| ✓   | Файл                                                                                       | Назначение                                  | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------------ | ------------------------------------------- | ----- | -------- |
| [ ] | [src/Service/AudioService.ts](../../../mobile/src/Service/AudioService.ts)                           | BGM + overlay players, stopAll              | 90    | 5        |
| [ ] | [src/Service/runDialogAudioEvents.ts](../../../mobile/src/Service/runDialogAudioEvents.ts)           | Выполнение DialogAudioEvent[] по orderIndex | 90    | 4        |
| [ ] | [src/App/store/quest/questAudioHelpers.ts](../../../mobile/src/App/store/quest/questAudioHelpers.ts) | `playSceneBgm`, `runReplicaAudioEvents`     | 90    | 4        |
| [ ] | [src/Common/models/audio.ts](../../../mobile/src/Common/models/audio.ts)                             | UI AudioTrack                               | 85    | 3        |
| [ ] | [src/Common/models/projectAsset.ts](../../../mobile/src/Common/models/projectAsset.ts)               | projectAssets[assetId].url для аудио        | 90    | 3        |


---

## 11. Переходы и анимации (orchestrators)


| ✓   | Файл                                                                                                                                     | Назначение                                        | Used% | Refactor |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- | ----- | -------- |
| [ ] | [src/Feature/Quest/context/QuestSceneTransitionContext.tsx](../../../mobile/src/Feature/Quest/context/QuestSceneTransitionContext.tsx)             | Scene: fade-to-black → swap → reveal → entryIn    | 95    | 6        |
| [ ] | [src/Feature/Quest/context/questSceneTransitionOrchestrator.ts](../../../mobile/src/Feature/Quest/context/questSceneTransitionOrchestrator.ts)     | Pure: фазы scene, `buildSceneEntrySequenceInput`  | 90    | 4        |
| [ ] | [src/Feature/Quest/context/QuestReplicaTransitionContext.tsx](../../../mobile/src/Feature/Quest/context/QuestReplicaTransitionContext.tsx)         | Replica: transitionOut → transitionIn, lock ввода | 95    | 7        |
| [ ] | [src/Feature/Quest/context/questReplicaTransitionOrchestrator.ts](../../../mobile/src/Feature/Quest/context/questReplicaTransitionOrchestrator.ts) | Pure: участники out/in, camera/character/dialog   | 90    | 5        |


---

## 12. Навигация и dev-инструменты


| ✓   | Файл                                                                                                                 | Назначение                                    | Used% | Refactor |
| --- | -------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- | ----- | -------- |
| [ ] | [src/navigation/routes.ts](../../../mobile/src/navigation/routes.ts)                                                           | Имена route: Quest, ChapterStart, Wardrobe, … | 95    | 2        |
| [ ] | [src/navigation/types.ts](../../../mobile/src/navigation/types.ts)                                                             | Param types для stack screens                 | 95    | 3        |
| [ ] | [src/navigation/AppNavigator.tsx](../../../mobile/src/navigation/AppNavigator.tsx)                                             | Регистрация quest screens в stack             | 95    | 5        |
| [ ] | [src/Feature/Quest/Navigation/QuestNavigationModal.tsx](../../../mobile/src/Feature/Quest/Navigation/QuestNavigationModal.tsx) | `__DEV`__: прыжок к scene/dialog/replica      | 70    | 5        |
| [ ] | [src/Feature/Quest/Navigation/index.ts](../../../mobile/src/Feature/Quest/Navigation/index.ts)                                 | Re-export navigation modal                    | 80    | 2        |
| [ ] | [src/UIComponents/QuestNavigationPopup.tsx](../../../mobile/src/UIComponents/QuestNavigationPopup.tsx)                         | UI попапа навигации (legacy/alternate)        | **0** | **8**    |


---

## 13. Маппинг и общие DTO


| ✓   | Файл                                                                                 | Назначение                                    | Used% | Refactor |
| --- | ------------------------------------------------------------------------------------ | --------------------------------------------- | ----- | -------- |
| [ ] | [src/App/store/helpers/mapper.ts](../../../mobile/src/App/store/helpers/mapper.ts)             | `domainToUIMapper`: Domain → Common models    | 95    | 8        |
| [ ] | [src/App/store/helpers/index.ts](../../../mobile/src/App/store/helpers/index.ts)               | RootState, AppDispatch                        | 95    | 4        |
| [ ] | [src/Service/data/StoryDomainMapper.ts](../../../mobile/src/Service/data/StoryDomainMapper.ts) | DTO Supabase → Domain (главы, сцены, диалоги) | 95    | 7        |
| [ ] | [src/Service/data/DTO/index.ts](../../../mobile/src/Service/data/DTO/index.ts)                 | Индекс DTO типов                              | 90    | 4        |
| [ ] | [src/Service/data/Domain/BaseDomain.ts](../../../mobile/src/Service/data/Domain/BaseDomain.ts) | Базовый Domain с uuid                         | 90    | 2        |
| [ ] | [src/Common/models/base.tsx](../../../mobile/src/Common/models/base.tsx)                       | Базовый UI model                              | 90    | 2        |


---

## 14. Unit-тесты геймплея


| ✓   | Файл                                                                                                                                                                   | Назначение                                                    | Used%   | Refactor |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ------- | -------- |
| [ ] | [src/test/createTestStore.ts](../../../mobile/src/test/createTestStore.ts)                                                                                                       | Test store (quest + storyProgress + смежные slices)           | Jest    | 3        |
| [ ] | [src/test/fixtures/storyGraph.ts](../../../mobile/src/test/fixtures/storyGraph.ts)                                                                                               | Fixtures: linear, variant-branch, stats-gated, regression IDs | Jest    | 3        |
| [ ] | [src/test/fixtures/checkpoint.ts](../../../mobile/src/test/fixtures/checkpoint.ts)                                                                                               | Checkpoint snapshots для resume                               | **~10** | 5        |
| [ ] | [src/App/store/quest/**tests**/helpers.test.ts](../../../mobile/src/App/store/quest/__tests__/helpers.test.ts)                                                                   | checkSceneConditions, findAvailableScene/DialogList           | Jest    | 3        |
| [ ] | [src/App/store/quest/**tests**/slice.test.ts](../../../mobile/src/App/store/quest/__tests__/slice.test.ts)                                                                       | Reducers quest slice                                          | Jest    | 3        |
| [ ] | [src/App/store/quest/**tests**/selectors.test.ts](../../../mobile/src/App/store/quest/__tests__/selectors.test.ts)                                                               | Селекторы quest                                               | Jest    | 3        |
| [ ] | [src/App/store/quest/**tests**/thunks.test.ts](../../../mobile/src/App/store/quest/__tests__/thunks.test.ts)                                                                     | handleNextReplica, advanceDialogList, handleSelectVariant     | Jest    | 3        |
| [ ] | [src/App/store/storyProgress/**tests**/progressSlice.test.ts](../../../mobile/src/App/store/storyProgress/__tests__/progressSlice.test.ts)                                       | updateLocalProgress                                           | Jest    | 3        |
| [ ] | [src/App/store/chapter/**tests**/](../../../mobile/src/App/store/chapter/__tests__/)                                                                                             | Session cache slice + selectors                               | Jest    | 3        |
| [ ] | [src/Feature/Quest/screens/ChapterStartScreen/**tests**/](../../../mobile/src/Feature/Quest/screens/ChapterStartScreen/__tests__/)                                               | Mapper + resolveChapterStartViewState                         | Jest    | 3        |
| [ ] | [src/Service/Quest/**tests**/QuestGamePlayLogicManager.test.ts](../../../mobile/src/Service/Quest/__tests__/QuestGamePlayLogicManager.test.ts)                                   | findNextScene/List, resume resolve                            | Jest    | 3        |
| [ ] | [src/Service/Quest/**tests**/SceneTransitionService.test.ts](../../../mobile/src/Service/Quest/__tests__/SceneTransitionService.test.ts)                                         | transitionToNextScene, canAccessScene                         | Jest    | 3        |
| [ ] | [src/Service/**tests**/runDialogAudioEvents.test.ts](../../../mobile/src/Service/__tests__/runDialogAudioEvents.test.ts)                                                         | Аудио-события реплики                                         | Jest    | 3        |
| [ ] | [src/Feature/Quest/context/**tests**/questReplicaTransitionOrchestrator.test.ts](../../../mobile/src/Feature/Quest/context/__tests__/questReplicaTransitionOrchestrator.test.ts) | Фазы replica orchestrator                                     | Jest    | 3        |
| [ ] | [src/Feature/Quest/context/**tests**/questSceneTransitionOrchestrator.test.ts](../../../mobile/src/Feature/Quest/context/__tests__/questSceneTransitionOrchestrator.test.ts)     | Scene entry, uuid change                                      | Jest    | 3        |
| [ ] | [src/Feature/Quest/dialogFrame/**tests**/dialogFrameTransition.test.ts](../../../mobile/src/Feature/Quest/dialogFrame/__tests__/dialogFrameTransition.test.ts)                   | classifyDialogFrameTransition                                 | Jest    | 3        |
| [ ] | [src/Feature/Quest/screens/SceneScreen/**tests**/SceneScreen.test.tsx](../../../mobile/src/Feature/Quest/screens/SceneScreen/__tests__/SceneScreen.test.tsx)                     | Integration + regression (tap, variant, c65cda3a)             | Jest    | 3        |
| [ ] | [src/Feature/Quest/screens/SceneScreen/**tests**/mapSceneUIModel.test.ts](../../../mobile/src/Feature/Quest/screens/SceneScreen/__tests__/mapSceneUIModel.test.ts)               | Pure mapper + tapAdvance + isLastReplica                      | Jest    | 2        |
| [ ] | [src/Feature/Quest/utils/**tests**/willAdvanceToNewScene.test.ts](../../../mobile/src/Feature/Quest/utils/__tests__/willAdvanceToNewScene.test.ts)                               | Предсказание смены сцены                                      | Jest    | 3        |
| [ ] | [src/Feature/Quest/utils/**tests**/effectiveCamera.test.ts](../../../mobile/src/Feature/Quest/utils/__tests__/effectiveCamera.test.ts)                                           | Липкая камера                                                 | Jest    | 3        |
| [ ] | [src/Feature/Quest/utils/**tests**/characterSceneGeometry.test.ts](../../../mobile/src/Feature/Quest/utils/__tests__/characterSceneGeometry.test.ts)                             | Геометрия спрайта                                             | Jest    | 3        |
| [ ] | [src/Feature/Quest/utils/**tests**/characterSceneTransition.test.ts](../../../mobile/src/Feature/Quest/utils/__tests__/characterSceneTransition.test.ts)                         | Fade logic персонажа                                          | Jest    | 3        |
| [ ] | [src/Feature/Quest/utils/**tests**/prefetchCharacterAssets.test.ts](../../../mobile/src/Feature/Quest/utils/__tests__/prefetchCharacterAssets.test.ts)                           | Prefetch URL слоёв                                            | Jest    | 3        |
| [ ] | [src/Feature/Quest/utils/**tests**/questSceneUtils.test.ts](../../../mobile/src/Feature/Quest/utils/__tests__/questSceneUtils.test.ts)                                           | Утилиты сцены                                                 | Jest    | 3        |
| [ ] | [src/Service/**tests**/DataEstimationService.test.ts](../../../mobile/src/Service/__tests__/DataEstimationService.test.ts)                                                       | Оценка размера главы                                          | Jest    | 3        |
| [ ] | [e2e/maestro/flows/](../../e2e/maestro/flows/)                                                                                                                         | Maestro E2E flows §3.1–3.12                                   | E2E     | 4        |
| [ ] | [e2e/detox/specs/questGameplay.test.js](../../e2e/detox/specs/questGameplay.test.js)                                                                                   | Detox smoke (overlay, variant)                                | E2E     | 4        |
| [ ] | [.github/workflows/gameplay-tests.yml](../../.github/workflows/gameplay-tests.yml)                                                                                     | CI: Jest + Maestro                                            | CI      | 4        |


> **Used% для тестов:** `Jest` / `E2E` / `CI` — файл используется в тестовом/инфра контуре, не в рантайме приложения.

---

## 15. Связанная документация (не spec)


| ✓   | Файл                                                                       | Назначение                      | Used% | Refactor |
| --- | -------------------------------------------------------------------------- | ------------------------------- | ----- | -------- |
| [ ] | [docs/quest-sequence-diagram.md](../../docs/quest-sequence-diagram.md)     | Sequence diagram потоков квеста | docs  | 3        |
| [ ] | [docs/architecture-diagrams.md](../../docs/architecture-diagrams.md)       | Блок-схемы архитектуры          | docs  | 3        |
| [ ] | [src/WARDROBE_SEQUENCE_DIAGRAM.md](../../../mobile/src/WARDROBE_SEQUENCE_DIAGRAM.md) | Диаграмма гардероба             | docs  | 3        |


---

## Сводка аудита по слоям


| Слой                   | Файлов ~ | Средний Used% | Средний Refactor | Комментарий                                          |
| ---------------------- | -------- | ------------- | ---------------- | ---------------------------------------------------- |
| Story UI+Redux+Service | 28       | 90            | 4.5              | Стабильно                                            |
| Chapter                | 23       | 90            | 4                | ChapterStart + stale-detection через `contentUpdate` |
| Scene + quest redux    | 25       | 91            | 6.5              | God-files: slice, thunks                             |
| Dialog + Variant       | 14       | 92            | 4.5              | Норм                                                 |
| Person + Wardrobe      | 22       | 87            | 4.5              | `models/assetChange.ts` — дубликат                   |
| DialogFrame            | 18       | 82            | 4.5              | `snapReanimated.ts` — мёртвый                        |
| Progress               | 16       | 88            | 5                | UserService жирный                                   |
| Audio                  | 5        | 89            | 4                | Норм                                                 |
| Orchestrators          | 4        | 93            | 5.5              | Replica context сложный                              |
| Nav                    | 6        | 72            | 4.5              | `QuestNavigationPopup` — legacy                      |
| Mapping                | 6        | 92            | 6                | `mapper.ts` god-file                                 |


**~5–7%** файлов реестра — явный мёртвый код (Used% < 30). **~15%** — Refactor ≥ 7 (god-files / split).

---

## Быстрый индекс по слою


| Слой          | Папки                                                                          |
| ------------- | ------------------------------------------------------------------------------ |
| **UI**        | `src/Feature/Quest/`, `src/Feature/Story/`, `src/Feature/Loading/`             |
| **Redux**     | `src/App/store/quest/`, `cutscene/`, `wardrobe/`, `storyProgress/`, `chapter/` |
| **Service**   | `src/Service/Quest/`, `User/`, `Character/`, `Stories/`, `AudioService.ts`     |
| **Domain**    | `src/Service/data/Domain/`                                                     |
| **UI models** | `src/Common/models/`                                                           |
| **Переходы**  | `src/Feature/Quest/context/`, `dialogFrame/`, `character/`                     |


