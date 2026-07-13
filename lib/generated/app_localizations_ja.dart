// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get selectDateTitle => '日付を選択';

  @override
  String get selectTimeTitle => '時間を選択';

  @override
  String get appTitle => 'Train Libre';

  @override
  String get bannerText => '推奨事項 / 現在のトレーニング';

  @override
  String get calories => 'カロリー';

  @override
  String get water => '水分';

  @override
  String get protein => 'タンパク質';

  @override
  String get carbs => '炭水化物';

  @override
  String get fat => '脂質';

  @override
  String get steps => '歩数';

  @override
  String get daily => '毎日';

  @override
  String get nowLabel => 'Now';

  @override
  String get today => '今日';

  @override
  String get workoutSection => 'ワークアウトセクション - まだ実装されていません';

  @override
  String get addMenuTitle => '何を追加したいですか?';

  @override
  String get addFoodOption => '食べ物を追加する';

  @override
  String get addLiquidOption => '液体を追加します';

  @override
  String get searchHintText => '検索...';

  @override
  String get mealtypeBreakfast => '朝食';

  @override
  String get mealtypeLunch => 'ランチ';

  @override
  String get mealtypeDinner => '夕食';

  @override
  String get mealtypeSnack => 'スナック';

  @override
  String get waterHeader => '水と飲み物';

  @override
  String get openFoodFactsSource => 'オープンな食品事実から得たデータ';

  @override
  String get tabRecent => '最近の';

  @override
  String get tabSearch => '検索';

  @override
  String get tabFavorites => 'お気に入り';

  @override
  String get fabCreateOwnFood => 'カスタムフード';

  @override
  String get recentEmptyState => '最近使用した食品\nここに表示されます。';

  @override
  String get favoritesEmptyState =>
      'まだお気に入りがありません。\n食べ物にハートのアイコンを付けると、ここに表示されます。';

  @override
  String get searchInitialHint => '検索語を入力してください。';

  @override
  String get searchNoResults => '結果が見つかりませんでした。';

  @override
  String get createFoodScreenTitle => 'カスタムフードの作成';

  @override
  String get formFieldName => '食べ物の名前';

  @override
  String get formFieldBrand => 'ブランド (オプション)';

  @override
  String get formSectionMainNutrients => '主な栄養成分（100gあたり）';

  @override
  String get formFieldCalories => 'カロリー(kcal)';

  @override
  String get formFieldProtein => 'たんぱく質(g)';

  @override
  String get formFieldCarbs => '炭水化物(g)';

  @override
  String get formFieldFat => '脂肪(g)';

  @override
  String get formSectionOptionalNutrients => '追加の栄養素（オプション、100gあたり）';

  @override
  String get formFieldSugar => 'うち糖質(g)';

  @override
  String get formFieldFiber => '食物繊維(g)';

  @override
  String get formFieldKj => 'キロジュール (kJ)';

  @override
  String get formFieldSalt => '食塩(g)';

  @override
  String get formFieldSodium => 'ナトリウム(mg)';

  @override
  String get formFieldCalcium => 'カルシウム(mg)';

  @override
  String get buttonSave => '保存';

  @override
  String get validatorPleaseEnterName => '名前を入力してください。';

  @override
  String get validatorPleaseEnterNumber => '有効な番号を入力してください。';

  @override
  String snackbarSaveSuccess(String foodName) {
    return '$foodName は正常に保存されました。';
  }

  @override
  String get foodDetailSegmentPortion => '部分';

  @override
  String get foodDetailSegment100g => '100g';

  @override
  String get sugar => '砂糖';

  @override
  String get fiber => 'ファイバ';

  @override
  String get salt => '塩';

  @override
  String get caffeine => 'カフェイン';

  @override
  String get explorerScreenTitle => 'フードエクスプローラー';

  @override
  String get nutritionScreenTitle => '栄養分析';

  @override
  String get entriesForDateRangeLabel => 'のエントリー';

  @override
  String get noEntriesForPeriod => 'この期間にはまだエントリーがありません。';

  @override
  String get waterEntryTitle => '水';

  @override
  String get profileScreenTitle => 'プロフィール';

  @override
  String get profileDailyGoals => '毎日の目標';

  @override
  String get profileDailyGoalsCL => '毎日の目標';

  @override
  String get snackbarGoalsSaved => '目標は正常に保存されました!';

  @override
  String get measurementsScreenTitle => '測定';

  @override
  String get measurementsEmptyState => 'まだ測定値は記録されていません。\n「+」ボタンから始めます。';

  @override
  String get addMeasurementDialogTitle => '新しい測定値を追加';

  @override
  String get formFieldMeasurementType => '測定の種類';

  @override
  String formFieldMeasurementValue(Object unit) {
    return '値 ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => '値を入力してください';

  @override
  String get measurementWeight => '体重';

  @override
  String get measurementFatPercent => '体脂肪';

  @override
  String get measurementNeck => 'ネック';

  @override
  String get measurementShoulder => 'ショルダー';

  @override
  String get measurementChest => '胸';

  @override
  String get measurementLeftBicep => '左上腕二頭筋';

  @override
  String get measurementRightBicep => '右上腕二頭筋';

  @override
  String get measurementLeftForearm => '左前腕';

  @override
  String get measurementRightForearm => '右前腕';

  @override
  String get measurementAbdomen => '腹部';

  @override
  String get measurementWaist => 'ウエスト';

  @override
  String get measurementHips => 'ヒップ';

  @override
  String get measurementLeftThigh => '左太もも';

  @override
  String get measurementRightThigh => '右太もも';

  @override
  String get measurementLeftCalf => '左ふくらはぎ';

  @override
  String get measurementRightCalf => '右ふくらはぎ';

  @override
  String get drawerMenuTitle => 'トレインリブレメニュー';

  @override
  String get drawerDashboard => 'ダッシュボード';

  @override
  String get drawerFoodExplorer => 'フードエクスプローラー';

  @override
  String get drawerDataManagement => 'データのバックアップ';

  @override
  String get drawerMeasurements => '測定';

  @override
  String get dataManagementTitle => 'データのバックアップ';

  @override
  String get exportCardTitle => 'データのエクスポート';

  @override
  String get exportCardDescription =>
      'すべての日記エントリ、お気に入り、カスタム食品を 1 つのバックアップ ファイルに保存します。';

  @override
  String get exportCardButton => 'バックアップの作成';

  @override
  String get importCardTitle => 'データのインポート';

  @override
  String get importCardDescription =>
      '以前に作成したバックアップ ファイルからデータを復元します。警告: 現在アプリに保存されているデータはすべて上書きされます。';

  @override
  String get importCardButton => 'バックアップを復元する';

  @override
  String get recommendationDefault => '初めての食事の記録をしましょう！';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return '過去 $count 日間: +$difference kcal が目標を上回りました';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return '過去 $count 日間: $difference kcal が目標を下回りました';
  }

  @override
  String recommendationOnTarget(Object count) {
    return '過去 $count 日間: 目標を達成しました ✅';
  }

  @override
  String get recommendationFirstEntry => '完了しました。最初のエントリが記録されました。';

  @override
  String get dialogConfirmTitle => '確認が必要です';

  @override
  String get dialogConfirmImportContent =>
      '本当にこのバックアップからデータを復元しますか?\n\n警告: 現在のエントリ、お気に入り、カスタム フードはすべて完全に削除され、置き換えられます。';

  @override
  String get dialogButtonCancel => 'キャンセル';

  @override
  String get dialogButtonOverwrite => 'はい、すべて上書きします';

  @override
  String get snackbarNoFileSelected => 'ファイルが選択されていません。';

  @override
  String get snackbarImportSuccessTitle => 'インポートが成功しました。';

  @override
  String get snackbarImportSuccessContent =>
      'データが復元されました。正しく表示するためにアプリを再起動することをお勧めします。';

  @override
  String get snackbarButtonOK => 'わかりました';

  @override
  String get snackbarImportError => 'データのインポート中にエラーが発生しました。';

  @override
  String get snackbarExportSuccess =>
      'バックアップ ファイルがシステムに渡されました。保存する場所を選択してください。';

  @override
  String get snackbarExportFailed => 'エクスポートがキャンセルされたか失敗しました。';

  @override
  String get profileUserHeight => '身長(cm)';

  @override
  String get workoutRoutinesTitle => 'ルーチン';

  @override
  String get workoutHistoryTitle => 'トレーニング履歴';

  @override
  String get workoutHistoryButton => '歴史';

  @override
  String get emptyRoutinesTitle => 'ルーチンが見つかりません';

  @override
  String get emptyRoutinesSubtitle => '最初のルーチンを作成するか、空のワークアウトを開始します。';

  @override
  String get createFirstRoutineButton => '最初のルーチンを作成する';

  @override
  String get startEmptyWorkoutButton => '無料のトレーニング';

  @override
  String get editRoutineSubtitle => 'タップして編集するか、ワークアウトを開始します。';

  @override
  String get startButton => '始める';

  @override
  String get addRoutineButton => '新しいルーチン';

  @override
  String get freeWorkoutTitle => '無料のトレーニング';

  @override
  String get finishWorkoutButton => '仕上げる';

  @override
  String get addSetButton => 'セットの追加';

  @override
  String get addExerciseToWorkoutButton => 'ワークアウトにエクササイズを追加';

  @override
  String get lastTimeLabel => '前回';

  @override
  String get setLabel => 'セット';

  @override
  String kgLabel(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get repsLabel => '担当者';

  @override
  String cardioDistanceLabel(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String get cardioTimeLabel => '時間';

  @override
  String get cardioIntensityLabel => 'インテンス。';

  @override
  String get cardioIntensityShortLabel => '内部。';

  @override
  String get restTimerLabel => '休む';

  @override
  String get skipButton => 'スキップ';

  @override
  String get appInitStarting => 'アプリを起動しています...';

  @override
  String get appInitInitializing => '初期化中...';

  @override
  String get appInitFinalizing => 'ファイナライズ中';

  @override
  String get appInitCheckingBackups => 'バックアップを確認しています...';

  @override
  String get appInitSkipDownload => 'ダウンロードをスキップする';

  @override
  String get appInitSkippingRemoteDownload => 'リモートダウンロードをスキップしています...';

  @override
  String get emptyHistory => 'まだ完了したワークアウトはありません。';

  @override
  String get workoutDetailsTitle => 'トレーニングの詳細';

  @override
  String get workoutHeartRateSectionTitle => '心拍';

  @override
  String get workoutHeartRateAverageLabel => '平均';

  @override
  String get workoutHeartRateMaxLabel => 'マックス';

  @override
  String get workoutHeartRateMinLabel => '分';

  @override
  String get workoutHeartRateQualityReady => '良好なカバレッジ';

  @override
  String get workoutHeartRateQualityLimited => '限られたデータ';

  @override
  String get workoutHeartRateQualityInsufficient => '非常にまばら';

  @override
  String get workoutHeartRateQualityNoData => 'データなし';

  @override
  String get workoutHeartRateNoDataGeneral =>
      'このワークアウト ウィンドウでは心拍数サンプルが見つかりませんでした。';

  @override
  String get workoutHeartRateNoDataPermission =>
      'ワークアウトの HR を表示するには、心拍数の許可が必要です。';

  @override
  String get workoutHeartRateNoDataUnavailable => '現在、このデバイスでは心拍数データを利用できません。';

  @override
  String get workoutHeartRateNoDataWorkoutNotFinished =>
      'ワークアウト終了後に心拍数の概要が表示されます。';

  @override
  String get workoutHeartRateNoDataInvalidWindow =>
      'ワークアウトの時間枠が無効であるため、HR を分析できません。';

  @override
  String get workoutHeartRateNoDataQueryFailed =>
      'このワークアウトの心拍数データを読み取ることができませんでした。';

  @override
  String get workoutHeartRateLimitedChartHint =>
      '信頼できるグラフを作成するには、一貫したサンプルが十分ではありません。';

  @override
  String workoutHeartRateSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count サンプル',
      one: '1',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get workoutNotFound => 'ワークアウトが見つかりません。';

  @override
  String get totalVolumeLabel => '総量';

  @override
  String get notesLabel => '注意事項';

  @override
  String get workoutImportTitle => '外部ワークアウトのインポート';

  @override
  String get workoutImportDescription =>
      'CSV または Excel エクスポート ファイルからトレーニング履歴をインポートします。';

  @override
  String get workoutImportButton => 'ワークアウトデータのインポート';

  @override
  String workoutImportSuccess(Object count) {
    return '$count 個のワークアウトを正常にインポートしました。';
  }

  @override
  String get workoutImportFailed => 'インポートに失敗しました。ファイルを確認してください。';

  @override
  String get importUnitSelectionTitle => '輸入単位';

  @override
  String get importUnitSelectionDescription => '提供されるファイルのデータはどの単位で表示されますか?';

  @override
  String get unitMetricLabel => 'メートル法(kg)';

  @override
  String get unitImperialLabel => 'インペリアル (ポンド)';

  @override
  String get excelExportButton => 'Excel エクスポート (.xlsx)';

  @override
  String get exportWorkoutHistory => 'トレーニング履歴';

  @override
  String get exportNutritionDiary => '栄養日記';

  @override
  String get exportMeasurements => '測定';

  @override
  String get startWorkout => 'ワークアウトを開始する';

  @override
  String get addMeasurement => '測定の追加';

  @override
  String get filterToday => '今日';

  @override
  String get filter7Days => '7日間';

  @override
  String get filter30Days => '30日';

  @override
  String get filter30DaysShort => '30日';

  @override
  String get filter90DaysShort => '90日';

  @override
  String get filter180DaysShort => '180日';

  @override
  String get filter7DaysShort => '7日';

  @override
  String get filter1MonthShort => '1ヶ月';

  @override
  String get filter3MonthsShort => '3ヶ月';

  @override
  String get filter6MonthsShort => '6ヶ月';

  @override
  String get filter1YearShort => '1年';

  @override
  String get filterMax => '最大';

  @override
  String get filterAll => '全て';

  @override
  String get showLess => '表示を少なくする';

  @override
  String get showMoreDetails => 'さらに詳細を表示';

  @override
  String get deleteConfirmTitle => '削除の確認';

  @override
  String get deleteConfirmContent => '本当にこのエントリを削除してもよろしいですか?';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get unsavedChangesTitle => '未保存の変更';

  @override
  String get unsavedChangesContent => '未保存の変更があります。出発する前に保存しますか?';

  @override
  String get share => '共有';

  @override
  String get shareWorkout => 'ワークアウトを共有する';

  @override
  String get shareRoutine => 'ルーチンを共有する';

  @override
  String get shareAsImage => '画像として共有';

  @override
  String get shareAsText => 'テキストとして共有する';

  @override
  String get sharedFromTrainLibre => 'トレイン・リブレから共有';

  @override
  String get sharedWithTrainLibre => 'トレイン・リブレと共用';

  @override
  String get shareImageSummary => 'まとめ';

  @override
  String get shareImageExercises => '演習';

  @override
  String get shareImageMuscleFocus => '筋肉の集中';

  @override
  String get shareImageMinimal => '最小限';

  @override
  String get volume => '音量';

  @override
  String moreExercises(int count) {
    return '+ $count 個以上のエクササイズ';
  }

  @override
  String shareSetNumber(int number) {
    return '$number を設定します';
  }

  @override
  String get repsShort => '担当者';

  @override
  String get shareFailed => '共有に失敗しました';

  @override
  String get workoutShareTitle => 'いい結果';

  @override
  String get routineShareTitle => 'ルーティーン';

  @override
  String get setTypeWarmup => '準備し始める';

  @override
  String get setTypeWork => 'ワークセット';

  @override
  String get setTypeFailure => '失敗';

  @override
  String get setTypeDropset => 'ドロップセット';

  @override
  String get setTypeSuperset => 'スーパーセット';

  @override
  String get setTypeOther => '他の';

  @override
  String get setTypeWarmupSuffix => '準備し始める';

  @override
  String get setTypeFailureSuffix => '失敗';

  @override
  String get setTypeDropsetSuffix => 'ドロップセット';

  @override
  String get setTypeSupersetSuffix => 'スーパーセット';

  @override
  String get setTypeOtherSuffix => '他の';

  @override
  String warmupSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ウォームアップ セット',
      one: '1',
    );
    return '$_temp0';
  }

  @override
  String workSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ワークセット',
      one: '1',
    );
    return '$_temp0';
  }

  @override
  String failureSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 障害セット',
      one: '1 ',
    );
    return '$_temp0';
  }

  @override
  String dropsetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ドロップセット',
      one: '1',
    );
    return '$_temp0';
  }

  @override
  String supersetSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count スーパーセット',
      one: '1 ',
    );
    return '$_temp0';
  }

  @override
  String otherSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 他のセット',
      one: '1',
    );
    return '$_temp0';
  }

  @override
  String warmupCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ウォームアップ',
      one: '1 ',
    );
    return '$_temp0';
  }

  @override
  String workCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count の作業',
      one: '1',
    );
    return '$_temp0';
  }

  @override
  String failureCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count の失敗',
      one: '1 ',
    );
    return '$_temp0';
  }

  @override
  String dropsetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ドロップセット',
      one: '1',
    );
    return '$_temp0';
  }

  @override
  String supersetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count スーパーセット',
      one: '1 ',
    );
    return '$_temp0';
  }

  @override
  String otherCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count その他',
      one: '1',
    );
    return '$_temp0';
  }

  @override
  String get shareExercisesLabel => '演習';

  @override
  String get shareSetsLabel => 'セット';

  @override
  String get shareSetLabel => 'セット';

  @override
  String get tabBaseFoods => 'ベースフード';

  @override
  String get baseFoodsEmptyState =>
      'このセクションには、果物、野菜などの基本的な食品の厳選されたリストが間もなく追加される予定です。';

  @override
  String get noBrand => 'ノーブランド';

  @override
  String get unknown => '未知';

  @override
  String backupFileSubject(String timestamp) {
    return 'Libre アプリのバックアップを訓練する - $timestamp';
  }

  @override
  String foodItemSubtitle(String brand, int calories) {
    return '$brand - $calories kcal / 100g';
  }

  @override
  String foodListSubtitle(int grams, String time) {
    return '${grams}g - $time';
  }

  @override
  String foodListTrailingKcal(int calories) {
    return '$calories kcal';
  }

  @override
  String waterListTrailingMl(int milliliters) {
    return '$milliliters ml';
  }

  @override
  String get exerciseCatalogTitle => 'エクササイズカタログ';

  @override
  String get filterByMuscle => '筋肉グループによるフィルター';

  @override
  String get noExercisesFound => '演習が見つかりません。';

  @override
  String get noDescriptionAvailable => '説明はありません。';

  @override
  String get filterByCategory => 'カテゴリでフィルタリングする';

  @override
  String get edit => '編集';

  @override
  String get repsLabelShort => '担当者';

  @override
  String get titleNewRoutine => '新しいルーチン';

  @override
  String get titleEditRoutine => 'ルーチンの編集';

  @override
  String get editRoutine => 'ルーチンの編集';

  @override
  String get validatorPleaseEnterRoutineName => 'ルーチンの名前を入力してください。';

  @override
  String get snackbarRoutineCreated => 'ルーチンが作成されました。次に、いくつかの演習を追加します。';

  @override
  String get snackbarRoutineSaved => 'ルーチンが保存されました。';

  @override
  String get saveAsRoutineButton => 'ルーチンとして保存';

  @override
  String get saveAsRoutineTitle => 'ルーチンとして保存';

  @override
  String get saveAsRoutinePrompt => '新しいルーチンの名前を入力してください:';

  @override
  String get saveAsRoutineSuccess => 'ルーティンができました！';

  @override
  String get snackbarRoutineSavedAction => 'ビュー';

  @override
  String get formFieldRoutineName => 'ルーチンの名前';

  @override
  String get emptyStateAddFirstExercise => '最初の演習を追加します。';

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count セット',
      one: '1',
    );
    return '$_temp0';
  }

  @override
  String get fabAddExercise => 'エクササイズを追加';

  @override
  String get drawerExerciseCatalog => 'エクササイズカタログ';

  @override
  String get lastWorkoutTitle => '最後のトレーニング';

  @override
  String get repeatButton => '繰り返す';

  @override
  String get weightHistoryTitle => '体重履歴';

  @override
  String get hideSummary => '概要を隠す';

  @override
  String get showSummary => '概要を表示';

  @override
  String get exerciseDataAttribution => 'wger からの運動データ';

  @override
  String get duplicate => '重複';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return 'ルーチン「$routineName」を完全に削除してもよろしいですか?';
  }

  @override
  String get editPauseTimeTitle => '一時停止時間を編集する';

  @override
  String get pauseInSeconds => '数秒で一時停止します';

  @override
  String get editPauseTime => '編集一時停止';

  @override
  String pauseDuration(int seconds) {
    return '$seconds秒の一時停止';
  }

  @override
  String maxPauseDuration(int seconds) {
    return '最大 $seconds秒まで一時停止します';
  }

  @override
  String get deleteWorkoutConfirmContent => 'このワークアウト ログを完全に削除してもよろしいですか?';

  @override
  String get removeExercise => 'エクササイズを削除する';

  @override
  String get deleteExerciseConfirmTitle => 'エクササイズを削除しますか?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return 'このルーチンから「$exerciseName」を削除してもよろしいですか?';
  }

  @override
  String get doneButtonLabel => '終わり';

  @override
  String get setRestTimeButton => '休憩時間を設定する';

  @override
  String get deleteExerciseButton => '練習の削除';

  @override
  String get restOverLabel => '一時停止が終わりました';

  @override
  String get workoutRunningLabel => 'トレーニングはアクティブです…';

  @override
  String get continueButton => '続く';

  @override
  String get discardButton => '破棄';

  @override
  String get workoutStatsTitle => '研修（7日間）';

  @override
  String get workoutsLabel => 'トレーニング';

  @override
  String get durationLabel => '間隔';

  @override
  String get volumeLabel => '音量';

  @override
  String get setsLabel => 'セット';

  @override
  String get muscleSplitLabel => '筋肉の分割';

  @override
  String get snackbar_could_not_open_open_link => 'リンクを開けませんでした';

  @override
  String get chart_no_data_for_period => 'この期間のチャート データはありません';

  @override
  String get amount_in_milliliters => 'ミリリットル単位の量';

  @override
  String get amount_in_grams => 'グラム単位の量';

  @override
  String get meal_label => '食事';

  @override
  String get add_to_water_intake => '水分摂取量に加える';

  @override
  String get create_exercise_screen_title => 'カスタム演習の作成';

  @override
  String get exercise_name_label => 'エクササイズ名';

  @override
  String get category_label => 'カテゴリ';

  @override
  String get description_optional_label => '説明 (オプション)';

  @override
  String get primary_muscles_label => '一次筋肉';

  @override
  String get primary_muscles_hint => '例えば胸、上腕三頭筋';

  @override
  String get secondary_muscles_label => '二次筋肉 (オプション)';

  @override
  String get secondary_muscles_hint => '例えば肩';

  @override
  String get fluidNameLabel => '名前';

  @override
  String get sugarPer100mlLabel => '砂糖(g/100ml)';

  @override
  String get set_type_normal => '普通';

  @override
  String get set_type_warmup => '準備し始める';

  @override
  String get set_type_failure => '失敗';

  @override
  String get set_type_dropset => 'ドロップセット';

  @override
  String get set_reps_hint => '8-12';

  @override
  String get data_export_button => '輸出';

  @override
  String get data_import_button => '輸入';

  @override
  String get snackbar_button_ok => 'わかりました';

  @override
  String get measurement_session_detail_view => '測定セッションの詳細図';

  @override
  String get unit_grams => 'g';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get delete_profile_picture_button => 'プロフィール写真を削除する';

  @override
  String get attribution_title => '帰属';

  @override
  String get add_liquid_title => '液体を追加する';

  @override
  String get add_button => '追加';

  @override
  String get discard_button => '破棄';

  @override
  String get continue_workout_button => '続く';

  @override
  String get soon_available_snackbar => 'この画面は近日公開予定です';

  @override
  String get start_button => '始める';

  @override
  String get today_overview_text => '今日に注目';

  @override
  String get quick_add_text => 'クイック追加';

  @override
  String get scann_barcode_capslock => 'バーコードをスキャンする';

  @override
  String get protocol_today_capslock => '今日のプロトコル';

  @override
  String get my_plans_capslock => '私の計画';

  @override
  String get overview_capslock => '概要';

  @override
  String get manage_all_plans => 'すべての計画を管理する';

  @override
  String get workoutSectionStart => '始める';

  @override
  String get workoutSectionMyPlans => '私の計画';

  @override
  String get workoutSectionHistoryLibrary => '歴史と図書館';

  @override
  String get workoutAllRoutines => 'すべてのルーチン';

  @override
  String get workoutEntryWorkouts => 'トレーニング';

  @override
  String get free_training => '無料のトレーニング';

  @override
  String get my_consistency => '私の一貫性';

  @override
  String get calendar_currently_not_available =>
      'カレンダー ビューは近日中に利用できるようになる予定です。';

  @override
  String get in_depth_analysis => '徹底した分析';

  @override
  String get body_measurements => '身体測定';

  @override
  String get measurements_description => '体重、体脂肪率、周囲径を分析します。';

  @override
  String get nutrition_description => 'マクロ、カロリー、トレンドを評価します。';

  @override
  String get training_analysis => 'トレーニング分析';

  @override
  String get training_analysis_description => 'ボリューム、強さ、進行状況を追跡します。';

  @override
  String get load_dots => '読み込み中...';

  @override
  String get profile_capslock => 'プロフィール';

  @override
  String get settings_capslock => '設定';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsUpdateFoodDatabase => 'データベースを更新';

  @override
  String get settingsUpdateFoodDatabaseSubtitle =>
      '食品およびエクササイズデータベースの更新を手動で確認します。';

  @override
  String get settingsUpdateFoodDatabaseSuccess => 'データベースが正常に更新されました。';

  @override
  String settingsUpdateFoodDatabaseError(String error) {
    return 'データベースの更新中にエラーが発生しました: $error';
  }

  @override
  String get settingsGuidedTourSectionTitle => 'ガイド付きツアー';

  @override
  String get settingsRestartAppTourTitle => 'アプリツアーを再開する';

  @override
  String get settingsRestartAppTourSubtitle => 'アプリ内の短いウォークスルーを再度実行します。';

  @override
  String get my_goals => '私の目標';

  @override
  String get my_goals_description => 'カロリー、マクロ、水を調整します。';

  @override
  String get backup_and_import => 'データのバックアップとインポート';

  @override
  String get backup_and_import_description => 'データのバックアップ、復元、インポートを作成します。';

  @override
  String get feedbackReportSettingsSectionTitle => 'サポート';

  @override
  String get feedbackReportSettingsEntryTitle => 'フィードバックを送信する';

  @override
  String get feedbackReportSettingsEntrySubtitle =>
      'ローカル診断レポートを作成し、それを共有する方法を選択します。';

  @override
  String get about_and_legal_capslock => '概要と法的事項';

  @override
  String get feedbackReportScreenTitle => 'フィードバックレポート';

  @override
  String get feedbackReportPrivacyTitle => 'プライバシー第一';

  @override
  String get feedbackReportPrivacyBody =>
      'このレポートはデバイス上でローカルに生成されます。何も自動的には送信されません。コピー、保存、共有、または電子メールを選択した場合、プレビューに表示されている内容のみが含まれます。電子メールを送信すると、feedback@schotte.me 宛ての下書きが開かれるため、送信前に確認、編集、またはキャンセルできます。';

  @override
  String get feedbackReportOptionalNoteTitle => 'オプションのメモ';

  @override
  String get feedbackReportOptionalNoteLabel => 'あなたのメモ (オプション)';

  @override
  String get feedbackReportOptionalNoteHint => '何が起こったのか、予想される動作、再現手順を説明します。';

  @override
  String get feedbackReportIncludeSectionTitle => 'レポートに含める';

  @override
  String get feedbackReportIncludeAdaptiveNutrition => '適応栄養診断';

  @override
  String get feedbackReportIncludeBackupRestore => 'バックアップ/復元診断';

  @override
  String get feedbackReportIncludeUserNote => 'ユーザーメモ';

  @override
  String get feedbackReportGeneratePreview => 'プレビューの生成';

  @override
  String get feedbackReportPreviewTitle => 'プレビュー';

  @override
  String get feedbackReportActionCopy => 'コピー';

  @override
  String get feedbackReportActionSave => '保存';

  @override
  String get feedbackReportActionShare => '共有';

  @override
  String get feedbackReportActionEmail => '電子メール';

  @override
  String get feedbackReportCopied => 'レポートがクリップボードにコピーされました。';

  @override
  String get feedbackReportSavedToTemporaryFile => '一時レポート ファイルに保存されます。';

  @override
  String get feedbackReportShareCompleted => '共有シートが開きました。';

  @override
  String get feedbackReportShareCanceled => '共有がキャンセルされました。';

  @override
  String get feedbackReportEmailOpenFailed => 'メールアプリを開けませんでした。';

  @override
  String get feedbackReportEmailSubject => 'Train Libre フィードバック レポート';

  @override
  String get feedbackReportReportTitle => 'Train Libre フィードバック レポート';

  @override
  String get feedbackReportReportGeneratedAt => '生成された';

  @override
  String get feedbackReportReportAppVersion => 'アプリのバージョン';

  @override
  String get feedbackReportReportBuildNumber => 'ビルド番号';

  @override
  String get feedbackReportReportPlatform => 'プラットフォーム';

  @override
  String get feedbackReportReportOsVersion => 'OSバージョン';

  @override
  String get feedbackReportUnavailable => '利用不可';

  @override
  String get feedbackReportSectionUserNote => 'ユーザーメモ';

  @override
  String get feedbackReportSectionAdaptiveNutrition => '適応栄養診断';

  @override
  String get feedbackReportSectionBackupRestore => 'バックアップ/復元診断';

  @override
  String get attribution_and_license => '帰属とライセンス';

  @override
  String get data_from_off_and_wger => 'Open Food Facts と調査からのデータ。';

  @override
  String get app_version => 'アプリのバージョン';

  @override
  String get all_measurements => 'すべての測定値';

  @override
  String get all_measurements_no_cap => 'すべての測定値';

  @override
  String get date_and_time_of_measurement => '測定日時';

  @override
  String get onbWelcomeTitle => 'トレイン・リブレへようこそ';

  @override
  String get onbWelcomeBody => 'まずはトレーニングと栄養の指針となる個人的な目標を設定しましょう。';

  @override
  String get onbTrackTitle => 'すべてを追跡する';

  @override
  String get onbTrackBody => '栄養、トレーニング、測定値をすべて 1 か所で記録します。';

  @override
  String get onbPrivacyTitle => 'オフラインファーストとプライバシー';

  @override
  String get onbPrivacyBody => 'データはデバイス上に残ります。クラウド アカウントもバックグラウンド同期もありません。';

  @override
  String get onbFinishTitle => '準備完了';

  @override
  String get onbFinishBody => 'アプリを探索する準備ができました。いつでも設定を調整できます。';

  @override
  String get onbFinishCta => 'さあ行こう！';

  @override
  String get onbShowTutorialAgain => 'オンボーディングを再度表示する';

  @override
  String get appTourOfferTitle => '簡単なアプリ ツアーに参加しますか?';

  @override
  String get appTourOfferBody =>
      'アプリの主要な領域について簡単に説明します。ここでスキップして、後で [設定] で再起動することができます。';

  @override
  String get appTourOfferStart => 'ツアーを開始します';

  @override
  String get appTourOfferSkip => 'たぶん後で';

  @override
  String get appTourSkip => 'スキップ';

  @override
  String get appTourNext => '次';

  @override
  String get appTourDone => '終わり';

  @override
  String get appTourStepNavigationTitle => 'メインナビゲーション';

  @override
  String get appTourStepNavigationBody => '下部のタブを使用して、日記、ワークアウト、統計、栄養の間を移動します。';

  @override
  String get appTourStepQuickActionsTitle => 'クイックアクション';

  @override
  String get appTourStepQuickActionsBody =>
      'プラスボタンをタップすると、食事、水分、測定値、トレーニングなどをすぐに追加できます。';

  @override
  String get appTourStepDiaryTitle => '日記';

  @override
  String get appTourStepDiaryBody =>
      '日記はあなたの毎日の概要です。食事、水分補給、サプリメント、一日の記録を一目で確認できます。';

  @override
  String get appTourStepWorkoutTitle => 'いい結果';

  @override
  String get appTourStepWorkoutBody =>
      'ワークアウトでは、セッションを開始し、ルーチンを管理し、トレーニング履歴を確認します。';

  @override
  String get appTourStepNutritionTitle => '栄養';

  @override
  String get appTourStepNutritionBody =>
      'Nutrition は、食事を計画し、目標を確認し、食事テンプレートなどのツールにアクセスするのに役立ちます。';

  @override
  String get appTourStepStatisticsTitle => '統計';

  @override
  String get appTourStepStatisticsBody =>
      '統計は傾向と進捗状況を示すため、時間の経過とともにデータがどのように変化するかを理解できます。';

  @override
  String get onbSetGoalsCta => '目標を設定する';

  @override
  String get onbHeaderTitle => 'チュートリアル';

  @override
  String get onbHeaderSkip => 'スキップ';

  @override
  String get onbBack => '戻る';

  @override
  String get onbNext => '次';

  @override
  String get onbGuideTitle => 'このチュートリアルの仕組み';

  @override
  String get onbGuideBody =>
      'スライド間をスワイプするか、「次へ」を使用します。各スライドのボタンをタップして機能を試してください。スキップでいつでも終了できます。';

  @override
  String get onbCtaOpenNutrition => 'オープン栄養学';

  @override
  String get onbCtaLearnMore => 'もっと詳しく知る';

  @override
  String get onbBadgeDone => '終わり';

  @override
  String get onbTipSetGoals => 'ヒント: 最初にターゲットを調整します';

  @override
  String get onbTipAddEntry => 'ヒント: 今すぐエントリーを 1 つ追加してください';

  @override
  String get onbTipLocalControl => 'すべてのデータをローカルで管理します';

  @override
  String get onbTrackHowBody =>
      '栄養を記録する方法:\n• [食品]タブを開きます。\n• ＋ボタンをタップします。\n• 製品を検索するか、バーコードをスキャンします。\n• 分量と時間を調整します。\n• 日記に保存します。';

  @override
  String get onbMeasureTitle => '測定を追跡する';

  @override
  String get onbMeasureBody =>
      '測定値を追加する方法:\n• [統計] タブを開きます。\n• ＋ボタンをタップします。\n• 測定基準 (体重、ウエスト、体脂肪など) を選択します。\n• 値と時間を入力します。\n• 履歴に保存します。';

  @override
  String get onbTipMeasureToday => 'ヒント: 今日の体重を追加してグラフを開始します';

  @override
  String get onbTrainTitle => 'ルーチンでトレーニングする';

  @override
  String get onbTrainBody =>
      'ルーチンを作成してワークアウトを開始します。\n• [トレイン] タブを開きます。\n• [ルーチンの作成] をタップして、エクササイズとセットを追加します。\n• ルーチンを保存します。\n• [開始] をタップして開始するか、[空のワークアウトを開始] を使用します。';

  @override
  String get onbTipStartWorkout => 'ヒント: 空のワークアウトを開始して、簡単なセッションを記録します。';

  @override
  String get unitsSection => '単位';

  @override
  String get weightUnit => '重量単位';

  @override
  String get lengthUnit => '長さの単位';

  @override
  String get comingSoon => '近日公開';

  @override
  String get noFavorites => 'お気に入りがありません';

  @override
  String get nothingTrackedYet => 'まだ何も追跡されていません';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'バーコード「$barcode」に対応する商品が見つかりませんでした。';
  }

  @override
  String get categoryHint => '例えば胸、背中、脚…';

  @override
  String get validatorPleaseEnterCategory => 'カテゴリを入力してください。';

  @override
  String get dialogEnterPasswordImport => 'バックアップをインポートするにはパスワードを入力してください';

  @override
  String get dataManagementBackupTitle => 'トレイン リブレ データ バックアップ';

  @override
  String get dataManagementBackupDescription =>
      'すべてのアプリデータをバックアップまたは復元します。機種変更に最適です。';

  @override
  String get exportEncrypted => '暗号化してエクスポート';

  @override
  String get dialogPasswordForExport => '暗号化エクスポート用のパスワード';

  @override
  String get snackbarEncryptedBackupShared => '暗号化されたバックアップが共有されました。';

  @override
  String get exportFailed => 'エクスポートに失敗しました。';

  @override
  String get csvExportTitle => 'データエクスポート(CSV)';

  @override
  String get csvExportDescription =>
      '他のプログラムで分析できるように、データの一部を CSV ファイルとしてエクスポートします。';

  @override
  String get snackbarSharingNutrition => '栄養日記を共有...';

  @override
  String get snackbarExportFailedNoEntries =>
      'エクスポートに失敗しました。まだエントリーがない可能性があります。';

  @override
  String get snackbarSharingMeasurements => '測定値を共有しています...';

  @override
  String get snackbarSharingWorkouts => 'ワークアウト履歴を共有しています...';

  @override
  String get mapExercisesTitle => '地図演習';

  @override
  String get mapExercisesDescription => 'ログから未知の名前を wger 演習にマッピングします。';

  @override
  String get mapExercisesButton => 'マッピングの開始';

  @override
  String get autoBackupTitle => '自動バックアップ';

  @override
  String get autoBackupDescription => '定期的にバックアップをフォルダーに保存します。現在のフォルダー:';

  @override
  String get autoBackupDefaultFolder => 'アプリ - ドキュメント/バックアップ (デフォルト)';

  @override
  String get autoBackupChooseFolder => 'フォルダーの選択';

  @override
  String get autoBackupCopyPath => 'パスのコピー';

  @override
  String get autoBackupRunNow => '今すぐチェック＆自動バックアップを実行';

  @override
  String get icloudAutoBackupTitle => 'iCloud自動バックアップ';

  @override
  String get icloudAutoBackupDescription =>
      'アプリがバックグラウンドになると、データベースを自動的にiCloud Driveに同期します。新しいデバイスや再インストール時にデータを復元できます。';

  @override
  String get icloudBackupNow => '今すぐiCloudにバックアップ';

  @override
  String get icloudBackupUploading => 'アップロード中…';

  @override
  String get icloudBackupSuccess => 'バックアップが正常にアップロードされました。';

  @override
  String get icloudBackupFailed => 'バックアップに失敗しました。iCloud接続を確認してください。';

  @override
  String get autoBackupRequestAccessSubtitle =>
      'データを自動的にバックアップするには、Train Libre は選択したフォルダーにアクセスする必要があります。バックアップはそこに保存されます。';

  @override
  String get snackbarAutoBackupSuccess => '自動バックアップが完了しました。';

  @override
  String get snackbarAutoBackupFailed => '自動バックアップが失敗したか、キャンセルされました。';

  @override
  String get localDataDeletionCardTitle => 'ローカルアプリデータ';

  @override
  String get localDataDeletionCardDescription =>
      'このデバイスに保存されているユーザー所有のデータを完全に削除し、Train Libre を新しいローカル状態にリセットします。';

  @override
  String get deleteAllLocalAppData => 'ローカルアプリのデータをすべて削除する';

  @override
  String get localDataDeletionConfirmTitle => 'ローカルアプリのデータをすべて削除しますか?';

  @override
  String get localDataDeletionConfirmBody =>
      'これにより、ローカルに保存されたワークアウト、栄養ログ、測定値、サプリメント、設定/状態、キャッシュされた分析、ローカル アプリ データが完全に削除されます。\n\nこれによって、すでに Apple Health または Health Connect にエクスポートされたデータは削除されません。\n\nこれにより、外部プロバイダー データやリモート パブリック カタログ ソースは削除されません。バンドルされたアプリのアセットと必要なデフォルトのカタログは、リセット後にアプリを起動できるように保持または再作成されます。';

  @override
  String get localDataDeletionTypeDeleteLabel => '「DELETE」と入力して確認します';

  @override
  String get localDataDeletionSuccessTitle => 'ローカルデータが削除されました';

  @override
  String get localDataDeletionSuccessBody => 'Train Libre は初期設定状態に戻ります。';

  @override
  String get localDataDeletionFailed => 'ローカルデータを削除できませんでした。もう一度試してください。';

  @override
  String get noUnknownExercisesFound => '不明な演習は見つかりませんでした';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return '自動バックアップフォルダーセット:\n$path';
  }

  @override
  String get snackbarPathCopied => 'コピーされたパス';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get descriptionLabel => '説明';

  @override
  String get involvedMuscles => '関与する筋肉';

  @override
  String get primaryLabel => '主要な：';

  @override
  String get secondaryLabel => '二次:';

  @override
  String get noMusclesSpecified => '筋肉の指定はありません。';

  @override
  String get frontLabel => 'フロント';

  @override
  String get backLabel => '戻る';

  @override
  String get noSelection => '選択なし';

  @override
  String get selectButton => '選択';

  @override
  String get applyingChanges => '変更を適用しています...';

  @override
  String get applyMapping => 'マッピングを適用する';

  @override
  String get mappingSuggestions => '提案';

  @override
  String get mappingSuggestionsEmpty => '一致する演習が見つかりませんでした';

  @override
  String get personalData => '個人データ';

  @override
  String get personalDataCL => '個人データ';

  @override
  String get macroDistribution => '主要栄養素の分布';

  @override
  String get dialogFinishWorkoutBody => 'このワークアウトを終了してもよろしいですか?';

  @override
  String get attributionText =>
      'このアプリは外部ソースからのデータを使用します。\n\n● CC-BY-SA 4.0 に基づいてライセンス供与された wger (wger.de) からのエクササイズ データと画像。\n\n● Open Food Facts (openfoodfacts.org) の食品データベース。Open Database License (ODbL) に基づいて利用できます。';

  @override
  String get errorRoutineNotFound => 'ルーチンが見つかりません';

  @override
  String get workoutHistoryEmptyTitle => 'あなたの履歴は空です';

  @override
  String get workoutSummaryTitle => 'ワークアウト完了';

  @override
  String get workoutSummaryExerciseOverview => '演習の概要';

  @override
  String get nutritionDiary => '日記';

  @override
  String get detailedNutrientGoals => '詳しい栄養素';

  @override
  String get detailedNutrientGoalsCL => '詳しい栄養素';

  @override
  String get supplementTrackerTitle => 'サプリメントトラッカー';

  @override
  String get supplementTrackerDescription => '目標、制限、摂取量を追跡します。';

  @override
  String get createSupplementTitle => 'サプリメントの作成';

  @override
  String get supplementNameLabel => 'サプリメント名';

  @override
  String get defaultDoseLabel => 'デフォルトの投与量';

  @override
  String get unitLabel => 'ユニット';

  @override
  String get dailyGoalLabel => '毎日の目標 (オプション)';

  @override
  String get dailyLimitLabel => '1 日あたりの制限 (オプション)';

  @override
  String get dailyProgressTitle => '日々の進歩';

  @override
  String get todaysLogTitle => '今日のログ';

  @override
  String get logIntakeTitle => 'ログの取り込み';

  @override
  String get emptySupplementGoals => 'ここでサプリメントの目標または制限を設定して、進捗状況を確認します。';

  @override
  String get emptySupplementLogs => '今日の摂取量はまだ記録されていません。';

  @override
  String get doseLabel => '用量';

  @override
  String get settingsDescription => 'テーマ、単元、データなど';

  @override
  String get settingsAppearance => '外観';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => '暗い';

  @override
  String get caffeinePrompt => 'カフェイン (オプション)';

  @override
  String get caffeineUnit => '100mlあたりmg';

  @override
  String get profile => 'プロフィール';

  @override
  String get measurementWeightCapslock => '体重';

  @override
  String get diary => '日記';

  @override
  String get analysis => '分析';

  @override
  String get yesterday => '昨日';

  @override
  String get dayBeforeYesterday => '2日前';

  @override
  String get statistics => '統計';

  @override
  String get workout => 'いい結果';

  @override
  String get addFoodTitle => '食べ物を追加する';

  @override
  String get nutritionExplorerTitle => '栄養探検家';

  @override
  String get myMeals => 'マイレシピ';

  @override
  String get myMealsCL => 'マイレシピ';

  @override
  String get nutritionSectionTodayInFocus => '今日の焦点';

  @override
  String get nutritionSectionMyMeals => 'マイレシピ';

  @override
  String get nutritionSectionToolsAndLibrary => 'ツールとライブラリ';

  @override
  String get supplement_caffeine => 'カフェイン';

  @override
  String get supplement_creatine_monohydrate => 'クレアチン一水和物';

  @override
  String get manageSupplementsTitle => 'サプリメントの管理';

  @override
  String get deleted => '削除されました';

  @override
  String get operationNotAllowed => 'この操作は許可されていません';

  @override
  String get emptySupplements => 'サプリメントは利用できません';

  @override
  String get undo => '元に戻す';

  @override
  String get deleteSupplementConfirm =>
      'この補足を削除してもよろしいですか?すべての履歴データは失われます。\n\nヒント: 代わりにサプリメントを編集することで、追跡を解除することができます。';

  @override
  String get fieldRequired => '必須';

  @override
  String get unitNotSupported => 'ユニットはサポートされていません。';

  @override
  String get caffeineUnitLocked => 'カフェインの場合、単位は mg に固定されています。';

  @override
  String get caffeineMustBeMg => 'カフェインはmg単位で記録する必要があります。';

  @override
  String get tabCatalogSearch => 'カタログ';

  @override
  String get tabMeals => 'レシピ';

  @override
  String get emptyCategory => 'エントリはありません';

  @override
  String get searchSectionBase => 'ベースフード';

  @override
  String get searchSectionOther => 'その他の結果';

  @override
  String get mealsComingSoonTitle => 'レシピ（近日公開予定）';

  @override
  String get mealsComingSoonBody => 'すぐに、複数の食品から独自のレシピを作成できるようになります。';

  @override
  String get mealsEmptyTitle => 'レシピテンプレートが保存されていません';

  @override
  String get mealsEmptyBody => 'レシピを作成して、複数の食品を一度にすばやく記録します。';

  @override
  String get mealsEmptyBodyWithShortcut =>
      '日記で、朝食または夕食の下にある「レシピとして保存」オプションを使用して、一般的な食事の組み合わせを簡単なテンプレートとして保存します。';

  @override
  String get mealsCreateManually => 'レシピを手動で作成する';

  @override
  String get saveMealTemplateShortcut => 'レシピとして保存';

  @override
  String get mealsCreate => 'レシピを作る';

  @override
  String get mealsEdit => 'レシピを編集する';

  @override
  String get mealsDelete => 'レシピを削除する';

  @override
  String get mealsAddToDiary => '食べ物を追加する';

  @override
  String get mealNameLabel => 'レシピ名';

  @override
  String get mealNotesLabel => '注意事項';

  @override
  String get mealIngredientsTitle => '材料';

  @override
  String get mealAddIngredient => '成分を追加する';

  @override
  String get mealIngredientAmountLabel => '額';

  @override
  String get mealDeleteConfirmTitle => 'レシピを削除する';

  @override
  String mealDeleteConfirmBody(Object name) {
    return 'レシピ「$name」を削除してもよろしいですか?その成分もすべて除去されます。';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'レシピ「$name」が日記に追加されました。';
  }

  @override
  String get mealSaved => 'レシピを保存しました。';

  @override
  String get mealDeleted => 'レシピを削除しました。';

  @override
  String get confirm => '確認する';

  @override
  String get addMealToDiaryTitle => '日記に追加';

  @override
  String get mealTypeLabel => 'レシピ';

  @override
  String get amountLabel => '額';

  @override
  String get mealAddedToDiarySuccess => '日記にレシピを追加しました';

  @override
  String get error => 'エラー';

  @override
  String get mealsViewTitle => '食事ビュータイトル';

  @override
  String get noNotes => 'メモはありません';

  @override
  String get ingredientsCapsLock => '材料';

  @override
  String get nutritionSectionLabel => '栄養成分表';

  @override
  String get nutritionCalculatedForCurrentAmounts => '現在の数量について';

  @override
  String get startCapsLock => '始める';

  @override
  String get nutritionHubSubtitle => 'ここですぐに洞察を発見し、食事を追跡し、栄養計画を立てましょう。';

  @override
  String get nutritionHubTitle => '栄養';

  @override
  String get nutrition => '栄養';

  @override
  String get changeSetTypTitle => 'セットタイプの変更';

  @override
  String get settingsVisualStyleTitle => 'ビジュアルスタイル';

  @override
  String get settingsVisualStyleStandard => 'すりガラス';

  @override
  String get settingsVisualStyleLiquid => '液体ガラス（液体）';

  @override
  String get settingsVisualStyleLiquidDesc => '丸みを帯びたフローティング UI 要素';

  @override
  String get settingsMaterialColorsTitle => '素材の色';

  @override
  String get settingsMaterialColorsSubtitle =>
      'Train Libre ブランド アクセントの代わりにシステムのダイナミック カラー (マテリアル ユー) を使用する';

  @override
  String get settingsFoodDbSectionTitle => '食品データベース';

  @override
  String get settingsFoodDbRegionTitle => '食品データベース地域';

  @override
  String get settingsFoodDbRegionSubtitle =>
      '検索に使用するOpen Food Facts製品カタログの地域を選択します。';

  @override
  String get settingsFoodDbRegionCurrent => '現在の地域';

  @override
  String get settingsFoodDbRegionDialogTitle => '食品データベース地域を選択';

  @override
  String get settingsFoodDbRegionDialogSubtitle =>
      '製品検索で使用されるOpen Food Factsカタログソースが変更されます。';

  @override
  String get settingsFoodDbRegionSearchPlaceholder => '地域を検索...';

  @override
  String get settingsFoodDbRegionNoResults => '地域が見つかりません';

  @override
  String get settingsFoodDbRegionIssueHint =>
      'あなたの国がまだリストされていない場合は、お気軽に GitHub の問題を開いてサポートをリクエストしてください。';

  @override
  String get settingsFoodDbRegionGermany => 'ドイツ (DE)';

  @override
  String get settingsFoodDbRegionSwitzerland => 'スイス (CH)';

  @override
  String get settingsFoodDbRegionUnitedStates => '米国 (US)';

  @override
  String get settingsFoodDbRegionFrance => 'フランス (FR)';

  @override
  String get settingsFoodDbRegionItaly => 'イタリア (IT)';

  @override
  String get settingsFoodDbRegionJapan => '日本 (JP)';

  @override
  String get settingsFoodDbRegionAustria => 'オーストリア (AT)';

  @override
  String get settingsColorfulMacroBadgesTitle => 'カラフルなマクロバッジ';

  @override
  String get settingsColorfulMacroBadgesSubtitle =>
      'AI検証による色分けされたバッジデザインをダイアリーにも採用。';

  @override
  String get settingsFoodDbRegionUnitedKingdom => '英国 (UK)';

  @override
  String settingsFoodDbRegionChanged(String region) {
    return 'データベースの地域を $region に設定しました。変更は次回のインポート時に適用されます。';
  }

  @override
  String get searchBaseFoodHint => 'ベースとなる食品を探す';

  @override
  String get searchNoHits => 'ヒットはありません。';

  @override
  String get onbSubtitleWelcome => 'フィットネス、栄養、進歩のための中心的なツール。';

  @override
  String get onbBodyWelcome =>
      '私たちはあなたの目標の設定と追跡をお手伝いします。ワークアウト、栄養、サプリメント、身体測定値を効率的に記録します。';

  @override
  String get onbBodyNutritionVisual =>
      '数回クリックするだけで食事を記録できます。カロリー、主要栄養素、水分に注目して、目標を簡単に追跡しましょう。';

  @override
  String get onbBodyMeasurementsVisual =>
      '自分の進歩を視覚化します。体重と周囲長のグラフにより、成功が目に見えるようになり、モチベーションが維持されます。';

  @override
  String get onbBodyWorkoutVisual =>
      'ルーチンを作成して、数秒でトレーニングを開始できます。最大限の進歩のために、セット、ウェイト、休憩を記録します。';

  @override
  String get onbTitleAppLayout => 'ナビゲーションとクイック追加';

  @override
  String get onbBodyAppLayout =>
      '下部のバーを使用すると、エリアをすばやく切り替えることができます。大きな [+] ボタンを使用すると、すべてを即座に記録できます。';

  @override
  String get dataHubTitle => 'データハブ';

  @override
  String get resumeButton => '再開する';

  @override
  String get onboardingWelcomeTitle => 'トレイン・リブレへようこそ';

  @override
  String get onboardingWelcomeSubtitle => '最良の結果を得るためにプロフィールを設定しましょう。';

  @override
  String get onboardingMissionTitle => '私たちの使命';

  @override
  String get onboardingMissionBody =>
      'Train Libreは、科学的根拠に基づいたデータ主導の進歩を求める、熱心なナチュラル・ボディビルダーのためのものです。';

  @override
  String get onboardingFeatureWorkoutTitle => 'ワークアウトトラッカー';

  @override
  String get onboardingFeatureWorkoutBody => 'セット（RIR/RPE）を記録し、筋肉の回復を追跡します。';

  @override
  String get onboardingFeatureTdeeTitle => '適応型TDEE';

  @override
  String get onboardingFeatureTdeeBody => '統合されたカルマンフィルターが実際の消費カロリーを計算します。';

  @override
  String get onboardingFeatureNutritionTitle => '栄養と水分';

  @override
  String get onboardingFeatureNutritionBody => 'マクロ、水分、任意のAI画像認識を記録します。';

  @override
  String get onboardingFeaturePrivacyTitle => '100%プライベートかつローカル';

  @override
  String get onboardingFeaturePrivacyBody => 'アカウント不要、クラウド強制なし。データはあなたのものです。';

  @override
  String get onboardingSettingsHint => 'すべての設定は後からいつでも設定画面で変更できます。';

  @override
  String get adaptiveRatePerWeekLabel => '週次目標レート';

  @override
  String get onboardingNameTitle => 'あなたの名前は何ですか？';

  @override
  String get onboardingNameLabel => 'あなたの名前';

  @override
  String get onboardingNameError => 'あなたの名前を入力してください';

  @override
  String get onboardingDobTitle => '生年月日は何ですか？';

  @override
  String get onboardingDobLabel => '生年月日';

  @override
  String get onboardingDobError => '生年月日を選択してください';

  @override
  String get onboardingWeightTitle => '現在の体重';

  @override
  String get onboardingWeightLabel => '重さ';

  @override
  String get onboardingWeightError => '有効な体重を入力してください';

  @override
  String get onboardingGoalsTitle => 'あなたの栄養目標';

  @override
  String get onboardingGoalsSubtitle => 'これらは後で設定で変更できます。';

  @override
  String get onboardingGoalCalories => '1日のカロリー(kcal)';

  @override
  String get onboardingGoalProtein => 'たんぱく質(g)';

  @override
  String get onboardingGoalCarbs => '炭水化物 (g)';

  @override
  String get onboardingGoalFat => '脂肪(g)';

  @override
  String get onboardingGoalWater => '水';

  @override
  String get onboardingNext => '次';

  @override
  String get onboardingBack => '戻る';

  @override
  String get onboardingFinish => '追跡を開始する';

  @override
  String get onboardingAiHealthTitle => 'AIと健康';

  @override
  String get onboardingAiHealthSubtitle =>
      '任意設定: BYOK (Bring Your Own Key) でAI食事認識を設定し、Train Libreが読み取れる健康データを選択します。';

  @override
  String get onboardingOpenSettings => '開く';

  @override
  String get onboardingUnitSystemTitle => '単位系を選択してください';

  @override
  String get onboardingUnitSystemSubtitle => 'これは後から「設定」で変更できます。';

  @override
  String get onboardingUnitMetric => 'メトリック';

  @override
  String get onboardingUnitMetricSubtitle => 'kg、cm、ml';

  @override
  String get onboardingUnitImperial => 'インペリアル';

  @override
  String get onboardingUnitImperialSubtitle => 'ポンド、インチ、液量オンス';

  @override
  String get onboardingHeightLabel => '身長';

  @override
  String get onboardingGenderLabel => '性別';

  @override
  String get onboardingBioDataInfo =>
      '年齢と生物学的性別は、筋肉回復モデルの基礎回復ウィンドウを決定し、Sleep Health Engineのアルゴリズムにも反映されます。';

  @override
  String get onboardingFieldCannotBeEmpty => 'このフィールドは必須です。';

  @override
  String get onboardingPhysiologicalRangeWarning =>
      '警告：この値は想定される生理学的範囲外です。当社のスポーツ科学分析およびヒューリスティックエンジンは、極端な測定値には対応していません。この値が意図的なものである場合は、もう一度「次へ」をクリックして続行してください。';

  @override
  String get onboardingMeasurementsTitle => '測定値とベースライン';

  @override
  String get onboardingMeasurementsSubtitle => '適応型レコメンドのために現在の基準値を設定します。';

  @override
  String get onboardingMeasurementsDisclaimer =>
      '体重、体脂肪、その他の測定値は、ダッシュボードでいつでも入力して記録できます。';

  @override
  String onboardingWaterNeedLabel(String unit) {
    return '水分目標 ($unit)';
  }

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女性';

  @override
  String get genderDiverse => '多様な';

  @override
  String get vegan => 'ビーガン';

  @override
  String get vegetarian => 'ベジタリアン';

  @override
  String get ingredients => '材料';

  @override
  String get aiSettingsTitle => 'AI食事認識';

  @override
  String get aiSettingsDescription => 'AI支援食事検出の設定を行います。';

  @override
  String get aiProviderSection => 'AIプロバイダー';

  @override
  String get aiProviderLabel => 'プロバイダー';

  @override
  String get aiApiKeySection => 'APIキー';

  @override
  String get aiApiKeyLabel => 'APIキー';

  @override
  String get aiApiKeyHint => 'ここに API キーを貼り付けてください';

  @override
  String get aiSaveKey => 'キーの保存';

  @override
  String get aiTestConnection => 'テスト';

  @override
  String get aiTestSuccess => '接続成功！';

  @override
  String get aiKeySaved => 'API キーは安全に保存されています。';

  @override
  String get aiPrivacySection => 'プライバシー';

  @override
  String get aiPrivacyDisclosure =>
      '画像、テキスト、生成されたプロンプトは、AI アクションを使用する場合にのみ、選択した AI プロバイダーに送信されます。プロバイダーの保持と処理は、そのプロバイダーの規約に従います。 API キーはこのデバイスにのみ暗号化されて保存されます。';

  @override
  String get aiMealCapture => 'AIミール';

  @override
  String get aiCaptureTitle => 'AI 食事キャプチャ';

  @override
  String get aiCaptureTabPhoto => '写真';

  @override
  String get aiCaptureTabText => '文章';

  @override
  String get aiCapturePhotoHint => '食事の写真を最大 4 枚まで撮影または選択します。';

  @override
  String get aiCaptureTextHint => '食事について説明してください (例: 「グリルチキンとライスとサラダ」)...';

  @override
  String get aiAnalyzeButton => '分析する';

  @override
  String get aiAnalyzing => '食事を分析中...';

  @override
  String get aiReviewTitle => '提案を確認する';

  @override
  String aiReviewFoundItems(int count) {
    return 'AI が $count 個のアイテムを見つけました';
  }

  @override
  String get aiReviewNoMatch => '一致しません — タップして検索します';

  @override
  String get aiReviewConfidence => '自信';

  @override
  String get aiReviewAddItem => '項目を手動で追加する';

  @override
  String get aiReviewReplaceItem => 'アイテムを交換する';

  @override
  String get aiReviewSaveToDiary => '日記に保存';

  @override
  String get aiReviewFeedbackHint => 'AI が何を間違えたのか説明してください...';

  @override
  String get aiReviewRetryButton => 'フィードバック付きで再試行';

  @override
  String get aiReviewFeedbackSection => '修正';

  @override
  String get aiErrorNoKey => 'API キーが設定されていません。 「設定」→「AI食事キャプチャ」で設定してください。';

  @override
  String get aiErrorNetwork => 'ネットワークエラー。接続を確認して、もう一度試してください。';

  @override
  String get aiErrorAuth => '認証に失敗しました。 API キーを確認してください。';

  @override
  String get aiErrorParse => 'AIの反応が理解できなかった。もう一度試してください。';

  @override
  String get aiErrorRateLimit => 'リクエストが多すぎます。しばらくお待ちください。';

  @override
  String get aiEnableTitle => 'AI 機能を有効にする';

  @override
  String get aiEnableSubtitle =>
      'AIを利用した食事認識が可能になります。これを無効にすると、アプリ内のすべての AI ボタン​​が非表示になります。';

  @override
  String get aiCustomInstructionsTitle => 'グローバル AI 命令';

  @override
  String get aiCustomInstructionsSubtitle =>
      'AI に固定ルール (アレルギー、「ボウル禁止」などの持ち込み禁止の食品、不耐性など) を与え、キャプチャごとに従うようにします。';

  @override
  String get aiValidationNoMatchedItemsSaveYet => '一致するアイテムはまだ保存できません。';

  @override
  String get aiValidationNoMatchedIngredientsSaveYet => '一致する材料はまだ保存できません。';

  @override
  String get aiValidationSomeItemsNeedReviewTitle => '一部の項目はレビューが必要です';

  @override
  String get aiValidationSomeIngredientsNeedReviewTitle => '一部の成分は見直しが必要です';

  @override
  String get aiValidationSaveMatchedItemsButton => '一致したアイテムを保存する';

  @override
  String get aiValidationSaveMatchedIngredientsButton => '一致した材料を保存する';

  @override
  String get aiValidationValidationPassedTitle => '検証に合格しました';

  @override
  String get aiValidationReviewSuggestedTitle => 'レビューの提案';

  @override
  String get aiValidationMacroFitValidatedTitle => 'マクロフィットが検証されました';

  @override
  String get aiValidationNeedsReviewTitle => '見直しが必要';

  @override
  String get aiValidationRepairLimitReachedReview =>
      '自動修復の制限に達しました。保存する前に確認してください。';

  @override
  String get aiValidationRecentMealContextIncluded => '最近の食事の内容も含まれていました。';

  @override
  String get aiValidationGeneratedWithoutRecentMealHistory =>
      '最近の食事履歴なしで生成されました。';

  @override
  String get aiValidationApiKeyRequiredTitle => 'APIキーが必要です';

  @override
  String aiValidationScoreLabel(int score) {
    return 'スコア $score/100';
  }

  @override
  String aiValidationDeltaSummary(
      int kcalDelta, int proteinDelta, int carbsDelta, int fatDelta) {
    return 'デルタ: $kcalDelta kcal · ${proteinDelta}g タンパク質 · ${carbsDelta}g 炭水化物 · ${fatDelta}g 脂肪';
  }

  @override
  String aiValidationPartialSaveItemsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other: '$unmatchedCount 項目はローカル データベースに一致しないため、保存されません。',
      one: '1  ',
    );
    return '$_temp0';
  }

  @override
  String aiValidationPartialSaveIngredientsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other: '$unmatchedCount 成分はローカル データベースに一致しないため、保存されません。',
      one: '1  ',
    );
    return '$_temp0';
  }

  @override
  String get aiValidationEmptyItemName => 'アイテムには食べ物の名前がありません。';

  @override
  String aiValidationDuplicateItemMerged(String name) {
    return '重複した「$name」エントリは検証前にマージされました。';
  }

  @override
  String get aiValidationInvalidQuantity => '量は 0g より大きくなければなりません。';

  @override
  String get aiValidationTinyQuantity => '量は非常に少ないです。グラム量を見直してください。';

  @override
  String get aiValidationExtremeQuantity => '1品の量としては信じられないほど多いです。';

  @override
  String get aiValidationLargeQuantity => '量が異常に多い。グラム量を見直してください。';

  @override
  String get aiValidationLowAiConfidence => 'この項目に対する AI の信頼度は低いです。';

  @override
  String get aiValidationUnmatchedItem => 'ローカル データベースに一致するものが見つかりませんでした。';

  @override
  String get aiValidationWeakDbMatch => 'ローカルデータベースの一致は弱いです。';

  @override
  String get aiValidationPartialDbMatch => 'ローカル データベースの一致は部分的です。';

  @override
  String get aiValidationAmbiguousDbMatch =>
      'いくつかのローカル データベースの一致も同様に妥当であるように見えます。';

  @override
  String get aiValidationStateMismatch =>
      'AI アイテムの状態がデータベース エントリと一致しない可能性があります。';

  @override
  String get aiValidationZeroNutritionMatch =>
      '一致したデータベース エントリには、使用できる栄養データがありません。';

  @override
  String get aiValidationImplausibleFoodDensity =>
      'マッチした食べ物は100gあたりのkcalが異常に高いです。';

  @override
  String get aiValidationMacroEnergyMismatch => '一致する食品マクロは kcal とうまく一致しません。';

  @override
  String get aiValidationImplausibleItemNutrition => 'この量の栄養価は異常に高いです。';

  @override
  String get aiValidationEmptyMeal => 'AI は食事アイテムを返しませんでした。';

  @override
  String get aiValidationAllItemsUnmatched => '地元の食品データベースと一致する項目はありませんでした。';

  @override
  String aiValidationPartialUnmatchedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項目は一致するまで保存できません。',
      one: '1 ',
    );
    return '$_temp0';
  }

  @override
  String get aiValidationZeroTotalKcal => '一致するアイテムの消費カロリーは0kcalです。';

  @override
  String get aiValidationCaptureTotalKcalExtreme =>
      '摂取した 1 回の食事の総 kcal は信じられないほど高くなります。';

  @override
  String get aiValidationCaptureTotalKcalHigh => '総カロリーが異常に高い。部分を見直します。';

  @override
  String get aiValidationMacroTotalExtreme => 'マクロの合計は信じられないほど多くなります。';

  @override
  String get aiValidationMacroTotalHigh => 'マクロの合計が異常に多い。部分を見直します。';

  @override
  String aiValidationTargetKcalMismatch(int delta) {
    return 'カロリーは目標を $delta kcal も下回っています。';
  }

  @override
  String aiValidationTargetProteinMismatch(int delta) {
    return 'タンパク質は、${delta}g だけターゲットを外します。';
  }

  @override
  String aiValidationTargetCarbsMismatch(int delta) {
    return '炭水化物は目標値を ${delta}g 逃します。';
  }

  @override
  String aiValidationTargetFatMismatch(int delta) {
    return '脂肪は ${delta}g だけターゲットを外します。';
  }

  @override
  String aiValidationUnknownIssue(String code) {
    return '検証の問題: $code';
  }

  @override
  String get currentlyTracking => '現在';

  @override
  String get currentlyTrackingDesc => 'デイリートラッカーハブに表示';

  @override
  String get filter3Months => '3ヶ月';

  @override
  String get filter6Months => '6ヶ月';

  @override
  String get sectionConsistency => '一貫性と頻度';

  @override
  String get metricsWorkoutsWeek => 'ワークアウト (週)';

  @override
  String get metricsCurrentStreak => '現在の連続数';

  @override
  String get metricsActiveWeeks => 'アクティブな週';

  @override
  String get placeholderCalendarHeatmap => 'カレンダーヒートマップビジュアル';

  @override
  String get consistencyTrackerTitle => '一貫性トラッカー';

  @override
  String get consistencyTrackerComingSoon => '一貫性と習慣のトラッカー (近日公開予定)';

  @override
  String get sectionMuscleVolume => '筋肉群と体積';

  @override
  String get metricsTopTrained => 'トップトレーニング済み';

  @override
  String get metricsMostNeglected => '最も無視されている';

  @override
  String get placeholderMuscleHeatmap => 'マッスルヒートマップビジュアル';

  @override
  String get muscleAnalyticsTitle => '筋肉グループの分析';

  @override
  String get muscleAnalyticsComingSoon => '筋肉量とヒートマップ (近日公開予定)';

  @override
  String get sectionPerformance => 'パフォーマンスとPR';

  @override
  String get metricsRecentPrs => '最近のPR';

  @override
  String get metricsVolumeLifted => 'ボリュームアップ';

  @override
  String get metricsMostImproved => '最も改善された';

  @override
  String get exerciseAnalyticsTitle => '運動分析';

  @override
  String get exerciseAnalyticsSubtitle => '特定の演習を検索して分析する';

  @override
  String get prDashboardTitle => 'PRダッシュボード';

  @override
  String get prDashboardComingSoon => '記録と進捗状況 (近日公開予定)';

  @override
  String get exerciseAnalyticsComingSoon => 'エクササイズの検索と特定のトレンド (近日公開)';

  @override
  String get sectionRecovery => '回復';

  @override
  String get metricsMuscleReadiness => '筋肉の準備状態';

  @override
  String get recoveryTrackerTitle => '回復トラッカー';

  @override
  String get recoveryTrackerComingSoon => '筋肉の準備と疲労 (近日公開予定)';

  @override
  String get recoveryOverallMostlyRecovered => 'ほとんど回復しました';

  @override
  String get recoveryOverallMixed => '混合回復状態';

  @override
  String get recoveryOverallSeveralRecovering => 'いくつかの筋肉群はまだ回復中';

  @override
  String get recoveryOverallInsufficientData => '回復に関する洞察を得るにはまだ十分なデータがありません';

  @override
  String recoveryHubCountsSummary(int recovering, int ready, int fresh) {
    return '回復中: $recovering 準備完了: $ready 新鮮: $fresh';
  }

  @override
  String get recoveryHubNoDataSummary => 'ワークアウトを記録し続けて、回復に関する洞察を引き出します。';

  @override
  String get recoveryByMuscleTitle => '筋肉による回復';

  @override
  String get recoveryStateRecovering => '回復';

  @override
  String get recoveryStateReady => '準備ができて';

  @override
  String get recoveryStateFresh => '新鮮な';

  @override
  String get recoveryStateUnknown => '未知';

  @override
  String recoveryLastLoadedHours(int hours) {
    return '最後に大幅に読み込まれた: $hours 時間前';
  }

  @override
  String get recoveryFatigueContextHigh => '疲労の状況: 高いセッション疲労';

  @override
  String get recoveryFatigueContextBaseline => '疲労のコンテキスト: ベースラインセッション疲労';

  @override
  String recoveryExplanationWithHighFatigue(String muscle, int hours) {
    return '$muscle: 最後に大幅にロードされたのは $hours 時間前で、セッション疲労が高くなっています。';
  }

  @override
  String recoveryExplanationBasic(String muscle, int hours) {
    return '$muscle: 最後に大幅にロードされたのは $hours 時間前です。';
  }

  @override
  String get recoveryHeuristicDisclaimer =>
      'これは、最近の大幅な読み込みとセッションの労力に基づいた保守的なヒューリスティックです。これは医学的な回復測定ではありません。';

  @override
  String get recoveryReadinessLabel => '準備完了';

  @override
  String recoveryRecentLoad(String sets) {
    return '最終ロード: $sets 個の同等のセット';
  }

  @override
  String recoveryLastLoadPressure(String level) {
    return '最終負荷圧力: $level';
  }

  @override
  String get recoveryPressureLow => '低い';

  @override
  String get recoveryPressureModerate => '適度';

  @override
  String get recoveryPressureHigh => '高い';

  @override
  String get recoveryPressureVeryHigh => '非常に高い';

  @override
  String recoveryCurrentWindow(int recoveringUpper, int readyUpper) {
    return '現在のウィンドウ: 約 $recoveringUpper 時間まで回復中、約 $readyUpper 時間まで準備完了。';
  }

  @override
  String recoveryWindowHeuristic(int from, int to) {
    return '現在の時間枠: 約 $from 時間まで回復中、約 $to 時間まで準備完了。';
  }

  @override
  String get recoveryRadarHeuristicCaption =>
      '筋肉ごとの現在の準備状態のレーダー概要。ステータス バッジは依然として主要なシグナルです。';

  @override
  String get recoveryNoDataBody => '筋肉の回復を推定するには、十分なトレーニング負荷がまだ記録されていません。';

  @override
  String get sectionBodyNutrition => '身体と栄養';

  @override
  String get statisticsSectionTraining => 'トレーニング';

  @override
  String get statisticsSectionBody => '体';

  @override
  String get statisticsEnableStepTrackingHint => '設定で歩数追跡を有効にする';

  @override
  String get statisticsNoStepDataYet => 'まだ歩数データが​​ありません';

  @override
  String get statisticsTotalSteps => '総ステップ数';

  @override
  String get statisticsLast7Days => '過去 7 日間';

  @override
  String get statisticsLast30Days => '過去 30 日間';

  @override
  String get statisticsLast3Months => '過去 3 か月';

  @override
  String get statisticsLast6Months => '過去6ヶ月';

  @override
  String get metricsCurrentWeight => '現在の体重';

  @override
  String get metricsAvgCalories => '平均カロリー';

  @override
  String get placeholderWeightTrend => '重量傾向折れ線グラフ';

  @override
  String get exerciseAnalyticsPrsLabel => '個人記録';

  @override
  String get exerciseAnalyticsTrendsLabel => 'トレンド';

  @override
  String get exerciseAnalyticsNoData => 'この演習には追跡データがありません。';

  @override
  String get exerciseAnalyticsNotEnoughData => 'データが不十分です';

  @override
  String get exerciseAnalyticsChartWeight => '経時的な重量 (kg)';

  @override
  String get exerciseAnalyticsChartVolume => '経時的な体積 (kg)';

  @override
  String get exerciseAnalyticsChartSets => '時間の経過に伴うセット';

  @override
  String get exerciseMetricMaxWeight => '最大重量';

  @override
  String get exerciseMetricVolume => '音量';

  @override
  String get exerciseMetricEst1RM => 'EST（東部基準時。 1RM';

  @override
  String get prBannerBestMaxWeight => 'ベスト最大体重';

  @override
  String get prBannerBestVolumeSet => 'ベストボリュームセット';

  @override
  String get prBannerBest1RM => 'ベスト 1-Rep Max';

  @override
  String get newPersonalRecordLabel => '新しい自己記録';

  @override
  String get prBadgeTooltip => '自己新記録更新！';

  @override
  String get workoutSummaryNewRecordsTitle => '新しい記録';

  @override
  String get allTimeRecordsLabel => '歴代記録';

  @override
  String get recentActivityLabel => '最近の活動';

  @override
  String get prsByRepRangeLabel => '担当範囲別のベストセット';

  @override
  String get volumeAnalyticsTitle => 'ボリューム分析';

  @override
  String get weeklyTonnageLabel => '週間トン数';

  @override
  String get volumeByMuscleLabel => '筋肉グループ別';

  @override
  String get topExercisesLabel => 'トップのエクササイズ';

  @override
  String get thisWeekLabel => '今週';

  @override
  String get avgPerWeekLabel => '平均/週';

  @override
  String get streakLabel => 'ストリーク';

  @override
  String get trainingCalendarLabel => 'トレーニングカレンダー';

  @override
  String get workoutsPerWeekLabel => '週あたりのワークアウト数';

  @override
  String get totalWorkoutsLabel => '合計';

  @override
  String get weeksLabel => '週間';

  @override
  String get tonnageKgLabel => 'トン数(kg)';

  @override
  String get noWorkoutDataLabel => 'まだトレーニングデータがありません。ログを開始して統計を確認します。';

  @override
  String get analyticsSectionVolumeMuscles => 'ボリュームと筋肉グループ';

  @override
  String get analyticsSectionPerformanceRecords => 'パフォーマンスと記録';

  @override
  String get analyticsTopVolume => 'トップトレーニング済み';

  @override
  String get analyticsLowestVolume => '最低音量';

  @override
  String get analyticsRecentRecords => '最近の記録';

  @override
  String analyticsPerfWithReps(String weight, int reps, Object unit) {
    return '$weight $unit x $reps';
  }

  @override
  String get analyticsKgThisWeek => 'kg（今週）';

  @override
  String get analyticsRecoverySummary => '3 回復中、8 準備完了';

  @override
  String get analyticsViewDetails => '詳細を見る';

  @override
  String get analyticsRepRangeSuffix => '担当者';

  @override
  String get analyticsNoRecordYet => 'まだ記録がありません';

  @override
  String get analyticsNotableImprovements => '注目すべき改善点';

  @override
  String get analyticsNoPrTrendInWindow => 'この分野ではまだ明確な PR 傾向はありません。';

  @override
  String analyticsE1rmProgress(String previous, String recent, Object unit) {
    return 'e1RM $previous -> $recent $unit';
  }

  @override
  String get analyticsUnitKg => 'kg';

  @override
  String get analyticsUnitSets => 'セット';

  @override
  String get analyticsViewLabel => 'ビュー';

  @override
  String get analyticsViewWeek => '週';

  @override
  String get analyticsViewMonth => '月';

  @override
  String get analyticsViewByExercise => '運動による';

  @override
  String get analyticsViewByMuscle => '筋肉グループ別';

  @override
  String get analyticsMetricLabel => 'メトリック';

  @override
  String get analyticsMovedWeightKg => '移動重量(kg)';

  @override
  String get analyticsWorkSets => 'ワークセット';

  @override
  String get analyticsVolumeContextWithSets =>
      '移動重量 = 重量 x 回数カウントベースのロードのワークセットに切り替えます。';

  @override
  String get analyticsVolumeContextTonnageOnly =>
      'このビューでは、移動した重量 (重量 x 回数) を使用します。';

  @override
  String get analyticsKpisHeader => 'KPI';

  @override
  String get analyticsTrainingDaysPerWeek => 'トレーニング日 / 週';

  @override
  String get analyticsLast4Weeks => '過去4週間';

  @override
  String get analyticsRhythm => 'リズム';

  @override
  String get analyticsVsPrior4Weeks => '過去 4 週間との比較';

  @override
  String get analyticsRollingConsistency => 'ローリング一貫性';

  @override
  String get analyticsWeeksAtLeast2Workouts => '少なくとも2回のセッションで週に1回';

  @override
  String get analyticsCalendarExplainer =>
      '色の濃さは 1 日あたりのセッションを反映しており、これが真の一貫性マップになります。';

  @override
  String get analyticsSelectDayPrompt => 'セッション数を検査する日を選択します。';

  @override
  String analyticsSelectedDayWorkouts(String date, int count) {
    return '$date: $count セッション';
  }

  @override
  String get analyticsTotalSessions => '合計セッション数';

  @override
  String get analyticsPlaceholderWeightValue => '体重値';

  @override
  String get analyticsPlaceholderWeightTrend => '体重傾向';

  @override
  String get analyticsPlaceholderCaloriesValue => 'カロリー値';

  @override
  String get analyticsPlaceholderCaloriesUnit => 'kcal/日';

  @override
  String get analyticsMuscleWeeklySets => 'ウィークリーセット';

  @override
  String get analyticsMuscleTopFrequency => 'トップ周波数';

  @override
  String get analyticsPerWeekAbbrev => '週';

  @override
  String get analyticsKeepTrackingUnlockInsights => '追跡を続けて洞察を引き出します。';

  @override
  String get analyticsGuidanceNoClearWeakPoint => 'ガイダンス: この時期に明確な弱点はありません。';

  @override
  String analyticsGuidanceLowerEmphasis(String muscles) {
    return 'ガイダンス: 最近では $muscles に重点を置きます。';
  }

  @override
  String get analyticsPeriodLabel => '期間';

  @override
  String get analyticsEquivalentSetsExplainer =>
      '同等のハード セットでは、プライマリ x1.0 とセカンダリ x0.3 の重み付けが使用されます。頻度は、同等のセットが 1.0 以上に達した日のみをカウントします。';

  @override
  String get analyticsWeeklySetsByMuscle => 'Ø 筋肉別週次セット';

  @override
  String get analyticsFrequencyByMuscle => '筋肉別の頻度';

  @override
  String get analyticsRecentDistributionHeatmap => '最近の配布ヒートマップ';

  @override
  String get analyticsRadarOverviewTitle => 'レーダーの概要';

  @override
  String get analyticsRadarVolumeCaption => '筋肉全体の相対的な体積分布を表示して、一目でわかる概要を示します。';

  @override
  String get analyticsGuidanceTitle => 'ガイダンス';

  @override
  String get analyticsGuidanceDirectionalDisclaimer =>
      'これは、最新のセット分布に基づいた方向性のガイダンスであり、絶対的な診断ではありません。';

  @override
  String get analyticsGuidanceSoftenedDisclaimer =>
      '十分なデータが利用可能になるまで、洞察は意図的に緩和されます。';

  @override
  String analyticsWeekTotalEquivalentSets(String value) {
    return 'Ø 1週当たり $value 相当セット';
  }

  @override
  String get analyticsFrequencyRuleFooter =>
      '頻度は、筋肉が同等のセット数 >= 1.0 に達した日のみをカウントします。';

  @override
  String liveWorkoutE1rmCurrentSet(String value, Object unit) {
    return 'e1RM $value $unit';
  }

  @override
  String liveWorkoutE1rmBestSession(String value, Object unit) {
    return 'このセッションの最高の e1RM: $value $unit';
  }

  @override
  String liveWorkoutE1rmVsLastSession(String delta, Object unit) {
    return '前回のセッションとの比較: $delta $unit';
  }

  @override
  String get bodyNutritionCorrelationTitle => '身体と栄養のトレンド';

  @override
  String get metricsWeightChange => '体重の変化';

  @override
  String get analyticsKcalPerDay => 'kcal/日';

  @override
  String get analyticsDaysWithWeightData => '体重が重い日々';

  @override
  String get analyticsDayUnitLabel => '日';

  @override
  String get analyticsPerDayLabel => '1日あたり';

  @override
  String get analyticsEffectiveRangeLabel => '有効範囲';

  @override
  String get analyticsAxisXLabel => '×';

  @override
  String get analyticsAxisYLabel => 'Y';

  @override
  String get analyticsHighConfidenceLabel => 'より信頼性の高いパターン';

  @override
  String get analyticsLowConfidenceLabel => '信頼度の低いパターン';

  @override
  String get analyticsObservedPatternLabel => '観察されたパターン';

  @override
  String get analyticsBodyNutritionTrendContext => '経時的な体重とカロリー';

  @override
  String analyticsBodyNutritionTrendContextHint(Object unit) {
    return 'グラフは、同じ空間に収まるように各系列を拡大縮小します。ツールチップには生の $unit と kcal の値が表示されます。';
  }

  @override
  String analyticsBodyNutritionNormalizedHint(Object unit) {
    return 'グラフは、同じスペースに収まるように体重とカロリーをスケールします。ツールチップには生の $unit と kcal の値が表示されます。';
  }

  @override
  String analyticsBodyNutritionTotalWeightLabel(Object unit) {
    return '総重量($unit)';
  }

  @override
  String get analyticsBodyNutritionTotalCaloriesLabel => '総カロリー（kcal）';

  @override
  String analyticsWeightTrendLabel(String unit) {
    return '重量($unit)';
  }

  @override
  String get analyticsCaloriesTrendLabel => 'カロリー(kcal)';

  @override
  String get analyticsInterpretationTitle => '解釈';

  @override
  String get analyticsBodyNutritionConfidenceHighHint =>
      'この範囲のデータ カバレッジは、より信頼性の高いパターン読み取りに十分な強度を持っています。';

  @override
  String get analyticsBodyNutritionConfidenceModerateHint =>
      'データ範囲は中程度です。傾向は便利なコンテキストですが、より強い確信を得るためにログを記録し続けてください。';

  @override
  String get analyticsBodyNutritionConfidenceLowHint =>
      'この範囲のデータ範囲はまだ限られているため、これを初期のコンテキストとして扱ってください。';

  @override
  String get analyticsBodyNutritionLowConfidenceNudge =>
      '自信を高めるために、体重とカロリーを定期的に記録してください。';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceHigh =>
      '解釈の信頼度: 高い。これは、直接の原因を説明するものではなく、傾向のコンテキストとして使用してください。';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceLow =>
      '解釈の信頼度: 低い。これを初期のパターン信号として使用し、追跡を続けます。';

  @override
  String get analyticsCorrelationDisclaimer =>
      'このビューはトレンドのコンテキストを提供します。カロリーの変化が体重の変化を直接引き起こしたということは証明されていません。';

  @override
  String get analyticsInsightStableWeightCaloriesUp =>
      '体重の傾向は安定していますが、平均カロリーは増加しています。';

  @override
  String get analyticsInsightWeightUpCaloriesUp =>
      '平均摂取カロリーの増加に伴い、体重も増加傾向にあります。';

  @override
  String get analyticsInsightCaloriesDownWeightStable =>
      '最近のカロリー削減では、体重の傾向はまだ明確に変化していません。';

  @override
  String get analyticsInsightWeightDownCaloriesDown =>
      '平均摂取カロリーの低下に伴い、体重も減少傾向にあります。';

  @override
  String get analyticsInsightMixedPattern => '体重とカロリーの傾向は混在しており、まだ明確な関係はありません。';

  @override
  String get analyticsInsightNotEnoughData =>
      '意味のある傾向を読み取るには、まだ十分な一貫したデータがありません。';

  @override
  String get analyticsModerateConfidenceLabel => '中程度の信頼パターン';

  @override
  String get analyticsInsufficientConfidenceLabel => 'データの信頼性が不十分';

  @override
  String get analyticsTrendRising => '上昇中';

  @override
  String get analyticsTrendFalling => '落ちる';

  @override
  String get analyticsTrendStable => '安定した';

  @override
  String get analyticsTrendUnclear => '不明瞭';

  @override
  String get analyticsRelationshipAlignedCut => '摂取量の低下と体重の減少は一致します。';

  @override
  String get analyticsRelationshipAlignedBulk => '摂取量の増加と体重の増加は一致しています。';

  @override
  String get analyticsRelationshipStableMaintenance => '体重と摂取量は概ね安定しているようだ。';

  @override
  String get analyticsRelationshipMixed => '信号が混在しているか遅延しています。';

  @override
  String get analyticsRelationshipInsufficient =>
      'パターンを分類するにはまだ十分な一貫した重複がありません。';

  @override
  String analyticsBasedOnDataCoverage(int weightDays, int calorieDays) {
    return '$weightDays 回の体重測定と $calorieDays 回のカロリー日数に基づきます';
  }

  @override
  String get restTimerNotificationTitle => '休憩終了';

  @override
  String get restTimerNotificationBody => '一時停止タイマーが終了しました。次のセットに向けて準備完了。';

  @override
  String get onboardingContinueSetup => 'プロファイルのセットアップ';

  @override
  String get onboardingRestoreFromBackup => 'バックアップから復元';

  @override
  String get onboardingRestoreImporting => 'バックアップをインポートしています...';

  @override
  String get onboardingRestoreSuccess => 'バックアップが正常に復元されました。';

  @override
  String get onboardingRestoreFailed => 'インポートに失敗しました。ファイルを確認して再試行してください。';

  @override
  String get finishWorkoutTitleLabel => 'ワークアウトのタイトル';

  @override
  String get finishWorkoutNotesLabel => '注記 (オプション)';

  @override
  String get finishWorkoutNotesHint => 'トレーニングはどうでしたか？';

  @override
  String get sleepSectionTitle => '寝る';

  @override
  String get sleepSectionSubtitleDayEntry => '一日の概要と詳細のドリルダウン';

  @override
  String get sleepSectionSubtitleAllEntry => '睡眠の日、週、月のビューはこのエントリから利用できます';

  @override
  String get sleepScopeDay => '日';

  @override
  String get sleepScopeWeek => '週';

  @override
  String get sleepScopeMonth => '月';

  @override
  String get sleepWeekSummaryTitle => '週の概要';

  @override
  String get sleepMonthSummaryTitle => '月の概要';

  @override
  String get sleepSleepWindowTitle => 'スリープウィンドウ';

  @override
  String get sleepDailyScoreTitle => '毎日のスコア';

  @override
  String get sleepMonthDailyScoreStatesTitle => '毎日のスコアの状態';

  @override
  String sleepMeanScoreLabel(String value) {
    return '平均スコア: $value';
  }

  @override
  String get sleepHubScoreLabel => '睡眠スコア';

  @override
  String get sleepHubAverageLabel => '平均';

  @override
  String get sleepHubBedtimeLabel => '就寝時間';

  @override
  String get sleepHubInterruptionsLabel => '中断';

  @override
  String sleepHubInterruptionsSummary(int count, String duration) {
    return '$count 回の目覚め、合計 $duration';
  }

  @override
  String sleepWeekdayAvgDurationLabel(String value) {
    return '平日の平均所要時間: $value';
  }

  @override
  String sleepWeekendAvgDurationLabel(String value) {
    return '週末の平均所要時間: $value';
  }

  @override
  String get sleepWeekNoScoredNights => '今週はまだ獲得可能な睡眠日数がありません。';

  @override
  String get sleepMonthNoScoredNights => '今月はまだスコア付き睡眠を利用できません。';

  @override
  String get sleepSettingsSectionTitle => '寝る';

  @override
  String get sleepEnableTrackingTitle => '睡眠追跡を有効にする';

  @override
  String get sleepEnableTrackingSubtitle =>
      'Health Connect / HealthKit から睡眠と夜間の心拍数を読み取る';

  @override
  String get sleepHealthConnectionStatusTitle => 'ヘルス接続ステータス';

  @override
  String get sleepRequestAccessTitle => 'アクセスをリクエストする';

  @override
  String get sleepRequestAccessSubtitle => '睡眠/心拍数の許可をリクエストまたは再リクエストする';

  @override
  String get sleepImportNowTitle => '今すぐ睡眠データをインポートする';

  @override
  String get sleepImportNowSubtitle => '利用可能なすべての睡眠データをインポートします (常時)';

  @override
  String get sleepRawImportsTitle => '未加工の睡眠インポートを表示する';

  @override
  String get sleepRawImportsSubtitle => '最近のヘルスコネクト ペイロードを表示する';

  @override
  String get sleepDataStatusTitle => 'データステータス';

  @override
  String get sleepDataStatusSubtitle =>
      '許可が付与されました。まだスリープが表示されない場合は、以下の手動インポートを実行します。';

  @override
  String get sleepDataStatusSubtitleIos =>
      '接続はアクティブです。データが見つからない場合（インポートされたセッションが 0 の場合）、Apple Health アプリで手動で読み取り権限を確認してください。';

  @override
  String get sleepNoPermissionSubtitle => '睡眠データをインポートするには、睡眠と心拍数の権限が必要です。';

  @override
  String get sleepFeatureUnavailableTitle => '利用できない機能';

  @override
  String get sleepFeatureUnavailableSubtitle =>
      'このデバイスでは睡眠のインポートが利用できないか、ヘルスコネクトがインストールされていません。';

  @override
  String get sleepNoRawImportsFound => '未加工の睡眠インポートはまだ見つかりません。';

  @override
  String get sleepRawImportsSheetTitle => 'Raw 睡眠インポート (最新)';

  @override
  String sleepImportFinishedSessions(int count) {
    return '睡眠のインポートが完了しました ($count セッション)。';
  }

  @override
  String get sleepImportUnavailableCheckPermissions =>
      '睡眠インポートは利用できません。権限を確認してください。';

  @override
  String get sleepStatusChecking => '許可ステータスを確認しています…';

  @override
  String get sleepStatusReady => '準備ができて';

  @override
  String get sleepStatusDenied => '拒否されました';

  @override
  String get sleepStatusPartial => '部分的なアクセス';

  @override
  String get sleepStatusUnavailable => 'このデバイスでは利用できません';

  @override
  String get sleepStatusNotInstalled => 'ヘルスコネクトがインストールされていません';

  @override
  String get sleepStatusTechnicalError => '技術的なエラー';

  @override
  String get sleepConnectHealthDataTitle => '健康データを接続する';

  @override
  String get sleepConnectHealthDataMessage =>
      'HealthKit または Health Connect に接続して睡眠記録をインポートします。';

  @override
  String get sleepPermissionDeniedTitle => '許可が拒否されました';

  @override
  String get sleepPermissionDeniedMessage => 'スリープ許可が拒否されます。設定を開いてアクセスを許可します。';

  @override
  String get sleepSourceUnavailableTitle => 'ソースが利用できません';

  @override
  String get sleepSourceUnavailableMessage =>
      '睡眠データ ソースが利用できないか、このデバイスにインストールされていません。';

  @override
  String get sleepEmptyDayNoData => 'この日の睡​​眠データはありません。';

  @override
  String get sleepEmptyDayConnectMessage =>
      '設定で Health Connect/HealthKit に接続し、最近の睡眠データをインポートします。';

  @override
  String get sleepOpenSettingsButton => '設定を開く';

  @override
  String get sleepImportNowButton => '今すぐインポート';

  @override
  String get sleepImportFinishedRefreshing => '睡眠のインポートが完了しました。爽やかな...';

  @override
  String get sleepImportUnavailableSettingsHint =>
      '睡眠インポートは利用できません。設定で権限を確認してください。';

  @override
  String get sleepTimelineTitle => 'タイムライン';

  @override
  String get sleepTimelineUnavailable => 'この夜のステージタイムラインはありません。';

  @override
  String get sleepSessionTypeCore => 'コアスリープ';

  @override
  String get sleepSessionTypeNap => '昼寝';

  @override
  String get sleepIntervalsDrawerTitle => '睡眠間隔';

  @override
  String get sleepStageDeepLabel => '深い';

  @override
  String get sleepStageLightLabel => 'ライト';

  @override
  String get sleepStageRemLabel => 'レム';

  @override
  String get sleepStageAwakeLabel => '起きている';

  @override
  String get sleepScoreCardTitle => '睡眠の質';

  @override
  String get sleepScoreUnavailableForNight => 'この夜のスコアは利用できません。';

  @override
  String sleepScoreCompletenessLabel(String value) {
    return 'スコアの完全性: $value';
  }

  @override
  String get sleepQualityGood => '良い';

  @override
  String get sleepQualityAverage => '平均';

  @override
  String get sleepQualityPoor => '貧しい';

  @override
  String get sleepQualityUnavailable => '利用不可';

  @override
  String get sleepQualitySubtitleGood => '一夜にして回復は堅調に見えた。';

  @override
  String get sleepQualitySubtitleAverage => '睡眠はまあまあでしたが、改善の余地がありました。';

  @override
  String get sleepQualitySubtitlePoor => '今夜の回復シグナルは弱かった。';

  @override
  String get sleepQualitySubtitleUnavailable => '今夜得点するにはデータが足りません。';

  @override
  String get sleepQualityRegularityNotContributing =>
      '規則性は寄与しませんでした (有効日が 5 日未満)。';

  @override
  String get sleepQualityRegularityPreliminary => '定期性は暫定的なものです (5 ～ 6 日間有効)。';

  @override
  String sleepQualityRegularityStable(int days) {
    return '規則性は安定しています ($days 日)。';
  }

  @override
  String sleepRegularityNightView(int count) {
    return '$count-夜景';
  }

  @override
  String get sleepMetricUnavailable => '利用不可';

  @override
  String get sleepMetricDurationTitle => '間隔';

  @override
  String get sleepMetricHeartRateTitle => '心拍';

  @override
  String get sleepMetricRegularityTitle => '規則性';

  @override
  String get sleepMetricDepthTitle => '深さ';

  @override
  String get sleepMetricInterruptionsTitle => '中断';

  @override
  String get sleepMetricDepthLowConfidence => '低い信頼性';

  @override
  String get sleepMetricDepthStagesAvailable => '利用可能なステージ';

  @override
  String get sleepDurationUnavailable => '期間データは利用できません。';

  @override
  String get sleepDurationStatusWithinTarget => '目標内';

  @override
  String get sleepDurationStatusBelowTarget => '目標を下回る';

  @override
  String get sleepDurationSubtitle => 'この夜の合計睡眠時間。';

  @override
  String get sleepDurationBenchmarkHint =>
      '成人の場合、通常は約 7 ～ 9 時間で最も効果が得られます。このベンチマークは、あなたの夜がその範囲内に位置するかを確認するのに役立ちます。';

  @override
  String get sleepDepthUnavailable => '深度データは利用できません。';

  @override
  String get sleepDepthConfidenceTooLow =>
      'ステージの信頼性が低すぎるため、信頼性の高い深さの内訳が得られません。';

  @override
  String get sleepDepthBreakdownUnavailable => 'この夜のステージ時間の内訳は表示されません。';

  @override
  String get sleepDepthRatingRestorative => '回復力のある';

  @override
  String get sleepDepthRatingLightLeaning => 'ライト寄り';

  @override
  String sleepDepthStageConfidenceLabel(String value) {
    return 'ステージの信頼度: $value';
  }

  @override
  String get sleepDepthSubtitle => '派生したタイムライン セグメントに基づいたステージ配信。';

  @override
  String get sleepInterruptionsUnavailable => '中断データは利用できません。';

  @override
  String get sleepInterruptionsStatusNoneDetected => '何も検出されませんでした';

  @override
  String get sleepInterruptionsStatusDetected => '検出されました';

  @override
  String get sleepInterruptionsSubtitle => '予選のウェイク中断は一晩中。';

  @override
  String get sleepInterruptionsTotalWakeDuration => '合計ウェイク持続時間';

  @override
  String get sleepInterruptionsFootnote => 'このビューには、派生解析出力からの適格な割り込みのみが含まれます。';

  @override
  String get sleepRegularityUnavailable => '規則性データは利用できません。';

  @override
  String sleepRegularityNightRange(int count) {
    return '$count 泊の範囲';
  }

  @override
  String get sleepRegularityStatusSufficientTrend => '十分なトレンドデータ';

  @override
  String get sleepRegularityStatusLimitedTrend => '限られたトレンドデータ';

  @override
  String get sleepRegularitySubtitle => '最近の夜の就寝時間と起床時間帯。';

  @override
  String get sleepRegularityAverageBedtime => '平均就寝時間';

  @override
  String get sleepRegularityAverageWake => '平均航跡';

  @override
  String get sleepHeartRateUnavailable => '睡眠時の心拍数データは利用できません。';

  @override
  String get sleepHeartRateStatusNoSampleSeries => 'この夜のサンプル シリーズはありません';

  @override
  String get sleepHeartRateStatusBaselineNotEstablished => 'ベースラインが確立されていない';

  @override
  String get sleepHeartRateStatusComparisonUnavailable => 'ベースライン比較は利用できません';

  @override
  String get sleepHeartRateStatusBelowBaseline => 'ベースラインを下回る';

  @override
  String get sleepHeartRateStatusAboveBaseline => 'ベースラインより上';

  @override
  String get sleepHeartRateNoSamplesText => 'この夜の持続睡眠心拍数サンプルは利用できません。';

  @override
  String get sleepHeartRateBaselineNotEstablishedText =>
      'ベースラインはまだ確立されていません。これは中立的なものであり、早い段階で予想されています。';

  @override
  String get sleepHeartRateComparisonUnavailableText =>
      '現在、今夜のベースライン比較は利用できません。';

  @override
  String sleepHeartRateDeltaText(String direction, String delta, String unit) {
    return 'あなたの睡眠心拍数は、$delta $unit による $direction ベースラインです。';
  }

  @override
  String get sleepHeartRateDirectionBelow => '下に';

  @override
  String get sleepHeartRateDirectionAbove => 'その上';

  @override
  String get sleepHeartRateComparedBaselineSubtitle => '確立された睡眠ベースラインと比較します。';

  @override
  String get sleepHeartRateNoBaselineSubtitle => 'ベースラインはまだ確立されていません。これは中立です。';

  @override
  String get sleepHeartRateSamplesUnavailable =>
      'この夜の心拍数サンプルは保存されませんでした。トレンドチャートは使用できません。';

  @override
  String sleepHeartRateDashedLineHint(String value, String unit) {
    return '破線はベースライン ($value $unit) を示します。';
  }

  @override
  String get sleepBpmUnit => 'BPM';

  @override
  String get sleepRawImportImportedAt => '輸入先';

  @override
  String get sleepRawImportStatus => '状態';

  @override
  String get sleepRawImportSource => 'ソース';

  @override
  String get sleepRawImportApp => 'アプリ';

  @override
  String get sleepRawImportConfidence => '自信';

  @override
  String get sleepRawImportPayload => 'ペイロード';

  @override
  String get adaptiveBodyweightTargetSectionTitle => '適応体重目標';

  @override
  String get adaptiveRecommendationSettingsSectionTitle => 'おすすめ設定';

  @override
  String get adaptiveGoalDirectionLabel => '目標の方向性';

  @override
  String get adaptiveGoalLose => '体重を減らす';

  @override
  String get adaptiveGoalMaintain => '体重を維持する';

  @override
  String get adaptiveGoalGain => '体重が増える';

  @override
  String adaptiveRatePerWeek(String value, Object unit) {
    return '$value $unit/週';
  }

  @override
  String get adaptivePriorActivityLabel => 'ベースラインの毎日の活動';

  @override
  String get adaptivePriorActivityLow => '低活性';

  @override
  String get adaptivePriorActivityModerate => '中程度の活動';

  @override
  String get adaptivePriorActivityHigh => '高い活性';

  @override
  String get adaptivePriorActivityVeryHigh => '非常に高い活性';

  @override
  String get adaptivePriorActivityHelpIntro =>
      'ベースラインの毎日のアクティビティのみ (追加の有酸素運動とは別に):';

  @override
  String get adaptivePriorActivityHelpLowLine =>
      '低: ほとんどが座って、学生/生徒またはオフィスでの日常生活。';

  @override
  String get adaptivePriorActivityHelpModerateLine => '中程度: 座る、歩く、立つの混合。';

  @override
  String get adaptivePriorActivityHelpHighLine =>
      '高: 立ったり歩いたりすることが多い、または身体を動かす仕事。';

  @override
  String get adaptivePriorActivityHelpVeryHighLine =>
      '非常に高い: 非常に動きの多い日常/仕事で、毎日の活動量が一貫して多い。';

  @override
  String get adaptiveExtraCardioLabel => 'アプリ外での追加の有酸素運動/持久力';

  @override
  String get adaptiveExtraCardioOption0 => '0時間/週';

  @override
  String get adaptiveExtraCardioOption1 => '1時間/週';

  @override
  String get adaptiveExtraCardioOption2 => '2時間/週';

  @override
  String get adaptiveExtraCardioOption3 => '3時間/週';

  @override
  String get adaptiveExtraCardioOption5 => '5時間/週';

  @override
  String get adaptiveExtraCardioOption7Plus => '週7時間以上';

  @override
  String get adaptiveExtraCardioHelp =>
      'Train Libre ワークアウトとして記録されないジョギング、ランニング、サイクリング、水泳、またはその他の持久力セッションを含めます。';

  @override
  String get onboardingAdaptiveGoalTitle => '適応型栄養学の推奨事項';

  @override
  String get onboardingAdaptiveGoalSubtitle =>
      '方向性と週次レートを設定します。控えめな開始推奨事項を作成し、それをログに合わせて調整します。';

  @override
  String get adaptiveRecommendationGenerating => '生成中...';

  @override
  String get adaptiveRecommendationRefresh => '更新の推奨';

  @override
  String get onboardingAdaptiveSummaryEmpty =>
      '目標入力を設定し、更新をタップして開始時の推奨事項をプレビューします。';

  @override
  String get onboardingAdaptiveSummaryTitle => '推奨事項のプレビュー';

  @override
  String onboardingAdaptiveSummaryCalories(int value) {
    return 'カロリー: $value kcal';
  }

  @override
  String onboardingAdaptiveSummaryProtein(int value) {
    return 'タンパク質: $value g';
  }

  @override
  String onboardingAdaptiveSummaryCarbs(int value) {
    return '炭水化物: $value g';
  }

  @override
  String onboardingAdaptiveSummaryFat(int value) {
    return '脂肪: $value g';
  }

  @override
  String onboardingAdaptiveSummaryConfidence(String value) {
    return 'データベース: $value';
  }

  @override
  String get onboardingAdaptiveSummaryApply => '毎日の目標に適用する';

  @override
  String get onboardingAdaptiveSummaryApplied => '毎日の目標に適用される';

  @override
  String get onboardingBodyFatPageTitle => '体脂肪率';

  @override
  String get onboardingBodyFatPageSubtitle =>
      'オプションのステップ: おおよその見積もりがわかっている場合は入力します。';

  @override
  String get onboardingBodyFatOptionalLabel => '体脂肪率 (オプション)';

  @override
  String get onboardingBodyFatOptionalHelper =>
      'オプション: 値がおおよそわかっている場合にのみこれを入力します。空のままでも大丈夫です。最初の推奨事項をパーソナライズするのに役立ちます。';

  @override
  String get onboardingBodyFatHelpAction => 'これはどのように推定すればよいでしょうか?';

  @override
  String get bodyFatGuidanceTitle => '体脂肪率の目安';

  @override
  String get bodyFatGuidanceIntro =>
      '体脂肪率は見た目からは大まかにしか推定できません。これは単なるオリエンテーションであり、正確な診断ではありません。';

  @override
  String get bodyFatGuidanceDisclaimer =>
      '筋肉量、脂肪分布、遺伝、水分保持、姿勢、照明などにより、同じ体脂肪レベルでも外観は大きく異なります。';

  @override
  String get bodyFatGuidanceSexLabel => '参照性別';

  @override
  String bodyFatGuidancePercent(int percent) {
    return '$percent％';
  }

  @override
  String get bodyFatGuidanceMale10 => '非常に無駄がなく、明確な定義。';

  @override
  String get bodyFatGuidanceMale15 => 'アスレチック、目に見えて定義されています。';

  @override
  String get bodyFatGuidanceMale20 => 'スポーティで少し柔らかめ。';

  @override
  String get bodyFatGuidanceMale25 => '鮮明度は低くなり、ウエストとお腹が柔らかくなります。';

  @override
  String get bodyFatGuidanceMale30 => '明らかに柔らかく、丸くなりました。';

  @override
  String get bodyFatGuidanceMale35 => '非常に柔らかく、目に見える鮮明さはほとんどありません。';

  @override
  String get bodyFatGuidanceMale40 => '非常に丸い外観で、目に見える輪郭はありません。';

  @override
  String get bodyFatGuidanceFemale15 => '非常に無駄がなく、非常に明確です。';

  @override
  String get bodyFatGuidanceFemale20 => 'スリムで運動能力が高い。';

  @override
  String get bodyFatGuidanceFemale25 => 'フィット感があり、軽く柔らかい。';

  @override
  String get bodyFatGuidanceFemale30 => '柔らかく、健康的に見える平均的な運動能力から正常範囲。';

  @override
  String get bodyFatGuidanceFemale35 => '明らかに柔らかくなりました。';

  @override
  String get bodyFatGuidanceFemale40 => '全体的に明らかに柔らかく、丸みのある外観になります。';

  @override
  String get adaptiveRecommendationCardTitle => '適応型レコメンデーション';

  @override
  String get adaptiveRecommendationEmptyBody =>
      '約 1 週間体重と栄養を追跡して、週ごとの最初の推奨事項を解除します。';

  @override
  String adaptiveRecommendationGoalLine(String goal, String rate) {
    return '目標: $goal ($rate)';
  }

  @override
  String adaptiveRecommendationMaintenanceLine(int value) {
    return 'メンテナンスの推定値: $value kcal';
  }

  @override
  String adaptiveRecommendationMaintenanceRangeLine(int lower, int upper) {
    return '推定範囲: $lower～$upper kcal';
  }

  @override
  String get adaptiveRecommendationUncertaintyHintNarrow =>
      'おそらくメンテナンス範囲はかなり狭いと思われます。少人数の日勤は通常のことです。';

  @override
  String get adaptiveRecommendationUncertaintyHintModerate =>
      '現時点ではおそらくメンテナンス範囲は中程度です。毎週ある程度の動きは正常です。';

  @override
  String get adaptiveRecommendationUncertaintyHintWide =>
      'おそらくメンテナンスの範囲はまだ広いです。より安定したデータを収集している間は、これは正常な現象です。';

  @override
  String get adaptiveRecommendationStabilizingHint =>
      '私たちはお客様の最近の段階にまだ適応している段階であるため、この見積もりは通常よりも変動する可能性があります。';

  @override
  String adaptiveRecommendationCaloriesValue(int value) {
    return '$value kcal';
  }

  @override
  String adaptiveRecommendationProteinValue(int value) {
    return '$value g';
  }

  @override
  String adaptiveRecommendationCarbsValue(int value) {
    return '$value g';
  }

  @override
  String adaptiveRecommendationFatValue(int value) {
    return '$value g';
  }

  @override
  String adaptiveRecommendationConfidenceLine(String value) {
    return 'データベース: $value';
  }

  @override
  String adaptiveRecommendationDataBasisLine(
      int windowDays, int weightLogs, int intakeDays) {
    return 'データ基準: $windowDays 日、$weightLogs 体重ログ、$intakeDays 摂取日';
  }

  @override
  String adaptiveRecommendationActiveCaloriesLine(int value) {
    return '現在のアクティブカロリー: $value kcal';
  }

  @override
  String adaptiveRecommendationCalculatedAtLine(String value) {
    return '計算値: $value';
  }

  @override
  String adaptiveRecommendationNextDueLine(String value) {
    return '次回の適応推奨事項の期限: $value';
  }

  @override
  String adaptiveRecommendationNextDueShort(String value) {
    return '次の $value';
  }

  @override
  String get adaptiveRecommendationDueNowLine => '新しい適応推奨事項は今週発表される予定です。';

  @override
  String get adaptiveRecommendationDueNowShort => '今週締め切り';

  @override
  String get adaptiveRecommendationMaintenanceLabel => 'メンテナンスの目安';

  @override
  String get adaptiveRecommendationMaintenanceSourceLabel =>
      'プロファイルの以前のログと最近のログ';

  @override
  String get adaptiveRecommendationMaintenanceUnit => 'kcal/日';

  @override
  String get adaptiveRecommendationMacroTargetsLabel => '推奨ターゲット';

  @override
  String get adaptiveRecommendationTargetCaloriesLabel => '目標kcal';

  @override
  String get adaptiveRecommendationDataQualityLabel => 'データ品質';

  @override
  String get adaptiveRecommendationEnergyDensityLabel => '実効エネルギー密度';

  @override
  String adaptiveRecommendationEnergyDensityValue(int value) {
    return '$value kcal/kg';
  }

  @override
  String get adaptiveRecommendationEnergyDensityExplanation =>
      '体重と水分損失の比率に基づく動的な値です';

  @override
  String get adaptiveRecommendationRecalculateNowAction => '今すぐ再計算してください';

  @override
  String get adaptiveRecommendationRecalculating => '再計算中...';

  @override
  String get adaptiveRecommendationApplying => '申請中...';

  @override
  String get adaptiveRecommendationApplyAction => '推奨事項をアクティブな目標に適用する';

  @override
  String get adaptiveRecommendationWarningCalorieFloor =>
      '推奨事項は、最小カロリー安全下限によって制限されます。申請する前に、プロフィール データと最近のログを確認してください。';

  @override
  String get adaptiveRecommendationWarningUnresolvedFood =>
      '一部の栄養エントリはカロリーを完全に解決できませんでした。適用する前に最近のログを確認してください。';

  @override
  String get adaptiveRecommendationWarningLargeAdjustment =>
      '大きな調整が検出されました。申請する前に、最近のログ記録の完了状況を確認してください。';

  @override
  String get adaptiveRecommendationWarningMacroConstrained =>
      'マクロ分割はカロリー予算によって制約されました。目標レートが強すぎるかどうかを確認してください。';

  @override
  String get adaptiveRecommendationWarningConservative =>
      'レビューの提案: データのばらつきのため、推奨事項は保守的に調整されました。';

  @override
  String get adaptiveRecommendationDataBasisHintDefault =>
      '最近のログとその完全性に基づいて構築されています。';

  @override
  String get adaptiveRecommendationDataBasisHintPriorOnly =>
      'プロフィール/以前のデータのみに基づいています。適応的な調整のために、最近の体重と摂取量のログを追加します。';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeight =>
      '最近の体重ログはまばらであるため、傾向の品質は限られています。';

  @override
  String get adaptiveRecommendationDataBasisHintSparseIntake =>
      '最近の取り込みログはまばらであるため、メンテナンスの推論には限界があります。';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeightAndIntake =>
      '最近の体重と摂取量のログがまばらであるため、この推奨事項はより保守的です。';

  @override
  String get adaptiveConfidenceNotEnoughData => 'プロフィール/以前のみ';

  @override
  String get adaptiveConfidenceLow => '限定された最近のログ';

  @override
  String get adaptiveConfidenceMedium => '使用可能な最近のログ';

  @override
  String get adaptiveConfidenceHigh => '強力な最近のログ';

  @override
  String get adaptiveRecommendationRecalculatedSnack => '推奨事項が再計算されました。';

  @override
  String get adaptiveRecommendationAppliedToGoalsSnack => 'アクティブな目標に適用される推奨事項。';

  @override
  String get adaptiveRecommendationNotAvailableSnack => '申請できる推薦はありません。';

  @override
  String get settingsSectionApp => 'アプリ';

  @override
  String get settingsAppearanceSubtitle => 'テーマ、ビジュアルスタイル、ハプティクスを調整する';

  @override
  String get settingsShowSugarInDiaryOverviewTitle => '日記の概要に砂糖を表示';

  @override
  String get settingsShowSugarInDiaryOverviewSubtitle =>
      '上部の毎日の概要セクションに砂糖が表示されます';

  @override
  String get settingsSectionHealthTracking => '健康状態と追跡';

  @override
  String get settingsStepsSubtitle => '追跡、ソースポリシー、およびプロバイダー';

  @override
  String get settingsSleepSubtitle => 'インポート、権限、スリープ状態';

  @override
  String get settingsPulseSubtitle => 'オプトインの脈拍分析と心拍数へのアクセス';

  @override
  String get settingsHealthExportSubtitle =>
      'Apple Health と Health Connect のエクスポートを管理する';

  @override
  String get settingsSectionNutritionAndData => '栄養とデータ';

  @override
  String get settingsSectionSupportAbout => 'サポート / 概要';

  @override
  String get settingsHapticFeedbackTitle => '触覚フィードバック';

  @override
  String get settingsHapticFeedbackSubtitle => '軽い振動で確認とAI待機';

  @override
  String get stepsSettingsEnableTrackingTitle => '歩数追跡を有効にする';

  @override
  String get stepsSettingsEnableTrackingSubtitle =>
      'Apple Health / Health Connect から歩数データを読み取る';

  @override
  String get stepsSettingsSourcePolicyTitle => 'ソースポリシー';

  @override
  String get stepsSettingsSourcePolicyAutoDominant => '自動 (主要なソース)';

  @override
  String get stepsSettingsSourcePolicyAutoDominantSubtitle =>
      '推奨: 重複したインフレを避けるために、1 日あたり 1 つのソースを使用します。';

  @override
  String get stepsSettingsSourcePolicyMaxPerHour => 'マージ (1 時間あたりの最大)';

  @override
  String get stepsSettingsSourcePolicyMaxPerHourSubtitle =>
      '最も高い時間単位のバケットを取得してソースを結合します。';

  @override
  String get stepsSettingsProviderFilterTitle => 'プロバイダーフィルター';

  @override
  String get pulseTitle => '脈';

  @override
  String get pulseChartTitle => '経時的なパルス';

  @override
  String get pulseRangeLabel => '範囲';

  @override
  String get pulseAverageLabel => '平均';

  @override
  String get pulseRestingLabel => '休憩中';

  @override
  String get pulseInsufficientData => '信頼できるグラフを作成するにはパルス サンプルが少なすぎます。';

  @override
  String get pulseMethodNote =>
      '平均パルスは時間重み付けされます。安静時脈拍は、選択した期間のサンプルの下位 20% からの控えめな推定値です。';

  @override
  String pulseSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count サンプル',
      one: '1',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get pulseQualityReady => '良好なカバレッジ';

  @override
  String get pulseQualityLimited => '限られたデータ';

  @override
  String get pulseQualityInsufficient => '非常にまばら';

  @override
  String get pulseQualityNoData => 'データなし';

  @override
  String get pulseNoDataDisabled => 'パルス分析は設定で無効になっています。';

  @override
  String get pulseNoDataPermissionDenied => '脈拍分析を表示するには、心拍数の許可が必要です。';

  @override
  String get pulseNoDataUnavailable => '現在、このデバイスではパルス データを利用できません。';

  @override
  String get pulseNoDataQueryFailed => 'パルスデータを読み取れませんでした。';

  @override
  String get pulseNoDataDefault => 'この期間ではパルス サンプルは見つかりませんでした。';

  @override
  String get pulseSettingsEnableTitle => 'パルス分析を有効にする';

  @override
  String get pulseSettingsEnableSubtitle =>
      'これをオンにした場合のみ、パルスビューの心拍数データを読み取ります。';

  @override
  String get pulseSettingsPermissionTitle => '心拍数へのアクセスを許可する';

  @override
  String get pulseSettingsPermissionSubtitle =>
      'Apple Health または Health Connect を開くと、Train Libre が脈拍サンプルを読み取ることができます。';

  @override
  String get pulseSettingsAnalysisSubtitle =>
      '範囲、時間加重平均、および控えめな安静時脈拍推定値を表示します。医学的な診断ではありません。';

  @override
  String get pulseSettingsPermissionGranted => '心拍数へのアクセスの準備ができました。';

  @override
  String get pulseSettingsPermissionFailed => '心拍数へのアクセスが許可されませんでした。';

  @override
  String get pulseOptInChip => 'オプトイン';

  @override
  String get statisticsPulseDescription => '選択した期間の範囲、時間加重平均、および安静時の脈拍。';

  @override
  String get statisticsPulseOpenCaption => '脈拍分析を開きます';

  @override
  String get healthExportTitle => '健康輸出';

  @override
  String get healthExportAppleHealthTitle => 'Apple Health のエクスポート';

  @override
  String get healthExportHealthConnectTitle => 'ヘルスコネクトのエクスポート';

  @override
  String get healthExportDomainNutritionHydration => '栄養と水分補給';

  @override
  String get healthExportDomainWorkouts => 'トレーニング';

  @override
  String get healthExportStateIdle => 'アイドル状態';

  @override
  String get healthExportStateExporting => '輸出中';

  @override
  String get healthExportStateSuccess => '成功';

  @override
  String get healthExportStateFailed => '失敗した';

  @override
  String get healthExportStateDisabled => '無効';

  @override
  String get healthExportResultComplete => 'エクスポートが完了しました';

  @override
  String get healthExportResultFailed => 'エクスポートに失敗しました';

  @override
  String get healthExportAppleHealthSubtitle =>
      'Train Libre から Apple Health への片道エクスポート';

  @override
  String get healthExportHealthConnectSubtitle =>
      'Train Libre から Health Connect への一方向エクスポート';

  @override
  String get healthExportAppleHealthStatusTitle => 'Apple Health の輸出状況';

  @override
  String get healthExportHealthConnectStatusTitle => 'ヘルスコネクトのエクスポートステータス';

  @override
  String get settingsBaseFoodLanguageTitle => '食品表示言語';

  @override
  String get settingsBaseFoodLanguageSubtitle => '基本食品名に使用する言語を選択します。';

  @override
  String get settingsBaseFoodLanguageFollowApp => 'アプリの言語に合わせる';

  @override
  String get settingsBaseFoodLanguageEnglish => '英語';

  @override
  String get settingsBaseFoodLanguageGerman => 'ドイツ語';

  @override
  String get settingsBaseFoodLanguageFrench => 'フランス語';

  @override
  String get settingsBaseFoodLanguageItalian => 'イタリア語';

  @override
  String get settingsBaseFoodLanguageJapanese => '日本語';

  @override
  String get aiModelLabel => 'モデル';

  @override
  String get autoBackupStoragePickerUnavailable =>
      'ストレージ ピッカーは使用できません。アップデート後はアプリを完全に再起動/再インストールしてください。';

  @override
  String autoBackupFolderPickerFailed(Object error) {
    return 'フォルダーピッカーが失敗しました: $error';
  }

  @override
  String get healthExportPermissionDenied => '許可が拒否されました';

  @override
  String get healthExportAdapterUnavailable => 'アダプターが使用できません';

  @override
  String get healthExportPlatformUnavailable => 'プラットフォームが利用できません';

  @override
  String get healthExportPlatformNotInstalled => 'プラットフォームがインストールされていません';

  @override
  String get healthExportExportDisabled => 'エクスポートが無効になっています';

  @override
  String get onboardingMacrosStepTitle => '主要栄養素';

  @override
  String get onboardingMacrosStepSubtitle => 'あなたの栄養はどのように構成されていますか？';

  @override
  String get statisticsProviderAppleHealth => 'アップルヘルス';

  @override
  String get statisticsProviderHealthConnect => 'ヘルスコネクト';

  @override
  String get statisticsProviderWithings => 'ウィジングズ';

  @override
  String get statisticsProviderGarmin => 'ガーミン';

  @override
  String get statisticsProviderFitbit => 'フィットビット';

  @override
  String get statisticsProviderLocal => '地元';

  @override
  String get unit_milliliters => 'ミリリットル';

  @override
  String get unit_kilograms => 'kg';

  @override
  String get mealEditorHintExample => '例えばチキン丼';

  @override
  String get mealEditorNoIngredientsYet => 'まだありません - 後で公開します';

  @override
  String get foodDetailSavedBaseDb => '保存済み（ベースDB）';

  @override
  String foodDetailExportError(Object error) {
    return 'エクスポート エラー: $error';
  }

  @override
  String get stepsModulePrevious => '前の';

  @override
  String get stepsModuleNext => '次';

  @override
  String get stepsModuleTotalSteps => '合計ステップ数';

  @override
  String get stepsModuleThisWeek => '今週';

  @override
  String get stepsModuleThisMonth => '今月';

  @override
  String stepsModuleUpdated(String time) {
    return '$time を更新しました';
  }

  @override
  String get stepsModuleScopeSwitcherSemantics => 'ステップスコープの切り替え';

  @override
  String get stepsModuleDay => '日';

  @override
  String get stepsModuleWeek => '週';

  @override
  String get stepsModuleMonth => '月';

  @override
  String get stepsModuleHourlyTimeline => '時間ごとのタイムライン';

  @override
  String get stepsModuleTotal => '合計';

  @override
  String get stepsModuleActiveHours => '活動時間';

  @override
  String get stepsModulePeakHour => 'ピーク時間帯';

  @override
  String get stepsModuleAvgPerDay => '平均/日';

  @override
  String get stepsModuleGoalHit => 'ゴールヒット';

  @override
  String get stepsModuleGoalDays => '目標日';

  @override
  String get diarySyncingSteps => 'ステップを同期しています...';

  @override
  String get diaryLoadingSleep => '睡眠を読み込んでいます...';

  @override
  String get unit_milligrams => 'mg';

  @override
  String get scannerPermissionRequired => 'バーコードをスキャンするにはカメラへのアクセスが必要です。';

  @override
  String get scannerPermissionPermanentlyDenied =>
      'カメラへのアクセスは永久に拒否されます。バーコードをスキャンするには設定で有効にしてください。';

  @override
  String get scannerOpenSettings => '設定を開く';

  @override
  String get scannerGrantPermission => '続行';

  @override
  String get scannerAlignInstruction => '赤いレーザーラインの内側にバーコードを水平に配置します。';

  @override
  String get about_train_libre => 'トレイン・リブレについて';

  @override
  String get legal_notice => '法的通知';

  @override
  String get privacy_policy => 'プライバシーポリシー';

  @override
  String get terms_of_service => '利用規約';

  @override
  String get view_in_browser => 'ブラウザで表示';

  @override
  String get legal_document_version => 'ドキュメントバージョン';

  @override
  String get legal_document_last_updated => '最終更新日';

  @override
  String get used_libraries => '使用済みライブラリ';

  @override
  String get licensing_info => 'ライセンス情報';

  @override
  String get project_website => 'プロジェクトのウェブサイト';

  @override
  String get github_repository => 'GitHub リポジトリ';

  @override
  String get health_permission_dialog_title => '健康データとプライバシー';

  @override
  String get health_permission_dialog_body =>
      'Train Libre は、毎日/毎週の統計を表示するために歩数データを読み取る必要があります。データはデバイス上にローカルに残ります。外部サーバーはありません。';

  @override
  String get health_permission_continue => '続く';

  @override
  String get health_permission_not_now => '今じゃない';

  @override
  String get welcome_privacy_title => 'ようこそとプライバシー';

  @override
  String get welcome_privacy_body =>
      'Train Libre を使用すると、当社のプライバシー ポリシーと法的通知に記載されているとおりにデータが処理されることに同意したものとみなされます。';

  @override
  String get i_agree_to_privacy_policy =>
      '私はプライバシー ポリシーに記載されているとおりに自分の健康データを処理することを読み、これに同意します。';

  @override
  String get acceptTermsPrompt => '利用規約に同意します';

  @override
  String get viewTermsInline => '利用規約';

  @override
  String get accept_and_get_started => '同意して始めましょう';

  @override
  String get about_section => 'について';

  @override
  String get legal_section => '法的通知とプライバシー';

  @override
  String get aiSettingsInstructionTitle => 'AI 食事認識の仕組み';

  @override
  String get aiSettingsInstructionBody =>
      'この機能は、AI を使用して食品の画像を分析し、栄養素の推定値を提供します。この機能を使用する場合、画像は選択した AI プロバイダーにのみ送信されます。これは Bring-Your-Own-Key (BYOK) アーキテクチャに依存しており、分析までデータをデバイス上にローカルに保持します。';

  @override
  String get aiSettingsSetupGuideTitle => 'セットアップガイド';

  @override
  String get aiSettingsSetupGuideBody =>
      'この機能を使用するには、AI プロバイダーからの API キーが必要です。現在、開発者とユーザーに無料利用枠を提供している Google Gemini が主な例として使用されています。';

  @override
  String get aiSettingsGetApiKeyButton => 'セットアップガイドを見る';

  @override
  String get legal_document_version_value => '1.2';

  @override
  String get legal_document_last_updated_value => '2026 年 5 月 20 日';

  @override
  String get muscleChest => '胸';

  @override
  String get muscleBack => '背中';

  @override
  String get muscleShoulders => '肩';

  @override
  String get muscleBiceps => '上腕二頭筋';

  @override
  String get muscleTriceps => '上腕三頭筋';

  @override
  String get muscleQuads => '大腿四頭筋';

  @override
  String get muscleHamstrings => 'ハムストリングス';

  @override
  String get muscleGlutes => '臀部';

  @override
  String get muscleCalves => 'ふくらはぎ';

  @override
  String get muscleLowerBack => '腰';

  @override
  String get muscleAbs => '腹筋';

  @override
  String get muscleAdductors => '内転筋';

  @override
  String get muscleForearms => '前腕';

  @override
  String get sleepDetailAnalysisHeader => '詳細な分析';

  @override
  String get sleepMetricDurationLabel => '睡眠時間';

  @override
  String get sleepMetricContinuityLabel => '継続性 (WASO/SE)';

  @override
  String get sleepMetricDepthLabel => '睡眠段階の深さ';

  @override
  String get sleepMetricTimingLabel => '概日タイミング';

  @override
  String get sleepMetricRegularityLabel => '規則性';

  @override
  String get sleepBannerTstBottleneck =>
      '睡眠時間ペナルティが有効です: 合計睡眠量が、同化ホルモンの放出を制限する最適再生時間である 6.5 時間を下回りました。';

  @override
  String get sleepBannerRemBottleneck =>
      'レム睡眠不足ペナルティ: レム睡眠が 60 分未満でした。これにより、神経細胞の回復と精神的な新鮮さが損なわれます。';

  @override
  String get sleepBannerN3Bottleneck =>
      '深い睡眠不足のペナルティ: N3 の深い睡眠が重大に欠如している (<70 分)。物理的な筋肉組織の修復は最適ではありません。';

  @override
  String get sleepBannerTimingBottleneck =>
      '概日位相シフトのペナルティ: 睡眠中は午前 5 時 30 分を過ぎていました。体内時計に逆らって眠ると、睡眠の質が低下し、インスリン感受性が低下します。';

  @override
  String get sleepBannerDefaultPenalty =>
      '臨床的保護ブレーキが作動中: 睡眠量が最適ではなかった (6 時間未満) か、概日タイミング (入眠) が大きくずれていました。合計スコアには制限があります。';

  @override
  String get infoTdeeTitle => '適応型カロリーと TDEE 推定ツール';

  @override
  String get infoTdeeExplanation =>
      'プロフィール、記録された食事、体重の変化に基づいて、1 日の総エネルギー消費量 (TDEE) を推定します。';

  @override
  String get infoTdeeKeyPoints =>
      '• 再帰的傾向モデルを使用して毎日の体重変動を平準化します。\n• ベイジアンにヒントを得たアプローチを使用して、毎週の目標を保守的に調整します。\n• ログの整合性が希薄すぎて、信頼性の高い更新ができない場合に警告を発します。';

  @override
  String get infoTdeeTechnicalTitle => 'ベイジアン再帰フィルタリングと代謝平滑化';

  @override
  String get infoTdeeTechnicalExplanation =>
      'Train Libre は、静的な公式に依存するのではなく、再帰的に推定される動的な「隠れた状態」として代謝をモデル化します。毎日観察される維持量は、体重の変化に対して摂取量を調整することによって計算されます。ログが記録されていない日にプロセス ノイズ係数が追加され、推定の不確実性が増加します。これにより、更新が抑制され、短期的な水の滞留による歪みが防止されます。';

  @override
  String get infoRecoveryTitle => '筋肉回復推定ツール';

  @override
  String get infoRecoveryExplanation =>
      'トレーニング量、強度、失敗への近さに基づいて、筋肉固有の準備状況と回復曲線を推定します。';

  @override
  String get infoRecoveryKeyPoints =>
      '• 重複する筋肉ストレスを考慮します (胸部、上腕三頭筋、肩のベンチプレス数など)。\n• RIR/RPE に基づいて回復速度を調整し、障害が発生するセットのウィンドウを拡張します。\n• 筋肉グループのサイズと代謝特性に基づいてベースライン回復ウィンドウを調整します。';

  @override
  String get infoRecoveryTechnicalTitle => '等価集合疲労および区分的減衰モデル';

  @override
  String get infoRecoveryTechnicalExplanation =>
      '非線形減衰曲線を介して動的準備状況を計算します。ボリューム追跡により、一次筋群と二次筋群の間で負荷が自動的に分散されます。回復速度は障害近接度 (RIR) に基づいて調整され、絶対的な障害に至るまでのセットに対して厳密なタイムライン延長が適用されます。';

  @override
  String get infoScientificReferencesButton => '科学的参考文献とソースを表示';

  @override
  String get infoScientificDisclaimer =>
      'この機能は、確立されたスポーツ科学および代謝モデリングの文献に基づいています。査読付き文献の完全なリストは当社ウェブサイトでご覧いただけます。';

  @override
  String get infoAiMealTitle => 'AIミールキャプチャハブ';

  @override
  String get infoAiMealExplanation =>
      '食事の写真やテキストの説明を構造化された日記エントリに変換し、プライベート製品データベースと照合します。';

  @override
  String get infoAiMealKeyPoints =>
      '• 不正確な説明 (例: 「パンのスライス」) をメートル単位の重量推定値に変換します。\n• AI の提案をオフラインでデバイス上のローカル製品データベースと照合します。\n• 外部サーバーに計算を委任するのではなく、ローカルで栄養を計算します。';

  @override
  String get infoAiMealTechnicalTitle => 'ハイブリッド BYOK AI と Jaro-Winkler マッチング';

  @override
  String get infoAiMealTechnicalExplanation =>
      'Bring-Your-Own-Key (BYOK) プライバシー モデルを使用します。 AI は厳密に提案レイヤーとして機能します。マッチングは、ローカル SQLite データベースに対してトークン化された Jaro-Winkler フィルターを使用してオフラインで実行されます。 AI プロバイダーは、システム プロンプトを介して栄養計算を実行することを固く禁じられています。';

  @override
  String get infoSleepTitle => '睡眠の質 (SHS v3.5)';

  @override
  String get infoSleepExplanation => '量、継続性、深さ、タイミング、毎日の規則性から総合的な睡眠指数を計算します。';

  @override
  String get infoSleepKeyPoints =>
      '• 加重合計を使用して 5 つの臨床的側面を集計します。\n• ウェアラブルが特定の段階や効率データを提供しない場合、要件を自動的にスケールします。\n• 重要なドメイン (REM やディープ スリープなど) が侵害された場合に、合計スコアを制限するソフト キャップ乗数によってユーザーを保護します。';

  @override
  String get infoSleepTechnicalTitle => '加重ベースラインと連続ソフトキャップ';

  @override
  String get infoSleepTechnicalExplanation =>
      '加重線形和を使用して 5 つのプライマリ ドメインを集計します: 期間 (30%)、継続性 (20%)、アーキテクチャ (25%)、タイミング (15%)、および規則性 (10%)。臨床領域が侵害された場合に誤解を招く平均値を防ぐため、睡眠段階または概日タイミングで重大なボトルネックが検出された場合、最終スコアは低下します。';

  @override
  String get tdeeRecalculationNotificationTitle => 'TDEEの再計算';

  @override
  String tdeeRecalculationNotificationBody(
      int calories, int protein, int carbs, int fat) {
    return '新しい 1 日の目標: $calories kcal | ${protein}g プロテイン | ${carbs}g 炭水化物 | ${fat}g 脂肪';
  }

  @override
  String recommendationBannerText(String delta) {
    return '新しい目標が利用可能です ($delta kcal)。';
  }

  @override
  String get recommendationBannerApply => '適用する';

  @override
  String get cancelingAndRollingBack => 'キャンセル中、安全にロールバックしています...';

  @override
  String get sleepSyncTitle => '睡眠履歴を同期中...';

  @override
  String get backupExportTitle => 'バックアップをエクスポート中...';

  @override
  String get backupImportTitle => 'バックアップをインポート中...';

  @override
  String progressImportingNight(int index, int total) {
    return '夜間のデータ $index/$total をインポート中...';
  }

  @override
  String progressExportingTable(String table) {
    return '$table をエクスポート中...';
  }

  @override
  String progressImportingTable(String table) {
    return '$table を復元中...';
  }

  @override
  String get shareDailyLogTitle => '一日の記録';

  @override
  String get shareSleepStartTime => '就寝時刻';

  @override
  String get shareSleepEndTime => '起床時刻';

  @override
  String get shareSleepDeep => '深い睡眠';

  @override
  String get shareSleepLight => '浅い睡眠';

  @override
  String get shareSleepRem => 'レム睡眠';

  @override
  String get shareSleepAwake => '覚醒/中途覚醒';

  @override
  String get shareTotalWater => '水分摂取量合計';

  @override
  String get shareNutritionSummary => '栄養サマリー';

  @override
  String get shareSleepEfficiency => '効率';

  @override
  String get shareSleepRestingHeartRate => '安静時心拍数';

  @override
  String get shareAsTextOrCopy => 'テキストとして共有・コピーする';

  @override
  String get editExercise => 'エクササイズを編集';

  @override
  String exerciseCopyCreated(String exerciseName) {
    return '「$exerciseName」のコピーが作成されました。';
  }

  @override
  String get copySystemExerciseTitle => 'システムエクササイズをコピー';

  @override
  String get copySystemExerciseBody =>
      'このエクササイズはシステム提供のものであるため、直接編集できません。編集するためにカスタムコピーを作成しますか？';

  @override
  String get createCopyAndEdit => 'コピーを作成して編集';

  @override
  String get profileEdit => 'プロフィールを編集';

  @override
  String get selectBirthday => '生年月日を選択';

  @override
  String get exerciseNoteTitle => 'エクササイズのメモ';

  @override
  String get exerciseNoteHint => 'メモやヒントを入力...';

  @override
  String get deleteNoteTooltip => 'メモを削除';

  @override
  String get emptyStateAddFirstExerciseSubtitle =>
      'ログの記録を開始するにはエクササイズを追加してください。';

  @override
  String get syncRoutineTitle => 'ルーティンを更新しますか？';

  @override
  String get syncRoutineSubtitle => '構造または順序の変更が検出されました。';

  @override
  String syncRoutineBody(String routineName) {
    return '現在のワークアウトデータ（エクササイズ、順序、セット）でルーティン「$routineName」を更新しますか？';
  }

  @override
  String get discard => '破棄する';

  @override
  String get updateNow => '今すぐ更新';

  @override
  String get syncRoutineSuccess => 'ルーティンが正常に更新されました！';

  @override
  String syncRoutineError(String error) {
    return 'ルーティンの更新エラー: $error';
  }

  @override
  String createRoutineError(String error) {
    return 'ルーティン作成エラー: $error';
  }

  @override
  String nutritionPerQuantity(String quantity) {
    return '${quantity}gあたりの栄養成分';
  }

  @override
  String get settingsLocalModelName => 'ローカルモデル名';

  @override
  String get settingsCustomBaseUrl => 'カスタムベースURL';

  @override
  String get settingsCustomModelName => 'カスタムモデル名';

  @override
  String get settingsAiFoodNameLanguage => 'AI食品名の言語';

  @override
  String get settingsRequestTimeout => 'リクエストタイムアウト';

  @override
  String settingsSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get semanticsApplyRecommendation => '推奨事項を適用する';

  @override
  String get semanticsDismissBanner => 'バナーを閉じる';

  @override
  String get importedWorkout => 'インポートされたワークアウト';

  @override
  String get unknownExercise => '不明なエクササイズ';

  @override
  String get devExportBaseDb => '基本データベースをエクスポート';

  @override
  String get initCheckingExercises => 'エクササイズを確認中...';

  @override
  String get initLoadingRemoteManifest => 'リモートマニフェストを読み込み中...';

  @override
  String get initExercisesUpToDate => 'エクササイズは最新です';

  @override
  String get initNoDownloadRequired => 'リモートダウンロードは不要です';

  @override
  String get initLoadingExercises => 'エクササイズを読み込み中...';

  @override
  String initDownloadingRemoteCatalog(String version) {
    return 'リモートエクササイズカタログ$versionをダウンロード中...';
  }

  @override
  String get initPreparingImport => 'インポート用ダウンロードを準備中...';

  @override
  String get initExercisesReady => 'エクササイズの準備完了';

  @override
  String initImportingRemoteCatalog(String version) {
    return 'リモートエクササイズカタログ$versionをインポート中...';
  }

  @override
  String initCheckingProductDatabase(String country) {
    return '製品データベースを確認中（$country）...';
  }

  @override
  String get initProductDatabaseUpToDate => '製品データベースは最新です';

  @override
  String get initLoadingProductDatabase => '製品データベースを読み込み中...';

  @override
  String initDownloadingProductBundle(String version) {
    return 'リモート製品バンドル$versionをダウンロード中...';
  }

  @override
  String get initProductDatabaseReady => '製品データベース의準備完了';

  @override
  String initImportingProductBundle(String version) {
    return 'リモート製品バンドル$versionをインポート中...';
  }

  @override
  String get initNoOffBundle =>
      '利用可能なOFFバンドル/リモートがありません。既存のローカルOFFデータは変更されません。';

  @override
  String initEntriesProgress(String processed, String totalCount) {
    return '$processed / $totalCount 件のエントリ';
  }

  @override
  String initUpdateTask(String task) {
    return '$taskを更新';
  }

  @override
  String initCheckingTask(String task) {
    return '$taskを確認中...';
  }

  @override
  String initTaskUpToDate(String task) {
    return '$taskは最新です';
  }

  @override
  String get initInitializing => '初期化中...';

  @override
  String get initPreparation => '準備中...';

  @override
  String get initReady => '準備完了';

  @override
  String yearsOld(int age) {
    return '$age歳';
  }

  @override
  String get customFoodsTitle => 'カスタムフード';

  @override
  String get deleteFoodConfirmTitle => '食品の削除';

  @override
  String get deleteFoodConfirmBody => 'このカスタム食品を削除してもよろしいですか？過去の履歴には影響しません。';

  @override
  String get foodItemDeleted => '食品が削除されました';

  @override
  String get copySystemFoodTitle => 'システム食品のコピー';

  @override
  String get copySystemFoodBody => 'システム食品は直接編集できません。カスタムコピーを作成して編集しますか？';

  @override
  String foodCopyCreated(String name) {
    return 'コピー作成完了: $name';
  }

  @override
  String get nutritionPer100g => '100gあたりの栄養成分';

  @override
  String nutritionPerPortion(int grams) {
    return '1食分（${grams}g）あたりの栄養成分';
  }

  @override
  String get workoutConflictTitle => 'ワークアウトが進行中';

  @override
  String get workoutConflictContent =>
      '現在進行中のワークアウトがあります。再開しますか？それとも破棄して新しいワークアウトを開始しますか？';

  @override
  String get resumeWorkoutButton => 'ワークアウトを再開';

  @override
  String get discardAndStartButton => '破棄して新しく開始';

  @override
  String get profileTapToSetUp => 'タップして設定';

  @override
  String get customLabel => 'カスタム';

  @override
  String get noData => 'データなし';

  @override
  String get languageAuto => '自動';

  @override
  String aiValidationCostEstimation(num tokenCount) {
    return 'コスト: 約$tokenCountトークン';
  }

  @override
  String showAllWithCount(num count) {
    return 'すべて表示 ($count)';
  }

  @override
  String repsCount(num count) {
    return '$count回';
  }

  @override
  String get offDownloadTitle => 'データベースカタログをダウンロード';

  @override
  String get offDownloadBody =>
      'オフラインでの食品検索、バーコードスキャン、およびAI機能を利用するには、ローカルカタログを初期化してください。GitHubから最新のデータベースリリースをダウンロードします。';

  @override
  String get offDownloadConfirm => '今すぐダウンロード';

  @override
  String get offDownloadCancel => '後で';

  @override
  String get offDownloadCTA => 'データベースをダウンロード';

  @override
  String get offPlaceholderText => '栄養機能を使用するにはローカルデータベースカタログが必要です。';

  @override
  String get backupImportLockedTitle => 'データベースカタログが必要です';

  @override
  String get backupImportLockedBody =>
      'バックアップをインポートする前に、データの不整合を防ぐため、エクササイズカタログと栄養カタログの両方を完全にダウンロードして初期化する必要があります。まず必要なデータベースをダウンロードしてください。';

  @override
  String get wgerPlaceholderText => 'エクササイズカタログ機能を使用するにはローカルデータベースカタログが必要です。';

  @override
  String get onboardingRegionTitle => '地域の選択';

  @override
  String get onboardingRegionExplanation =>
      '食料品を購入する国を選択してください。これにより、地域の製品に適した正しいOpen Food Factsデータベースがダウンロードされます。';

  @override
  String get onboardingRegionSettingsHint =>
      'これは後でいつでも「設定 → 栄養 → データベース地域」で変更できます。';

  @override
  String get clearSearch => '検索をクリア';

  @override
  String rollingDaysLabel(int days) {
    return '過去 $days 日間（ローリング）';
  }

  @override
  String get muscleTraps => '僧帽筋';

  @override
  String get muscleObliques => '腹斜筋';
}
