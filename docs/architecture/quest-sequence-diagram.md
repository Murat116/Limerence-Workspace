sequenceDiagram
    participant Nav as Navigation
    participant Stories as StoriesScreen
    participant ChStart as ChapterStartScreen
    participant Scene as SceneScreen
    participant Cutscene as CutsceneScreen
    participant Redux as Redux Store
    participant Thunks as Quest Thunks
    participant STService as SceneTransitionService
    participant QService as QuestService
    participant UService as UserService
    participant Audio as AudioService
    participant Repo as Repository
    participant Manager as Manager (Cache)
    participant DB as Supabase DB

    %% Сценарий 1: Начало чтения главы
    Note over Stories,DB: Сценарий 1: Инициализация чтения главы
    Stories->>UService: startReadChapter(storyId)
    UService->>Repo: startReadChapter(storyId)
    Repo->>DB: Edge Function: start-read-chapter
    DB-->>Repo: UserProgressDTO
    Repo-->>UService: UserProgressDTO
    UService-->>Stories: UserProgressDomain
    Stories->>Nav: navigate('ChapterStart', {storyId, userProgress})
    
    %% Экран начала главы
    Note over ChStart,Manager: Загрузка метаданных главы
    Nav->>ChStart: render
    ChStart->>Redux: dispatch(fetchDialogFrames(storyId))
    Redux->>QService: getDialogFrames(storyId)
    QService->>Manager: getDialogFrames (cache)
    alt Cache hit
        Manager-->>QService: DialogFrames[]
    else Cache miss
        QService->>Repo: getDialogFrames(storyId)
        Repo->>DB: SELECT from dialog_frames
        DB-->>Repo: DialogFramesDTO[]
        Repo-->>QService: DialogFramesDTO[]
        QService->>Manager: saveDialogFrames()
        Manager-->>QService: DialogFrameDomain[]
    end
    QService-->>Redux: DialogFrameDomain[]
    Redux-->>ChStart: state.dialogFrames updated
    
    ChStart->>ChStart: User clicks "Начать"
    ChStart->>Nav: navigate('SceneRouter', {userProgress})
    
    %% Сценарий 2: Инициализация квеста
    Note over Nav,DB: Сценарий 2: Инициализация квеста и загрузка данных
    Nav->>Scene: render (SceneRouterScreen)
    Scene->>Redux: dispatch(initializeQuest({userProgress, storyId}))
    Redux->>Thunks: initializeQuest
    
    %% Загрузка главы
    Thunks->>QService: getChapterDetails(chapterUUID)
    QService->>Manager: getChapter (cache)
    alt Cache hit
        Manager-->>QService: ChapterDomain
    else Cache miss
        QService->>Repo: getChapterDetails(chapterUUID)
        Repo->>DB: SELECT chapter with scenes
        DB-->>Repo: ChapterDTO
        Repo-->>QService: ChapterDTO
        QService->>Manager: saveChapter(ChapterDTO)
        Manager-->>QService: ChapterDomain
    end
    QService-->>Thunks: ChapterDomain
    
    %% Загрузка персонажей
    Thunks->>QService: getPersonsForStory(storyId)
    QService->>Manager: getPersons (cache)
    alt Cache miss
        QService->>Repo: getPersonsForStory(storyId)
        Repo->>DB: SELECT persons + assets
        DB-->>Repo: PersonDTO[]
        Repo-->>QService: PersonDTO[]
        QService->>Manager: savePersons()
        Manager-->>QService: PersonDomain[]
    end
    QService-->>Thunks: PersonDomain[]
    
    %% Загрузка диалогов (если не cutscene)
    alt Scene type = REGULAR
        Thunks->>QService: getDialogListById(dialogListUUID)
        QService->>Manager: getDialogList (cache)
        Manager-->>QService: DialogListDomain
        QService-->>Thunks: DialogListDomain
    else Scene type = CUTSCENE
        Thunks->>Thunks: Skip dialogList load
    end
    
    %% Запуск аудио
    Thunks->>Audio: playSceneAudio(scene.audioTracks)
    Audio-->>Thunks: Audio started
    
    %% Обновление state
    Thunks-->>Redux: Update state (chapter, scene, dialogList, stats)
    Redux-->>Scene: state.status = 'playing'
    
    alt Scene type = CUTSCENE
        Scene->>Nav: navigate('Cutscene', {scene, chapter})
        Nav->>Cutscene: render
    else Scene type = REGULAR
        Scene->>Nav: navigate('Scene', {scene, dialogList})
        Nav->>Scene: render SceneScreen
    end
    
    %% Сценарий 3: Переход по репликам
    Note over Scene,DB: Сценарий 3: Чтение реплик и выбор вариантов
    Scene->>Scene: User clicks "Далее"
    Scene->>Redux: dispatch(handleNextReplica())
    Redux->>Thunks: handleNextReplica
    
    alt НЕ последняя реплика
        Thunks->>UService: markReplicaAsCurrent(storyId, nextDialogId)
        UService->>Repo: updateCurrentDialog(storyId, dialogId)
        Repo->>DB: UPDATE user_progress SET current_dialog_id
        DB-->>Repo: Success
        Repo-->>UService: Success
        UService-->>Thunks: Success
        Thunks->>Redux: dispatch(advanceReplica())
        Redux->>Redux: replicaIndex++
        Thunks-->>Redux: Done
        Redux-->>Scene: Re-render with next replica
    else Последняя реплика
        Thunks->>QService: findNextDialogList(dialogList, stats, variants)
        QService->>Manager: Load nextAvailableDialogList[]
        Manager-->>QService: DialogListDomain[]
        QService->>QService: Check availability (stats, variants)
        alt Найден доступный DialogList
            QService-->>Thunks: NextDialogList
            Thunks->>UService: markDialogListAsCurrent(dialogListUUID)
            UService->>Repo: updateCurrentDialogList()
            Repo->>DB: UPDATE user_progress
            DB-->>Repo: Success
            Repo-->>UService: Success
            UService-->>Thunks: Success
            Thunks->>Redux: Update dialogList, reset replicaIndex
            Thunks-->>Redux: Done
            Redux-->>Scene: Re-render with new dialogList
        else НЕ найден DialogList
            QService-->>Thunks: null
            Thunks->>Thunks: advanceScene()
            Thunks-->>Redux: Scene transition started
            Redux-->>Scene: Navigation pending
            Note over Thunks,DB: Переход к Сценарию 4
        end
    end
    
    %% Выбор варианта
    Scene->>Scene: User selects variant
    Scene->>Redux: dispatch(handleSelectVariant(variant))
    Redux->>Thunks: handleSelectVariant
    Thunks->>Redux: dispatch(newSelectVariant(variant))
    Redux->>Redux: Add to completedVariantIds
    
    %% Обновление статов
    loop For each stat change
        Thunks->>Redux: dispatch(updateStat({statUUID, value}))
        Redux->>Redux: Update stats array
    end
    
    Thunks->>UService: updatePlayerStatsForStory(storyId, chapterId, stats)
    UService->>Repo: updateUserStats(storyId, chapterId, statsRecord)
    Repo->>DB: UPDATE user_progress & user_chapter_progress
    DB-->>Repo: Success
    Repo-->>UService: Success
    UService-->>Thunks: Success
    
    Thunks->>UService: updateChosenVariant(storyId, chapterId, variantUUID)
    UService->>Repo: updateChosenVariant()
    Repo->>DB: UPDATE chosen_variants array
    DB-->>Repo: Success
    Repo-->>UService: Success
    UService-->>Thunks: Success
    
    Thunks->>Thunks: handleNextReplica()
    Thunks-->>Redux: Continue flow
    Redux-->>Scene: Re-render
    
    %% Сценарий 4: Переход к следующей сцене
    Note over Thunks,DB: Сценарий 4: Переход между сценами
    Thunks->>STService: transitionToNextScene(scene, chapter, storyId, stats, variants)
    STService->>STService: getNextAvailableScene(availableSceneIds)
    
    loop For each availableSceneId
        STService->>STService: canAccessScene(scene, stats, variants)
        STService->>STService: Check minimumRequiredStats
        STService->>STService: Check requiredSelectedVariants
    end
    
    alt Найдена доступная сцена
        STService->>UService: markSceneAsViewed(storyId, chapterId, newSceneId, oldSceneId)
        UService->>Repo: updateViewedScene()
        Repo->>DB: UPDATE user_progress & user_chapter_progress
        DB-->>Repo: Success
        Repo-->>UService: Success
        UService-->>STService: Success
        
        alt Next scene type = REGULAR
            STService->>QService: getDialogListById(scene.initialDialogId)
            QService->>Manager: getDialogList (cache)
            Manager-->>QService: DialogListDomain
            QService-->>STService: DialogListDomain
        else Next scene type = CUTSCENE
            STService->>STService: dialogList = null
        end
        
        STService->>Audio: playSceneAudio(nextScene.audioTracks)
        Audio-->>STService: Audio started
        
        STService-->>Thunks: {scene: nextScene, dialogList, finished: false}
        Thunks->>Redux: Update scene, dialogList, reset replicaIndex
        Redux-->>Scene: Re-render with new scene
        
        alt Next scene = CUTSCENE
            Scene->>Nav: navigate('Cutscene')
            Nav->>Cutscene: render
        end
        
    else НЕ найдена доступная сцена
        STService-->>Thunks: {scene: null, dialogList: null, finished: true}
        Thunks->>Redux: state.status = 'finished'
        Redux-->>Scene: Chapter finished
        Scene->>Nav: navigate('ChapterEnd')
    end
    
    %% Сценарий 5: Обработка Cutscene
    Note over Cutscene,DB: Сценарий 5: Cutscene переход
    Cutscene->>Cutscene: User clicks "Продолжить"
    Cutscene->>Redux: dispatch(handleCutsceneNext({currentScene, chapter, storyId}))
    Redux->>Thunks: handleCutsceneNext
    Thunks->>STService: transitionToNextScene()
    STService->>STService: Same logic as Scenario 4
    
    alt Chapter finished
        STService-->>Thunks: {finished: true}
        Thunks-->>Redux: {type: 'navigate_to_ending'}
        Redux-->>Cutscene: Navigation result
        Cutscene->>Nav: navigate('ChapterEnd')
    else Next scene found
        STService-->>Thunks: {scene: nextScene, dialogList}
        Thunks-->>Redux: {type: 'navigate_to_scene', sceneId}
        Redux-->>Cutscene: Navigation result
        Cutscene->>Nav: navigate('Scene' or 'Cutscene')
    end
    
    %% Сценарий 6: Обработка ошибок
    Note over Scene,DB: Сценарий 6: Обработка ошибок
    Scene->>Redux: dispatch(initializeQuest())
    Redux->>Thunks: initializeQuest
    Thunks->>QService: getChapterDetails(chapterUUID)
    QService->>Repo: getChapterDetails()
    Repo->>DB: SELECT chapter
    DB-->>Repo: ERROR (Network timeout)
    Repo-->>QService: throws Error
    QService-->>Thunks: throws Error
    Thunks->>Thunks: catch (error)
    Thunks-->>Redux: rejectWithValue('Failed to initialize quest')
    Redux->>Redux: state.status = 'error'
    Redux-->>Scene: error state
    Scene->>Scene: Show error UI
    
    alt User retries
        Scene->>Redux: dispatch(initializeQuest()) again
    else User goes back
        Scene->>Nav: goBack()
    end
    
    %% Завершение главы
    Note over Scene,DB: Завершение главы
    Scene->>Redux: dispatch(endChapter())
    Redux->>QService: endReadChapter(storyId, completedChapterId)
    QService->>Repo: endReadChapter()
    Repo->>DB: Edge Function: end-read-chapter
    DB-->>Repo: Updated UserProgressDTO (next chapter)
    Repo-->>QService: UserProgressDTO
    QService-->>Redux: UserProgressDomain
    Redux-->>Scene: Success
    Scene->>Audio: stopAllAudio()
    Audio-->>Scene: Stopped
    Scene->>Nav: navigate('ChapterEnd', {nextChapterUUID})
