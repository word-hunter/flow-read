// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BookEntriesTable extends BookEntries
    with TableInfo<$BookEntriesTable, BookEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalChaptersMeta = const VerificationMeta(
    'totalChapters',
  );
  @override
  late final GeneratedColumn<int> totalChapters = GeneratedColumn<int>(
    'total_chapters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(_zeroInt),
  );
  static const VerificationMeta _globalProgressMeta = const VerificationMeta(
    'globalProgress',
  );
  @override
  late final GeneratedColumn<double> globalProgress = GeneratedColumn<double>(
    'global_progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(_zeroReal),
  );
  static const VerificationMeta _currentChapterMeta = const VerificationMeta(
    'currentChapter',
  );
  @override
  late final GeneratedColumn<int> currentChapter = GeneratedColumn<int>(
    'current_chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(_zeroInt),
  );
  static const VerificationMeta _chapterProgressMeta = const VerificationMeta(
    'chapterProgress',
  );
  @override
  late final GeneratedColumn<double> chapterProgress = GeneratedColumn<double>(
    'chapter_progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(_zeroReal),
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<String> lastReadAt = GeneratedColumn<String>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chapterScrollOffsetMeta =
      const VerificationMeta('chapterScrollOffset');
  @override
  late final GeneratedColumn<double> chapterScrollOffset =
      GeneratedColumn<double>(
        'chapter_scroll_offset',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceLanguageMeta = const VerificationMeta(
    'sourceLanguage',
  );
  @override
  late final GeneratedColumn<String> sourceLanguage = GeneratedColumn<String>(
    'source_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _sourceLanguageOverrideMeta =
      const VerificationMeta('sourceLanguageOverride');
  @override
  late final GeneratedColumn<String> sourceLanguageOverride =
      GeneratedColumn<String>(
        'source_language_override',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _languageConfidenceMeta =
      const VerificationMeta('languageConfidence');
  @override
  late final GeneratedColumn<double> languageConfidence =
      GeneratedColumn<double>(
        'language_confidence',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _targetExplanationLanguageMeta =
      const VerificationMeta('targetExplanationLanguage');
  @override
  late final GeneratedColumn<String> targetExplanationLanguage =
      GeneratedColumn<String>(
        'target_explanation_language',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _difficultyStudyWordsMeta =
      const VerificationMeta('difficultyStudyWords');
  @override
  late final GeneratedColumn<String> difficultyStudyWords =
      GeneratedColumn<String>(
        'difficulty_study_words',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _difficultyRatingJsonMeta =
      const VerificationMeta('difficultyRatingJson');
  @override
  late final GeneratedColumn<String> difficultyRatingJson =
      GeneratedColumn<String>(
        'difficulty_rating_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _difficultyVocabularySignatureMeta =
      const VerificationMeta('difficultyVocabularySignature');
  @override
  late final GeneratedColumn<String> difficultyVocabularySignature =
      GeneratedColumn<String>(
        'difficulty_vocabulary_signature',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _difficultyComputedAtMeta =
      const VerificationMeta('difficultyComputedAt');
  @override
  late final GeneratedColumn<String> difficultyComputedAt =
      GeneratedColumn<String>(
        'difficulty_computed_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    language,
    title,
    author,
    sourcePath,
    coverPath,
    totalChapters,
    globalProgress,
    currentChapter,
    chapterProgress,
    lastReadAt,
    chapterScrollOffset,
    sourceLanguage,
    sourceLanguageOverride,
    languageConfidence,
    targetExplanationLanguage,
    difficultyStudyWords,
    difficultyRatingJson,
    difficultyVocabularySignature,
    difficultyComputedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcePathMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('total_chapters')) {
      context.handle(
        _totalChaptersMeta,
        totalChapters.isAcceptableOrUnknown(
          data['total_chapters']!,
          _totalChaptersMeta,
        ),
      );
    }
    if (data.containsKey('global_progress')) {
      context.handle(
        _globalProgressMeta,
        globalProgress.isAcceptableOrUnknown(
          data['global_progress']!,
          _globalProgressMeta,
        ),
      );
    }
    if (data.containsKey('current_chapter')) {
      context.handle(
        _currentChapterMeta,
        currentChapter.isAcceptableOrUnknown(
          data['current_chapter']!,
          _currentChapterMeta,
        ),
      );
    }
    if (data.containsKey('chapter_progress')) {
      context.handle(
        _chapterProgressMeta,
        chapterProgress.isAcceptableOrUnknown(
          data['chapter_progress']!,
          _chapterProgressMeta,
        ),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('chapter_scroll_offset')) {
      context.handle(
        _chapterScrollOffsetMeta,
        chapterScrollOffset.isAcceptableOrUnknown(
          data['chapter_scroll_offset']!,
          _chapterScrollOffsetMeta,
        ),
      );
    }
    if (data.containsKey('source_language')) {
      context.handle(
        _sourceLanguageMeta,
        sourceLanguage.isAcceptableOrUnknown(
          data['source_language']!,
          _sourceLanguageMeta,
        ),
      );
    }
    if (data.containsKey('source_language_override')) {
      context.handle(
        _sourceLanguageOverrideMeta,
        sourceLanguageOverride.isAcceptableOrUnknown(
          data['source_language_override']!,
          _sourceLanguageOverrideMeta,
        ),
      );
    }
    if (data.containsKey('language_confidence')) {
      context.handle(
        _languageConfidenceMeta,
        languageConfidence.isAcceptableOrUnknown(
          data['language_confidence']!,
          _languageConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('target_explanation_language')) {
      context.handle(
        _targetExplanationLanguageMeta,
        targetExplanationLanguage.isAcceptableOrUnknown(
          data['target_explanation_language']!,
          _targetExplanationLanguageMeta,
        ),
      );
    }
    if (data.containsKey('difficulty_study_words')) {
      context.handle(
        _difficultyStudyWordsMeta,
        difficultyStudyWords.isAcceptableOrUnknown(
          data['difficulty_study_words']!,
          _difficultyStudyWordsMeta,
        ),
      );
    }
    if (data.containsKey('difficulty_rating_json')) {
      context.handle(
        _difficultyRatingJsonMeta,
        difficultyRatingJson.isAcceptableOrUnknown(
          data['difficulty_rating_json']!,
          _difficultyRatingJsonMeta,
        ),
      );
    }
    if (data.containsKey('difficulty_vocabulary_signature')) {
      context.handle(
        _difficultyVocabularySignatureMeta,
        difficultyVocabularySignature.isAcceptableOrUnknown(
          data['difficulty_vocabulary_signature']!,
          _difficultyVocabularySignatureMeta,
        ),
      );
    }
    if (data.containsKey('difficulty_computed_at')) {
      context.handle(
        _difficultyComputedAtMeta,
        difficultyComputedAt.isAcceptableOrUnknown(
          data['difficulty_computed_at']!,
          _difficultyComputedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      totalChapters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chapters'],
      )!,
      globalProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}global_progress'],
      )!,
      currentChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_chapter'],
      )!,
      chapterProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chapter_progress'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_read_at'],
      ),
      chapterScrollOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chapter_scroll_offset'],
      ),
      sourceLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_language'],
      )!,
      sourceLanguageOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_language_override'],
      ),
      languageConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}language_confidence'],
      ),
      targetExplanationLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_explanation_language'],
      ),
      difficultyStudyWords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty_study_words'],
      ),
      difficultyRatingJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty_rating_json'],
      ),
      difficultyVocabularySignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty_vocabulary_signature'],
      ),
      difficultyComputedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty_computed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BookEntriesTable createAlias(String alias) {
    return $BookEntriesTable(attachedDatabase, alias);
  }
}

class BookEntry extends DataClass implements Insertable<BookEntry> {
  final String id;
  final String language;
  final String title;
  final String author;
  final String sourcePath;
  final String? coverPath;
  final int totalChapters;
  final double globalProgress;
  final int currentChapter;
  final double chapterProgress;
  final String? lastReadAt;
  final double? chapterScrollOffset;
  final String sourceLanguage;
  final String? sourceLanguageOverride;
  final double? languageConfidence;
  final String? targetExplanationLanguage;
  final String? difficultyStudyWords;
  final String? difficultyRatingJson;
  final String? difficultyVocabularySignature;
  final String? difficultyComputedAt;
  final String createdAt;
  final String updatedAt;
  const BookEntry({
    required this.id,
    required this.language,
    required this.title,
    required this.author,
    required this.sourcePath,
    this.coverPath,
    required this.totalChapters,
    required this.globalProgress,
    required this.currentChapter,
    required this.chapterProgress,
    this.lastReadAt,
    this.chapterScrollOffset,
    required this.sourceLanguage,
    this.sourceLanguageOverride,
    this.languageConfidence,
    this.targetExplanationLanguage,
    this.difficultyStudyWords,
    this.difficultyRatingJson,
    this.difficultyVocabularySignature,
    this.difficultyComputedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language'] = Variable<String>(language);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    map['source_path'] = Variable<String>(sourcePath);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['total_chapters'] = Variable<int>(totalChapters);
    map['global_progress'] = Variable<double>(globalProgress);
    map['current_chapter'] = Variable<int>(currentChapter);
    map['chapter_progress'] = Variable<double>(chapterProgress);
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<String>(lastReadAt);
    }
    if (!nullToAbsent || chapterScrollOffset != null) {
      map['chapter_scroll_offset'] = Variable<double>(chapterScrollOffset);
    }
    map['source_language'] = Variable<String>(sourceLanguage);
    if (!nullToAbsent || sourceLanguageOverride != null) {
      map['source_language_override'] = Variable<String>(
        sourceLanguageOverride,
      );
    }
    if (!nullToAbsent || languageConfidence != null) {
      map['language_confidence'] = Variable<double>(languageConfidence);
    }
    if (!nullToAbsent || targetExplanationLanguage != null) {
      map['target_explanation_language'] = Variable<String>(
        targetExplanationLanguage,
      );
    }
    if (!nullToAbsent || difficultyStudyWords != null) {
      map['difficulty_study_words'] = Variable<String>(difficultyStudyWords);
    }
    if (!nullToAbsent || difficultyRatingJson != null) {
      map['difficulty_rating_json'] = Variable<String>(difficultyRatingJson);
    }
    if (!nullToAbsent || difficultyVocabularySignature != null) {
      map['difficulty_vocabulary_signature'] = Variable<String>(
        difficultyVocabularySignature,
      );
    }
    if (!nullToAbsent || difficultyComputedAt != null) {
      map['difficulty_computed_at'] = Variable<String>(difficultyComputedAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  BookEntriesCompanion toCompanion(bool nullToAbsent) {
    return BookEntriesCompanion(
      id: Value(id),
      language: Value(language),
      title: Value(title),
      author: Value(author),
      sourcePath: Value(sourcePath),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      totalChapters: Value(totalChapters),
      globalProgress: Value(globalProgress),
      currentChapter: Value(currentChapter),
      chapterProgress: Value(chapterProgress),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
      chapterScrollOffset: chapterScrollOffset == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterScrollOffset),
      sourceLanguage: Value(sourceLanguage),
      sourceLanguageOverride: sourceLanguageOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLanguageOverride),
      languageConfidence: languageConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(languageConfidence),
      targetExplanationLanguage:
          targetExplanationLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(targetExplanationLanguage),
      difficultyStudyWords: difficultyStudyWords == null && nullToAbsent
          ? const Value.absent()
          : Value(difficultyStudyWords),
      difficultyRatingJson: difficultyRatingJson == null && nullToAbsent
          ? const Value.absent()
          : Value(difficultyRatingJson),
      difficultyVocabularySignature:
          difficultyVocabularySignature == null && nullToAbsent
          ? const Value.absent()
          : Value(difficultyVocabularySignature),
      difficultyComputedAt: difficultyComputedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(difficultyComputedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BookEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookEntry(
      id: serializer.fromJson<String>(json['id']),
      language: serializer.fromJson<String>(json['language']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      sourcePath: serializer.fromJson<String>(json['sourcePath']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      totalChapters: serializer.fromJson<int>(json['totalChapters']),
      globalProgress: serializer.fromJson<double>(json['globalProgress']),
      currentChapter: serializer.fromJson<int>(json['currentChapter']),
      chapterProgress: serializer.fromJson<double>(json['chapterProgress']),
      lastReadAt: serializer.fromJson<String?>(json['lastReadAt']),
      chapterScrollOffset: serializer.fromJson<double?>(
        json['chapterScrollOffset'],
      ),
      sourceLanguage: serializer.fromJson<String>(json['sourceLanguage']),
      sourceLanguageOverride: serializer.fromJson<String?>(
        json['sourceLanguageOverride'],
      ),
      languageConfidence: serializer.fromJson<double?>(
        json['languageConfidence'],
      ),
      targetExplanationLanguage: serializer.fromJson<String?>(
        json['targetExplanationLanguage'],
      ),
      difficultyStudyWords: serializer.fromJson<String?>(
        json['difficultyStudyWords'],
      ),
      difficultyRatingJson: serializer.fromJson<String?>(
        json['difficultyRatingJson'],
      ),
      difficultyVocabularySignature: serializer.fromJson<String?>(
        json['difficultyVocabularySignature'],
      ),
      difficultyComputedAt: serializer.fromJson<String?>(
        json['difficultyComputedAt'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'language': serializer.toJson<String>(language),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'sourcePath': serializer.toJson<String>(sourcePath),
      'coverPath': serializer.toJson<String?>(coverPath),
      'totalChapters': serializer.toJson<int>(totalChapters),
      'globalProgress': serializer.toJson<double>(globalProgress),
      'currentChapter': serializer.toJson<int>(currentChapter),
      'chapterProgress': serializer.toJson<double>(chapterProgress),
      'lastReadAt': serializer.toJson<String?>(lastReadAt),
      'chapterScrollOffset': serializer.toJson<double?>(chapterScrollOffset),
      'sourceLanguage': serializer.toJson<String>(sourceLanguage),
      'sourceLanguageOverride': serializer.toJson<String?>(
        sourceLanguageOverride,
      ),
      'languageConfidence': serializer.toJson<double?>(languageConfidence),
      'targetExplanationLanguage': serializer.toJson<String?>(
        targetExplanationLanguage,
      ),
      'difficultyStudyWords': serializer.toJson<String?>(difficultyStudyWords),
      'difficultyRatingJson': serializer.toJson<String?>(difficultyRatingJson),
      'difficultyVocabularySignature': serializer.toJson<String?>(
        difficultyVocabularySignature,
      ),
      'difficultyComputedAt': serializer.toJson<String?>(difficultyComputedAt),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  BookEntry copyWith({
    String? id,
    String? language,
    String? title,
    String? author,
    String? sourcePath,
    Value<String?> coverPath = const Value.absent(),
    int? totalChapters,
    double? globalProgress,
    int? currentChapter,
    double? chapterProgress,
    Value<String?> lastReadAt = const Value.absent(),
    Value<double?> chapterScrollOffset = const Value.absent(),
    String? sourceLanguage,
    Value<String?> sourceLanguageOverride = const Value.absent(),
    Value<double?> languageConfidence = const Value.absent(),
    Value<String?> targetExplanationLanguage = const Value.absent(),
    Value<String?> difficultyStudyWords = const Value.absent(),
    Value<String?> difficultyRatingJson = const Value.absent(),
    Value<String?> difficultyVocabularySignature = const Value.absent(),
    Value<String?> difficultyComputedAt = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => BookEntry(
    id: id ?? this.id,
    language: language ?? this.language,
    title: title ?? this.title,
    author: author ?? this.author,
    sourcePath: sourcePath ?? this.sourcePath,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    totalChapters: totalChapters ?? this.totalChapters,
    globalProgress: globalProgress ?? this.globalProgress,
    currentChapter: currentChapter ?? this.currentChapter,
    chapterProgress: chapterProgress ?? this.chapterProgress,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
    chapterScrollOffset: chapterScrollOffset.present
        ? chapterScrollOffset.value
        : this.chapterScrollOffset,
    sourceLanguage: sourceLanguage ?? this.sourceLanguage,
    sourceLanguageOverride: sourceLanguageOverride.present
        ? sourceLanguageOverride.value
        : this.sourceLanguageOverride,
    languageConfidence: languageConfidence.present
        ? languageConfidence.value
        : this.languageConfidence,
    targetExplanationLanguage: targetExplanationLanguage.present
        ? targetExplanationLanguage.value
        : this.targetExplanationLanguage,
    difficultyStudyWords: difficultyStudyWords.present
        ? difficultyStudyWords.value
        : this.difficultyStudyWords,
    difficultyRatingJson: difficultyRatingJson.present
        ? difficultyRatingJson.value
        : this.difficultyRatingJson,
    difficultyVocabularySignature: difficultyVocabularySignature.present
        ? difficultyVocabularySignature.value
        : this.difficultyVocabularySignature,
    difficultyComputedAt: difficultyComputedAt.present
        ? difficultyComputedAt.value
        : this.difficultyComputedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BookEntry copyWithCompanion(BookEntriesCompanion data) {
    return BookEntry(
      id: data.id.present ? data.id.value : this.id,
      language: data.language.present ? data.language.value : this.language,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      totalChapters: data.totalChapters.present
          ? data.totalChapters.value
          : this.totalChapters,
      globalProgress: data.globalProgress.present
          ? data.globalProgress.value
          : this.globalProgress,
      currentChapter: data.currentChapter.present
          ? data.currentChapter.value
          : this.currentChapter,
      chapterProgress: data.chapterProgress.present
          ? data.chapterProgress.value
          : this.chapterProgress,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      chapterScrollOffset: data.chapterScrollOffset.present
          ? data.chapterScrollOffset.value
          : this.chapterScrollOffset,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      sourceLanguageOverride: data.sourceLanguageOverride.present
          ? data.sourceLanguageOverride.value
          : this.sourceLanguageOverride,
      languageConfidence: data.languageConfidence.present
          ? data.languageConfidence.value
          : this.languageConfidence,
      targetExplanationLanguage: data.targetExplanationLanguage.present
          ? data.targetExplanationLanguage.value
          : this.targetExplanationLanguage,
      difficultyStudyWords: data.difficultyStudyWords.present
          ? data.difficultyStudyWords.value
          : this.difficultyStudyWords,
      difficultyRatingJson: data.difficultyRatingJson.present
          ? data.difficultyRatingJson.value
          : this.difficultyRatingJson,
      difficultyVocabularySignature: data.difficultyVocabularySignature.present
          ? data.difficultyVocabularySignature.value
          : this.difficultyVocabularySignature,
      difficultyComputedAt: data.difficultyComputedAt.present
          ? data.difficultyComputedAt.value
          : this.difficultyComputedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookEntry(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('coverPath: $coverPath, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('globalProgress: $globalProgress, ')
          ..write('currentChapter: $currentChapter, ')
          ..write('chapterProgress: $chapterProgress, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('chapterScrollOffset: $chapterScrollOffset, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('sourceLanguageOverride: $sourceLanguageOverride, ')
          ..write('languageConfidence: $languageConfidence, ')
          ..write('targetExplanationLanguage: $targetExplanationLanguage, ')
          ..write('difficultyStudyWords: $difficultyStudyWords, ')
          ..write('difficultyRatingJson: $difficultyRatingJson, ')
          ..write(
            'difficultyVocabularySignature: $difficultyVocabularySignature, ',
          )
          ..write('difficultyComputedAt: $difficultyComputedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    language,
    title,
    author,
    sourcePath,
    coverPath,
    totalChapters,
    globalProgress,
    currentChapter,
    chapterProgress,
    lastReadAt,
    chapterScrollOffset,
    sourceLanguage,
    sourceLanguageOverride,
    languageConfidence,
    targetExplanationLanguage,
    difficultyStudyWords,
    difficultyRatingJson,
    difficultyVocabularySignature,
    difficultyComputedAt,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookEntry &&
          other.id == this.id &&
          other.language == this.language &&
          other.title == this.title &&
          other.author == this.author &&
          other.sourcePath == this.sourcePath &&
          other.coverPath == this.coverPath &&
          other.totalChapters == this.totalChapters &&
          other.globalProgress == this.globalProgress &&
          other.currentChapter == this.currentChapter &&
          other.chapterProgress == this.chapterProgress &&
          other.lastReadAt == this.lastReadAt &&
          other.chapterScrollOffset == this.chapterScrollOffset &&
          other.sourceLanguage == this.sourceLanguage &&
          other.sourceLanguageOverride == this.sourceLanguageOverride &&
          other.languageConfidence == this.languageConfidence &&
          other.targetExplanationLanguage == this.targetExplanationLanguage &&
          other.difficultyStudyWords == this.difficultyStudyWords &&
          other.difficultyRatingJson == this.difficultyRatingJson &&
          other.difficultyVocabularySignature ==
              this.difficultyVocabularySignature &&
          other.difficultyComputedAt == this.difficultyComputedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BookEntriesCompanion extends UpdateCompanion<BookEntry> {
  final Value<String> id;
  final Value<String> language;
  final Value<String> title;
  final Value<String> author;
  final Value<String> sourcePath;
  final Value<String?> coverPath;
  final Value<int> totalChapters;
  final Value<double> globalProgress;
  final Value<int> currentChapter;
  final Value<double> chapterProgress;
  final Value<String?> lastReadAt;
  final Value<double?> chapterScrollOffset;
  final Value<String> sourceLanguage;
  final Value<String?> sourceLanguageOverride;
  final Value<double?> languageConfidence;
  final Value<String?> targetExplanationLanguage;
  final Value<String?> difficultyStudyWords;
  final Value<String?> difficultyRatingJson;
  final Value<String?> difficultyVocabularySignature;
  final Value<String?> difficultyComputedAt;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const BookEntriesCompanion({
    this.id = const Value.absent(),
    this.language = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.globalProgress = const Value.absent(),
    this.currentChapter = const Value.absent(),
    this.chapterProgress = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.chapterScrollOffset = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.sourceLanguageOverride = const Value.absent(),
    this.languageConfidence = const Value.absent(),
    this.targetExplanationLanguage = const Value.absent(),
    this.difficultyStudyWords = const Value.absent(),
    this.difficultyRatingJson = const Value.absent(),
    this.difficultyVocabularySignature = const Value.absent(),
    this.difficultyComputedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookEntriesCompanion.insert({
    required String id,
    this.language = const Value.absent(),
    required String title,
    this.author = const Value.absent(),
    required String sourcePath,
    this.coverPath = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.globalProgress = const Value.absent(),
    this.currentChapter = const Value.absent(),
    this.chapterProgress = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.chapterScrollOffset = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.sourceLanguageOverride = const Value.absent(),
    this.languageConfidence = const Value.absent(),
    this.targetExplanationLanguage = const Value.absent(),
    this.difficultyStudyWords = const Value.absent(),
    this.difficultyRatingJson = const Value.absent(),
    this.difficultyVocabularySignature = const Value.absent(),
    this.difficultyComputedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       sourcePath = Value(sourcePath);
  static Insertable<BookEntry> custom({
    Expression<String>? id,
    Expression<String>? language,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? sourcePath,
    Expression<String>? coverPath,
    Expression<int>? totalChapters,
    Expression<double>? globalProgress,
    Expression<int>? currentChapter,
    Expression<double>? chapterProgress,
    Expression<String>? lastReadAt,
    Expression<double>? chapterScrollOffset,
    Expression<String>? sourceLanguage,
    Expression<String>? sourceLanguageOverride,
    Expression<double>? languageConfidence,
    Expression<String>? targetExplanationLanguage,
    Expression<String>? difficultyStudyWords,
    Expression<String>? difficultyRatingJson,
    Expression<String>? difficultyVocabularySignature,
    Expression<String>? difficultyComputedAt,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (language != null) 'language': language,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (sourcePath != null) 'source_path': sourcePath,
      if (coverPath != null) 'cover_path': coverPath,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (globalProgress != null) 'global_progress': globalProgress,
      if (currentChapter != null) 'current_chapter': currentChapter,
      if (chapterProgress != null) 'chapter_progress': chapterProgress,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (chapterScrollOffset != null)
        'chapter_scroll_offset': chapterScrollOffset,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (sourceLanguageOverride != null)
        'source_language_override': sourceLanguageOverride,
      if (languageConfidence != null) 'language_confidence': languageConfidence,
      if (targetExplanationLanguage != null)
        'target_explanation_language': targetExplanationLanguage,
      if (difficultyStudyWords != null)
        'difficulty_study_words': difficultyStudyWords,
      if (difficultyRatingJson != null)
        'difficulty_rating_json': difficultyRatingJson,
      if (difficultyVocabularySignature != null)
        'difficulty_vocabulary_signature': difficultyVocabularySignature,
      if (difficultyComputedAt != null)
        'difficulty_computed_at': difficultyComputedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? language,
    Value<String>? title,
    Value<String>? author,
    Value<String>? sourcePath,
    Value<String?>? coverPath,
    Value<int>? totalChapters,
    Value<double>? globalProgress,
    Value<int>? currentChapter,
    Value<double>? chapterProgress,
    Value<String?>? lastReadAt,
    Value<double?>? chapterScrollOffset,
    Value<String>? sourceLanguage,
    Value<String?>? sourceLanguageOverride,
    Value<double?>? languageConfidence,
    Value<String?>? targetExplanationLanguage,
    Value<String?>? difficultyStudyWords,
    Value<String?>? difficultyRatingJson,
    Value<String?>? difficultyVocabularySignature,
    Value<String?>? difficultyComputedAt,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return BookEntriesCompanion(
      id: id ?? this.id,
      language: language ?? this.language,
      title: title ?? this.title,
      author: author ?? this.author,
      sourcePath: sourcePath ?? this.sourcePath,
      coverPath: coverPath ?? this.coverPath,
      totalChapters: totalChapters ?? this.totalChapters,
      globalProgress: globalProgress ?? this.globalProgress,
      currentChapter: currentChapter ?? this.currentChapter,
      chapterProgress: chapterProgress ?? this.chapterProgress,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      chapterScrollOffset: chapterScrollOffset ?? this.chapterScrollOffset,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      sourceLanguageOverride:
          sourceLanguageOverride ?? this.sourceLanguageOverride,
      languageConfidence: languageConfidence ?? this.languageConfidence,
      targetExplanationLanguage:
          targetExplanationLanguage ?? this.targetExplanationLanguage,
      difficultyStudyWords: difficultyStudyWords ?? this.difficultyStudyWords,
      difficultyRatingJson: difficultyRatingJson ?? this.difficultyRatingJson,
      difficultyVocabularySignature:
          difficultyVocabularySignature ?? this.difficultyVocabularySignature,
      difficultyComputedAt: difficultyComputedAt ?? this.difficultyComputedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (totalChapters.present) {
      map['total_chapters'] = Variable<int>(totalChapters.value);
    }
    if (globalProgress.present) {
      map['global_progress'] = Variable<double>(globalProgress.value);
    }
    if (currentChapter.present) {
      map['current_chapter'] = Variable<int>(currentChapter.value);
    }
    if (chapterProgress.present) {
      map['chapter_progress'] = Variable<double>(chapterProgress.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<String>(lastReadAt.value);
    }
    if (chapterScrollOffset.present) {
      map['chapter_scroll_offset'] = Variable<double>(
        chapterScrollOffset.value,
      );
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (sourceLanguageOverride.present) {
      map['source_language_override'] = Variable<String>(
        sourceLanguageOverride.value,
      );
    }
    if (languageConfidence.present) {
      map['language_confidence'] = Variable<double>(languageConfidence.value);
    }
    if (targetExplanationLanguage.present) {
      map['target_explanation_language'] = Variable<String>(
        targetExplanationLanguage.value,
      );
    }
    if (difficultyStudyWords.present) {
      map['difficulty_study_words'] = Variable<String>(
        difficultyStudyWords.value,
      );
    }
    if (difficultyRatingJson.present) {
      map['difficulty_rating_json'] = Variable<String>(
        difficultyRatingJson.value,
      );
    }
    if (difficultyVocabularySignature.present) {
      map['difficulty_vocabulary_signature'] = Variable<String>(
        difficultyVocabularySignature.value,
      );
    }
    if (difficultyComputedAt.present) {
      map['difficulty_computed_at'] = Variable<String>(
        difficultyComputedAt.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookEntriesCompanion(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('coverPath: $coverPath, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('globalProgress: $globalProgress, ')
          ..write('currentChapter: $currentChapter, ')
          ..write('chapterProgress: $chapterProgress, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('chapterScrollOffset: $chapterScrollOffset, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('sourceLanguageOverride: $sourceLanguageOverride, ')
          ..write('languageConfidence: $languageConfidence, ')
          ..write('targetExplanationLanguage: $targetExplanationLanguage, ')
          ..write('difficultyStudyWords: $difficultyStudyWords, ')
          ..write('difficultyRatingJson: $difficultyRatingJson, ')
          ..write(
            'difficultyVocabularySignature: $difficultyVocabularySignature, ',
          )
          ..write('difficultyComputedAt: $difficultyComputedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserVocabulariesTable extends UserVocabularies
    with TableInfo<$UserVocabulariesTable, UserVocabulary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserVocabulariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _canonicalMeta = const VerificationMeta(
    'canonical',
  );
  @override
  late final GeneratedColumn<String> canonical = GeneratedColumn<String>(
    'canonical',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<String> lastModifiedAt = GeneratedColumn<String>(
    'last_modified_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  static const VerificationMeta _sourceBookIdMeta = const VerificationMeta(
    'sourceBookId',
  );
  @override
  late final GeneratedColumn<String> sourceBookId = GeneratedColumn<String>(
    'source_book_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceChapterIndexMeta =
      const VerificationMeta('sourceChapterIndex');
  @override
  late final GeneratedColumn<int> sourceChapterIndex = GeneratedColumn<int>(
    'source_chapter_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    language,
    canonical,
    status,
    createdAt,
    lastModifiedAt,
    sourceBookId,
    sourceChapterIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_vocabulary';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserVocabulary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('canonical')) {
      context.handle(
        _canonicalMeta,
        canonical.isAcceptableOrUnknown(data['canonical']!, _canonicalMeta),
      );
    } else if (isInserting) {
      context.missing(_canonicalMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('source_book_id')) {
      context.handle(
        _sourceBookIdMeta,
        sourceBookId.isAcceptableOrUnknown(
          data['source_book_id']!,
          _sourceBookIdMeta,
        ),
      );
    }
    if (data.containsKey('source_chapter_index')) {
      context.handle(
        _sourceChapterIndexMeta,
        sourceChapterIndex.isAcceptableOrUnknown(
          data['source_chapter_index']!,
          _sourceChapterIndexMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserVocabulary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserVocabulary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      canonical: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_at'],
      )!,
      sourceBookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_book_id'],
      ),
      sourceChapterIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_chapter_index'],
      ),
    );
  }

  @override
  $UserVocabulariesTable createAlias(String alias) {
    return $UserVocabulariesTable(attachedDatabase, alias);
  }
}

class UserVocabulary extends DataClass implements Insertable<UserVocabulary> {
  final String id;
  final String language;
  final String canonical;
  final String status;
  final String createdAt;
  final String lastModifiedAt;
  final String? sourceBookId;
  final int? sourceChapterIndex;
  const UserVocabulary({
    required this.id,
    required this.language,
    required this.canonical,
    required this.status,
    required this.createdAt,
    required this.lastModifiedAt,
    this.sourceBookId,
    this.sourceChapterIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language'] = Variable<String>(language);
    map['canonical'] = Variable<String>(canonical);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    map['last_modified_at'] = Variable<String>(lastModifiedAt);
    if (!nullToAbsent || sourceBookId != null) {
      map['source_book_id'] = Variable<String>(sourceBookId);
    }
    if (!nullToAbsent || sourceChapterIndex != null) {
      map['source_chapter_index'] = Variable<int>(sourceChapterIndex);
    }
    return map;
  }

  UserVocabulariesCompanion toCompanion(bool nullToAbsent) {
    return UserVocabulariesCompanion(
      id: Value(id),
      language: Value(language),
      canonical: Value(canonical),
      status: Value(status),
      createdAt: Value(createdAt),
      lastModifiedAt: Value(lastModifiedAt),
      sourceBookId: sourceBookId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceBookId),
      sourceChapterIndex: sourceChapterIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceChapterIndex),
    );
  }

  factory UserVocabulary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserVocabulary(
      id: serializer.fromJson<String>(json['id']),
      language: serializer.fromJson<String>(json['language']),
      canonical: serializer.fromJson<String>(json['canonical']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      lastModifiedAt: serializer.fromJson<String>(json['lastModifiedAt']),
      sourceBookId: serializer.fromJson<String?>(json['sourceBookId']),
      sourceChapterIndex: serializer.fromJson<int?>(json['sourceChapterIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'language': serializer.toJson<String>(language),
      'canonical': serializer.toJson<String>(canonical),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
      'lastModifiedAt': serializer.toJson<String>(lastModifiedAt),
      'sourceBookId': serializer.toJson<String?>(sourceBookId),
      'sourceChapterIndex': serializer.toJson<int?>(sourceChapterIndex),
    };
  }

  UserVocabulary copyWith({
    String? id,
    String? language,
    String? canonical,
    String? status,
    String? createdAt,
    String? lastModifiedAt,
    Value<String?> sourceBookId = const Value.absent(),
    Value<int?> sourceChapterIndex = const Value.absent(),
  }) => UserVocabulary(
    id: id ?? this.id,
    language: language ?? this.language,
    canonical: canonical ?? this.canonical,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    sourceBookId: sourceBookId.present ? sourceBookId.value : this.sourceBookId,
    sourceChapterIndex: sourceChapterIndex.present
        ? sourceChapterIndex.value
        : this.sourceChapterIndex,
  );
  UserVocabulary copyWithCompanion(UserVocabulariesCompanion data) {
    return UserVocabulary(
      id: data.id.present ? data.id.value : this.id,
      language: data.language.present ? data.language.value : this.language,
      canonical: data.canonical.present ? data.canonical.value : this.canonical,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      sourceBookId: data.sourceBookId.present
          ? data.sourceBookId.value
          : this.sourceBookId,
      sourceChapterIndex: data.sourceChapterIndex.present
          ? data.sourceChapterIndex.value
          : this.sourceChapterIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserVocabulary(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('canonical: $canonical, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('sourceBookId: $sourceBookId, ')
          ..write('sourceChapterIndex: $sourceChapterIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    language,
    canonical,
    status,
    createdAt,
    lastModifiedAt,
    sourceBookId,
    sourceChapterIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserVocabulary &&
          other.id == this.id &&
          other.language == this.language &&
          other.canonical == this.canonical &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.sourceBookId == this.sourceBookId &&
          other.sourceChapterIndex == this.sourceChapterIndex);
}

class UserVocabulariesCompanion extends UpdateCompanion<UserVocabulary> {
  final Value<String> id;
  final Value<String> language;
  final Value<String> canonical;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<String> lastModifiedAt;
  final Value<String?> sourceBookId;
  final Value<int?> sourceChapterIndex;
  final Value<int> rowid;
  const UserVocabulariesCompanion({
    this.id = const Value.absent(),
    this.language = const Value.absent(),
    this.canonical = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.sourceBookId = const Value.absent(),
    this.sourceChapterIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserVocabulariesCompanion.insert({
    required String id,
    this.language = const Value.absent(),
    required String canonical,
    required String status,
    this.createdAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.sourceBookId = const Value.absent(),
    this.sourceChapterIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       canonical = Value(canonical),
       status = Value(status);
  static Insertable<UserVocabulary> custom({
    Expression<String>? id,
    Expression<String>? language,
    Expression<String>? canonical,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<String>? lastModifiedAt,
    Expression<String>? sourceBookId,
    Expression<int>? sourceChapterIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (language != null) 'language': language,
      if (canonical != null) 'canonical': canonical,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (sourceBookId != null) 'source_book_id': sourceBookId,
      if (sourceChapterIndex != null)
        'source_chapter_index': sourceChapterIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserVocabulariesCompanion copyWith({
    Value<String>? id,
    Value<String>? language,
    Value<String>? canonical,
    Value<String>? status,
    Value<String>? createdAt,
    Value<String>? lastModifiedAt,
    Value<String?>? sourceBookId,
    Value<int?>? sourceChapterIndex,
    Value<int>? rowid,
  }) {
    return UserVocabulariesCompanion(
      id: id ?? this.id,
      language: language ?? this.language,
      canonical: canonical ?? this.canonical,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      sourceBookId: sourceBookId ?? this.sourceBookId,
      sourceChapterIndex: sourceChapterIndex ?? this.sourceChapterIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (canonical.present) {
      map['canonical'] = Variable<String>(canonical.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt.value);
    }
    if (sourceBookId.present) {
      map['source_book_id'] = Variable<String>(sourceBookId.value);
    }
    if (sourceChapterIndex.present) {
      map['source_chapter_index'] = Variable<int>(sourceChapterIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserVocabulariesCompanion(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('canonical: $canonical, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('sourceBookId: $sourceBookId, ')
          ..write('sourceChapterIndex: $sourceChapterIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordBookmarksTable extends WordBookmarks
    with TableInfo<$WordBookmarksTable, WordBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<String> addedAt = GeneratedColumn<String>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    language,
    bookId,
    word,
    translation,
    context,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordBookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordBookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $WordBookmarksTable createAlias(String alias) {
    return $WordBookmarksTable(attachedDatabase, alias);
  }
}

class WordBookmark extends DataClass implements Insertable<WordBookmark> {
  final String id;
  final String language;
  final String bookId;
  final String word;
  final String translation;
  final String context;
  final String addedAt;
  const WordBookmark({
    required this.id,
    required this.language,
    required this.bookId,
    required this.word,
    required this.translation,
    required this.context,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language'] = Variable<String>(language);
    map['book_id'] = Variable<String>(bookId);
    map['word'] = Variable<String>(word);
    map['translation'] = Variable<String>(translation);
    map['context'] = Variable<String>(context);
    map['added_at'] = Variable<String>(addedAt);
    return map;
  }

  WordBookmarksCompanion toCompanion(bool nullToAbsent) {
    return WordBookmarksCompanion(
      id: Value(id),
      language: Value(language),
      bookId: Value(bookId),
      word: Value(word),
      translation: Value(translation),
      context: Value(context),
      addedAt: Value(addedAt),
    );
  }

  factory WordBookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordBookmark(
      id: serializer.fromJson<String>(json['id']),
      language: serializer.fromJson<String>(json['language']),
      bookId: serializer.fromJson<String>(json['bookId']),
      word: serializer.fromJson<String>(json['word']),
      translation: serializer.fromJson<String>(json['translation']),
      context: serializer.fromJson<String>(json['context']),
      addedAt: serializer.fromJson<String>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'language': serializer.toJson<String>(language),
      'bookId': serializer.toJson<String>(bookId),
      'word': serializer.toJson<String>(word),
      'translation': serializer.toJson<String>(translation),
      'context': serializer.toJson<String>(context),
      'addedAt': serializer.toJson<String>(addedAt),
    };
  }

  WordBookmark copyWith({
    String? id,
    String? language,
    String? bookId,
    String? word,
    String? translation,
    String? context,
    String? addedAt,
  }) => WordBookmark(
    id: id ?? this.id,
    language: language ?? this.language,
    bookId: bookId ?? this.bookId,
    word: word ?? this.word,
    translation: translation ?? this.translation,
    context: context ?? this.context,
    addedAt: addedAt ?? this.addedAt,
  );
  WordBookmark copyWithCompanion(WordBookmarksCompanion data) {
    return WordBookmark(
      id: data.id.present ? data.id.value : this.id,
      language: data.language.present ? data.language.value : this.language,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      word: data.word.present ? data.word.value : this.word,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      context: data.context.present ? data.context.value : this.context,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordBookmark(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('bookId: $bookId, ')
          ..write('word: $word, ')
          ..write('translation: $translation, ')
          ..write('context: $context, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, language, bookId, word, translation, context, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordBookmark &&
          other.id == this.id &&
          other.language == this.language &&
          other.bookId == this.bookId &&
          other.word == this.word &&
          other.translation == this.translation &&
          other.context == this.context &&
          other.addedAt == this.addedAt);
}

class WordBookmarksCompanion extends UpdateCompanion<WordBookmark> {
  final Value<String> id;
  final Value<String> language;
  final Value<String> bookId;
  final Value<String> word;
  final Value<String> translation;
  final Value<String> context;
  final Value<String> addedAt;
  final Value<int> rowid;
  const WordBookmarksCompanion({
    this.id = const Value.absent(),
    this.language = const Value.absent(),
    this.bookId = const Value.absent(),
    this.word = const Value.absent(),
    this.translation = const Value.absent(),
    this.context = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordBookmarksCompanion.insert({
    required String id,
    this.language = const Value.absent(),
    required String bookId,
    required String word,
    this.translation = const Value.absent(),
    this.context = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       word = Value(word);
  static Insertable<WordBookmark> custom({
    Expression<String>? id,
    Expression<String>? language,
    Expression<String>? bookId,
    Expression<String>? word,
    Expression<String>? translation,
    Expression<String>? context,
    Expression<String>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (language != null) 'language': language,
      if (bookId != null) 'book_id': bookId,
      if (word != null) 'word': word,
      if (translation != null) 'translation': translation,
      if (context != null) 'context': context,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordBookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? language,
    Value<String>? bookId,
    Value<String>? word,
    Value<String>? translation,
    Value<String>? context,
    Value<String>? addedAt,
    Value<int>? rowid,
  }) {
    return WordBookmarksCompanion(
      id: id ?? this.id,
      language: language ?? this.language,
      bookId: bookId ?? this.bookId,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      context: context ?? this.context,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<String>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('bookId: $bookId, ')
          ..write('word: $word, ')
          ..write('translation: $translation, ')
          ..write('context: $context, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingBookmarksTable extends ReadingBookmarks
    with TableInfo<$ReadingBookmarksTable, ReadingBookmarkEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterIndexMeta = const VerificationMeta(
    'chapterIndex',
  );
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
    'chapter_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterTitleMeta = const VerificationMeta(
    'chapterTitle',
  );
  @override
  late final GeneratedColumn<String> chapterTitle = GeneratedColumn<String>(
    'chapter_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _excerptMeta = const VerificationMeta(
    'excerpt',
  );
  @override
  late final GeneratedColumn<String> excerpt = GeneratedColumn<String>(
    'excerpt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    language,
    bookId,
    chapterIndex,
    progress,
    chapterTitle,
    excerpt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingBookmarkEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
        _chapterIndexMeta,
        chapterIndex.isAcceptableOrUnknown(
          data['chapter_index']!,
          _chapterIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterIndexMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    } else if (isInserting) {
      context.missing(_progressMeta);
    }
    if (data.containsKey('chapter_title')) {
      context.handle(
        _chapterTitleMeta,
        chapterTitle.isAcceptableOrUnknown(
          data['chapter_title']!,
          _chapterTitleMeta,
        ),
      );
    }
    if (data.containsKey('excerpt')) {
      context.handle(
        _excerptMeta,
        excerpt.isAcceptableOrUnknown(data['excerpt']!, _excerptMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingBookmarkEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingBookmarkEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      chapterIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_index'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      chapterTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_title'],
      )!,
      excerpt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excerpt'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadingBookmarksTable createAlias(String alias) {
    return $ReadingBookmarksTable(attachedDatabase, alias);
  }
}

class ReadingBookmarkEntry extends DataClass
    implements Insertable<ReadingBookmarkEntry> {
  final String id;
  final String language;
  final String bookId;
  final int chapterIndex;
  final double progress;
  final String chapterTitle;
  final String excerpt;
  final String createdAt;
  const ReadingBookmarkEntry({
    required this.id,
    required this.language,
    required this.bookId,
    required this.chapterIndex,
    required this.progress,
    required this.chapterTitle,
    required this.excerpt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language'] = Variable<String>(language);
    map['book_id'] = Variable<String>(bookId);
    map['chapter_index'] = Variable<int>(chapterIndex);
    map['progress'] = Variable<double>(progress);
    map['chapter_title'] = Variable<String>(chapterTitle);
    map['excerpt'] = Variable<String>(excerpt);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ReadingBookmarksCompanion toCompanion(bool nullToAbsent) {
    return ReadingBookmarksCompanion(
      id: Value(id),
      language: Value(language),
      bookId: Value(bookId),
      chapterIndex: Value(chapterIndex),
      progress: Value(progress),
      chapterTitle: Value(chapterTitle),
      excerpt: Value(excerpt),
      createdAt: Value(createdAt),
    );
  }

  factory ReadingBookmarkEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingBookmarkEntry(
      id: serializer.fromJson<String>(json['id']),
      language: serializer.fromJson<String>(json['language']),
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterIndex: serializer.fromJson<int>(json['chapterIndex']),
      progress: serializer.fromJson<double>(json['progress']),
      chapterTitle: serializer.fromJson<String>(json['chapterTitle']),
      excerpt: serializer.fromJson<String>(json['excerpt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'language': serializer.toJson<String>(language),
      'bookId': serializer.toJson<String>(bookId),
      'chapterIndex': serializer.toJson<int>(chapterIndex),
      'progress': serializer.toJson<double>(progress),
      'chapterTitle': serializer.toJson<String>(chapterTitle),
      'excerpt': serializer.toJson<String>(excerpt),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ReadingBookmarkEntry copyWith({
    String? id,
    String? language,
    String? bookId,
    int? chapterIndex,
    double? progress,
    String? chapterTitle,
    String? excerpt,
    String? createdAt,
  }) => ReadingBookmarkEntry(
    id: id ?? this.id,
    language: language ?? this.language,
    bookId: bookId ?? this.bookId,
    chapterIndex: chapterIndex ?? this.chapterIndex,
    progress: progress ?? this.progress,
    chapterTitle: chapterTitle ?? this.chapterTitle,
    excerpt: excerpt ?? this.excerpt,
    createdAt: createdAt ?? this.createdAt,
  );
  ReadingBookmarkEntry copyWithCompanion(ReadingBookmarksCompanion data) {
    return ReadingBookmarkEntry(
      id: data.id.present ? data.id.value : this.id,
      language: data.language.present ? data.language.value : this.language,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      progress: data.progress.present ? data.progress.value : this.progress,
      chapterTitle: data.chapterTitle.present
          ? data.chapterTitle.value
          : this.chapterTitle,
      excerpt: data.excerpt.present ? data.excerpt.value : this.excerpt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingBookmarkEntry(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('bookId: $bookId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('progress: $progress, ')
          ..write('chapterTitle: $chapterTitle, ')
          ..write('excerpt: $excerpt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    language,
    bookId,
    chapterIndex,
    progress,
    chapterTitle,
    excerpt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingBookmarkEntry &&
          other.id == this.id &&
          other.language == this.language &&
          other.bookId == this.bookId &&
          other.chapterIndex == this.chapterIndex &&
          other.progress == this.progress &&
          other.chapterTitle == this.chapterTitle &&
          other.excerpt == this.excerpt &&
          other.createdAt == this.createdAt);
}

class ReadingBookmarksCompanion extends UpdateCompanion<ReadingBookmarkEntry> {
  final Value<String> id;
  final Value<String> language;
  final Value<String> bookId;
  final Value<int> chapterIndex;
  final Value<double> progress;
  final Value<String> chapterTitle;
  final Value<String> excerpt;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ReadingBookmarksCompanion({
    this.id = const Value.absent(),
    this.language = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.progress = const Value.absent(),
    this.chapterTitle = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingBookmarksCompanion.insert({
    required String id,
    this.language = const Value.absent(),
    required String bookId,
    required int chapterIndex,
    required double progress,
    this.chapterTitle = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       chapterIndex = Value(chapterIndex),
       progress = Value(progress);
  static Insertable<ReadingBookmarkEntry> custom({
    Expression<String>? id,
    Expression<String>? language,
    Expression<String>? bookId,
    Expression<int>? chapterIndex,
    Expression<double>? progress,
    Expression<String>? chapterTitle,
    Expression<String>? excerpt,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (language != null) 'language': language,
      if (bookId != null) 'book_id': bookId,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (progress != null) 'progress': progress,
      if (chapterTitle != null) 'chapter_title': chapterTitle,
      if (excerpt != null) 'excerpt': excerpt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingBookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? language,
    Value<String>? bookId,
    Value<int>? chapterIndex,
    Value<double>? progress,
    Value<String>? chapterTitle,
    Value<String>? excerpt,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return ReadingBookmarksCompanion(
      id: id ?? this.id,
      language: language ?? this.language,
      bookId: bookId ?? this.bookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      progress: progress ?? this.progress,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      excerpt: excerpt ?? this.excerpt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (chapterTitle.present) {
      map['chapter_title'] = Variable<String>(chapterTitle.value);
    }
    if (excerpt.present) {
      map['excerpt'] = Variable<String>(excerpt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('bookId: $bookId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('progress: $progress, ')
          ..write('chapterTitle: $chapterTitle, ')
          ..write('excerpt: $excerpt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingConfigTable extends ReadingConfig
    with TableInfo<$ReadingConfigTable, ReadingConfigEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  @override
  List<GeneratedColumn> get $columns => [key, language, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_config';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingConfigEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key, language};
  @override
  ReadingConfigEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingConfigEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $ReadingConfigTable createAlias(String alias) {
    return $ReadingConfigTable(attachedDatabase, alias);
  }
}

class ReadingConfigEntry extends DataClass
    implements Insertable<ReadingConfigEntry> {
  final String key;
  final String language;
  final String value;
  const ReadingConfigEntry({
    required this.key,
    required this.language,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['language'] = Variable<String>(language);
    map['value'] = Variable<String>(value);
    return map;
  }

  ReadingConfigCompanion toCompanion(bool nullToAbsent) {
    return ReadingConfigCompanion(
      key: Value(key),
      language: Value(language),
      value: Value(value),
    );
  }

  factory ReadingConfigEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingConfigEntry(
      key: serializer.fromJson<String>(json['key']),
      language: serializer.fromJson<String>(json['language']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'language': serializer.toJson<String>(language),
      'value': serializer.toJson<String>(value),
    };
  }

  ReadingConfigEntry copyWith({String? key, String? language, String? value}) =>
      ReadingConfigEntry(
        key: key ?? this.key,
        language: language ?? this.language,
        value: value ?? this.value,
      );
  ReadingConfigEntry copyWithCompanion(ReadingConfigCompanion data) {
    return ReadingConfigEntry(
      key: data.key.present ? data.key.value : this.key,
      language: data.language.present ? data.language.value : this.language,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingConfigEntry(')
          ..write('key: $key, ')
          ..write('language: $language, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, language, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingConfigEntry &&
          other.key == this.key &&
          other.language == this.language &&
          other.value == this.value);
}

class ReadingConfigCompanion extends UpdateCompanion<ReadingConfigEntry> {
  final Value<String> key;
  final Value<String> language;
  final Value<String> value;
  final Value<int> rowid;
  const ReadingConfigCompanion({
    this.key = const Value.absent(),
    this.language = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingConfigCompanion.insert({
    required String key,
    this.language = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<ReadingConfigEntry> custom({
    Expression<String>? key,
    Expression<String>? language,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (language != null) 'language': language,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingConfigCompanion copyWith({
    Value<String>? key,
    Value<String>? language,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ReadingConfigCompanion(
      key: key ?? this.key,
      language: language ?? this.language,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingConfigCompanion(')
          ..write('key: $key, ')
          ..write('language: $language, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingTimeTable extends ReadingTime
    with TableInfo<$ReadingTimeTable, ReadingTimeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingTimeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(_zeroInt),
  );
  @override
  List<GeneratedColumn> get $columns => [key, language, seconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_time';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingTimeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key, language};
  @override
  ReadingTimeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingTimeEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
    );
  }

  @override
  $ReadingTimeTable createAlias(String alias) {
    return $ReadingTimeTable(attachedDatabase, alias);
  }
}

class ReadingTimeEntry extends DataClass
    implements Insertable<ReadingTimeEntry> {
  final String key;
  final String language;
  final int seconds;
  const ReadingTimeEntry({
    required this.key,
    required this.language,
    required this.seconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['language'] = Variable<String>(language);
    map['seconds'] = Variable<int>(seconds);
    return map;
  }

  ReadingTimeCompanion toCompanion(bool nullToAbsent) {
    return ReadingTimeCompanion(
      key: Value(key),
      language: Value(language),
      seconds: Value(seconds),
    );
  }

  factory ReadingTimeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingTimeEntry(
      key: serializer.fromJson<String>(json['key']),
      language: serializer.fromJson<String>(json['language']),
      seconds: serializer.fromJson<int>(json['seconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'language': serializer.toJson<String>(language),
      'seconds': serializer.toJson<int>(seconds),
    };
  }

  ReadingTimeEntry copyWith({String? key, String? language, int? seconds}) =>
      ReadingTimeEntry(
        key: key ?? this.key,
        language: language ?? this.language,
        seconds: seconds ?? this.seconds,
      );
  ReadingTimeEntry copyWithCompanion(ReadingTimeCompanion data) {
    return ReadingTimeEntry(
      key: data.key.present ? data.key.value : this.key,
      language: data.language.present ? data.language.value : this.language,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingTimeEntry(')
          ..write('key: $key, ')
          ..write('language: $language, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, language, seconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingTimeEntry &&
          other.key == this.key &&
          other.language == this.language &&
          other.seconds == this.seconds);
}

class ReadingTimeCompanion extends UpdateCompanion<ReadingTimeEntry> {
  final Value<String> key;
  final Value<String> language;
  final Value<int> seconds;
  final Value<int> rowid;
  const ReadingTimeCompanion({
    this.key = const Value.absent(),
    this.language = const Value.absent(),
    this.seconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingTimeCompanion.insert({
    required String key,
    this.language = const Value.absent(),
    this.seconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<ReadingTimeEntry> custom({
    Expression<String>? key,
    Expression<String>? language,
    Expression<int>? seconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (language != null) 'language': language,
      if (seconds != null) 'seconds': seconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingTimeCompanion copyWith({
    Value<String>? key,
    Value<String>? language,
    Value<int>? seconds,
    Value<int>? rowid,
  }) {
    return ReadingTimeCompanion(
      key: key ?? this.key,
      language: language ?? this.language,
      seconds: seconds ?? this.seconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingTimeCompanion(')
          ..write('key: $key, ')
          ..write('language: $language, ')
          ..write('seconds: $seconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictionaryCacheTable extends DictionaryCache
    with TableInfo<$DictionaryCacheTable, DictionaryCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  @override
  List<GeneratedColumn> get $columns => [key, language, value, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key, language};
  @override
  DictionaryCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryCacheEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DictionaryCacheTable createAlias(String alias) {
    return $DictionaryCacheTable(attachedDatabase, alias);
  }
}

class DictionaryCacheEntry extends DataClass
    implements Insertable<DictionaryCacheEntry> {
  final String key;
  final String language;
  final String value;
  final String createdAt;
  const DictionaryCacheEntry({
    required this.key,
    required this.language,
    required this.value,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['language'] = Variable<String>(language);
    map['value'] = Variable<String>(value);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  DictionaryCacheCompanion toCompanion(bool nullToAbsent) {
    return DictionaryCacheCompanion(
      key: Value(key),
      language: Value(language),
      value: Value(value),
      createdAt: Value(createdAt),
    );
  }

  factory DictionaryCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryCacheEntry(
      key: serializer.fromJson<String>(json['key']),
      language: serializer.fromJson<String>(json['language']),
      value: serializer.fromJson<String>(json['value']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'language': serializer.toJson<String>(language),
      'value': serializer.toJson<String>(value),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DictionaryCacheEntry copyWith({
    String? key,
    String? language,
    String? value,
    String? createdAt,
  }) => DictionaryCacheEntry(
    key: key ?? this.key,
    language: language ?? this.language,
    value: value ?? this.value,
    createdAt: createdAt ?? this.createdAt,
  );
  DictionaryCacheEntry copyWithCompanion(DictionaryCacheCompanion data) {
    return DictionaryCacheEntry(
      key: data.key.present ? data.key.value : this.key,
      language: data.language.present ? data.language.value : this.language,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryCacheEntry(')
          ..write('key: $key, ')
          ..write('language: $language, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, language, value, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryCacheEntry &&
          other.key == this.key &&
          other.language == this.language &&
          other.value == this.value &&
          other.createdAt == this.createdAt);
}

class DictionaryCacheCompanion extends UpdateCompanion<DictionaryCacheEntry> {
  final Value<String> key;
  final Value<String> language;
  final Value<String> value;
  final Value<String> createdAt;
  final Value<int> rowid;
  const DictionaryCacheCompanion({
    this.key = const Value.absent(),
    this.language = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictionaryCacheCompanion.insert({
    required String key,
    this.language = const Value.absent(),
    required String value,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<DictionaryCacheEntry> custom({
    Expression<String>? key,
    Expression<String>? language,
    Expression<String>? value,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (language != null) 'language': language,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictionaryCacheCompanion copyWith({
    Value<String>? key,
    Value<String>? language,
    Value<String>? value,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return DictionaryCacheCompanion(
      key: key ?? this.key,
      language: language ?? this.language,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryCacheCompanion(')
          ..write('key: $key, ')
          ..write('language: $language, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordContextsTable extends WordContexts
    with TableInfo<$WordContextsTable, WordContextEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  @override
  List<GeneratedColumn> get $columns => [word, language, data, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordContextEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {word, language};
  @override
  WordContextEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordContextEntry(
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WordContextsTable createAlias(String alias) {
    return $WordContextsTable(attachedDatabase, alias);
  }
}

class WordContextEntry extends DataClass
    implements Insertable<WordContextEntry> {
  final String word;
  final String language;
  final String data;
  final String createdAt;
  const WordContextEntry({
    required this.word,
    required this.language,
    required this.data,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word'] = Variable<String>(word);
    map['language'] = Variable<String>(language);
    map['data'] = Variable<String>(data);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  WordContextsCompanion toCompanion(bool nullToAbsent) {
    return WordContextsCompanion(
      word: Value(word),
      language: Value(language),
      data: Value(data),
      createdAt: Value(createdAt),
    );
  }

  factory WordContextEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordContextEntry(
      word: serializer.fromJson<String>(json['word']),
      language: serializer.fromJson<String>(json['language']),
      data: serializer.fromJson<String>(json['data']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'language': serializer.toJson<String>(language),
      'data': serializer.toJson<String>(data),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  WordContextEntry copyWith({
    String? word,
    String? language,
    String? data,
    String? createdAt,
  }) => WordContextEntry(
    word: word ?? this.word,
    language: language ?? this.language,
    data: data ?? this.data,
    createdAt: createdAt ?? this.createdAt,
  );
  WordContextEntry copyWithCompanion(WordContextsCompanion data) {
    return WordContextEntry(
      word: data.word.present ? data.word.value : this.word,
      language: data.language.present ? data.language.value : this.language,
      data: data.data.present ? data.data.value : this.data,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordContextEntry(')
          ..write('word: $word, ')
          ..write('language: $language, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(word, language, data, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordContextEntry &&
          other.word == this.word &&
          other.language == this.language &&
          other.data == this.data &&
          other.createdAt == this.createdAt);
}

class WordContextsCompanion extends UpdateCompanion<WordContextEntry> {
  final Value<String> word;
  final Value<String> language;
  final Value<String> data;
  final Value<String> createdAt;
  final Value<int> rowid;
  const WordContextsCompanion({
    this.word = const Value.absent(),
    this.language = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordContextsCompanion.insert({
    required String word,
    this.language = const Value.absent(),
    required String data,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : word = Value(word),
       data = Value(data);
  static Insertable<WordContextEntry> custom({
    Expression<String>? word,
    Expression<String>? language,
    Expression<String>? data,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (word != null) 'word': word,
      if (language != null) 'language': language,
      if (data != null) 'data': data,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordContextsCompanion copyWith({
    Value<String>? word,
    Value<String>? language,
    Value<String>? data,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return WordContextsCompanion(
      word: word ?? this.word,
      language: language ?? this.language,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordContextsCompanion(')
          ..write('word: $word, ')
          ..write('language: $language, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningItemsTable extends LearningItems
    with TableInfo<$LearningItemsTable, LearningItemEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalKeyMeta = const VerificationMeta(
    'canonicalKey',
  );
  @override
  late final GeneratedColumn<String> canonicalKey = GeneratedColumn<String>(
    'canonical_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _sourceTextMeta = const VerificationMeta(
    'sourceText',
  );
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
    'source_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _chapterIndexMeta = const VerificationMeta(
    'chapterIndex',
  );
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
    'chapter_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(_zeroInt),
  );
  static const VerificationMeta _chapterTitleMeta = const VerificationMeta(
    'chapterTitle',
  );
  @override
  late final GeneratedColumn<String> chapterTitle = GeneratedColumn<String>(
    'chapter_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<String> nextReviewAt = GeneratedColumn<String>(
    'next_review_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(_zeroInt),
  );
  static const VerificationMeta _lastResultMeta = const VerificationMeta(
    'lastResult',
  );
  @override
  late final GeneratedColumn<String> lastResult = GeneratedColumn<String>(
    'last_result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('newItem'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    language,
    type,
    canonicalKey,
    title,
    content,
    answer,
    note,
    sourceText,
    bookId,
    chapterIndex,
    chapterTitle,
    tags,
    metadata,
    nextReviewAt,
    reviewCount,
    lastResult,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningItemEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('canonical_key')) {
      context.handle(
        _canonicalKeyMeta,
        canonicalKey.isAcceptableOrUnknown(
          data['canonical_key']!,
          _canonicalKeyMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('source_text')) {
      context.handle(
        _sourceTextMeta,
        sourceText.isAcceptableOrUnknown(data['source_text']!, _sourceTextMeta),
      );
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
        _chapterIndexMeta,
        chapterIndex.isAcceptableOrUnknown(
          data['chapter_index']!,
          _chapterIndexMeta,
        ),
      );
    }
    if (data.containsKey('chapter_title')) {
      context.handle(
        _chapterTitleMeta,
        chapterTitle.isAcceptableOrUnknown(
          data['chapter_title']!,
          _chapterTitleMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextReviewAtMeta);
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('last_result')) {
      context.handle(
        _lastResultMeta,
        lastResult.isAcceptableOrUnknown(data['last_result']!, _lastResultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningItemEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningItemEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      canonicalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      sourceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_text'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      chapterIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_index'],
      )!,
      chapterTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_title'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      )!,
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_review_at'],
      )!,
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      lastResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_result'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LearningItemsTable createAlias(String alias) {
    return $LearningItemsTable(attachedDatabase, alias);
  }
}

class LearningItemEntry extends DataClass
    implements Insertable<LearningItemEntry> {
  final String id;
  final String language;
  final String type;
  final String canonicalKey;
  final String title;
  final String content;
  final String answer;
  final String note;
  final String sourceText;
  final String bookId;
  final int chapterIndex;
  final String chapterTitle;
  final String tags;
  final String metadata;
  final String nextReviewAt;
  final int reviewCount;
  final String lastResult;
  final String createdAt;
  final String updatedAt;
  const LearningItemEntry({
    required this.id,
    required this.language,
    required this.type,
    required this.canonicalKey,
    required this.title,
    required this.content,
    required this.answer,
    required this.note,
    required this.sourceText,
    required this.bookId,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.tags,
    required this.metadata,
    required this.nextReviewAt,
    required this.reviewCount,
    required this.lastResult,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language'] = Variable<String>(language);
    map['type'] = Variable<String>(type);
    map['canonical_key'] = Variable<String>(canonicalKey);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['answer'] = Variable<String>(answer);
    map['note'] = Variable<String>(note);
    map['source_text'] = Variable<String>(sourceText);
    map['book_id'] = Variable<String>(bookId);
    map['chapter_index'] = Variable<int>(chapterIndex);
    map['chapter_title'] = Variable<String>(chapterTitle);
    map['tags'] = Variable<String>(tags);
    map['metadata'] = Variable<String>(metadata);
    map['next_review_at'] = Variable<String>(nextReviewAt);
    map['review_count'] = Variable<int>(reviewCount);
    map['last_result'] = Variable<String>(lastResult);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  LearningItemsCompanion toCompanion(bool nullToAbsent) {
    return LearningItemsCompanion(
      id: Value(id),
      language: Value(language),
      type: Value(type),
      canonicalKey: Value(canonicalKey),
      title: Value(title),
      content: Value(content),
      answer: Value(answer),
      note: Value(note),
      sourceText: Value(sourceText),
      bookId: Value(bookId),
      chapterIndex: Value(chapterIndex),
      chapterTitle: Value(chapterTitle),
      tags: Value(tags),
      metadata: Value(metadata),
      nextReviewAt: Value(nextReviewAt),
      reviewCount: Value(reviewCount),
      lastResult: Value(lastResult),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LearningItemEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningItemEntry(
      id: serializer.fromJson<String>(json['id']),
      language: serializer.fromJson<String>(json['language']),
      type: serializer.fromJson<String>(json['type']),
      canonicalKey: serializer.fromJson<String>(json['canonicalKey']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      answer: serializer.fromJson<String>(json['answer']),
      note: serializer.fromJson<String>(json['note']),
      sourceText: serializer.fromJson<String>(json['sourceText']),
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterIndex: serializer.fromJson<int>(json['chapterIndex']),
      chapterTitle: serializer.fromJson<String>(json['chapterTitle']),
      tags: serializer.fromJson<String>(json['tags']),
      metadata: serializer.fromJson<String>(json['metadata']),
      nextReviewAt: serializer.fromJson<String>(json['nextReviewAt']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      lastResult: serializer.fromJson<String>(json['lastResult']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'language': serializer.toJson<String>(language),
      'type': serializer.toJson<String>(type),
      'canonicalKey': serializer.toJson<String>(canonicalKey),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'answer': serializer.toJson<String>(answer),
      'note': serializer.toJson<String>(note),
      'sourceText': serializer.toJson<String>(sourceText),
      'bookId': serializer.toJson<String>(bookId),
      'chapterIndex': serializer.toJson<int>(chapterIndex),
      'chapterTitle': serializer.toJson<String>(chapterTitle),
      'tags': serializer.toJson<String>(tags),
      'metadata': serializer.toJson<String>(metadata),
      'nextReviewAt': serializer.toJson<String>(nextReviewAt),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'lastResult': serializer.toJson<String>(lastResult),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  LearningItemEntry copyWith({
    String? id,
    String? language,
    String? type,
    String? canonicalKey,
    String? title,
    String? content,
    String? answer,
    String? note,
    String? sourceText,
    String? bookId,
    int? chapterIndex,
    String? chapterTitle,
    String? tags,
    String? metadata,
    String? nextReviewAt,
    int? reviewCount,
    String? lastResult,
    String? createdAt,
    String? updatedAt,
  }) => LearningItemEntry(
    id: id ?? this.id,
    language: language ?? this.language,
    type: type ?? this.type,
    canonicalKey: canonicalKey ?? this.canonicalKey,
    title: title ?? this.title,
    content: content ?? this.content,
    answer: answer ?? this.answer,
    note: note ?? this.note,
    sourceText: sourceText ?? this.sourceText,
    bookId: bookId ?? this.bookId,
    chapterIndex: chapterIndex ?? this.chapterIndex,
    chapterTitle: chapterTitle ?? this.chapterTitle,
    tags: tags ?? this.tags,
    metadata: metadata ?? this.metadata,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    reviewCount: reviewCount ?? this.reviewCount,
    lastResult: lastResult ?? this.lastResult,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LearningItemEntry copyWithCompanion(LearningItemsCompanion data) {
    return LearningItemEntry(
      id: data.id.present ? data.id.value : this.id,
      language: data.language.present ? data.language.value : this.language,
      type: data.type.present ? data.type.value : this.type,
      canonicalKey: data.canonicalKey.present
          ? data.canonicalKey.value
          : this.canonicalKey,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      answer: data.answer.present ? data.answer.value : this.answer,
      note: data.note.present ? data.note.value : this.note,
      sourceText: data.sourceText.present
          ? data.sourceText.value
          : this.sourceText,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      chapterTitle: data.chapterTitle.present
          ? data.chapterTitle.value
          : this.chapterTitle,
      tags: data.tags.present ? data.tags.value : this.tags,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      lastResult: data.lastResult.present
          ? data.lastResult.value
          : this.lastResult,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningItemEntry(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('type: $type, ')
          ..write('canonicalKey: $canonicalKey, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('answer: $answer, ')
          ..write('note: $note, ')
          ..write('sourceText: $sourceText, ')
          ..write('bookId: $bookId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('chapterTitle: $chapterTitle, ')
          ..write('tags: $tags, ')
          ..write('metadata: $metadata, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lastResult: $lastResult, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    language,
    type,
    canonicalKey,
    title,
    content,
    answer,
    note,
    sourceText,
    bookId,
    chapterIndex,
    chapterTitle,
    tags,
    metadata,
    nextReviewAt,
    reviewCount,
    lastResult,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningItemEntry &&
          other.id == this.id &&
          other.language == this.language &&
          other.type == this.type &&
          other.canonicalKey == this.canonicalKey &&
          other.title == this.title &&
          other.content == this.content &&
          other.answer == this.answer &&
          other.note == this.note &&
          other.sourceText == this.sourceText &&
          other.bookId == this.bookId &&
          other.chapterIndex == this.chapterIndex &&
          other.chapterTitle == this.chapterTitle &&
          other.tags == this.tags &&
          other.metadata == this.metadata &&
          other.nextReviewAt == this.nextReviewAt &&
          other.reviewCount == this.reviewCount &&
          other.lastResult == this.lastResult &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LearningItemsCompanion extends UpdateCompanion<LearningItemEntry> {
  final Value<String> id;
  final Value<String> language;
  final Value<String> type;
  final Value<String> canonicalKey;
  final Value<String> title;
  final Value<String> content;
  final Value<String> answer;
  final Value<String> note;
  final Value<String> sourceText;
  final Value<String> bookId;
  final Value<int> chapterIndex;
  final Value<String> chapterTitle;
  final Value<String> tags;
  final Value<String> metadata;
  final Value<String> nextReviewAt;
  final Value<int> reviewCount;
  final Value<String> lastResult;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const LearningItemsCompanion({
    this.id = const Value.absent(),
    this.language = const Value.absent(),
    this.type = const Value.absent(),
    this.canonicalKey = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.answer = const Value.absent(),
    this.note = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.chapterTitle = const Value.absent(),
    this.tags = const Value.absent(),
    this.metadata = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.lastResult = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningItemsCompanion.insert({
    required String id,
    this.language = const Value.absent(),
    required String type,
    this.canonicalKey = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.answer = const Value.absent(),
    this.note = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.chapterTitle = const Value.absent(),
    this.tags = const Value.absent(),
    this.metadata = const Value.absent(),
    required String nextReviewAt,
    this.reviewCount = const Value.absent(),
    this.lastResult = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       nextReviewAt = Value(nextReviewAt);
  static Insertable<LearningItemEntry> custom({
    Expression<String>? id,
    Expression<String>? language,
    Expression<String>? type,
    Expression<String>? canonicalKey,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? answer,
    Expression<String>? note,
    Expression<String>? sourceText,
    Expression<String>? bookId,
    Expression<int>? chapterIndex,
    Expression<String>? chapterTitle,
    Expression<String>? tags,
    Expression<String>? metadata,
    Expression<String>? nextReviewAt,
    Expression<int>? reviewCount,
    Expression<String>? lastResult,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (language != null) 'language': language,
      if (type != null) 'type': type,
      if (canonicalKey != null) 'canonical_key': canonicalKey,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (answer != null) 'answer': answer,
      if (note != null) 'note': note,
      if (sourceText != null) 'source_text': sourceText,
      if (bookId != null) 'book_id': bookId,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (chapterTitle != null) 'chapter_title': chapterTitle,
      if (tags != null) 'tags': tags,
      if (metadata != null) 'metadata': metadata,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (reviewCount != null) 'review_count': reviewCount,
      if (lastResult != null) 'last_result': lastResult,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? language,
    Value<String>? type,
    Value<String>? canonicalKey,
    Value<String>? title,
    Value<String>? content,
    Value<String>? answer,
    Value<String>? note,
    Value<String>? sourceText,
    Value<String>? bookId,
    Value<int>? chapterIndex,
    Value<String>? chapterTitle,
    Value<String>? tags,
    Value<String>? metadata,
    Value<String>? nextReviewAt,
    Value<int>? reviewCount,
    Value<String>? lastResult,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return LearningItemsCompanion(
      id: id ?? this.id,
      language: language ?? this.language,
      type: type ?? this.type,
      canonicalKey: canonicalKey ?? this.canonicalKey,
      title: title ?? this.title,
      content: content ?? this.content,
      answer: answer ?? this.answer,
      note: note ?? this.note,
      sourceText: sourceText ?? this.sourceText,
      bookId: bookId ?? this.bookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastResult: lastResult ?? this.lastResult,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (canonicalKey.present) {
      map['canonical_key'] = Variable<String>(canonicalKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (chapterTitle.present) {
      map['chapter_title'] = Variable<String>(chapterTitle.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<String>(nextReviewAt.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (lastResult.present) {
      map['last_result'] = Variable<String>(lastResult.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningItemsCompanion(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('type: $type, ')
          ..write('canonicalKey: $canonicalKey, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('answer: $answer, ')
          ..write('note: $note, ')
          ..write('sourceText: $sourceText, ')
          ..write('bookId: $bookId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('chapterTitle: $chapterTitle, ')
          ..write('tags: $tags, ')
          ..write('metadata: $metadata, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lastResult: $lastResult, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningAnalyticsTable extends LearningAnalytics
    with TableInfo<$LearningAnalyticsTable, LearningAnalyticsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningAnalyticsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_defaultLang),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(_zeroInt),
  );
  @override
  List<GeneratedColumn> get $columns => [key, language, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_analytics';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningAnalyticsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key, language};
  @override
  LearningAnalyticsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningAnalyticsEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LearningAnalyticsTable createAlias(String alias) {
    return $LearningAnalyticsTable(attachedDatabase, alias);
  }
}

class LearningAnalyticsEntry extends DataClass
    implements Insertable<LearningAnalyticsEntry> {
  final String key;
  final String language;
  final int value;
  const LearningAnalyticsEntry({
    required this.key,
    required this.language,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['language'] = Variable<String>(language);
    map['value'] = Variable<int>(value);
    return map;
  }

  LearningAnalyticsCompanion toCompanion(bool nullToAbsent) {
    return LearningAnalyticsCompanion(
      key: Value(key),
      language: Value(language),
      value: Value(value),
    );
  }

  factory LearningAnalyticsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningAnalyticsEntry(
      key: serializer.fromJson<String>(json['key']),
      language: serializer.fromJson<String>(json['language']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'language': serializer.toJson<String>(language),
      'value': serializer.toJson<int>(value),
    };
  }

  LearningAnalyticsEntry copyWith({
    String? key,
    String? language,
    int? value,
  }) => LearningAnalyticsEntry(
    key: key ?? this.key,
    language: language ?? this.language,
    value: value ?? this.value,
  );
  LearningAnalyticsEntry copyWithCompanion(LearningAnalyticsCompanion data) {
    return LearningAnalyticsEntry(
      key: data.key.present ? data.key.value : this.key,
      language: data.language.present ? data.language.value : this.language,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningAnalyticsEntry(')
          ..write('key: $key, ')
          ..write('language: $language, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, language, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningAnalyticsEntry &&
          other.key == this.key &&
          other.language == this.language &&
          other.value == this.value);
}

class LearningAnalyticsCompanion
    extends UpdateCompanion<LearningAnalyticsEntry> {
  final Value<String> key;
  final Value<String> language;
  final Value<int> value;
  final Value<int> rowid;
  const LearningAnalyticsCompanion({
    this.key = const Value.absent(),
    this.language = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningAnalyticsCompanion.insert({
    required String key,
    this.language = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<LearningAnalyticsEntry> custom({
    Expression<String>? key,
    Expression<String>? language,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (language != null) 'language': language,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningAnalyticsCompanion copyWith({
    Value<String>? key,
    Value<String>? language,
    Value<int>? value,
    Value<int>? rowid,
  }) {
    return LearningAnalyticsCompanion(
      key: key ?? this.key,
      language: language ?? this.language,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningAnalyticsCompanion(')
          ..write('key: $key, ')
          ..write('language: $language, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordLevelsTable extends WordLevels
    with TableInfo<$WordLevelsTable, WordLevelEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originFormMeta = const VerificationMeta(
    'originForm',
  );
  @override
  late final GeneratedColumn<String> originForm = GeneratedColumn<String>(
    'origin_form',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _levelIndexMeta = const VerificationMeta(
    'levelIndex',
  );
  @override
  late final GeneratedColumn<int> levelIndex = GeneratedColumn<int>(
    'level_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [word, originForm, levelIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_levels';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordLevelEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('origin_form')) {
      context.handle(
        _originFormMeta,
        originForm.isAcceptableOrUnknown(data['origin_form']!, _originFormMeta),
      );
    }
    if (data.containsKey('level_index')) {
      context.handle(
        _levelIndexMeta,
        levelIndex.isAcceptableOrUnknown(data['level_index']!, _levelIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_levelIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {word};
  @override
  WordLevelEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordLevelEntry(
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      originForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_form'],
      )!,
      levelIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level_index'],
      )!,
    );
  }

  @override
  $WordLevelsTable createAlias(String alias) {
    return $WordLevelsTable(attachedDatabase, alias);
  }
}

class WordLevelEntry extends DataClass implements Insertable<WordLevelEntry> {
  final String word;
  final String originForm;
  final int levelIndex;
  const WordLevelEntry({
    required this.word,
    required this.originForm,
    required this.levelIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word'] = Variable<String>(word);
    map['origin_form'] = Variable<String>(originForm);
    map['level_index'] = Variable<int>(levelIndex);
    return map;
  }

  WordLevelsCompanion toCompanion(bool nullToAbsent) {
    return WordLevelsCompanion(
      word: Value(word),
      originForm: Value(originForm),
      levelIndex: Value(levelIndex),
    );
  }

  factory WordLevelEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordLevelEntry(
      word: serializer.fromJson<String>(json['word']),
      originForm: serializer.fromJson<String>(json['originForm']),
      levelIndex: serializer.fromJson<int>(json['levelIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'originForm': serializer.toJson<String>(originForm),
      'levelIndex': serializer.toJson<int>(levelIndex),
    };
  }

  WordLevelEntry copyWith({
    String? word,
    String? originForm,
    int? levelIndex,
  }) => WordLevelEntry(
    word: word ?? this.word,
    originForm: originForm ?? this.originForm,
    levelIndex: levelIndex ?? this.levelIndex,
  );
  WordLevelEntry copyWithCompanion(WordLevelsCompanion data) {
    return WordLevelEntry(
      word: data.word.present ? data.word.value : this.word,
      originForm: data.originForm.present
          ? data.originForm.value
          : this.originForm,
      levelIndex: data.levelIndex.present
          ? data.levelIndex.value
          : this.levelIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordLevelEntry(')
          ..write('word: $word, ')
          ..write('originForm: $originForm, ')
          ..write('levelIndex: $levelIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(word, originForm, levelIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordLevelEntry &&
          other.word == this.word &&
          other.originForm == this.originForm &&
          other.levelIndex == this.levelIndex);
}

class WordLevelsCompanion extends UpdateCompanion<WordLevelEntry> {
  final Value<String> word;
  final Value<String> originForm;
  final Value<int> levelIndex;
  final Value<int> rowid;
  const WordLevelsCompanion({
    this.word = const Value.absent(),
    this.originForm = const Value.absent(),
    this.levelIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordLevelsCompanion.insert({
    required String word,
    this.originForm = const Value.absent(),
    required int levelIndex,
    this.rowid = const Value.absent(),
  }) : word = Value(word),
       levelIndex = Value(levelIndex);
  static Insertable<WordLevelEntry> custom({
    Expression<String>? word,
    Expression<String>? originForm,
    Expression<int>? levelIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (word != null) 'word': word,
      if (originForm != null) 'origin_form': originForm,
      if (levelIndex != null) 'level_index': levelIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordLevelsCompanion copyWith({
    Value<String>? word,
    Value<String>? originForm,
    Value<int>? levelIndex,
    Value<int>? rowid,
  }) {
    return WordLevelsCompanion(
      word: word ?? this.word,
      originForm: originForm ?? this.originForm,
      levelIndex: levelIndex ?? this.levelIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (originForm.present) {
      map['origin_form'] = Variable<String>(originForm.value);
    }
    if (levelIndex.present) {
      map['level_index'] = Variable<int>(levelIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordLevelsCompanion(')
          ..write('word: $word, ')
          ..write('originForm: $originForm, ')
          ..write('levelIndex: $levelIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RssSubscriptionsTable extends RssSubscriptions
    with TableInfo<$RssSubscriptionsTable, RssSubscriptionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssSubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<String> lastFetchedAt = GeneratedColumn<String>(
    'last_fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    url,
    title,
    description,
    imageUrl,
    lastFetchedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssSubscriptionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RssSubscriptionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssSubscriptionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_fetched_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RssSubscriptionsTable createAlias(String alias) {
    return $RssSubscriptionsTable(attachedDatabase, alias);
  }
}

class RssSubscriptionEntry extends DataClass
    implements Insertable<RssSubscriptionEntry> {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? lastFetchedAt;
  final String createdAt;
  const RssSubscriptionEntry({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
    this.lastFetchedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || lastFetchedAt != null) {
      map['last_fetched_at'] = Variable<String>(lastFetchedAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  RssSubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return RssSubscriptionsCompanion(
      id: Value(id),
      url: Value(url),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      lastFetchedAt: lastFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchedAt),
      createdAt: Value(createdAt),
    );
  }

  factory RssSubscriptionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssSubscriptionEntry(
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      lastFetchedAt: serializer.fromJson<String?>(json['lastFetchedAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'lastFetchedAt': serializer.toJson<String?>(lastFetchedAt),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  RssSubscriptionEntry copyWith({
    String? id,
    String? url,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> lastFetchedAt = const Value.absent(),
    String? createdAt,
  }) => RssSubscriptionEntry(
    id: id ?? this.id,
    url: url ?? this.url,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    lastFetchedAt: lastFetchedAt.present
        ? lastFetchedAt.value
        : this.lastFetchedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  RssSubscriptionEntry copyWithCompanion(RssSubscriptionsCompanion data) {
    return RssSubscriptionEntry(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssSubscriptionEntry(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    url,
    title,
    description,
    imageUrl,
    lastFetchedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssSubscriptionEntry &&
          other.id == this.id &&
          other.url == this.url &&
          other.title == this.title &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl &&
          other.lastFetchedAt == this.lastFetchedAt &&
          other.createdAt == this.createdAt);
}

class RssSubscriptionsCompanion extends UpdateCompanion<RssSubscriptionEntry> {
  final Value<String> id;
  final Value<String> url;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> imageUrl;
  final Value<String?> lastFetchedAt;
  final Value<String> createdAt;
  final Value<int> rowid;
  const RssSubscriptionsCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssSubscriptionsCompanion.insert({
    required String id,
    required String url,
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       url = Value(url);
  static Insertable<RssSubscriptionEntry> custom({
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<String>? lastFetchedAt,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssSubscriptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? url,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? imageUrl,
    Value<String?>? lastFetchedAt,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return RssSubscriptionsCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<String>(lastFetchedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RssSubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RssArticlesTable extends RssArticles
    with TableInfo<$RssArticlesTable, RssArticleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subscriptionIdMeta = const VerificationMeta(
    'subscriptionId',
  );
  @override
  late final GeneratedColumn<String> subscriptionId = GeneratedColumn<String>(
    'subscription_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedUrlMeta = const VerificationMeta(
    'feedUrl',
  );
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
    'feed_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedTitleMeta = const VerificationMeta(
    'feedTitle',
  );
  @override
  late final GeneratedColumn<String> feedTitle = GeneratedColumn<String>(
    'feed_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyBlocksMeta = const VerificationMeta(
    'bodyBlocks',
  );
  @override
  late final GeneratedColumn<String> bodyBlocks = GeneratedColumn<String>(
    'body_blocks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumn<String> images = GeneratedColumn<String>(
    'images',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _pubDateMeta = const VerificationMeta(
    'pubDate',
  );
  @override
  late final GeneratedColumn<String> pubDate = GeneratedColumn<String>(
    'pub_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isReadLaterMeta = const VerificationMeta(
    'isReadLater',
  );
  @override
  late final GeneratedColumn<bool> isReadLater = GeneratedColumn<bool>(
    'is_read_later',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read_later" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subscriptionId,
    feedUrl,
    feedTitle,
    title,
    link,
    description,
    content,
    bodyBlocks,
    images,
    pubDate,
    author,
    isRead,
    isFavorite,
    isReadLater,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssArticleEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subscription_id')) {
      context.handle(
        _subscriptionIdMeta,
        subscriptionId.isAcceptableOrUnknown(
          data['subscription_id']!,
          _subscriptionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subscriptionIdMeta);
    }
    if (data.containsKey('feed_url')) {
      context.handle(
        _feedUrlMeta,
        feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_feedUrlMeta);
    }
    if (data.containsKey('feed_title')) {
      context.handle(
        _feedTitleMeta,
        feedTitle.isAcceptableOrUnknown(data['feed_title']!, _feedTitleMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('body_blocks')) {
      context.handle(
        _bodyBlocksMeta,
        bodyBlocks.isAcceptableOrUnknown(data['body_blocks']!, _bodyBlocksMeta),
      );
    }
    if (data.containsKey('images')) {
      context.handle(
        _imagesMeta,
        images.isAcceptableOrUnknown(data['images']!, _imagesMeta),
      );
    }
    if (data.containsKey('pub_date')) {
      context.handle(
        _pubDateMeta,
        pubDate.isAcceptableOrUnknown(data['pub_date']!, _pubDateMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    } else if (isInserting) {
      context.missing(_isReadMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    } else if (isInserting) {
      context.missing(_isFavoriteMeta);
    }
    if (data.containsKey('is_read_later')) {
      context.handle(
        _isReadLaterMeta,
        isReadLater.isAcceptableOrUnknown(
          data['is_read_later']!,
          _isReadLaterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isReadLaterMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RssArticleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssArticleEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subscriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subscription_id'],
      )!,
      feedUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_url'],
      )!,
      feedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_title'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      bodyBlocks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_blocks'],
      )!,
      images: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}images'],
      )!,
      pubDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_date'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isReadLater: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read_later'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RssArticlesTable createAlias(String alias) {
    return $RssArticlesTable(attachedDatabase, alias);
  }
}

class RssArticleEntry extends DataClass implements Insertable<RssArticleEntry> {
  final String id;
  final String subscriptionId;
  final String feedUrl;
  final String feedTitle;
  final String title;
  final String? link;
  final String? description;
  final String? content;
  final String bodyBlocks;
  final String images;
  final String? pubDate;
  final String? author;
  final bool isRead;
  final bool isFavorite;
  final bool isReadLater;
  final String createdAt;
  const RssArticleEntry({
    required this.id,
    required this.subscriptionId,
    required this.feedUrl,
    required this.feedTitle,
    required this.title,
    this.link,
    this.description,
    this.content,
    required this.bodyBlocks,
    required this.images,
    this.pubDate,
    this.author,
    required this.isRead,
    required this.isFavorite,
    required this.isReadLater,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subscription_id'] = Variable<String>(subscriptionId);
    map['feed_url'] = Variable<String>(feedUrl);
    map['feed_title'] = Variable<String>(feedTitle);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || link != null) {
      map['link'] = Variable<String>(link);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['body_blocks'] = Variable<String>(bodyBlocks);
    map['images'] = Variable<String>(images);
    if (!nullToAbsent || pubDate != null) {
      map['pub_date'] = Variable<String>(pubDate);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    map['is_read'] = Variable<bool>(isRead);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_read_later'] = Variable<bool>(isReadLater);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  RssArticlesCompanion toCompanion(bool nullToAbsent) {
    return RssArticlesCompanion(
      id: Value(id),
      subscriptionId: Value(subscriptionId),
      feedUrl: Value(feedUrl),
      feedTitle: Value(feedTitle),
      title: Value(title),
      link: link == null && nullToAbsent ? const Value.absent() : Value(link),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      bodyBlocks: Value(bodyBlocks),
      images: Value(images),
      pubDate: pubDate == null && nullToAbsent
          ? const Value.absent()
          : Value(pubDate),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      isRead: Value(isRead),
      isFavorite: Value(isFavorite),
      isReadLater: Value(isReadLater),
      createdAt: Value(createdAt),
    );
  }

  factory RssArticleEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssArticleEntry(
      id: serializer.fromJson<String>(json['id']),
      subscriptionId: serializer.fromJson<String>(json['subscriptionId']),
      feedUrl: serializer.fromJson<String>(json['feedUrl']),
      feedTitle: serializer.fromJson<String>(json['feedTitle']),
      title: serializer.fromJson<String>(json['title']),
      link: serializer.fromJson<String?>(json['link']),
      description: serializer.fromJson<String?>(json['description']),
      content: serializer.fromJson<String?>(json['content']),
      bodyBlocks: serializer.fromJson<String>(json['bodyBlocks']),
      images: serializer.fromJson<String>(json['images']),
      pubDate: serializer.fromJson<String?>(json['pubDate']),
      author: serializer.fromJson<String?>(json['author']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isReadLater: serializer.fromJson<bool>(json['isReadLater']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subscriptionId': serializer.toJson<String>(subscriptionId),
      'feedUrl': serializer.toJson<String>(feedUrl),
      'feedTitle': serializer.toJson<String>(feedTitle),
      'title': serializer.toJson<String>(title),
      'link': serializer.toJson<String?>(link),
      'description': serializer.toJson<String?>(description),
      'content': serializer.toJson<String?>(content),
      'bodyBlocks': serializer.toJson<String>(bodyBlocks),
      'images': serializer.toJson<String>(images),
      'pubDate': serializer.toJson<String?>(pubDate),
      'author': serializer.toJson<String?>(author),
      'isRead': serializer.toJson<bool>(isRead),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isReadLater': serializer.toJson<bool>(isReadLater),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  RssArticleEntry copyWith({
    String? id,
    String? subscriptionId,
    String? feedUrl,
    String? feedTitle,
    String? title,
    Value<String?> link = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> content = const Value.absent(),
    String? bodyBlocks,
    String? images,
    Value<String?> pubDate = const Value.absent(),
    Value<String?> author = const Value.absent(),
    bool? isRead,
    bool? isFavorite,
    bool? isReadLater,
    String? createdAt,
  }) => RssArticleEntry(
    id: id ?? this.id,
    subscriptionId: subscriptionId ?? this.subscriptionId,
    feedUrl: feedUrl ?? this.feedUrl,
    feedTitle: feedTitle ?? this.feedTitle,
    title: title ?? this.title,
    link: link.present ? link.value : this.link,
    description: description.present ? description.value : this.description,
    content: content.present ? content.value : this.content,
    bodyBlocks: bodyBlocks ?? this.bodyBlocks,
    images: images ?? this.images,
    pubDate: pubDate.present ? pubDate.value : this.pubDate,
    author: author.present ? author.value : this.author,
    isRead: isRead ?? this.isRead,
    isFavorite: isFavorite ?? this.isFavorite,
    isReadLater: isReadLater ?? this.isReadLater,
    createdAt: createdAt ?? this.createdAt,
  );
  RssArticleEntry copyWithCompanion(RssArticlesCompanion data) {
    return RssArticleEntry(
      id: data.id.present ? data.id.value : this.id,
      subscriptionId: data.subscriptionId.present
          ? data.subscriptionId.value
          : this.subscriptionId,
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      feedTitle: data.feedTitle.present ? data.feedTitle.value : this.feedTitle,
      title: data.title.present ? data.title.value : this.title,
      link: data.link.present ? data.link.value : this.link,
      description: data.description.present
          ? data.description.value
          : this.description,
      content: data.content.present ? data.content.value : this.content,
      bodyBlocks: data.bodyBlocks.present
          ? data.bodyBlocks.value
          : this.bodyBlocks,
      images: data.images.present ? data.images.value : this.images,
      pubDate: data.pubDate.present ? data.pubDate.value : this.pubDate,
      author: data.author.present ? data.author.value : this.author,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isReadLater: data.isReadLater.present
          ? data.isReadLater.value
          : this.isReadLater,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssArticleEntry(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('feedTitle: $feedTitle, ')
          ..write('title: $title, ')
          ..write('link: $link, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('bodyBlocks: $bodyBlocks, ')
          ..write('images: $images, ')
          ..write('pubDate: $pubDate, ')
          ..write('author: $author, ')
          ..write('isRead: $isRead, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isReadLater: $isReadLater, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subscriptionId,
    feedUrl,
    feedTitle,
    title,
    link,
    description,
    content,
    bodyBlocks,
    images,
    pubDate,
    author,
    isRead,
    isFavorite,
    isReadLater,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssArticleEntry &&
          other.id == this.id &&
          other.subscriptionId == this.subscriptionId &&
          other.feedUrl == this.feedUrl &&
          other.feedTitle == this.feedTitle &&
          other.title == this.title &&
          other.link == this.link &&
          other.description == this.description &&
          other.content == this.content &&
          other.bodyBlocks == this.bodyBlocks &&
          other.images == this.images &&
          other.pubDate == this.pubDate &&
          other.author == this.author &&
          other.isRead == this.isRead &&
          other.isFavorite == this.isFavorite &&
          other.isReadLater == this.isReadLater &&
          other.createdAt == this.createdAt);
}

class RssArticlesCompanion extends UpdateCompanion<RssArticleEntry> {
  final Value<String> id;
  final Value<String> subscriptionId;
  final Value<String> feedUrl;
  final Value<String> feedTitle;
  final Value<String> title;
  final Value<String?> link;
  final Value<String?> description;
  final Value<String?> content;
  final Value<String> bodyBlocks;
  final Value<String> images;
  final Value<String?> pubDate;
  final Value<String?> author;
  final Value<bool> isRead;
  final Value<bool> isFavorite;
  final Value<bool> isReadLater;
  final Value<String> createdAt;
  final Value<int> rowid;
  const RssArticlesCompanion({
    this.id = const Value.absent(),
    this.subscriptionId = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.feedTitle = const Value.absent(),
    this.title = const Value.absent(),
    this.link = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.bodyBlocks = const Value.absent(),
    this.images = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.author = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isReadLater = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssArticlesCompanion.insert({
    required String id,
    required String subscriptionId,
    required String feedUrl,
    this.feedTitle = const Value.absent(),
    required String title,
    this.link = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.bodyBlocks = const Value.absent(),
    this.images = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.author = const Value.absent(),
    required bool isRead,
    required bool isFavorite,
    required bool isReadLater,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subscriptionId = Value(subscriptionId),
       feedUrl = Value(feedUrl),
       title = Value(title),
       isRead = Value(isRead),
       isFavorite = Value(isFavorite),
       isReadLater = Value(isReadLater);
  static Insertable<RssArticleEntry> custom({
    Expression<String>? id,
    Expression<String>? subscriptionId,
    Expression<String>? feedUrl,
    Expression<String>? feedTitle,
    Expression<String>? title,
    Expression<String>? link,
    Expression<String>? description,
    Expression<String>? content,
    Expression<String>? bodyBlocks,
    Expression<String>? images,
    Expression<String>? pubDate,
    Expression<String>? author,
    Expression<bool>? isRead,
    Expression<bool>? isFavorite,
    Expression<bool>? isReadLater,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (feedTitle != null) 'feed_title': feedTitle,
      if (title != null) 'title': title,
      if (link != null) 'link': link,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (bodyBlocks != null) 'body_blocks': bodyBlocks,
      if (images != null) 'images': images,
      if (pubDate != null) 'pub_date': pubDate,
      if (author != null) 'author': author,
      if (isRead != null) 'is_read': isRead,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isReadLater != null) 'is_read_later': isReadLater,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssArticlesCompanion copyWith({
    Value<String>? id,
    Value<String>? subscriptionId,
    Value<String>? feedUrl,
    Value<String>? feedTitle,
    Value<String>? title,
    Value<String?>? link,
    Value<String?>? description,
    Value<String?>? content,
    Value<String>? bodyBlocks,
    Value<String>? images,
    Value<String?>? pubDate,
    Value<String?>? author,
    Value<bool>? isRead,
    Value<bool>? isFavorite,
    Value<bool>? isReadLater,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return RssArticlesCompanion(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      feedUrl: feedUrl ?? this.feedUrl,
      feedTitle: feedTitle ?? this.feedTitle,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      content: content ?? this.content,
      bodyBlocks: bodyBlocks ?? this.bodyBlocks,
      images: images ?? this.images,
      pubDate: pubDate ?? this.pubDate,
      author: author ?? this.author,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      isReadLater: isReadLater ?? this.isReadLater,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subscriptionId.present) {
      map['subscription_id'] = Variable<String>(subscriptionId.value);
    }
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (feedTitle.present) {
      map['feed_title'] = Variable<String>(feedTitle.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (bodyBlocks.present) {
      map['body_blocks'] = Variable<String>(bodyBlocks.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(images.value);
    }
    if (pubDate.present) {
      map['pub_date'] = Variable<String>(pubDate.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isReadLater.present) {
      map['is_read_later'] = Variable<bool>(isReadLater.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RssArticlesCompanion(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('feedTitle: $feedTitle, ')
          ..write('title: $title, ')
          ..write('link: $link, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('bodyBlocks: $bodyBlocks, ')
          ..write('images: $images, ')
          ..write('pubDate: $pubDate, ')
          ..write('author: $author, ')
          ..write('isRead: $isRead, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isReadLater: $isReadLater, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookGlossaryTable extends BookGlossary
    with TableInfo<$BookGlossaryTable, BookGlossaryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookGlossaryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalFormMeta = const VerificationMeta(
    'canonicalForm',
  );
  @override
  late final GeneratedColumn<String> canonicalForm = GeneratedColumn<String>(
    'canonical_form',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  static const VerificationMeta _sourceContextMeta = const VerificationMeta(
    'sourceContext',
  );
  @override
  late final GeneratedColumn<String> sourceContext = GeneratedColumn<String>(
    'source_context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: _nowIso,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<String> lastAccessedAt = GeneratedColumn<String>(
    'last_accessed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    word,
    canonicalForm,
    explanation,
    sourceContext,
    createdAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_glossary';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookGlossaryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('canonical_form')) {
      context.handle(
        _canonicalFormMeta,
        canonicalForm.isAcceptableOrUnknown(
          data['canonical_form']!,
          _canonicalFormMeta,
        ),
      );
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    if (data.containsKey('source_context')) {
      context.handle(
        _sourceContextMeta,
        sourceContext.isAcceptableOrUnknown(
          data['source_context']!,
          _sourceContextMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookGlossaryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookGlossaryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      canonicalForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_form'],
      ),
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      sourceContext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_context'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_accessed_at'],
      ),
    );
  }

  @override
  $BookGlossaryTable createAlias(String alias) {
    return $BookGlossaryTable(attachedDatabase, alias);
  }
}

class BookGlossaryEntry extends DataClass
    implements Insertable<BookGlossaryEntry> {
  final String id;
  final String bookId;
  final String word;
  final String? canonicalForm;
  final String explanation;
  final String? sourceContext;
  final String createdAt;
  final String? lastAccessedAt;
  const BookGlossaryEntry({
    required this.id,
    required this.bookId,
    required this.word,
    this.canonicalForm,
    required this.explanation,
    this.sourceContext,
    required this.createdAt,
    this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || canonicalForm != null) {
      map['canonical_form'] = Variable<String>(canonicalForm);
    }
    map['explanation'] = Variable<String>(explanation);
    if (!nullToAbsent || sourceContext != null) {
      map['source_context'] = Variable<String>(sourceContext);
    }
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<String>(lastAccessedAt);
    }
    return map;
  }

  BookGlossaryCompanion toCompanion(bool nullToAbsent) {
    return BookGlossaryCompanion(
      id: Value(id),
      bookId: Value(bookId),
      word: Value(word),
      canonicalForm: canonicalForm == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalForm),
      explanation: Value(explanation),
      sourceContext: sourceContext == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceContext),
      createdAt: Value(createdAt),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
    );
  }

  factory BookGlossaryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookGlossaryEntry(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      word: serializer.fromJson<String>(json['word']),
      canonicalForm: serializer.fromJson<String?>(json['canonicalForm']),
      explanation: serializer.fromJson<String>(json['explanation']),
      sourceContext: serializer.fromJson<String?>(json['sourceContext']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      lastAccessedAt: serializer.fromJson<String?>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'word': serializer.toJson<String>(word),
      'canonicalForm': serializer.toJson<String?>(canonicalForm),
      'explanation': serializer.toJson<String>(explanation),
      'sourceContext': serializer.toJson<String?>(sourceContext),
      'createdAt': serializer.toJson<String>(createdAt),
      'lastAccessedAt': serializer.toJson<String?>(lastAccessedAt),
    };
  }

  BookGlossaryEntry copyWith({
    String? id,
    String? bookId,
    String? word,
    Value<String?> canonicalForm = const Value.absent(),
    String? explanation,
    Value<String?> sourceContext = const Value.absent(),
    String? createdAt,
    Value<String?> lastAccessedAt = const Value.absent(),
  }) => BookGlossaryEntry(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    word: word ?? this.word,
    canonicalForm: canonicalForm.present
        ? canonicalForm.value
        : this.canonicalForm,
    explanation: explanation ?? this.explanation,
    sourceContext: sourceContext.present
        ? sourceContext.value
        : this.sourceContext,
    createdAt: createdAt ?? this.createdAt,
    lastAccessedAt: lastAccessedAt.present
        ? lastAccessedAt.value
        : this.lastAccessedAt,
  );
  BookGlossaryEntry copyWithCompanion(BookGlossaryCompanion data) {
    return BookGlossaryEntry(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      word: data.word.present ? data.word.value : this.word,
      canonicalForm: data.canonicalForm.present
          ? data.canonicalForm.value
          : this.canonicalForm,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      sourceContext: data.sourceContext.present
          ? data.sourceContext.value
          : this.sourceContext,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookGlossaryEntry(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('word: $word, ')
          ..write('canonicalForm: $canonicalForm, ')
          ..write('explanation: $explanation, ')
          ..write('sourceContext: $sourceContext, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    word,
    canonicalForm,
    explanation,
    sourceContext,
    createdAt,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookGlossaryEntry &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.word == this.word &&
          other.canonicalForm == this.canonicalForm &&
          other.explanation == this.explanation &&
          other.sourceContext == this.sourceContext &&
          other.createdAt == this.createdAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class BookGlossaryCompanion extends UpdateCompanion<BookGlossaryEntry> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> word;
  final Value<String?> canonicalForm;
  final Value<String> explanation;
  final Value<String?> sourceContext;
  final Value<String> createdAt;
  final Value<String?> lastAccessedAt;
  final Value<int> rowid;
  const BookGlossaryCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.word = const Value.absent(),
    this.canonicalForm = const Value.absent(),
    this.explanation = const Value.absent(),
    this.sourceContext = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookGlossaryCompanion.insert({
    required String id,
    required String bookId,
    required String word,
    this.canonicalForm = const Value.absent(),
    this.explanation = const Value.absent(),
    this.sourceContext = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       word = Value(word);
  static Insertable<BookGlossaryEntry> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? word,
    Expression<String>? canonicalForm,
    Expression<String>? explanation,
    Expression<String>? sourceContext,
    Expression<String>? createdAt,
    Expression<String>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (word != null) 'word': word,
      if (canonicalForm != null) 'canonical_form': canonicalForm,
      if (explanation != null) 'explanation': explanation,
      if (sourceContext != null) 'source_context': sourceContext,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookGlossaryCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? word,
    Value<String?>? canonicalForm,
    Value<String>? explanation,
    Value<String?>? sourceContext,
    Value<String>? createdAt,
    Value<String?>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return BookGlossaryCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      word: word ?? this.word,
      canonicalForm: canonicalForm ?? this.canonicalForm,
      explanation: explanation ?? this.explanation,
      sourceContext: sourceContext ?? this.sourceContext,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (canonicalForm.present) {
      map['canonical_form'] = Variable<String>(canonicalForm.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (sourceContext.present) {
      map['source_context'] = Variable<String>(sourceContext.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<String>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookGlossaryCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('word: $word, ')
          ..write('canonicalForm: $canonicalForm, ')
          ..write('explanation: $explanation, ')
          ..write('sourceContext: $sourceContext, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterRegistryTable extends CharacterRegistry
    with TableInfo<$CharacterRegistryTable, CharacterRegistryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterRegistryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_registry';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterRegistryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CharacterRegistryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterRegistryEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $CharacterRegistryTable createAlias(String alias) {
    return $CharacterRegistryTable(attachedDatabase, alias);
  }
}

class CharacterRegistryEntry extends DataClass
    implements Insertable<CharacterRegistryEntry> {
  final String key;
  final String value;
  const CharacterRegistryEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  CharacterRegistryCompanion toCompanion(bool nullToAbsent) {
    return CharacterRegistryCompanion(key: Value(key), value: Value(value));
  }

  factory CharacterRegistryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterRegistryEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  CharacterRegistryEntry copyWith({String? key, String? value}) =>
      CharacterRegistryEntry(key: key ?? this.key, value: value ?? this.value);
  CharacterRegistryEntry copyWithCompanion(CharacterRegistryCompanion data) {
    return CharacterRegistryEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterRegistryEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterRegistryEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class CharacterRegistryCompanion
    extends UpdateCompanion<CharacterRegistryEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const CharacterRegistryCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterRegistryCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<CharacterRegistryEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterRegistryCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return CharacterRegistryCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterRegistryCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(_emptyStr),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String value;
  const SettingsEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsEntry copyWith({String? key, String? value}) =>
      SettingsEntry(key: key ?? this.key, value: value ?? this.value);
  SettingsEntry copyWithCompanion(SettingsCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SettingsEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BookEntriesTable bookEntries = $BookEntriesTable(this);
  late final $UserVocabulariesTable userVocabularies = $UserVocabulariesTable(
    this,
  );
  late final $WordBookmarksTable wordBookmarks = $WordBookmarksTable(this);
  late final $ReadingBookmarksTable readingBookmarks = $ReadingBookmarksTable(
    this,
  );
  late final $ReadingConfigTable readingConfig = $ReadingConfigTable(this);
  late final $ReadingTimeTable readingTime = $ReadingTimeTable(this);
  late final $DictionaryCacheTable dictionaryCache = $DictionaryCacheTable(
    this,
  );
  late final $WordContextsTable wordContexts = $WordContextsTable(this);
  late final $LearningItemsTable learningItems = $LearningItemsTable(this);
  late final $LearningAnalyticsTable learningAnalytics =
      $LearningAnalyticsTable(this);
  late final $WordLevelsTable wordLevels = $WordLevelsTable(this);
  late final $RssSubscriptionsTable rssSubscriptions = $RssSubscriptionsTable(
    this,
  );
  late final $RssArticlesTable rssArticles = $RssArticlesTable(this);
  late final $BookGlossaryTable bookGlossary = $BookGlossaryTable(this);
  late final $CharacterRegistryTable characterRegistry =
      $CharacterRegistryTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxBooksLanguage = Index(
    'idx_books_language',
    'CREATE INDEX idx_books_language ON books (language)',
  );
  late final Index idxBooksLastRead = Index(
    'idx_books_last_read',
    'CREATE INDEX idx_books_last_read ON books (last_read_at)',
  );
  late final Index idxUserVocabLangCanonical = Index(
    'idx_user_vocab_lang_canonical',
    'CREATE INDEX idx_user_vocab_lang_canonical ON user_vocabulary (language, canonical)',
  );
  late final Index idxUserVocabStatus = Index(
    'idx_user_vocab_status',
    'CREATE INDEX idx_user_vocab_status ON user_vocabulary (status)',
  );
  late final Index idxWordBookmarksBook = Index(
    'idx_word_bookmarks_book',
    'CREATE INDEX idx_word_bookmarks_book ON word_bookmarks (book_id)',
  );
  late final Index idxWordBookmarksWord = Index(
    'idx_word_bookmarks_word',
    'CREATE INDEX idx_word_bookmarks_word ON word_bookmarks (word)',
  );
  late final Index idxReadingBookmarksBook = Index(
    'idx_reading_bookmarks_book',
    'CREATE INDEX idx_reading_bookmarks_book ON reading_bookmarks (book_id)',
  );
  late final Index idxLearningItemsType = Index(
    'idx_learning_items_type',
    'CREATE INDEX idx_learning_items_type ON learning_items (type)',
  );
  late final Index idxLearningItemsBook = Index(
    'idx_learning_items_book',
    'CREATE INDEX idx_learning_items_book ON learning_items (book_id)',
  );
  late final Index idxLearningItemsNextReview = Index(
    'idx_learning_items_next_review',
    'CREATE INDEX idx_learning_items_next_review ON learning_items (next_review_at)',
  );
  late final Index idxLearningItemsLang = Index(
    'idx_learning_items_lang',
    'CREATE INDEX idx_learning_items_lang ON learning_items (language)',
  );
  late final Index idxWordLevelsLevel = Index(
    'idx_word_levels_level',
    'CREATE INDEX idx_word_levels_level ON word_levels (level_index)',
  );
  late final Index idxRssUrl = Index(
    'idx_rss_url',
    'CREATE UNIQUE INDEX idx_rss_url ON rss_subscriptions (url)',
  );
  late final Index idxRssArticlesSub = Index(
    'idx_rss_articles_sub',
    'CREATE INDEX idx_rss_articles_sub ON rss_articles (subscription_id)',
  );
  late final Index idxRssArticlesUnread = Index(
    'idx_rss_articles_unread',
    'CREATE INDEX idx_rss_articles_unread ON rss_articles (is_read, pub_date)',
  );
  late final Index idxRssArticlesFav = Index(
    'idx_rss_articles_fav',
    'CREATE INDEX idx_rss_articles_fav ON rss_articles (is_favorite)',
  );
  late final Index idxRssArticlesLater = Index(
    'idx_rss_articles_later',
    'CREATE INDEX idx_rss_articles_later ON rss_articles (is_read_later)',
  );
  late final Index idxGlossaryBook = Index(
    'idx_glossary_book',
    'CREATE INDEX idx_glossary_book ON book_glossary (book_id)',
  );
  late final Index idxGlossaryWord = Index(
    'idx_glossary_word',
    'CREATE INDEX idx_glossary_word ON book_glossary (word)',
  );
  late final BookDao bookDao = BookDao(this as AppDatabase);
  late final BookGlossaryDao bookGlossaryDao = BookGlossaryDao(
    this as AppDatabase,
  );
  late final BookmarkDao bookmarkDao = BookmarkDao(this as AppDatabase);
  late final CharacterRegistryDao characterRegistryDao = CharacterRegistryDao(
    this as AppDatabase,
  );
  late final DictionaryCacheDao dictionaryCacheDao = DictionaryCacheDao(
    this as AppDatabase,
  );
  late final LearningAnalyticsDao learningAnalyticsDao = LearningAnalyticsDao(
    this as AppDatabase,
  );
  late final LearningItemDao learningItemDao = LearningItemDao(
    this as AppDatabase,
  );
  late final ReadingConfigDao readingConfigDao = ReadingConfigDao(
    this as AppDatabase,
  );
  late final ReadingTimeDao readingTimeDao = ReadingTimeDao(
    this as AppDatabase,
  );
  late final RssDao rssDao = RssDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final UserVocabularyDao userVocabularyDao = UserVocabularyDao(
    this as AppDatabase,
  );
  late final WordContextDao wordContextDao = WordContextDao(
    this as AppDatabase,
  );
  late final WordLevelDao wordLevelDao = WordLevelDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bookEntries,
    userVocabularies,
    wordBookmarks,
    readingBookmarks,
    readingConfig,
    readingTime,
    dictionaryCache,
    wordContexts,
    learningItems,
    learningAnalytics,
    wordLevels,
    rssSubscriptions,
    rssArticles,
    bookGlossary,
    characterRegistry,
    settings,
    idxBooksLanguage,
    idxBooksLastRead,
    idxUserVocabLangCanonical,
    idxUserVocabStatus,
    idxWordBookmarksBook,
    idxWordBookmarksWord,
    idxReadingBookmarksBook,
    idxLearningItemsType,
    idxLearningItemsBook,
    idxLearningItemsNextReview,
    idxLearningItemsLang,
    idxWordLevelsLevel,
    idxRssUrl,
    idxRssArticlesSub,
    idxRssArticlesUnread,
    idxRssArticlesFav,
    idxRssArticlesLater,
    idxGlossaryBook,
    idxGlossaryWord,
  ];
}

typedef $$BookEntriesTableCreateCompanionBuilder =
    BookEntriesCompanion Function({
      required String id,
      Value<String> language,
      required String title,
      Value<String> author,
      required String sourcePath,
      Value<String?> coverPath,
      Value<int> totalChapters,
      Value<double> globalProgress,
      Value<int> currentChapter,
      Value<double> chapterProgress,
      Value<String?> lastReadAt,
      Value<double?> chapterScrollOffset,
      Value<String> sourceLanguage,
      Value<String?> sourceLanguageOverride,
      Value<double?> languageConfidence,
      Value<String?> targetExplanationLanguage,
      Value<String?> difficultyStudyWords,
      Value<String?> difficultyRatingJson,
      Value<String?> difficultyVocabularySignature,
      Value<String?> difficultyComputedAt,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $$BookEntriesTableUpdateCompanionBuilder =
    BookEntriesCompanion Function({
      Value<String> id,
      Value<String> language,
      Value<String> title,
      Value<String> author,
      Value<String> sourcePath,
      Value<String?> coverPath,
      Value<int> totalChapters,
      Value<double> globalProgress,
      Value<int> currentChapter,
      Value<double> chapterProgress,
      Value<String?> lastReadAt,
      Value<double?> chapterScrollOffset,
      Value<String> sourceLanguage,
      Value<String?> sourceLanguageOverride,
      Value<double?> languageConfidence,
      Value<String?> targetExplanationLanguage,
      Value<String?> difficultyStudyWords,
      Value<String?> difficultyRatingJson,
      Value<String?> difficultyVocabularySignature,
      Value<String?> difficultyComputedAt,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$BookEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BookEntriesTable> {
  $$BookEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get globalProgress => $composableBuilder(
    column: $table.globalProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentChapter => $composableBuilder(
    column: $table.currentChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chapterProgress => $composableBuilder(
    column: $table.chapterProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chapterScrollOffset => $composableBuilder(
    column: $table.chapterScrollOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLanguageOverride => $composableBuilder(
    column: $table.sourceLanguageOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get languageConfidence => $composableBuilder(
    column: $table.languageConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetExplanationLanguage => $composableBuilder(
    column: $table.targetExplanationLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficultyStudyWords => $composableBuilder(
    column: $table.difficultyStudyWords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficultyRatingJson => $composableBuilder(
    column: $table.difficultyRatingJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficultyVocabularySignature => $composableBuilder(
    column: $table.difficultyVocabularySignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficultyComputedAt => $composableBuilder(
    column: $table.difficultyComputedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BookEntriesTable> {
  $$BookEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get globalProgress => $composableBuilder(
    column: $table.globalProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentChapter => $composableBuilder(
    column: $table.currentChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chapterProgress => $composableBuilder(
    column: $table.chapterProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chapterScrollOffset => $composableBuilder(
    column: $table.chapterScrollOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLanguageOverride => $composableBuilder(
    column: $table.sourceLanguageOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get languageConfidence => $composableBuilder(
    column: $table.languageConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetExplanationLanguage => $composableBuilder(
    column: $table.targetExplanationLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficultyStudyWords => $composableBuilder(
    column: $table.difficultyStudyWords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficultyRatingJson => $composableBuilder(
    column: $table.difficultyRatingJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficultyVocabularySignature =>
      $composableBuilder(
        column: $table.difficultyVocabularySignature,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get difficultyComputedAt => $composableBuilder(
    column: $table.difficultyComputedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookEntriesTable> {
  $$BookEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get globalProgress => $composableBuilder(
    column: $table.globalProgress,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentChapter => $composableBuilder(
    column: $table.currentChapter,
    builder: (column) => column,
  );

  GeneratedColumn<double> get chapterProgress => $composableBuilder(
    column: $table.chapterProgress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get chapterScrollOffset => $composableBuilder(
    column: $table.chapterScrollOffset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceLanguageOverride => $composableBuilder(
    column: $table.sourceLanguageOverride,
    builder: (column) => column,
  );

  GeneratedColumn<double> get languageConfidence => $composableBuilder(
    column: $table.languageConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetExplanationLanguage => $composableBuilder(
    column: $table.targetExplanationLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficultyStudyWords => $composableBuilder(
    column: $table.difficultyStudyWords,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficultyRatingJson => $composableBuilder(
    column: $table.difficultyRatingJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficultyVocabularySignature =>
      $composableBuilder(
        column: $table.difficultyVocabularySignature,
        builder: (column) => column,
      );

  GeneratedColumn<String> get difficultyComputedAt => $composableBuilder(
    column: $table.difficultyComputedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BookEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookEntriesTable,
          BookEntry,
          $$BookEntriesTableFilterComposer,
          $$BookEntriesTableOrderingComposer,
          $$BookEntriesTableAnnotationComposer,
          $$BookEntriesTableCreateCompanionBuilder,
          $$BookEntriesTableUpdateCompanionBuilder,
          (
            BookEntry,
            BaseReferences<_$AppDatabase, $BookEntriesTable, BookEntry>,
          ),
          BookEntry,
          PrefetchHooks Function()
        > {
  $$BookEntriesTableTableManager(_$AppDatabase db, $BookEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> sourcePath = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<int> totalChapters = const Value.absent(),
                Value<double> globalProgress = const Value.absent(),
                Value<int> currentChapter = const Value.absent(),
                Value<double> chapterProgress = const Value.absent(),
                Value<String?> lastReadAt = const Value.absent(),
                Value<double?> chapterScrollOffset = const Value.absent(),
                Value<String> sourceLanguage = const Value.absent(),
                Value<String?> sourceLanguageOverride = const Value.absent(),
                Value<double?> languageConfidence = const Value.absent(),
                Value<String?> targetExplanationLanguage = const Value.absent(),
                Value<String?> difficultyStudyWords = const Value.absent(),
                Value<String?> difficultyRatingJson = const Value.absent(),
                Value<String?> difficultyVocabularySignature =
                    const Value.absent(),
                Value<String?> difficultyComputedAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookEntriesCompanion(
                id: id,
                language: language,
                title: title,
                author: author,
                sourcePath: sourcePath,
                coverPath: coverPath,
                totalChapters: totalChapters,
                globalProgress: globalProgress,
                currentChapter: currentChapter,
                chapterProgress: chapterProgress,
                lastReadAt: lastReadAt,
                chapterScrollOffset: chapterScrollOffset,
                sourceLanguage: sourceLanguage,
                sourceLanguageOverride: sourceLanguageOverride,
                languageConfidence: languageConfidence,
                targetExplanationLanguage: targetExplanationLanguage,
                difficultyStudyWords: difficultyStudyWords,
                difficultyRatingJson: difficultyRatingJson,
                difficultyVocabularySignature: difficultyVocabularySignature,
                difficultyComputedAt: difficultyComputedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> language = const Value.absent(),
                required String title,
                Value<String> author = const Value.absent(),
                required String sourcePath,
                Value<String?> coverPath = const Value.absent(),
                Value<int> totalChapters = const Value.absent(),
                Value<double> globalProgress = const Value.absent(),
                Value<int> currentChapter = const Value.absent(),
                Value<double> chapterProgress = const Value.absent(),
                Value<String?> lastReadAt = const Value.absent(),
                Value<double?> chapterScrollOffset = const Value.absent(),
                Value<String> sourceLanguage = const Value.absent(),
                Value<String?> sourceLanguageOverride = const Value.absent(),
                Value<double?> languageConfidence = const Value.absent(),
                Value<String?> targetExplanationLanguage = const Value.absent(),
                Value<String?> difficultyStudyWords = const Value.absent(),
                Value<String?> difficultyRatingJson = const Value.absent(),
                Value<String?> difficultyVocabularySignature =
                    const Value.absent(),
                Value<String?> difficultyComputedAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookEntriesCompanion.insert(
                id: id,
                language: language,
                title: title,
                author: author,
                sourcePath: sourcePath,
                coverPath: coverPath,
                totalChapters: totalChapters,
                globalProgress: globalProgress,
                currentChapter: currentChapter,
                chapterProgress: chapterProgress,
                lastReadAt: lastReadAt,
                chapterScrollOffset: chapterScrollOffset,
                sourceLanguage: sourceLanguage,
                sourceLanguageOverride: sourceLanguageOverride,
                languageConfidence: languageConfidence,
                targetExplanationLanguage: targetExplanationLanguage,
                difficultyStudyWords: difficultyStudyWords,
                difficultyRatingJson: difficultyRatingJson,
                difficultyVocabularySignature: difficultyVocabularySignature,
                difficultyComputedAt: difficultyComputedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookEntriesTable,
      BookEntry,
      $$BookEntriesTableFilterComposer,
      $$BookEntriesTableOrderingComposer,
      $$BookEntriesTableAnnotationComposer,
      $$BookEntriesTableCreateCompanionBuilder,
      $$BookEntriesTableUpdateCompanionBuilder,
      (BookEntry, BaseReferences<_$AppDatabase, $BookEntriesTable, BookEntry>),
      BookEntry,
      PrefetchHooks Function()
    >;
typedef $$UserVocabulariesTableCreateCompanionBuilder =
    UserVocabulariesCompanion Function({
      required String id,
      Value<String> language,
      required String canonical,
      required String status,
      Value<String> createdAt,
      Value<String> lastModifiedAt,
      Value<String?> sourceBookId,
      Value<int?> sourceChapterIndex,
      Value<int> rowid,
    });
typedef $$UserVocabulariesTableUpdateCompanionBuilder =
    UserVocabulariesCompanion Function({
      Value<String> id,
      Value<String> language,
      Value<String> canonical,
      Value<String> status,
      Value<String> createdAt,
      Value<String> lastModifiedAt,
      Value<String?> sourceBookId,
      Value<int?> sourceChapterIndex,
      Value<int> rowid,
    });

class $$UserVocabulariesTableFilterComposer
    extends Composer<_$AppDatabase, $UserVocabulariesTable> {
  $$UserVocabulariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonical => $composableBuilder(
    column: $table.canonical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceBookId => $composableBuilder(
    column: $table.sourceBookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceChapterIndex => $composableBuilder(
    column: $table.sourceChapterIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserVocabulariesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserVocabulariesTable> {
  $$UserVocabulariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonical => $composableBuilder(
    column: $table.canonical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceBookId => $composableBuilder(
    column: $table.sourceBookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceChapterIndex => $composableBuilder(
    column: $table.sourceChapterIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserVocabulariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserVocabulariesTable> {
  $$UserVocabulariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get canonical =>
      $composableBuilder(column: $table.canonical, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceBookId => $composableBuilder(
    column: $table.sourceBookId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceChapterIndex => $composableBuilder(
    column: $table.sourceChapterIndex,
    builder: (column) => column,
  );
}

class $$UserVocabulariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserVocabulariesTable,
          UserVocabulary,
          $$UserVocabulariesTableFilterComposer,
          $$UserVocabulariesTableOrderingComposer,
          $$UserVocabulariesTableAnnotationComposer,
          $$UserVocabulariesTableCreateCompanionBuilder,
          $$UserVocabulariesTableUpdateCompanionBuilder,
          (
            UserVocabulary,
            BaseReferences<
              _$AppDatabase,
              $UserVocabulariesTable,
              UserVocabulary
            >,
          ),
          UserVocabulary,
          PrefetchHooks Function()
        > {
  $$UserVocabulariesTableTableManager(
    _$AppDatabase db,
    $UserVocabulariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserVocabulariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserVocabulariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserVocabulariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> canonical = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> lastModifiedAt = const Value.absent(),
                Value<String?> sourceBookId = const Value.absent(),
                Value<int?> sourceChapterIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserVocabulariesCompanion(
                id: id,
                language: language,
                canonical: canonical,
                status: status,
                createdAt: createdAt,
                lastModifiedAt: lastModifiedAt,
                sourceBookId: sourceBookId,
                sourceChapterIndex: sourceChapterIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> language = const Value.absent(),
                required String canonical,
                required String status,
                Value<String> createdAt = const Value.absent(),
                Value<String> lastModifiedAt = const Value.absent(),
                Value<String?> sourceBookId = const Value.absent(),
                Value<int?> sourceChapterIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserVocabulariesCompanion.insert(
                id: id,
                language: language,
                canonical: canonical,
                status: status,
                createdAt: createdAt,
                lastModifiedAt: lastModifiedAt,
                sourceBookId: sourceBookId,
                sourceChapterIndex: sourceChapterIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserVocabulariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserVocabulariesTable,
      UserVocabulary,
      $$UserVocabulariesTableFilterComposer,
      $$UserVocabulariesTableOrderingComposer,
      $$UserVocabulariesTableAnnotationComposer,
      $$UserVocabulariesTableCreateCompanionBuilder,
      $$UserVocabulariesTableUpdateCompanionBuilder,
      (
        UserVocabulary,
        BaseReferences<_$AppDatabase, $UserVocabulariesTable, UserVocabulary>,
      ),
      UserVocabulary,
      PrefetchHooks Function()
    >;
typedef $$WordBookmarksTableCreateCompanionBuilder =
    WordBookmarksCompanion Function({
      required String id,
      Value<String> language,
      required String bookId,
      required String word,
      Value<String> translation,
      Value<String> context,
      Value<String> addedAt,
      Value<int> rowid,
    });
typedef $$WordBookmarksTableUpdateCompanionBuilder =
    WordBookmarksCompanion Function({
      Value<String> id,
      Value<String> language,
      Value<String> bookId,
      Value<String> word,
      Value<String> translation,
      Value<String> context,
      Value<String> addedAt,
      Value<int> rowid,
    });

class $$WordBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $WordBookmarksTable> {
  $$WordBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $WordBookmarksTable> {
  $$WordBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordBookmarksTable> {
  $$WordBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$WordBookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordBookmarksTable,
          WordBookmark,
          $$WordBookmarksTableFilterComposer,
          $$WordBookmarksTableOrderingComposer,
          $$WordBookmarksTableAnnotationComposer,
          $$WordBookmarksTableCreateCompanionBuilder,
          $$WordBookmarksTableUpdateCompanionBuilder,
          (
            WordBookmark,
            BaseReferences<_$AppDatabase, $WordBookmarksTable, WordBookmark>,
          ),
          WordBookmark,
          PrefetchHooks Function()
        > {
  $$WordBookmarksTableTableManager(_$AppDatabase db, $WordBookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordBookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> translation = const Value.absent(),
                Value<String> context = const Value.absent(),
                Value<String> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordBookmarksCompanion(
                id: id,
                language: language,
                bookId: bookId,
                word: word,
                translation: translation,
                context: context,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> language = const Value.absent(),
                required String bookId,
                required String word,
                Value<String> translation = const Value.absent(),
                Value<String> context = const Value.absent(),
                Value<String> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordBookmarksCompanion.insert(
                id: id,
                language: language,
                bookId: bookId,
                word: word,
                translation: translation,
                context: context,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordBookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordBookmarksTable,
      WordBookmark,
      $$WordBookmarksTableFilterComposer,
      $$WordBookmarksTableOrderingComposer,
      $$WordBookmarksTableAnnotationComposer,
      $$WordBookmarksTableCreateCompanionBuilder,
      $$WordBookmarksTableUpdateCompanionBuilder,
      (
        WordBookmark,
        BaseReferences<_$AppDatabase, $WordBookmarksTable, WordBookmark>,
      ),
      WordBookmark,
      PrefetchHooks Function()
    >;
typedef $$ReadingBookmarksTableCreateCompanionBuilder =
    ReadingBookmarksCompanion Function({
      required String id,
      Value<String> language,
      required String bookId,
      required int chapterIndex,
      required double progress,
      Value<String> chapterTitle,
      Value<String> excerpt,
      Value<String> createdAt,
      Value<int> rowid,
    });
typedef $$ReadingBookmarksTableUpdateCompanionBuilder =
    ReadingBookmarksCompanion Function({
      Value<String> id,
      Value<String> language,
      Value<String> bookId,
      Value<int> chapterIndex,
      Value<double> progress,
      Value<String> chapterTitle,
      Value<String> excerpt,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$ReadingBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingBookmarksTable> {
  $$ReadingBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterTitle => $composableBuilder(
    column: $table.chapterTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingBookmarksTable> {
  $$ReadingBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterTitle => $composableBuilder(
    column: $table.chapterTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingBookmarksTable> {
  $$ReadingBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get chapterTitle => $composableBuilder(
    column: $table.chapterTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get excerpt =>
      $composableBuilder(column: $table.excerpt, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReadingBookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingBookmarksTable,
          ReadingBookmarkEntry,
          $$ReadingBookmarksTableFilterComposer,
          $$ReadingBookmarksTableOrderingComposer,
          $$ReadingBookmarksTableAnnotationComposer,
          $$ReadingBookmarksTableCreateCompanionBuilder,
          $$ReadingBookmarksTableUpdateCompanionBuilder,
          (
            ReadingBookmarkEntry,
            BaseReferences<
              _$AppDatabase,
              $ReadingBookmarksTable,
              ReadingBookmarkEntry
            >,
          ),
          ReadingBookmarkEntry,
          PrefetchHooks Function()
        > {
  $$ReadingBookmarksTableTableManager(
    _$AppDatabase db,
    $ReadingBookmarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingBookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<int> chapterIndex = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String> chapterTitle = const Value.absent(),
                Value<String> excerpt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingBookmarksCompanion(
                id: id,
                language: language,
                bookId: bookId,
                chapterIndex: chapterIndex,
                progress: progress,
                chapterTitle: chapterTitle,
                excerpt: excerpt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> language = const Value.absent(),
                required String bookId,
                required int chapterIndex,
                required double progress,
                Value<String> chapterTitle = const Value.absent(),
                Value<String> excerpt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingBookmarksCompanion.insert(
                id: id,
                language: language,
                bookId: bookId,
                chapterIndex: chapterIndex,
                progress: progress,
                chapterTitle: chapterTitle,
                excerpt: excerpt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingBookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingBookmarksTable,
      ReadingBookmarkEntry,
      $$ReadingBookmarksTableFilterComposer,
      $$ReadingBookmarksTableOrderingComposer,
      $$ReadingBookmarksTableAnnotationComposer,
      $$ReadingBookmarksTableCreateCompanionBuilder,
      $$ReadingBookmarksTableUpdateCompanionBuilder,
      (
        ReadingBookmarkEntry,
        BaseReferences<
          _$AppDatabase,
          $ReadingBookmarksTable,
          ReadingBookmarkEntry
        >,
      ),
      ReadingBookmarkEntry,
      PrefetchHooks Function()
    >;
typedef $$ReadingConfigTableCreateCompanionBuilder =
    ReadingConfigCompanion Function({
      required String key,
      Value<String> language,
      Value<String> value,
      Value<int> rowid,
    });
typedef $$ReadingConfigTableUpdateCompanionBuilder =
    ReadingConfigCompanion Function({
      Value<String> key,
      Value<String> language,
      Value<String> value,
      Value<int> rowid,
    });

class $$ReadingConfigTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingConfigTable> {
  $$ReadingConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingConfigTable> {
  $$ReadingConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingConfigTable> {
  $$ReadingConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$ReadingConfigTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingConfigTable,
          ReadingConfigEntry,
          $$ReadingConfigTableFilterComposer,
          $$ReadingConfigTableOrderingComposer,
          $$ReadingConfigTableAnnotationComposer,
          $$ReadingConfigTableCreateCompanionBuilder,
          $$ReadingConfigTableUpdateCompanionBuilder,
          (
            ReadingConfigEntry,
            BaseReferences<
              _$AppDatabase,
              $ReadingConfigTable,
              ReadingConfigEntry
            >,
          ),
          ReadingConfigEntry,
          PrefetchHooks Function()
        > {
  $$ReadingConfigTableTableManager(_$AppDatabase db, $ReadingConfigTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingConfigCompanion(
                key: key,
                language: language,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String> language = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingConfigCompanion.insert(
                key: key,
                language: language,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingConfigTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingConfigTable,
      ReadingConfigEntry,
      $$ReadingConfigTableFilterComposer,
      $$ReadingConfigTableOrderingComposer,
      $$ReadingConfigTableAnnotationComposer,
      $$ReadingConfigTableCreateCompanionBuilder,
      $$ReadingConfigTableUpdateCompanionBuilder,
      (
        ReadingConfigEntry,
        BaseReferences<_$AppDatabase, $ReadingConfigTable, ReadingConfigEntry>,
      ),
      ReadingConfigEntry,
      PrefetchHooks Function()
    >;
typedef $$ReadingTimeTableCreateCompanionBuilder =
    ReadingTimeCompanion Function({
      required String key,
      Value<String> language,
      Value<int> seconds,
      Value<int> rowid,
    });
typedef $$ReadingTimeTableUpdateCompanionBuilder =
    ReadingTimeCompanion Function({
      Value<String> key,
      Value<String> language,
      Value<int> seconds,
      Value<int> rowid,
    });

class $$ReadingTimeTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingTimeTable> {
  $$ReadingTimeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingTimeTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingTimeTable> {
  $$ReadingTimeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingTimeTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingTimeTable> {
  $$ReadingTimeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);
}

class $$ReadingTimeTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingTimeTable,
          ReadingTimeEntry,
          $$ReadingTimeTableFilterComposer,
          $$ReadingTimeTableOrderingComposer,
          $$ReadingTimeTableAnnotationComposer,
          $$ReadingTimeTableCreateCompanionBuilder,
          $$ReadingTimeTableUpdateCompanionBuilder,
          (
            ReadingTimeEntry,
            BaseReferences<_$AppDatabase, $ReadingTimeTable, ReadingTimeEntry>,
          ),
          ReadingTimeEntry,
          PrefetchHooks Function()
        > {
  $$ReadingTimeTableTableManager(_$AppDatabase db, $ReadingTimeTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingTimeTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingTimeTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingTimeTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingTimeCompanion(
                key: key,
                language: language,
                seconds: seconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String> language = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingTimeCompanion.insert(
                key: key,
                language: language,
                seconds: seconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingTimeTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingTimeTable,
      ReadingTimeEntry,
      $$ReadingTimeTableFilterComposer,
      $$ReadingTimeTableOrderingComposer,
      $$ReadingTimeTableAnnotationComposer,
      $$ReadingTimeTableCreateCompanionBuilder,
      $$ReadingTimeTableUpdateCompanionBuilder,
      (
        ReadingTimeEntry,
        BaseReferences<_$AppDatabase, $ReadingTimeTable, ReadingTimeEntry>,
      ),
      ReadingTimeEntry,
      PrefetchHooks Function()
    >;
typedef $$DictionaryCacheTableCreateCompanionBuilder =
    DictionaryCacheCompanion Function({
      required String key,
      Value<String> language,
      required String value,
      Value<String> createdAt,
      Value<int> rowid,
    });
typedef $$DictionaryCacheTableUpdateCompanionBuilder =
    DictionaryCacheCompanion Function({
      Value<String> key,
      Value<String> language,
      Value<String> value,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$DictionaryCacheTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryCacheTable> {
  $$DictionaryCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryCacheTable> {
  $$DictionaryCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryCacheTable> {
  $$DictionaryCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DictionaryCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryCacheTable,
          DictionaryCacheEntry,
          $$DictionaryCacheTableFilterComposer,
          $$DictionaryCacheTableOrderingComposer,
          $$DictionaryCacheTableAnnotationComposer,
          $$DictionaryCacheTableCreateCompanionBuilder,
          $$DictionaryCacheTableUpdateCompanionBuilder,
          (
            DictionaryCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $DictionaryCacheTable,
              DictionaryCacheEntry
            >,
          ),
          DictionaryCacheEntry,
          PrefetchHooks Function()
        > {
  $$DictionaryCacheTableTableManager(
    _$AppDatabase db,
    $DictionaryCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionaryCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionaryCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictionaryCacheCompanion(
                key: key,
                language: language,
                value: value,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String> language = const Value.absent(),
                required String value,
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictionaryCacheCompanion.insert(
                key: key,
                language: language,
                value: value,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryCacheTable,
      DictionaryCacheEntry,
      $$DictionaryCacheTableFilterComposer,
      $$DictionaryCacheTableOrderingComposer,
      $$DictionaryCacheTableAnnotationComposer,
      $$DictionaryCacheTableCreateCompanionBuilder,
      $$DictionaryCacheTableUpdateCompanionBuilder,
      (
        DictionaryCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $DictionaryCacheTable,
          DictionaryCacheEntry
        >,
      ),
      DictionaryCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$WordContextsTableCreateCompanionBuilder =
    WordContextsCompanion Function({
      required String word,
      Value<String> language,
      required String data,
      Value<String> createdAt,
      Value<int> rowid,
    });
typedef $$WordContextsTableUpdateCompanionBuilder =
    WordContextsCompanion Function({
      Value<String> word,
      Value<String> language,
      Value<String> data,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$WordContextsTableFilterComposer
    extends Composer<_$AppDatabase, $WordContextsTable> {
  $$WordContextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordContextsTable> {
  $$WordContextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordContextsTable> {
  $$WordContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WordContextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordContextsTable,
          WordContextEntry,
          $$WordContextsTableFilterComposer,
          $$WordContextsTableOrderingComposer,
          $$WordContextsTableAnnotationComposer,
          $$WordContextsTableCreateCompanionBuilder,
          $$WordContextsTableUpdateCompanionBuilder,
          (
            WordContextEntry,
            BaseReferences<_$AppDatabase, $WordContextsTable, WordContextEntry>,
          ),
          WordContextEntry,
          PrefetchHooks Function()
        > {
  $$WordContextsTableTableManager(_$AppDatabase db, $WordContextsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordContextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordContextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> word = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordContextsCompanion(
                word: word,
                language: language,
                data: data,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String word,
                Value<String> language = const Value.absent(),
                required String data,
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordContextsCompanion.insert(
                word: word,
                language: language,
                data: data,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordContextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordContextsTable,
      WordContextEntry,
      $$WordContextsTableFilterComposer,
      $$WordContextsTableOrderingComposer,
      $$WordContextsTableAnnotationComposer,
      $$WordContextsTableCreateCompanionBuilder,
      $$WordContextsTableUpdateCompanionBuilder,
      (
        WordContextEntry,
        BaseReferences<_$AppDatabase, $WordContextsTable, WordContextEntry>,
      ),
      WordContextEntry,
      PrefetchHooks Function()
    >;
typedef $$LearningItemsTableCreateCompanionBuilder =
    LearningItemsCompanion Function({
      required String id,
      Value<String> language,
      required String type,
      Value<String> canonicalKey,
      Value<String> title,
      Value<String> content,
      Value<String> answer,
      Value<String> note,
      Value<String> sourceText,
      Value<String> bookId,
      Value<int> chapterIndex,
      Value<String> chapterTitle,
      Value<String> tags,
      Value<String> metadata,
      required String nextReviewAt,
      Value<int> reviewCount,
      Value<String> lastResult,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $$LearningItemsTableUpdateCompanionBuilder =
    LearningItemsCompanion Function({
      Value<String> id,
      Value<String> language,
      Value<String> type,
      Value<String> canonicalKey,
      Value<String> title,
      Value<String> content,
      Value<String> answer,
      Value<String> note,
      Value<String> sourceText,
      Value<String> bookId,
      Value<int> chapterIndex,
      Value<String> chapterTitle,
      Value<String> tags,
      Value<String> metadata,
      Value<String> nextReviewAt,
      Value<int> reviewCount,
      Value<String> lastResult,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$LearningItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningItemsTable> {
  $$LearningItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalKey => $composableBuilder(
    column: $table.canonicalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterTitle => $composableBuilder(
    column: $table.chapterTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastResult => $composableBuilder(
    column: $table.lastResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningItemsTable> {
  $$LearningItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalKey => $composableBuilder(
    column: $table.canonicalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterTitle => $composableBuilder(
    column: $table.chapterTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastResult => $composableBuilder(
    column: $table.lastResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningItemsTable> {
  $$LearningItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get canonicalKey => $composableBuilder(
    column: $table.canonicalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chapterTitle => $composableBuilder(
    column: $table.chapterTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastResult => $composableBuilder(
    column: $table.lastResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LearningItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningItemsTable,
          LearningItemEntry,
          $$LearningItemsTableFilterComposer,
          $$LearningItemsTableOrderingComposer,
          $$LearningItemsTableAnnotationComposer,
          $$LearningItemsTableCreateCompanionBuilder,
          $$LearningItemsTableUpdateCompanionBuilder,
          (
            LearningItemEntry,
            BaseReferences<
              _$AppDatabase,
              $LearningItemsTable,
              LearningItemEntry
            >,
          ),
          LearningItemEntry,
          PrefetchHooks Function()
        > {
  $$LearningItemsTableTableManager(_$AppDatabase db, $LearningItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> canonicalKey = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> sourceText = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<int> chapterIndex = const Value.absent(),
                Value<String> chapterTitle = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                Value<String> nextReviewAt = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<String> lastResult = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningItemsCompanion(
                id: id,
                language: language,
                type: type,
                canonicalKey: canonicalKey,
                title: title,
                content: content,
                answer: answer,
                note: note,
                sourceText: sourceText,
                bookId: bookId,
                chapterIndex: chapterIndex,
                chapterTitle: chapterTitle,
                tags: tags,
                metadata: metadata,
                nextReviewAt: nextReviewAt,
                reviewCount: reviewCount,
                lastResult: lastResult,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> language = const Value.absent(),
                required String type,
                Value<String> canonicalKey = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> sourceText = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<int> chapterIndex = const Value.absent(),
                Value<String> chapterTitle = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                required String nextReviewAt,
                Value<int> reviewCount = const Value.absent(),
                Value<String> lastResult = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningItemsCompanion.insert(
                id: id,
                language: language,
                type: type,
                canonicalKey: canonicalKey,
                title: title,
                content: content,
                answer: answer,
                note: note,
                sourceText: sourceText,
                bookId: bookId,
                chapterIndex: chapterIndex,
                chapterTitle: chapterTitle,
                tags: tags,
                metadata: metadata,
                nextReviewAt: nextReviewAt,
                reviewCount: reviewCount,
                lastResult: lastResult,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningItemsTable,
      LearningItemEntry,
      $$LearningItemsTableFilterComposer,
      $$LearningItemsTableOrderingComposer,
      $$LearningItemsTableAnnotationComposer,
      $$LearningItemsTableCreateCompanionBuilder,
      $$LearningItemsTableUpdateCompanionBuilder,
      (
        LearningItemEntry,
        BaseReferences<_$AppDatabase, $LearningItemsTable, LearningItemEntry>,
      ),
      LearningItemEntry,
      PrefetchHooks Function()
    >;
typedef $$LearningAnalyticsTableCreateCompanionBuilder =
    LearningAnalyticsCompanion Function({
      required String key,
      Value<String> language,
      Value<int> value,
      Value<int> rowid,
    });
typedef $$LearningAnalyticsTableUpdateCompanionBuilder =
    LearningAnalyticsCompanion Function({
      Value<String> key,
      Value<String> language,
      Value<int> value,
      Value<int> rowid,
    });

class $$LearningAnalyticsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningAnalyticsTable> {
  $$LearningAnalyticsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningAnalyticsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningAnalyticsTable> {
  $$LearningAnalyticsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningAnalyticsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningAnalyticsTable> {
  $$LearningAnalyticsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LearningAnalyticsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningAnalyticsTable,
          LearningAnalyticsEntry,
          $$LearningAnalyticsTableFilterComposer,
          $$LearningAnalyticsTableOrderingComposer,
          $$LearningAnalyticsTableAnnotationComposer,
          $$LearningAnalyticsTableCreateCompanionBuilder,
          $$LearningAnalyticsTableUpdateCompanionBuilder,
          (
            LearningAnalyticsEntry,
            BaseReferences<
              _$AppDatabase,
              $LearningAnalyticsTable,
              LearningAnalyticsEntry
            >,
          ),
          LearningAnalyticsEntry,
          PrefetchHooks Function()
        > {
  $$LearningAnalyticsTableTableManager(
    _$AppDatabase db,
    $LearningAnalyticsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningAnalyticsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningAnalyticsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningAnalyticsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningAnalyticsCompanion(
                key: key,
                language: language,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String> language = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningAnalyticsCompanion.insert(
                key: key,
                language: language,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningAnalyticsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningAnalyticsTable,
      LearningAnalyticsEntry,
      $$LearningAnalyticsTableFilterComposer,
      $$LearningAnalyticsTableOrderingComposer,
      $$LearningAnalyticsTableAnnotationComposer,
      $$LearningAnalyticsTableCreateCompanionBuilder,
      $$LearningAnalyticsTableUpdateCompanionBuilder,
      (
        LearningAnalyticsEntry,
        BaseReferences<
          _$AppDatabase,
          $LearningAnalyticsTable,
          LearningAnalyticsEntry
        >,
      ),
      LearningAnalyticsEntry,
      PrefetchHooks Function()
    >;
typedef $$WordLevelsTableCreateCompanionBuilder =
    WordLevelsCompanion Function({
      required String word,
      Value<String> originForm,
      required int levelIndex,
      Value<int> rowid,
    });
typedef $$WordLevelsTableUpdateCompanionBuilder =
    WordLevelsCompanion Function({
      Value<String> word,
      Value<String> originForm,
      Value<int> levelIndex,
      Value<int> rowid,
    });

class $$WordLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $WordLevelsTable> {
  $$WordLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originForm => $composableBuilder(
    column: $table.originForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get levelIndex => $composableBuilder(
    column: $table.levelIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordLevelsTable> {
  $$WordLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originForm => $composableBuilder(
    column: $table.originForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get levelIndex => $composableBuilder(
    column: $table.levelIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordLevelsTable> {
  $$WordLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get originForm => $composableBuilder(
    column: $table.originForm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get levelIndex => $composableBuilder(
    column: $table.levelIndex,
    builder: (column) => column,
  );
}

class $$WordLevelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordLevelsTable,
          WordLevelEntry,
          $$WordLevelsTableFilterComposer,
          $$WordLevelsTableOrderingComposer,
          $$WordLevelsTableAnnotationComposer,
          $$WordLevelsTableCreateCompanionBuilder,
          $$WordLevelsTableUpdateCompanionBuilder,
          (
            WordLevelEntry,
            BaseReferences<_$AppDatabase, $WordLevelsTable, WordLevelEntry>,
          ),
          WordLevelEntry,
          PrefetchHooks Function()
        > {
  $$WordLevelsTableTableManager(_$AppDatabase db, $WordLevelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> word = const Value.absent(),
                Value<String> originForm = const Value.absent(),
                Value<int> levelIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordLevelsCompanion(
                word: word,
                originForm: originForm,
                levelIndex: levelIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String word,
                Value<String> originForm = const Value.absent(),
                required int levelIndex,
                Value<int> rowid = const Value.absent(),
              }) => WordLevelsCompanion.insert(
                word: word,
                originForm: originForm,
                levelIndex: levelIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordLevelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordLevelsTable,
      WordLevelEntry,
      $$WordLevelsTableFilterComposer,
      $$WordLevelsTableOrderingComposer,
      $$WordLevelsTableAnnotationComposer,
      $$WordLevelsTableCreateCompanionBuilder,
      $$WordLevelsTableUpdateCompanionBuilder,
      (
        WordLevelEntry,
        BaseReferences<_$AppDatabase, $WordLevelsTable, WordLevelEntry>,
      ),
      WordLevelEntry,
      PrefetchHooks Function()
    >;
typedef $$RssSubscriptionsTableCreateCompanionBuilder =
    RssSubscriptionsCompanion Function({
      required String id,
      required String url,
      Value<String> title,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> lastFetchedAt,
      Value<String> createdAt,
      Value<int> rowid,
    });
typedef $$RssSubscriptionsTableUpdateCompanionBuilder =
    RssSubscriptionsCompanion Function({
      Value<String> id,
      Value<String> url,
      Value<String> title,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> lastFetchedAt,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$RssSubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $RssSubscriptionsTable> {
  $$RssSubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RssSubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RssSubscriptionsTable> {
  $$RssSubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RssSubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RssSubscriptionsTable> {
  $$RssSubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RssSubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RssSubscriptionsTable,
          RssSubscriptionEntry,
          $$RssSubscriptionsTableFilterComposer,
          $$RssSubscriptionsTableOrderingComposer,
          $$RssSubscriptionsTableAnnotationComposer,
          $$RssSubscriptionsTableCreateCompanionBuilder,
          $$RssSubscriptionsTableUpdateCompanionBuilder,
          (
            RssSubscriptionEntry,
            BaseReferences<
              _$AppDatabase,
              $RssSubscriptionsTable,
              RssSubscriptionEntry
            >,
          ),
          RssSubscriptionEntry,
          PrefetchHooks Function()
        > {
  $$RssSubscriptionsTableTableManager(
    _$AppDatabase db,
    $RssSubscriptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RssSubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RssSubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RssSubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> lastFetchedAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssSubscriptionsCompanion(
                id: id,
                url: url,
                title: title,
                description: description,
                imageUrl: imageUrl,
                lastFetchedAt: lastFetchedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String url,
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> lastFetchedAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssSubscriptionsCompanion.insert(
                id: id,
                url: url,
                title: title,
                description: description,
                imageUrl: imageUrl,
                lastFetchedAt: lastFetchedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RssSubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RssSubscriptionsTable,
      RssSubscriptionEntry,
      $$RssSubscriptionsTableFilterComposer,
      $$RssSubscriptionsTableOrderingComposer,
      $$RssSubscriptionsTableAnnotationComposer,
      $$RssSubscriptionsTableCreateCompanionBuilder,
      $$RssSubscriptionsTableUpdateCompanionBuilder,
      (
        RssSubscriptionEntry,
        BaseReferences<
          _$AppDatabase,
          $RssSubscriptionsTable,
          RssSubscriptionEntry
        >,
      ),
      RssSubscriptionEntry,
      PrefetchHooks Function()
    >;
typedef $$RssArticlesTableCreateCompanionBuilder =
    RssArticlesCompanion Function({
      required String id,
      required String subscriptionId,
      required String feedUrl,
      Value<String> feedTitle,
      required String title,
      Value<String?> link,
      Value<String?> description,
      Value<String?> content,
      Value<String> bodyBlocks,
      Value<String> images,
      Value<String?> pubDate,
      Value<String?> author,
      required bool isRead,
      required bool isFavorite,
      required bool isReadLater,
      Value<String> createdAt,
      Value<int> rowid,
    });
typedef $$RssArticlesTableUpdateCompanionBuilder =
    RssArticlesCompanion Function({
      Value<String> id,
      Value<String> subscriptionId,
      Value<String> feedUrl,
      Value<String> feedTitle,
      Value<String> title,
      Value<String?> link,
      Value<String?> description,
      Value<String?> content,
      Value<String> bodyBlocks,
      Value<String> images,
      Value<String?> pubDate,
      Value<String?> author,
      Value<bool> isRead,
      Value<bool> isFavorite,
      Value<bool> isReadLater,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$RssArticlesTableFilterComposer
    extends Composer<_$AppDatabase, $RssArticlesTable> {
  $$RssArticlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subscriptionId => $composableBuilder(
    column: $table.subscriptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedTitle => $composableBuilder(
    column: $table.feedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyBlocks => $composableBuilder(
    column: $table.bodyBlocks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReadLater => $composableBuilder(
    column: $table.isReadLater,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RssArticlesTableOrderingComposer
    extends Composer<_$AppDatabase, $RssArticlesTable> {
  $$RssArticlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subscriptionId => $composableBuilder(
    column: $table.subscriptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedTitle => $composableBuilder(
    column: $table.feedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyBlocks => $composableBuilder(
    column: $table.bodyBlocks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReadLater => $composableBuilder(
    column: $table.isReadLater,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RssArticlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RssArticlesTable> {
  $$RssArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subscriptionId => $composableBuilder(
    column: $table.subscriptionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<String> get feedTitle =>
      $composableBuilder(column: $table.feedTitle, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get bodyBlocks => $composableBuilder(
    column: $table.bodyBlocks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumn<String> get pubDate =>
      $composableBuilder(column: $table.pubDate, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isReadLater => $composableBuilder(
    column: $table.isReadLater,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RssArticlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RssArticlesTable,
          RssArticleEntry,
          $$RssArticlesTableFilterComposer,
          $$RssArticlesTableOrderingComposer,
          $$RssArticlesTableAnnotationComposer,
          $$RssArticlesTableCreateCompanionBuilder,
          $$RssArticlesTableUpdateCompanionBuilder,
          (
            RssArticleEntry,
            BaseReferences<_$AppDatabase, $RssArticlesTable, RssArticleEntry>,
          ),
          RssArticleEntry,
          PrefetchHooks Function()
        > {
  $$RssArticlesTableTableManager(_$AppDatabase db, $RssArticlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RssArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RssArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RssArticlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> subscriptionId = const Value.absent(),
                Value<String> feedUrl = const Value.absent(),
                Value<String> feedTitle = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> link = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> bodyBlocks = const Value.absent(),
                Value<String> images = const Value.absent(),
                Value<String?> pubDate = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isReadLater = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssArticlesCompanion(
                id: id,
                subscriptionId: subscriptionId,
                feedUrl: feedUrl,
                feedTitle: feedTitle,
                title: title,
                link: link,
                description: description,
                content: content,
                bodyBlocks: bodyBlocks,
                images: images,
                pubDate: pubDate,
                author: author,
                isRead: isRead,
                isFavorite: isFavorite,
                isReadLater: isReadLater,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String subscriptionId,
                required String feedUrl,
                Value<String> feedTitle = const Value.absent(),
                required String title,
                Value<String?> link = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> bodyBlocks = const Value.absent(),
                Value<String> images = const Value.absent(),
                Value<String?> pubDate = const Value.absent(),
                Value<String?> author = const Value.absent(),
                required bool isRead,
                required bool isFavorite,
                required bool isReadLater,
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssArticlesCompanion.insert(
                id: id,
                subscriptionId: subscriptionId,
                feedUrl: feedUrl,
                feedTitle: feedTitle,
                title: title,
                link: link,
                description: description,
                content: content,
                bodyBlocks: bodyBlocks,
                images: images,
                pubDate: pubDate,
                author: author,
                isRead: isRead,
                isFavorite: isFavorite,
                isReadLater: isReadLater,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RssArticlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RssArticlesTable,
      RssArticleEntry,
      $$RssArticlesTableFilterComposer,
      $$RssArticlesTableOrderingComposer,
      $$RssArticlesTableAnnotationComposer,
      $$RssArticlesTableCreateCompanionBuilder,
      $$RssArticlesTableUpdateCompanionBuilder,
      (
        RssArticleEntry,
        BaseReferences<_$AppDatabase, $RssArticlesTable, RssArticleEntry>,
      ),
      RssArticleEntry,
      PrefetchHooks Function()
    >;
typedef $$BookGlossaryTableCreateCompanionBuilder =
    BookGlossaryCompanion Function({
      required String id,
      required String bookId,
      required String word,
      Value<String?> canonicalForm,
      Value<String> explanation,
      Value<String?> sourceContext,
      Value<String> createdAt,
      Value<String?> lastAccessedAt,
      Value<int> rowid,
    });
typedef $$BookGlossaryTableUpdateCompanionBuilder =
    BookGlossaryCompanion Function({
      Value<String> id,
      Value<String> bookId,
      Value<String> word,
      Value<String?> canonicalForm,
      Value<String> explanation,
      Value<String?> sourceContext,
      Value<String> createdAt,
      Value<String?> lastAccessedAt,
      Value<int> rowid,
    });

class $$BookGlossaryTableFilterComposer
    extends Composer<_$AppDatabase, $BookGlossaryTable> {
  $$BookGlossaryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalForm => $composableBuilder(
    column: $table.canonicalForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookGlossaryTableOrderingComposer
    extends Composer<_$AppDatabase, $BookGlossaryTable> {
  $$BookGlossaryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalForm => $composableBuilder(
    column: $table.canonicalForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookGlossaryTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookGlossaryTable> {
  $$BookGlossaryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get canonicalForm => $composableBuilder(
    column: $table.canonicalForm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );
}

class $$BookGlossaryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookGlossaryTable,
          BookGlossaryEntry,
          $$BookGlossaryTableFilterComposer,
          $$BookGlossaryTableOrderingComposer,
          $$BookGlossaryTableAnnotationComposer,
          $$BookGlossaryTableCreateCompanionBuilder,
          $$BookGlossaryTableUpdateCompanionBuilder,
          (
            BookGlossaryEntry,
            BaseReferences<
              _$AppDatabase,
              $BookGlossaryTable,
              BookGlossaryEntry
            >,
          ),
          BookGlossaryEntry,
          PrefetchHooks Function()
        > {
  $$BookGlossaryTableTableManager(_$AppDatabase db, $BookGlossaryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookGlossaryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookGlossaryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookGlossaryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String?> canonicalForm = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String?> sourceContext = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookGlossaryCompanion(
                id: id,
                bookId: bookId,
                word: word,
                canonicalForm: canonicalForm,
                explanation: explanation,
                sourceContext: sourceContext,
                createdAt: createdAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String word,
                Value<String?> canonicalForm = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String?> sourceContext = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookGlossaryCompanion.insert(
                id: id,
                bookId: bookId,
                word: word,
                canonicalForm: canonicalForm,
                explanation: explanation,
                sourceContext: sourceContext,
                createdAt: createdAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookGlossaryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookGlossaryTable,
      BookGlossaryEntry,
      $$BookGlossaryTableFilterComposer,
      $$BookGlossaryTableOrderingComposer,
      $$BookGlossaryTableAnnotationComposer,
      $$BookGlossaryTableCreateCompanionBuilder,
      $$BookGlossaryTableUpdateCompanionBuilder,
      (
        BookGlossaryEntry,
        BaseReferences<_$AppDatabase, $BookGlossaryTable, BookGlossaryEntry>,
      ),
      BookGlossaryEntry,
      PrefetchHooks Function()
    >;
typedef $$CharacterRegistryTableCreateCompanionBuilder =
    CharacterRegistryCompanion Function({
      required String key,
      Value<String> value,
      Value<int> rowid,
    });
typedef $$CharacterRegistryTableUpdateCompanionBuilder =
    CharacterRegistryCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$CharacterRegistryTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterRegistryTable> {
  $$CharacterRegistryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharacterRegistryTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterRegistryTable> {
  $$CharacterRegistryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharacterRegistryTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterRegistryTable> {
  $$CharacterRegistryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$CharacterRegistryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterRegistryTable,
          CharacterRegistryEntry,
          $$CharacterRegistryTableFilterComposer,
          $$CharacterRegistryTableOrderingComposer,
          $$CharacterRegistryTableAnnotationComposer,
          $$CharacterRegistryTableCreateCompanionBuilder,
          $$CharacterRegistryTableUpdateCompanionBuilder,
          (
            CharacterRegistryEntry,
            BaseReferences<
              _$AppDatabase,
              $CharacterRegistryTable,
              CharacterRegistryEntry
            >,
          ),
          CharacterRegistryEntry,
          PrefetchHooks Function()
        > {
  $$CharacterRegistryTableTableManager(
    _$AppDatabase db,
    $CharacterRegistryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterRegistryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterRegistryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterRegistryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterRegistryCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterRegistryCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharacterRegistryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterRegistryTable,
      CharacterRegistryEntry,
      $$CharacterRegistryTableFilterComposer,
      $$CharacterRegistryTableOrderingComposer,
      $$CharacterRegistryTableAnnotationComposer,
      $$CharacterRegistryTableCreateCompanionBuilder,
      $$CharacterRegistryTableUpdateCompanionBuilder,
      (
        CharacterRegistryEntry,
        BaseReferences<
          _$AppDatabase,
          $CharacterRegistryTable,
          CharacterRegistryEntry
        >,
      ),
      CharacterRegistryEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      Value<String> value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingsEntry,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingsEntry,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingsEntry>,
          ),
          SettingsEntry,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingsEntry,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (
        SettingsEntry,
        BaseReferences<_$AppDatabase, $SettingsTable, SettingsEntry>,
      ),
      SettingsEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BookEntriesTableTableManager get bookEntries =>
      $$BookEntriesTableTableManager(_db, _db.bookEntries);
  $$UserVocabulariesTableTableManager get userVocabularies =>
      $$UserVocabulariesTableTableManager(_db, _db.userVocabularies);
  $$WordBookmarksTableTableManager get wordBookmarks =>
      $$WordBookmarksTableTableManager(_db, _db.wordBookmarks);
  $$ReadingBookmarksTableTableManager get readingBookmarks =>
      $$ReadingBookmarksTableTableManager(_db, _db.readingBookmarks);
  $$ReadingConfigTableTableManager get readingConfig =>
      $$ReadingConfigTableTableManager(_db, _db.readingConfig);
  $$ReadingTimeTableTableManager get readingTime =>
      $$ReadingTimeTableTableManager(_db, _db.readingTime);
  $$DictionaryCacheTableTableManager get dictionaryCache =>
      $$DictionaryCacheTableTableManager(_db, _db.dictionaryCache);
  $$WordContextsTableTableManager get wordContexts =>
      $$WordContextsTableTableManager(_db, _db.wordContexts);
  $$LearningItemsTableTableManager get learningItems =>
      $$LearningItemsTableTableManager(_db, _db.learningItems);
  $$LearningAnalyticsTableTableManager get learningAnalytics =>
      $$LearningAnalyticsTableTableManager(_db, _db.learningAnalytics);
  $$WordLevelsTableTableManager get wordLevels =>
      $$WordLevelsTableTableManager(_db, _db.wordLevels);
  $$RssSubscriptionsTableTableManager get rssSubscriptions =>
      $$RssSubscriptionsTableTableManager(_db, _db.rssSubscriptions);
  $$RssArticlesTableTableManager get rssArticles =>
      $$RssArticlesTableTableManager(_db, _db.rssArticles);
  $$BookGlossaryTableTableManager get bookGlossary =>
      $$BookGlossaryTableTableManager(_db, _db.bookGlossary);
  $$CharacterRegistryTableTableManager get characterRegistry =>
      $$CharacterRegistryTableTableManager(_db, _db.characterRegistry);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
