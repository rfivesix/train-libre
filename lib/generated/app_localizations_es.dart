// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get selectDateTitle => 'Seleccionar fecha';

  @override
  String get selectTimeTitle => 'Seleccionar hora';

  @override
  String get selectDateTimeTitle => 'Seleccionar fecha y hora';

  @override
  String get mealDetailChangeDateTime => 'Cambiar fecha y hora';

  @override
  String mealMovedToDate(String date) {
    return 'Comida movida al $date';
  }

  @override
  String get removeTimer => 'Quitar temporizador';

  @override
  String get connectSuperset => 'Agrupar en superserie';

  @override
  String get disconnectSuperset => 'Deshacer superserie';

  @override
  String get connectSupersetShort => 'Superserie';

  @override
  String get disconnectSupersetShort => 'Desvincular';

  @override
  String get noTimerLabel => 'Sin temporizador';

  @override
  String get appTitle => 'Train Libre';

  @override
  String get bannerText => 'Recomendación / Entrenamiento actual';

  @override
  String get calories => 'Calorías';

  @override
  String get water => 'Agua';

  @override
  String get protein => 'Proteínas';

  @override
  String get carbs => 'Carbohidratos';

  @override
  String get fat => 'Grasas';

  @override
  String get steps => 'Pasos';

  @override
  String get daily => 'Diario';

  @override
  String get nowLabel => 'Ahora';

  @override
  String get today => 'Hoy';

  @override
  String get workoutSection => 'Sección de entrenamiento: aún no implementada';

  @override
  String get addMenuTitle => '¿Qué quieres añadir?';

  @override
  String get addFoodOption => 'Añadir alimento';

  @override
  String get addLiquidOption => 'Añadir bebida';

  @override
  String get searchHintText => 'Buscar...';

  @override
  String get mealtypeBreakfast => 'Desayuno';

  @override
  String get mealtypeLunch => 'Comida';

  @override
  String get mealtypeDinner => 'Cena';

  @override
  String get mealtypeSnack => 'Tentempié';

  @override
  String get waterHeader => 'Agua y bebidas';

  @override
  String get openFoodFactsSource => 'Datos de Open Food Facts';

  @override
  String get tabRecent => 'Recientes';

  @override
  String get tabSearch => 'Buscar';

  @override
  String get tabFavorites => 'Favoritos';

  @override
  String get fabCreateOwnFood => 'Alimento personalizado';

  @override
  String get recentEmptyState =>
      'Aquí aparecerán los alimentos que hayas usado recientemente.';

  @override
  String get favoritesEmptyState =>
      'Aún no tienes favoritos.\nToca el icono del corazón en un alimento para verlo aquí.';

  @override
  String get searchInitialHint => 'Introduce un término de búsqueda.';

  @override
  String get searchNoResults => 'No se han encontrado resultados.';

  @override
  String get createFoodScreenTitle => 'Crear alimento personalizado';

  @override
  String get formFieldName => 'Nombre del alimento';

  @override
  String get formFieldBrand => 'Marca (opcional)';

  @override
  String get formSectionMainNutrients => 'Nutrientes principales (por 100 g)';

  @override
  String get formFieldCalories => 'Calorías (kcal)';

  @override
  String get formFieldProtein => 'Proteínas (g)';

  @override
  String get formFieldCarbs => 'Carbohidratos (g)';

  @override
  String get formFieldFat => 'Grasas (g)';

  @override
  String get formSectionOptionalNutrients =>
      'Nutrientes adicionales (opcional, por 100 g)';

  @override
  String get formFieldSugar => 'De los cuales, azúcares (g)';

  @override
  String get formFieldFiber => 'Fibra (g)';

  @override
  String get formFieldKj => 'Kilojulios (kJ)';

  @override
  String get formFieldSalt => 'Sal (g)';

  @override
  String get formFieldSodium => 'Sodio (mg)';

  @override
  String get formFieldCalcium => 'Calcio (mg)';

  @override
  String get buttonSave => 'Guardar';

  @override
  String get validatorPleaseEnterName => 'Introduce un nombre.';

  @override
  String get validatorPleaseEnterNumber => 'Introduce un número válido.';

  @override
  String snackbarSaveSuccess(String foodName) {
    return 'Se ha guardado $foodName.';
  }

  @override
  String get foodDetailSegmentPortion => 'Porción';

  @override
  String get foodDetailSegment100g => '100 g';

  @override
  String get foodDetailEnergyGroup => 'Energía';

  @override
  String get foodDetailMacronutrientsGroup => 'Macronutrientes';

  @override
  String get foodDetailOtherNutrientsGroup => 'Otros nutrientes';

  @override
  String get sugar => 'Azúcar';

  @override
  String get fiber => 'Fibra';

  @override
  String get salt => 'Sal';

  @override
  String get caffeine => 'Cafeína';

  @override
  String get nutritionScreenTitle => 'Análisis nutricional';

  @override
  String get entriesForDateRangeLabel => 'Registros del periodo';

  @override
  String get noEntriesForPeriod =>
      'Todavía no hay registros para este periodo.';

  @override
  String get waterEntryTitle => 'Agua';

  @override
  String get profileScreenTitle => 'Perfil';

  @override
  String get profileDailyGoals => 'Objetivos diarios';

  @override
  String get profileDailyGoalsCL => 'OBJETIVOS DIARIOS';

  @override
  String get snackbarGoalsSaved => 'Objetivos guardados correctamente.';

  @override
  String get measurementsScreenTitle => 'Medidas';

  @override
  String get measurementsEmptyState =>
      'Todavía no hay medidas registradas.\nEmpieza con el botón «+».';

  @override
  String get addMeasurementDialogTitle => 'Añadir medida';

  @override
  String get formFieldMeasurementType => 'Tipo de medida';

  @override
  String formFieldMeasurementValue(Object unit) {
    return 'Valor ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => 'Introduce un valor.';

  @override
  String get measurementWeight => 'Peso corporal';

  @override
  String get measurementFatPercent => 'Grasa corporal';

  @override
  String get measurementNeck => 'Cuello';

  @override
  String get measurementShoulder => 'Hombros';

  @override
  String get measurementChest => 'Pecho';

  @override
  String get measurementLeftBicep => 'Bíceps izquierdo';

  @override
  String get measurementRightBicep => 'Bíceps derecho';

  @override
  String get measurementLeftForearm => 'Antebrazo izquierdo';

  @override
  String get measurementRightForearm => 'Antebrazo derecho';

  @override
  String get measurementAbdomen => 'Abdomen';

  @override
  String get measurementWaist => 'Cintura';

  @override
  String get measurementHips => 'Caderas';

  @override
  String get measurementLeftThigh => 'Muslo izquierdo';

  @override
  String get measurementRightThigh => 'Muslo derecho';

  @override
  String get measurementLeftCalf => 'Pantorrilla izquierda';

  @override
  String get measurementRightCalf => 'Pantorrilla derecha';

  @override
  String get drawerMenuTitle => 'Menú de Train Libre';

  @override
  String get drawerDashboard => 'Panel';

  @override
  String get drawerDataManagement => 'Copia de seguridad';

  @override
  String get drawerMeasurements => 'Medidas';

  @override
  String get dataManagementTitle => 'Copia de seguridad';

  @override
  String get exportCardTitle => 'Exportar datos';

  @override
  String get exportCardDescription =>
      'Guarda todos los registros del diario, favoritos y alimentos personalizados en un único archivo de copia de seguridad.';

  @override
  String get exportCardButton => 'Crear copia de seguridad';

  @override
  String get importCardTitle => 'Importar datos';

  @override
  String get importCardDescription =>
      'Restaura tus datos desde un archivo de copia de seguridad creado anteriormente. AVISO: se sobrescribirán todos los datos guardados actualmente en la aplicación.';

  @override
  String get importCardButton => 'Restaurar copia de seguridad';

  @override
  String get recommendationDefault => '¡Registra tu primera comida!';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return 'Últimos $count días: +$difference kcal por encima del objetivo';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return 'Últimos $count días: $difference kcal por debajo del objetivo';
  }

  @override
  String recommendationOnTarget(Object count) {
    return 'Últimos $count días: objetivo alcanzado ✅';
  }

  @override
  String get recommendationFirstEntry =>
      '¡Genial! Ya has registrado tu primera entrada.';

  @override
  String get dialogConfirmTitle => 'Se requiere confirmación';

  @override
  String get dialogConfirmImportContent =>
      '¿Seguro que quieres restaurar los datos de esta copia de seguridad?\n\nAVISO: se eliminarán permanentemente todas tus entradas, favoritos y alimentos personalizados actuales y se sustituirán por los de la copia.';

  @override
  String get dialogButtonCancel => 'Cancelar';

  @override
  String get dialogButtonOverwrite => 'Sí, sobrescribir todo';

  @override
  String get snackbarNoFileSelected => 'No se ha seleccionado ningún archivo.';

  @override
  String get snackbarImportSuccessTitle => 'Importación completada';

  @override
  String get snackbarImportSuccessContent =>
      'Se han restaurado tus datos. Para que se muestren correctamente, se recomienda reiniciar la aplicación.';

  @override
  String get snackbarButtonOK => 'Aceptar';

  @override
  String get snackbarImportError => 'Error al importar los datos.';

  @override
  String get snackbarExportSuccess =>
      'El archivo de copia de seguridad se ha enviado al sistema. Elige dónde guardarlo.';

  @override
  String get snackbarExportFailed =>
      'La exportación se ha cancelado o ha fallado.';

  @override
  String get profileUserHeight => 'Estatura (cm)';

  @override
  String get workoutRoutinesTitle => 'Rutinas';

  @override
  String get workoutHistoryTitle => 'Historial de entrenamientos';

  @override
  String get workoutHistoryButton => 'Historial';

  @override
  String get emptyRoutinesTitle => 'No hay rutinas';

  @override
  String get emptyRoutinesSubtitle =>
      'Crea tu primera rutina o empieza un entrenamiento sin plan.';

  @override
  String get createFirstRoutineButton => 'Crear primera rutina';

  @override
  String get startEmptyWorkoutButton => 'Entrenamiento libre';

  @override
  String get editRoutineSubtitle =>
      'Toca para editar o empezar el entrenamiento.';

  @override
  String get startButton => 'Empezar';

  @override
  String get addRoutineButton => 'Nueva rutina';

  @override
  String get freeWorkoutTitle => 'Entrenamiento libre';

  @override
  String get finishWorkoutButton => 'Finalizar';

  @override
  String get addSetButton => 'Añadir serie';

  @override
  String get addExerciseToWorkoutButton => 'Añadir ejercicio al entrenamiento';

  @override
  String get lastTimeLabel => 'Última vez';

  @override
  String get setLabel => 'Serie';

  @override
  String kgLabel(String unit) {
    return 'Peso ($unit)';
  }

  @override
  String get repsLabel => 'Repeticiones';

  @override
  String cardioDistanceLabel(String unit) {
    return 'Distancia ($unit)';
  }

  @override
  String get cardioTimeLabel => 'Duración';

  @override
  String get cardioIntensityLabel => 'Intensidad';

  @override
  String get cardioIntensityShortLabel => 'Intens.';

  @override
  String get restTimerLabel => 'Descanso';

  @override
  String get pauseTimerLabel => 'Temporizador de descanso';

  @override
  String get timerOffLabel => 'Desactivado';

  @override
  String get skipButton => 'Omitir';

  @override
  String get appInitStarting => 'Iniciando la aplicación…';

  @override
  String get appInitFailed =>
      'Train Libre no se ha podido iniciar. Tus datos guardados no se han borrado. Vuelve a intentarlo.';

  @override
  String get appInitInitializing => 'Inicializando…';

  @override
  String get appInitFinalizing => 'Finalizando';

  @override
  String get appInitCheckingBackups => 'Comprobando copias de seguridad…';

  @override
  String get appInitSkipDownload => 'Omitir descarga';

  @override
  String get appInitSkippingRemoteDownload => 'Omitiendo descarga remota…';

  @override
  String get emptyHistory => 'Aún no hay entrenamientos completados.';

  @override
  String get workoutDetailsTitle => 'Detalles del entrenamiento';

  @override
  String get workoutHeartRateSectionTitle => 'Frecuencia cardíaca';

  @override
  String get workoutHeartRateAverageLabel => 'Media';

  @override
  String get workoutHeartRateMaxLabel => 'Máx.';

  @override
  String get workoutHeartRateMinLabel => 'Mín.';

  @override
  String get workoutHeartRateQualityReady => 'Cobertura adecuada';

  @override
  String get workoutHeartRateQualityLimited => 'Datos limitados';

  @override
  String get workoutHeartRateQualityInsufficient => 'Muy pocos datos';

  @override
  String get workoutHeartRateQualityNoData => 'Sin datos';

  @override
  String get workoutHeartRateNoDataGeneral =>
      'No se encontraron mediciones de frecuencia cardíaca durante este entrenamiento.';

  @override
  String get workoutHeartRateNoDataPermission =>
      'Se necesita permiso para mostrar la frecuencia cardíaca del entrenamiento.';

  @override
  String get workoutHeartRateNoDataUnavailable =>
      'Los datos de frecuencia cardíaca no están disponibles en este dispositivo.';

  @override
  String get workoutHeartRateNoDataWorkoutNotFinished =>
      'El resumen de frecuencia cardíaca estará disponible al finalizar el entrenamiento.';

  @override
  String get workoutHeartRateNoDataInvalidWindow =>
      'El intervalo del entrenamiento no es válido, así que no se puede analizar la frecuencia cardíaca.';

  @override
  String get workoutHeartRateNoDataQueryFailed =>
      'No se pudieron leer los datos de frecuencia cardíaca de este entrenamiento.';

  @override
  String get workoutHeartRateLimitedChartHint =>
      'No hay suficientes mediciones constantes para mostrar un gráfico fiable.';

  @override
  String workoutHeartRateSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mediciones',
      one: '1 medición',
      zero: 'Sin mediciones',
    );
    return '$_temp0';
  }

  @override
  String get workoutNotFound => 'No se ha encontrado el entrenamiento.';

  @override
  String get totalVolumeLabel => 'Volumen total';

  @override
  String get notesLabel => 'Notas';

  @override
  String get workoutImportTitle => 'Importar entrenamientos';

  @override
  String get workoutImportDescription =>
      'Importa tu historial de entrenamientos desde un archivo CSV o Excel.';

  @override
  String workoutImportPreviewSummary(int workouts, int sets, int duplicates) {
    return 'Se importarán $workouts entrenamientos y $sets series. Se omitirán $duplicates entrenamientos que ya existen.';
  }

  @override
  String get workoutImportHevyInstructions =>
      'Se ha detectado una exportación de Hevy. Expórtala desde Perfil > Ajustes > Exportar e importar datos > Exportar datos > Exportar entrenamientos.';

  @override
  String get workoutImportStrongInstructions =>
      'Se ha detectado una exportación de Strong. En Ajustes, selecciona Exportar datos de Strong en iOS o Exportar datos en Android.';

  @override
  String get workoutImportGenericInstructions =>
      'Se ha detectado un archivo CSV o Excel. Confirma la unidad de peso antes de importar.';

  @override
  String workoutImportPreviewInvalidRows(int count) {
    return 'Se omitirán $count filas con fechas ausentes o no válidas.';
  }

  @override
  String get onboardingWorkoutImportHint =>
      '¿Ya registras tus entrenamientos en otra app? Importa tu historial en el siguiente paso o más tarde desde Ajustes > Datos y copias de seguridad.';

  @override
  String get onboardingWorkoutImportTitle =>
      '¿Quieres traer tu historial de entrenamientos?';

  @override
  String get onboardingWorkoutImportDescription =>
      'Importa tu historial de Hevy, Strong o un archivo CSV. Podrás revisar una vista previa antes de añadir nada.';

  @override
  String get onboardingWorkoutImportButton => 'Elegir archivo de exportación';

  @override
  String get onboardingWorkoutImportLater => 'Lo haré más tarde';

  @override
  String get onboardingWorkoutImportPrivacy =>
      'Tu exportación se procesa en este dispositivo. Si están activadas las estadísticas de uso seudónimas, se puede registrar el estado de la importación; no se incluyen los detalles del entrenamiento.';

  @override
  String get workoutImportButton => 'Importar entrenamientos';

  @override
  String workoutImportSuccess(Object count) {
    return 'Se han importado $count entrenamientos.';
  }

  @override
  String get workoutImportFailed =>
      'No se ha podido importar. Comprueba el archivo.';

  @override
  String get importUnitSelectionTitle => 'Unidad de importación';

  @override
  String get importUnitSelectionDescription =>
      '¿En qué unidad están los datos del archivo?';

  @override
  String get unitMetricLabel => 'Métrico (kg)';

  @override
  String get unitImperialLabel => 'Imperial (lb)';

  @override
  String get excelExportButton => 'Exportación completa de datos (.xlsx)';

  @override
  String get exportWorkoutHistory => 'Historial de entrenamientos';

  @override
  String get exportNutritionDiary => 'Diario de alimentación';

  @override
  String get exportMeasurements => 'Medidas';

  @override
  String get startWorkout => 'Empezar entrenamiento';

  @override
  String get addMeasurement => 'Añadir medida';

  @override
  String get filterToday => 'Hoy';

  @override
  String get filter7Days => '7 días';

  @override
  String get filter30Days => '30 días';

  @override
  String get filter30DaysShort => '30 d';

  @override
  String get filter90DaysShort => '90 d';

  @override
  String get filter180DaysShort => '180 d';

  @override
  String get filter1DayShort => '1 d';

  @override
  String get filter7DaysShort => '7 d';

  @override
  String get filter1MonthShort => '1 m';

  @override
  String get filter3MonthsShort => '3 m';

  @override
  String get filter6MonthsShort => '6 m';

  @override
  String get filter1YearShort => '1 a';

  @override
  String get filterMax => 'MÁX.';

  @override
  String get filterAll => 'Todo';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get showMoreDetails => 'Mostrar más detalles';

  @override
  String get deleteConfirmTitle => 'Confirmar eliminación';

  @override
  String get deleteConfirmContent =>
      '¿Seguro que quieres eliminar esta entrada?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get unsavedChangesTitle => 'Cambios sin guardar';

  @override
  String get unsavedChangesContent =>
      'Hay cambios sin guardar. ¿Quieres guardarlos antes de salir?';

  @override
  String get share => 'Compartir';

  @override
  String get shareWorkout => 'Compartir entrenamiento';

  @override
  String get shareRoutine => 'Compartir rutina';

  @override
  String get shareAsImage => 'Compartir como imagen';

  @override
  String get shareAsText => 'Compartir como texto';

  @override
  String get shareWebLink => 'Compartir enlace web';

  @override
  String get shareFormattedText => 'Compartir como texto con formato';

  @override
  String get sharePortableJson => 'Exportar como JSON / datos';

  @override
  String get shareCopyJson => 'Copiar JSON';

  @override
  String get shareJsonCopied => 'JSON copiado al portapapeles';

  @override
  String get shareJsonFile => 'Compartir archivo JSON';

  @override
  String get shareImportFile => 'Importar archivo JSON compartido';

  @override
  String get shareImportSectionTitle => 'Importar contenido compartido';

  @override
  String get shareImportSectionDescription =>
      'Importa rutinas, planes de entrenamiento, recetas o entrenamientos desde un archivo JSON, o pega texto JSON, por ejemplo, una respuesta de IA. Revisa el contenido antes de importarlo.';

  @override
  String get shareImportPasteButton => 'Pegar texto JSON';

  @override
  String get shareImportPasteTitle => 'Importar texto JSON';

  @override
  String get shareImportPasteDescription =>
      'Pega aquí el contenido JSON completo de Train Libre. Podrás revisarlo antes de guardarlo.';

  @override
  String get shareImportPasteHint => 'Pegar JSON aquí';

  @override
  String get shareImportReplaceWarning =>
      'El contenido abierto se sustituirá por completo. Los entrenamientos completados y las versiones anteriores de los planes se conservarán.';

  @override
  String get shareImportAddWarning =>
      'Este contenido se importará como un elemento nuevo. Las rutinas, los planes de entrenamiento, las recetas y los entrenamientos existentes no cambiarán.';

  @override
  String get shareImportPreview => 'Importar elemento compartido';

  @override
  String get shareImportConfirm => 'Importar a Train Libre';

  @override
  String get shareImportSuccess => 'Importación completada';

  @override
  String get shareImportInvalid =>
      'No se ha podido importar este elemento compartido.';

  @override
  String get shareImportRetry => 'Intentar de nuevo';

  @override
  String get sharePlanWeekly => 'Plan semanal';

  @override
  String get sharePlanSequence => 'Secuencia de entrenamiento';

  @override
  String get shareRestDay => 'Día de descanso';

  @override
  String get shareDay => 'Día';

  @override
  String get shareDays => 'días';

  @override
  String get sharePortions => 'Porciones';

  @override
  String get shareIngredients => 'Ingredientes';

  @override
  String get shareRestSeconds => 'Descanso (segundos)';

  @override
  String get shareTargetMuscles => 'Músculos objetivo';

  @override
  String get shareTotal => 'Total';

  @override
  String get sharedFromTrainLibre => 'Compartido desde Train Libre';

  @override
  String get sharedWithTrainLibre => 'Compartido con Train Libre';

  @override
  String get shareImageSummary => 'Resumen';

  @override
  String get shareImageExercises => 'Ejercicios';

  @override
  String get shareImageMuscleFocus => 'Músculos trabajados';

  @override
  String get shareImageMinimal => 'Minimalista';

  @override
  String get volume => 'Volumen';

  @override
  String moreExercises(int count) {
    return '+ $count ejercicios más';
  }

  @override
  String shareSetNumber(int number) {
    return 'Serie $number';
  }

  @override
  String get repsShort => 'reps';

  @override
  String get shareFailed => 'No se ha podido compartir';

  @override
  String get workoutShareTitle => 'Entrenamiento';

  @override
  String get routineShareTitle => 'Rutina';

  @override
  String get setTypeWarmup => 'Calentamiento';

  @override
  String get setTypeWork => 'Series efectivas';

  @override
  String get setTypeFailure => 'Al fallo';

  @override
  String get setTypeDropset => 'Serie descendente';

  @override
  String get setTypeSuperset => 'Superserie';

  @override
  String get setTypeOther => 'Otro';

  @override
  String get setTypeWarmupSuffix => 'Calentamiento';

  @override
  String get setTypeFailureSuffix => 'Al fallo';

  @override
  String get setTypeDropsetSuffix => 'Descendente';

  @override
  String get setTypeSupersetSuffix => 'Superserie';

  @override
  String get setTypeOtherSuffix => 'Otro';

  @override
  String warmupSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series de calentamiento',
      one: '1 serie de calentamiento',
    );
    return '$_temp0';
  }

  @override
  String workSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series efectivas',
      one: '1 serie efectiva',
    );
    return '$_temp0';
  }

  @override
  String failureSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series al fallo',
      one: '1 serie al fallo',
    );
    return '$_temp0';
  }

  @override
  String dropsetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series descendentes',
      one: '1 serie descendente',
    );
    return '$_temp0';
  }

  @override
  String supersetSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count superseries',
      one: '1 superserie',
    );
    return '$_temp0';
  }

  @override
  String otherSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count otras series',
      one: '1 otra serie',
    );
    return '$_temp0';
  }

  @override
  String warmupCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calentamiento',
      one: '1 calentamiento',
    );
    return '$_temp0';
  }

  @override
  String workCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count efectivas',
      one: '1 serie efectiva',
    );
    return '$_temp0';
  }

  @override
  String failureCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series al fallo',
      one: '1 serie al fallo',
    );
    return '$_temp0';
  }

  @override
  String dropsetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count descendentes',
      one: '1 descendente',
    );
    return '$_temp0';
  }

  @override
  String supersetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count superseries',
      one: '1 superserie',
    );
    return '$_temp0';
  }

  @override
  String otherCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count otras series',
      one: '1 otra serie',
    );
    return '$_temp0';
  }

  @override
  String get shareExercisesLabel => 'ejercicios';

  @override
  String get shareSetsLabel => 'series';

  @override
  String get shareSetLabel => 'serie';

  @override
  String get tabBaseFoods => 'Alimentos básicos';

  @override
  String get baseFoodsEmptyState =>
      'En esta sección pronto encontrarás una selección de alimentos básicos, como frutas, verduras y mucho más.';

  @override
  String get noBrand => 'Sin marca';

  @override
  String get unknown => 'Desconocido';

  @override
  String backupFileSubject(String timestamp) {
    return 'Copia de seguridad de Train Libre - $timestamp';
  }

  @override
  String foodItemSubtitle(String brand, int calories) {
    return '$brand - $calories kcal / 100 g';
  }

  @override
  String foodListSubtitle(int grams, String time) {
    return '$grams g - $time';
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
  String get exerciseCatalogTitle => 'Catálogo de ejercicios';

  @override
  String get filterByMuscle => 'Filtrar por grupo muscular';

  @override
  String get noExercisesFound => 'No se han encontrado ejercicios.';

  @override
  String get noDescriptionAvailable => 'No hay ninguna descripción disponible.';

  @override
  String get filterByCategory => 'Filtrar por categoría';

  @override
  String get edit => 'Editar';

  @override
  String get repsLabelShort => 'reps';

  @override
  String get titleNewRoutine => 'Nueva rutina';

  @override
  String get titleEditRoutine => 'Editar rutina';

  @override
  String get editRoutine => 'Editar rutina';

  @override
  String get validatorPleaseEnterRoutineName =>
      'Introduce un nombre para la rutina.';

  @override
  String get snackbarRoutineCreated =>
      'Rutina creada. Ahora añade algunos ejercicios.';

  @override
  String get snackbarRoutineSaved => 'Rutina guardada.';

  @override
  String get saveAsRoutineButton => 'Guardar como rutina';

  @override
  String get saveAsRoutineTitle => 'Guardar como rutina';

  @override
  String get saveAsRoutinePrompt => 'Introduce un nombre para la nueva rutina:';

  @override
  String get saveAsRoutineSuccess => '¡Rutina creada!';

  @override
  String get snackbarRoutineSavedAction => 'Ver';

  @override
  String get formFieldRoutineName => 'Nombre de la rutina';

  @override
  String get emptyStateAddFirstExercise => 'Añade tu primer ejercicio.';

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series',
      one: '1 serie',
    );
    return '$_temp0';
  }

  @override
  String get fabAddExercise => 'Añadir ejercicio';

  @override
  String get drawerExerciseCatalog => 'Catálogo de ejercicios';

  @override
  String get lastWorkoutTitle => 'Último entrenamiento';

  @override
  String get repeatButton => 'Repetir';

  @override
  String get weightHistoryTitle => 'Historial de peso';

  @override
  String get hideSummary => 'Ocultar resumen';

  @override
  String get showSummary => 'Mostrar resumen';

  @override
  String get exerciseDataAttribution => 'Datos de ejercicios de OpenExerciseDB';

  @override
  String get exerciseDataLicense => 'Licencia de los datos de ejercicios';

  @override
  String get exerciseDataUpstream => 'Derivado en parte de wger';

  @override
  String get duplicate => 'Duplicar';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return '¿Seguro que quieres eliminar definitivamente la rutina «$routineName»?';
  }

  @override
  String get editPauseTimeTitle => 'Editar duración del descanso';

  @override
  String get pauseInSeconds => 'Descanso en segundos';

  @override
  String get editPauseTime => 'Editar descanso';

  @override
  String pauseDuration(int seconds) {
    return 'Descanso de $seconds s';
  }

  @override
  String maxPauseDuration(int seconds) {
    return 'Descansos de hasta $seconds s';
  }

  @override
  String get deleteWorkoutConfirmContent =>
      '¿Seguro que quieres eliminar definitivamente este registro de entrenamiento?';

  @override
  String get removeExercise => 'Quitar ejercicio';

  @override
  String get deleteExerciseConfirmTitle => '¿Quitar ejercicio?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return '¿Seguro que quieres quitar «$exerciseName» de esta rutina?';
  }

  @override
  String get doneButtonLabel => 'Listo';

  @override
  String get setRestTimeButton => 'Definir descanso';

  @override
  String get deleteExerciseButton => 'Eliminar ejercicio';

  @override
  String get deleteCustomExerciseTitle => 'Eliminar ejercicio personalizado';

  @override
  String deleteCustomExerciseBody(String name) {
    return '«$name» se eliminará definitivamente. Esta acción no se puede deshacer.';
  }

  @override
  String get deleteCustomExerciseWithLogsWarning =>
      'Este ejercicio aparece en tu historial de entrenamientos. Se conservarán los registros, pero se quitará el vínculo con el ejercicio.';

  @override
  String get deleteCustomExerciseWithRoutinesWarning =>
      'Este ejercicio se usa en una o varias rutinas. Se quitará de ellas.';

  @override
  String get deleteCustomExerciseSuccess => 'Ejercicio eliminado.';

  @override
  String get restOverLabel => 'Descanso terminado';

  @override
  String get workoutRunningLabel => 'Entrenamiento activo…';

  @override
  String get continueButton => 'Continuar';

  @override
  String get discardButton => 'Descartar';

  @override
  String get workoutStatsTitle => 'Entrenamiento (7 días)';

  @override
  String get workoutsLabel => 'Entrenamientos';

  @override
  String get durationLabel => 'Duración';

  @override
  String get clearDuration => 'Borrar duración';

  @override
  String get volumeLabel => 'Volumen';

  @override
  String get setsLabel => 'Series';

  @override
  String get muscleSplitLabel => 'Distribución muscular';

  @override
  String get snackbar_could_not_open_open_link =>
      'No se ha podido abrir el enlace';

  @override
  String get chart_no_data_for_period =>
      'No hay datos en el gráfico para este periodo';

  @override
  String get amount_in_milliliters => 'Cantidad';

  @override
  String get amount_in_grams => 'Cantidad en gramos';

  @override
  String get meal_label => 'Comida';

  @override
  String get add_to_water_intake => 'Añadir al consumo de agua';

  @override
  String get create_exercise_screen_title => 'Crear ejercicio personalizado';

  @override
  String get exercise_name_label => 'Nombre del ejercicio';

  @override
  String get category_label => 'Categoría';

  @override
  String get description_optional_label => 'Descripción (opcional)';

  @override
  String get primary_muscles_label => 'Músculos principales';

  @override
  String get primary_muscles_hint => 'p. ej., pecho, tríceps';

  @override
  String get secondary_muscles_label => 'Músculos secundarios (opcional)';

  @override
  String get secondary_muscles_hint => 'p. ej., hombros';

  @override
  String get fluidNameLabel => 'Nombre';

  @override
  String get sugarPer100mlLabel => 'Azúcar (g / 100 ml)';

  @override
  String get set_type_normal => 'Normal';

  @override
  String get set_type_warmup => 'Calentamiento';

  @override
  String get set_type_failure => 'Al fallo';

  @override
  String get set_type_dropset => 'Serie descendente';

  @override
  String get set_type_info => 'Información y explicaciones';

  @override
  String get set_type_normal_help =>
      'Serie de trabajo normal. Después del calentamiento, la primera suele ser la serie principal con más carga; cuenta para la progresión.';

  @override
  String get set_type_warmup_help =>
      'Calienta aumentando la carga poco a poco. No cuenta para la progresión.';

  @override
  String get set_type_failure_help =>
      'Serie de trabajo hasta que ya no puedas hacer más repeticiones con buena técnica. Cuenta para la progresión.';

  @override
  String get set_type_dropset_help =>
      'Reduce la carga justo después de una serie de trabajo y continúa. No cuenta para la progresión.';

  @override
  String get set_reps_hint => '8-12';

  @override
  String get data_export_button => 'Exportar';

  @override
  String get data_import_button => 'Importar';

  @override
  String get snackbar_button_ok => 'Aceptar';

  @override
  String get measurement_session_detail_view =>
      'Detalle de la sesión de medición';

  @override
  String get unit_grams => 'g';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get delete_profile_picture_button => 'Eliminar foto de perfil';

  @override
  String get attribution_title => 'Atribución';

  @override
  String get add_liquid_title => 'Añadir bebida';

  @override
  String get add_button => 'Añadir';

  @override
  String get discard_button => 'Descartar';

  @override
  String get continue_workout_button => 'Continuar';

  @override
  String get minimizeWorkoutButton => 'Minimizar';

  @override
  String get soon_available_snackbar =>
      'Esta pantalla estará disponible próximamente';

  @override
  String get start_button => 'Empezar';

  @override
  String get today_overview_text => 'RESUMEN DE HOY';

  @override
  String get quick_add_text => 'AÑADIR RÁPIDO';

  @override
  String get scann_barcode_capslock => 'Escanear código de barras';

  @override
  String get protocol_today_capslock => 'REGISTRO';

  @override
  String get my_plans_capslock => 'MIS PLANES';

  @override
  String get overview_capslock => 'RESUMEN';

  @override
  String get manage_all_plans => 'Gestionar todos los planes';

  @override
  String get workoutSectionStart => 'Empezar';

  @override
  String get workoutSectionMyPlans => 'Mis planes';

  @override
  String get emptyStateWorkoutRoutinesCallout =>
      'Crea tu primera rutina para registrar tus entrenamientos en el gimnasio de forma organizada.';

  @override
  String get workoutSectionHistoryLibrary => 'Historial y biblioteca';

  @override
  String get workoutAllRoutines => 'Todas las rutinas';

  @override
  String get workoutEntryWorkouts => 'Entrenamientos';

  @override
  String get free_training => 'entrenamiento libre';

  @override
  String get my_consistency => 'MI CONSTANCIA';

  @override
  String get calendar_currently_not_available =>
      'La vista de calendario estará disponible próximamente.';

  @override
  String get datePickerCalendar => 'Vista de calendario';

  @override
  String get datePickerWheel => 'Vista de rueda';

  @override
  String get in_depth_analysis => 'ANÁLISIS DETALLADO';

  @override
  String get body_measurements => 'Medidas corporales';

  @override
  String get measurements_description =>
      'Analiza el peso, el porcentaje de grasa corporal y los perímetros.';

  @override
  String get nutrition_description =>
      'Evalúa los macronutrientes, las calorías y las tendencias.';

  @override
  String get training_analysis => 'Análisis del entrenamiento';

  @override
  String get training_analysis_description =>
      'Sigue el volumen, la fuerza y la progresión.';

  @override
  String get load_dots => 'cargando…';

  @override
  String get profile_capslock => 'PERFIL';

  @override
  String get settings_capslock => 'AJUSTES';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsUpdateFoodDatabase => 'Actualizar bases de datos';

  @override
  String get settingsUpdateFoodDatabaseSubtitle =>
      'Busca manualmente actualizaciones de las bases de datos de alimentos y ejercicios.';

  @override
  String get settingsUpdateFoodDatabaseSuccess =>
      'Las bases de datos se han actualizado correctamente.';

  @override
  String settingsUpdateFoodDatabaseError(String error) {
    return 'Error al actualizar las bases de datos: $error';
  }

  @override
  String get settingsGuidedTourSectionTitle => 'Visita guiada';

  @override
  String get settingsRestartAppTourTitle => 'Volver a iniciar la visita guiada';

  @override
  String get settingsRestartAppTourSubtitle =>
      'Vuelve a recorrer la breve guía de la aplicación.';

  @override
  String get my_goals => 'Mis objetivos';

  @override
  String get my_goals_description =>
      'Ajusta las calorías, los macronutrientes y el agua.';

  @override
  String get backup_and_import => 'Copia de seguridad e importación de datos';

  @override
  String get backup_and_import_description =>
      'Crea copias de seguridad, restaura e importa datos.';

  @override
  String get feedbackReportSettingsSectionTitle => 'Ayuda';

  @override
  String get feedbackReportSettingsEntryTitle => 'Enviar comentarios';

  @override
  String get feedbackReportSettingsEntrySubtitle =>
      'Crea un informe de diagnóstico en tu dispositivo y elige cómo compartirlo.';

  @override
  String get about_and_legal_capslock => 'ACERCA DE Y AVISOS LEGALES';

  @override
  String get feedbackReportScreenTitle => 'Informe de comentarios';

  @override
  String get feedbackReportPrivacyTitle => 'Tu privacidad, primero';

  @override
  String get feedbackReportPrivacyBody =>
      'El informe se genera localmente en tu dispositivo. No se envía nada automáticamente. Al copiarlo, guardarlo, compartirlo o enviarlo por correo, solo se incluye lo que ves en la vista previa. El correo abre un borrador dirigido a feedback@schotte.me para que puedas revisarlo, editarlo o cancelarlo antes de enviarlo.';

  @override
  String get feedbackReportOptionalNoteTitle => 'Nota opcional';

  @override
  String get feedbackReportOptionalNoteLabel => 'Tu nota (opcional)';

  @override
  String get feedbackReportOptionalNoteHint =>
      'Describe qué ocurrió, qué esperabas y qué pasos permiten reproducirlo.';

  @override
  String get feedbackReportIncludeSectionTitle => 'Incluir en el informe';

  @override
  String get feedbackReportIncludeAdaptiveNutrition =>
      'Diagnóstico de nutrición adaptativa';

  @override
  String get feedbackReportIncludeBackupRestore =>
      'Diagnóstico de copias y restauración';

  @override
  String get feedbackReportIncludePerformance =>
      'Registro de rendimiento (tiempos de fotograma)';

  @override
  String get settingsPerformanceLogTitle => 'Registro de rendimiento';

  @override
  String get settingsPerformanceLogSubtitle =>
      'Muestra en qué pantallas se pierden fotogramas';

  @override
  String get performanceLogIntro =>
      'Registra en este dispositivo la frecuencia de actualización y los fotogramas perdidos. Se ejecuta en segundo plano y los datos solo salen del dispositivo si compartes el registro.';

  @override
  String get performanceLogDeviceLabel => 'Dispositivo';

  @override
  String get performanceLogDisplayLabel => 'Pantalla';

  @override
  String get performanceLogFramesLabel => 'Fotogramas';

  @override
  String get performanceLogJankLabel => 'Fotogramas perdidos';

  @override
  String get performanceLogStallsLabel => 'Bloqueos';

  @override
  String get performanceLogCopyButton => 'Copiar';

  @override
  String get performanceLogShareButton => 'Compartir';

  @override
  String get performanceLogCopiedSnack => 'Registro de rendimiento copiado.';

  @override
  String get performanceLogScreensSection => 'Pantallas';

  @override
  String get performanceLogEmpty => 'Aún no se han registrado fotogramas.';

  @override
  String get performanceLogStallsSection =>
      'Bloqueos (hilo de interfaz bloqueado)';

  @override
  String get performanceLogStartupSection => 'Inicio y reanudación';

  @override
  String get performanceLogStartupEmpty => 'Aún no se ha medido el inicio.';

  @override
  String get performanceLogStartupCold => 'Inicio en frío';

  @override
  String get performanceLogStartupResume => 'Reanudación';

  @override
  String get performanceLogStartupUnattributed =>
      'Framework y primer renderizado';

  @override
  String get performanceLogSevereLabel => 'grave';

  @override
  String get performanceLogPauseTitle => 'Pausar registro';

  @override
  String get performanceLogResetTitle => 'Restablecer mediciones';

  @override
  String get performanceLogResetDialogBody =>
      'Se eliminarán todas las estadísticas de fotogramas y los bloqueos registrados. Después, la grabación volverá a empezar desde cero.';

  @override
  String get performanceLogResetConfirm => 'Restablecer';

  @override
  String get performanceLogResetDoneSnack => 'Mediciones restablecidas.';

  @override
  String get feedbackReportIncludeUserNote => 'Nota del usuario';

  @override
  String get feedbackReportGeneratePreview => 'Generar vista previa';

  @override
  String get feedbackReportPreviewTitle => 'Vista previa';

  @override
  String get feedbackReportActionCopy => 'Copiar';

  @override
  String get feedbackReportActionSave => 'Guardar';

  @override
  String get feedbackReportActionShare => 'Compartir';

  @override
  String get feedbackReportActionEmail => 'Correo electrónico';

  @override
  String get feedbackReportCopied => 'Informe copiado al portapapeles.';

  @override
  String get feedbackReportSavedToTemporaryFile =>
      'Informe guardado en un archivo temporal.';

  @override
  String get feedbackReportShareCompleted =>
      'Se ha abierto el menú para compartir.';

  @override
  String get feedbackReportShareCanceled =>
      'Se ha cancelado el uso compartido.';

  @override
  String get feedbackReportEmailOpenFailed =>
      'No se ha podido abrir la aplicación de correo.';

  @override
  String get feedbackReportEmailSubject =>
      'Informe de comentarios de Train Libre';

  @override
  String get feedbackReportReportTitle =>
      'Informe de comentarios de Train Libre';

  @override
  String get feedbackReportReportGeneratedAt => 'Generado';

  @override
  String get feedbackReportReportAppVersion => 'Versión de la aplicación';

  @override
  String get feedbackReportReportBuildNumber => 'Número de compilación';

  @override
  String get feedbackReportReportPlatform => 'Plataforma';

  @override
  String get feedbackReportReportOsVersion => 'Versión del sistema operativo';

  @override
  String get feedbackReportUnavailable => 'no disponible';

  @override
  String get feedbackReportSectionUserNote => 'Nota del usuario';

  @override
  String get feedbackReportSectionAdaptiveNutrition =>
      'Diagnóstico de nutrición adaptativa';

  @override
  String get feedbackReportSectionBackupRestore =>
      'Diagnóstico de copias y restauración';

  @override
  String get attribution_and_license => 'Atribución y licencias';

  @override
  String get data_from_off_and_wger => 'Datos de Open Food Facts y wger.';

  @override
  String get app_version => 'Versión de la aplicación';

  @override
  String get all_measurements => 'TODAS LAS MEDIDAS';

  @override
  String get all_measurements_no_cap => 'Todas las medidas';

  @override
  String get date_and_time_of_measurement => 'Fecha y hora de la medición';

  @override
  String get onbWelcomeTitle => 'Te damos la bienvenida a Train Libre';

  @override
  String get onbWelcomeBody =>
      'Empieza por fijar tus objetivos personales para orientar tu entrenamiento y alimentación.';

  @override
  String get onbTrackTitle => 'Regístralo todo';

  @override
  String get onbTrackBody =>
      'Registra tu alimentación, entrenamientos y medidas en un solo lugar.';

  @override
  String get onbPrivacyTitle => 'Sin conexión y con privacidad';

  @override
  String get onbPrivacyBody =>
      'Train Libre guarda los datos principalmente en el dispositivo. Las funciones opcionales pueden enviarlos o copiarlos fuera de él.';

  @override
  String get onbFinishTitle => 'Todo listo';

  @override
  String get onbFinishBody =>
      'Ya puedes explorar la aplicación. Puedes cambiar los ajustes cuando quieras.';

  @override
  String get onbFinishCta => '¡Vamos!';

  @override
  String get onbShowTutorialAgain => 'Volver a ver la introducción';

  @override
  String get appTourOfferTitle => '¿Quieres conocer la aplicación?';

  @override
  String get appTourOfferBody =>
      'Descubre brevemente las principales secciones. Puedes saltarte la visita y volver a iniciarla más tarde desde Ajustes.';

  @override
  String get appTourOfferStart => 'Iniciar visita';

  @override
  String get appTourOfferSkip => 'Ahora no';

  @override
  String get appTourSkip => 'Omitir';

  @override
  String get appTourNext => 'Siguiente';

  @override
  String get appTourDone => 'Listo';

  @override
  String get appTourStepNavigationTitle => 'Navegación principal';

  @override
  String get appTourStepNavigationBody =>
      'Usa las pestañas inferiores para ir al Diario, Entrenamiento, Estadísticas y Nutrición.';

  @override
  String get appTourStepQuickActionsTitle => 'Acciones rápidas';

  @override
  String get appTourStepQuickActionsBody =>
      'Pulsa el botón + para añadir rápidamente alimentos, líquidos, medidas, entrenamientos y mucho más.';

  @override
  String get appTourStepDiaryTitle => 'Diario';

  @override
  String get appTourStepDiaryBody =>
      'El Diario ofrece un resumen del día. Registra comidas, hidratación y suplementos, y consulta tu día de un vistazo.';

  @override
  String get appTourStepWorkoutTitle => 'Entrenamiento';

  @override
  String get appTourStepWorkoutBody =>
      'En Entrenamiento puedes iniciar sesiones, gestionar rutinas y consultar tu historial.';

  @override
  String get appTourStepNutritionTitle => 'Nutrición';

  @override
  String get appTourStepNutritionBody =>
      'En Nutrición puedes planificar comidas, revisar objetivos y usar herramientas como las plantillas de comidas.';

  @override
  String get appTourStepStatisticsTitle => 'Estadísticas';

  @override
  String get appTourStepStatisticsBody =>
      'Las Estadísticas muestran tendencias y progresos para que veas cómo cambian tus datos con el tiempo.';

  @override
  String get appTourRestartTitle => 'Ver la visita guiada';

  @override
  String get appTourRestartSubtitle =>
      'Repasa la introducción y las funciones principales';

  @override
  String get onbSetGoalsCta => 'Fijar objetivos';

  @override
  String get onbHeaderTitle => 'Tutorial';

  @override
  String get onbHeaderSkip => 'Omitir';

  @override
  String get onbBack => 'Atrás';

  @override
  String get onbNext => 'Siguiente';

  @override
  String get onbGuideTitle => 'Cómo funciona este tutorial';

  @override
  String get onbGuideBody =>
      'Desliza entre las pantallas o pulsa Siguiente. Prueba las funciones con los botones. Puedes terminar cuando quieras con Omitir.';

  @override
  String get onbCtaOpenNutrition => 'Abrir Nutrición';

  @override
  String get onbCtaLearnMore => 'Más información';

  @override
  String get onbBadgeDone => 'Listo';

  @override
  String get onbTipSetGoals => 'Consejo: ajusta primero tus objetivos';

  @override
  String get onbTipAddEntry => 'Consejo: añade un registro hoy';

  @override
  String get onbTipLocalControl =>
      'Tú controlas todos tus datos en el dispositivo';

  @override
  String get onbTrackHowBody =>
      'Cómo registrar tu alimentación:\n• Abre la pestaña Alimentos.\n• Pulsa el botón +.\n• Busca productos o escanea un código de barras.\n• Ajusta la porción y la hora.\n• Guarda el registro en tu diario.';

  @override
  String get onbMeasureTitle => 'Registra tus medidas';

  @override
  String get onbMeasureBody =>
      'Cómo añadir medidas:\n• Abre la pestaña Estadísticas.\n• Pulsa el botón +.\n• Elige una medida (por ejemplo, peso, cintura o grasa corporal).\n• Introduce el valor y la hora.\n• Guarda el registro en tu historial.';

  @override
  String get onbTipMeasureToday =>
      'Consejo: añade tu peso de hoy para empezar el gráfico';

  @override
  String get onbTrainTitle => 'Entrena con rutinas';

  @override
  String get onbTrainBody =>
      'Crea una rutina e inicia un entrenamiento:\n• Abre la pestaña Entrenamiento.\n• Pulsa Crear rutina para añadir ejercicios y series.\n• Guarda la rutina.\n• Pulsa Empezar o elige «Empezar entrenamiento libre».';

  @override
  String get onbTipStartWorkout =>
      'Consejo: inicia un entrenamiento libre para registrar una sesión rápida';

  @override
  String get unitsSection => 'Unidades';

  @override
  String get weightUnit => 'Unidades de peso';

  @override
  String get lengthUnit => 'Unidad de longitud';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get noFavorites => 'No hay favoritos';

  @override
  String get nothingTrackedYet => 'Aún no hay registros';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'No se ha encontrado ningún producto con el código de barras «$barcode».';
  }

  @override
  String get categoryHint => 'p. ej., pecho, espalda, piernas…';

  @override
  String get validatorPleaseEnterCategory => 'Introduce una categoría.';

  @override
  String get dialogEnterPasswordImport =>
      'Introduce la contraseña para importar la copia de seguridad';

  @override
  String get dataManagementBackupTitle => 'Copia de seguridad de Train Libre';

  @override
  String get dataManagementBackupDescription =>
      'Guarda o restaura tus registros y las imágenes de vista previa de Train Libre. Las fotos originales permanecen en este dispositivo.';

  @override
  String get exportEncrypted => 'Exportar cifrado';

  @override
  String get dialogPasswordForExport =>
      'Contraseña para la exportación cifrada';

  @override
  String get snackbarEncryptedBackupShared =>
      'Copia de seguridad cifrada compartida.';

  @override
  String get exportFailed => 'No se ha podido exportar.';

  @override
  String get csvExportTitle => 'Exportar datos';

  @override
  String get csvExportDescription =>
      'Exporta los registros seleccionados como archivos CSV o todos tus datos personales tabulares en un libro de Excel. Para restaurar datos, usa una copia de seguridad.';

  @override
  String get snackbarSharingNutrition =>
      'Compartiendo el diario de alimentación…';

  @override
  String get snackbarExportFailedNoEntries =>
      'No se ha podido exportar. Puede que aún no haya registros.';

  @override
  String get snackbarSharingMeasurements => 'Compartiendo las medidas…';

  @override
  String get snackbarSharingWorkouts =>
      'Compartiendo el historial de entrenamientos…';

  @override
  String get mapExercisesTitle => 'Asignar ejercicios';

  @override
  String get mapExercisesDescription =>
      'Asigna los nombres desconocidos de tus registros a ejercicios de wger.';

  @override
  String get mapExercisesButton => 'Empezar asignación';

  @override
  String get autoBackupTitle => 'Copias de seguridad automáticas';

  @override
  String get autoBackupDescription =>
      'Guarda copias periódicamente en esta carpeta. Carpeta actual:';

  @override
  String get autoBackupDefaultFolder =>
      'Documentos de la aplicación/Copias de seguridad (predeterminada)';

  @override
  String get autoBackupChooseFolder => 'Elegir carpeta';

  @override
  String get autoBackupCopyPath => 'Copiar ruta';

  @override
  String get autoBackupRunNow => 'Comprobar e iniciar la copia automática';

  @override
  String get icloudAutoBackupTitle => 'Copia automática en iCloud';

  @override
  String get icloudAutoBackupDescription =>
      'Sincroniza automáticamente la base de datos con iCloud Drive cuando la aplicación pasa a segundo plano. Podrás restaurar tus datos en un dispositivo nuevo o después de reinstalar la aplicación.';

  @override
  String get icloudBackupNow => 'Guardar copia en iCloud ahora';

  @override
  String get icloudBackupUploading => 'Subiendo…';

  @override
  String get icloudBackupSuccess => 'Copia de seguridad subida correctamente.';

  @override
  String get icloudBackupFailed =>
      'No se ha podido crear la copia. Comprueba la conexión con iCloud.';

  @override
  String get autoBackupRequestAccessSubtitle =>
      'Para guardar copias automáticamente, Train Libre necesita acceso a una carpeta que elijas. Las copias se guardarán allí.';

  @override
  String get snackbarAutoBackupSuccess =>
      'Copia de seguridad automática completada.';

  @override
  String get snackbarAutoBackupFailed =>
      'La copia de seguridad automática ha fallado o se ha cancelado.';

  @override
  String get localDataDeletionCardTitle => 'Datos locales de la aplicación';

  @override
  String get localDataDeletionCardDescription =>
      'Eliminar registros y ajustes locales de la aplicación. Pueden quedar algunas copias.';

  @override
  String get deleteAllLocalAppData =>
      'Eliminar todos los datos locales de la aplicación';

  @override
  String get localDataDeletionConfirmTitle =>
      '¿Eliminar todos los datos locales?';

  @override
  String get localDataDeletionConfirmBody =>
      'El restablecimiento elimina muchos registros y ajustes locales, pero pueden quedar algunos adjuntos o configuraciones. No elimina copias de seguridad, exportaciones, datos de plataformas de salud ni datos de proveedores externos.';

  @override
  String get localDataDeletionTypeDeleteLabel =>
      'Escribe DELETE para confirmar';

  @override
  String get localDataDeletionSuccessTitle => 'Datos locales eliminados';

  @override
  String get localDataDeletionSuccessBody =>
      'Train Libre volverá a su configuración inicial.';

  @override
  String get localDataDeletionFailed =>
      'No se han podido eliminar los datos locales. Vuelve a intentarlo.';

  @override
  String get noUnknownExercisesFound =>
      'No se han encontrado ejercicios desconocidos';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return 'Carpeta para copias automáticas:\n$path';
  }

  @override
  String get snackbarPathCopied => 'Ruta copiada';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get involvedMuscles => 'Músculos implicados';

  @override
  String get primaryLabel => 'Principales:';

  @override
  String get secondaryLabel => 'Secundarios:';

  @override
  String get noMusclesSpecified => 'No se han indicado músculos.';

  @override
  String get frontLabel => 'Frontal';

  @override
  String get backLabel => 'Posterior';

  @override
  String get noSelection => 'Ninguna selección';

  @override
  String get selectButton => 'Seleccionar';

  @override
  String get applyingChanges => 'Aplicando cambios…';

  @override
  String get applyMapping => 'Aplicar asignación';

  @override
  String get mappingSuggestions => 'Sugerencias';

  @override
  String get mappingSuggestionsEmpty =>
      'No se han encontrado ejercicios coincidentes';

  @override
  String get personalData => 'Datos personales';

  @override
  String get personalDataCL => 'DATOS PERSONALES';

  @override
  String get macroDistribution => 'Distribución de macronutrientes';

  @override
  String get dialogFinishWorkoutBody =>
      '¿Seguro que quieres finalizar este entrenamiento?';

  @override
  String get attributionText =>
      'Esta aplicación utiliza datos de fuentes externas:\n\n● Datos de ejercicios de OpenExerciseDB (github.com/rfivesix/OpenExerciseDB), con licencia CC BY-SA 4.0 y derivados en parte del proyecto wger (wger.de).\n\n● Base de datos de alimentos de Open Food Facts (openfoodfacts.org), disponible bajo la Open Database License (ODbL).\n\n● Datos de nutrientes de alimentos básicos del Bundeslebensmittelschlüssel (BLS) 4.0, publicado por el Max Rubner-Institut, DOI 10.25826/Data20251217-134202-0, con licencia CC BY 4.0. Train Libre añade traducciones, alias de búsqueda y categorías.';

  @override
  String get errorRoutineNotFound => 'No se ha encontrado la rutina';

  @override
  String get workoutHistoryEmptyTitle => 'Tu historial está vacío';

  @override
  String get workoutSummaryTitle => 'Entrenamiento completado';

  @override
  String get workoutSummaryExerciseOverview => 'Resumen de ejercicios';

  @override
  String get nutritionDiary => 'Diario';

  @override
  String get detailedNutrientGoals => 'Nutrientes detallados';

  @override
  String get detailedNutrientGoalsCL => 'NUTRIENTES DETALLADOS';

  @override
  String get supplementTrackerTitle => 'Seguimiento de suplementos';

  @override
  String get supplementTrackerDescription =>
      'Controla tus objetivos, límites y tomas.';

  @override
  String get createSupplementTitle => 'Crear suplemento';

  @override
  String get supplementNameLabel => 'Nombre del suplemento';

  @override
  String get defaultDoseLabel => 'Dosis predeterminada';

  @override
  String get unitLabel => 'Unidad';

  @override
  String get dailyGoalLabel => 'Objetivo diario (opcional)';

  @override
  String get dailyLimitLabel => 'Límite diario (opcional)';

  @override
  String get dailyProgressTitle => 'Progreso diario';

  @override
  String get todaysLogTitle => 'Registro de hoy';

  @override
  String get logIntakeTitle => 'Registrar toma';

  @override
  String get emptySupplementGoals =>
      'Define objetivos o límites para tus suplementos y consulta aquí tu progreso.';

  @override
  String get emptySupplementLogs => 'Aún no has registrado ninguna toma hoy.';

  @override
  String get doseLabel => 'Dosis';

  @override
  String get settingsDescription => 'Tema, unidades, datos y más';

  @override
  String get settingsAppearance => 'Aspecto';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get caffeinePrompt => 'Cafeína (opcional)';

  @override
  String get caffeineUnit => 'mg por 100 ml';

  @override
  String get profile => 'Perfil';

  @override
  String get measurementWeightCapslock => 'PESO CORPORAL';

  @override
  String get diary => 'Diario';

  @override
  String get analysis => 'Análisis';

  @override
  String get yesterday => 'Ayer';

  @override
  String get dayBeforeYesterday => 'Hace dos días';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get workout => 'Entrenamiento';

  @override
  String get addFoodTitle => 'añadir alimento';

  @override
  String get nutritionExplorerTitle => 'Explorador de nutrición';

  @override
  String get myMeals => 'Mis recetas';

  @override
  String get myMealsCL => 'MIS RECETAS';

  @override
  String get nutritionSectionTodayInFocus => 'Hoy en detalle';

  @override
  String get nutritionSectionMyMeals => 'Mis recetas';

  @override
  String get emptyStateNutritionRecipesCallout =>
      'Crea tu primera receta para registrar rápidamente tus comidas habituales.';

  @override
  String get nutritionSectionToolsAndLibrary => 'Herramientas y biblioteca';

  @override
  String get supplement_caffeine => 'Cafeína';

  @override
  String get supplement_creatine_monohydrate => 'Creatina monohidrato';

  @override
  String get manageSupplementsTitle => 'Gestionar suplementos';

  @override
  String get deleted => 'eliminado';

  @override
  String get operationNotAllowed => 'Esta operación no está permitida';

  @override
  String get emptySupplements => 'No hay suplementos disponibles';

  @override
  String get undo => 'Deshacer';

  @override
  String get deleteSupplementConfirm =>
      '¿Seguro que quieres eliminar este suplemento? Se perderá todo el historial.\n\nConsejo: puedes dejar de hacerle seguimiento editando el suplemento.';

  @override
  String get editSupplementLogTitle => 'Editar registro';

  @override
  String get deleteSupplementLogConfirm =>
      '¿Seguro que quieres eliminar este registro?';

  @override
  String get fieldRequired => 'Obligatorio';

  @override
  String get unitNotSupported => 'Unidad no compatible.';

  @override
  String get caffeineUnitLocked => 'La unidad de la cafeína es fija: mg.';

  @override
  String get caffeineMustBeMg => 'La cafeína debe registrarse en mg.';

  @override
  String get tabCatalogSearch => 'Catálogo';

  @override
  String get tabMeals => 'Recetas';

  @override
  String get emptyCategory => 'No hay registros';

  @override
  String get searchSectionBase => 'Alimentos básicos';

  @override
  String get searchSectionOther => 'Otros resultados';

  @override
  String get mealsComingSoonTitle => 'Recetas (próximamente)';

  @override
  String get mealsComingSoonBody =>
      'Pronto podrás crear tus propias recetas con varios alimentos.';

  @override
  String get mealsEmptyTitle => 'No hay recetas guardadas';

  @override
  String get mealsEmptyBody =>
      'Crea recetas para registrar varios alimentos a la vez.';

  @override
  String get mealsEmptyBodyWithShortcut =>
      'En el diario, usa la opción «Guardar como receta» debajo del desayuno o la cena para guardar combinaciones habituales de alimentos como plantilla rápida.';

  @override
  String get mealsCreateManually => 'Crear receta manualmente';

  @override
  String get saveMealTemplateShortcut => 'Guardar como receta';

  @override
  String get mealsCreate => 'Crear receta';

  @override
  String get mealsEdit => 'Editar receta';

  @override
  String get mealsDelete => 'Eliminar receta';

  @override
  String get mealsAddToDiary => 'Añadir alimento';

  @override
  String get mealNameLabel => 'Nombre de la receta';

  @override
  String get mealNotesLabel => 'Notas';

  @override
  String get mealIngredientsTitle => 'Ingredientes';

  @override
  String get mealAddIngredient => 'Añadir ingrediente';

  @override
  String get mealIngredientAmountLabel => 'Cantidad';

  @override
  String get mealTotalAmountLabel => 'Cantidad total de la receta';

  @override
  String get mealWeightBasisLabel => 'Estado';

  @override
  String get mealWeightBasisRaw => 'Crudo';

  @override
  String get mealWeightBasisCooked => 'Cocido';

  @override
  String get mealPreviewBasisLabel => 'Ajustar vista previa según';

  @override
  String get mealTotalNutrientsLabel => 'total';

  @override
  String mealTotalAmountHint(int grams) {
    return 'Receta completa: $grams g. Las cantidades de los ingredientes se ajustan proporcionalmente.';
  }

  @override
  String get mealServingCountLabel => 'Porciones de la receta';

  @override
  String get mealServingCountHint =>
      'Número de porciones que rinde la receta completa.';

  @override
  String get mealCookedWeightLabel => 'Peso final tras la cocción';

  @override
  String get mealCookedWeightHint =>
      'Opcional: pesa la receta terminada para calcular con precisión las porciones en gramos.';

  @override
  String mealServingsSummary(String count) {
    return '$count porciones';
  }

  @override
  String mealCookedWeightSummary(String weight) {
    return '$weight g cocinados';
  }

  @override
  String get mealPortionAmountLabel => 'Porciones consumidas';

  @override
  String get mealDecreasePortion => 'Reducir media porción';

  @override
  String get mealIncreasePortion => 'Aumentar media porción';

  @override
  String mealPortionAmountHint(int count) {
    return 'Receta guardada: $count porciones';
  }

  @override
  String get mealDuplicate => 'Duplicar receta';

  @override
  String get mealCopySuffix => '(copia)';

  @override
  String get mealDeleteConfirmTitle => 'Eliminar receta';

  @override
  String mealDeleteConfirmBody(Object name) {
    return '¿Seguro que quieres eliminar la receta «$name»? También se eliminarán todos sus ingredientes.';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'Se ha añadido la receta «$name» a tu diario.';
  }

  @override
  String get mealSaved => 'Receta guardada.';

  @override
  String get mealDeleted => 'Receta eliminada.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get addMealToDiaryTitle => 'Añadir al diario';

  @override
  String get mealTypeLabel => 'Receta';

  @override
  String get amountLabel => 'Cantidad';

  @override
  String get mealAddedToDiarySuccess => 'Receta añadida al diario';

  @override
  String get error => 'Error';

  @override
  String get mealsViewTitle => 'Recetas';

  @override
  String get noNotes => 'Sin notas';

  @override
  String get ingredientsCapsLock => 'INGREDIENTES';

  @override
  String get nutritionSectionLabel => 'INFORMACIÓN NUTRICIONAL';

  @override
  String get nutritionCalculatedForCurrentAmounts =>
      'para las cantidades actuales';

  @override
  String get startCapsLock => 'EMPEZAR';

  @override
  String get nutritionHubSubtitle =>
      'Muy pronto podrás descubrir información, registrar comidas y planificar tu alimentación aquí.';

  @override
  String get nutritionHubTitle => 'Nutrición';

  @override
  String get nutrition => 'Nutrición';

  @override
  String get changeSetTypTitle => 'Cambiar tipo de serie';

  @override
  String get settingsVisualStyleTitle => 'Estilo visual';

  @override
  String get settingsVisualStyleStandard => 'Cristal translúcido';

  @override
  String get settingsVisualStyleLiquid => 'Cristal líquido (fluido)';

  @override
  String get settingsVisualStyleLiquidDesc =>
      'Elementos de interfaz redondeados y flotantes';

  @override
  String get settingsMaterialColorsTitle => 'Colores de Material';

  @override
  String get settingsMaterialColorsSubtitle =>
      'Usa los colores dinámicos del sistema (Material You) en lugar del color de marca de Train Libre';

  @override
  String get settingsAppColorTitle => 'Color de la aplicación';

  @override
  String get settingsAppColorSubtitle =>
      'Elige un color de acento que se adapte a los modos claro y oscuro.';

  @override
  String get appColorPresetTrainLibre => 'Train Libre';

  @override
  String get appColorPresetMonochrome => 'Blanco y negro';

  @override
  String get appColorPresetBlue => 'Azul';

  @override
  String get appColorPresetTeal => 'Verde azulado';

  @override
  String get appColorPresetPurple => 'Morado';

  @override
  String get appColorPresetOrange => 'Naranja';

  @override
  String get appColorPresetRose => 'Rosa';

  @override
  String get appColorPresetCustom => 'Personalizado';

  @override
  String get appColorPresetSystem => 'Colores del sistema';

  @override
  String get appColorCustomDialogTitle => 'Elegir color';

  @override
  String get appColorHexLabel => 'Color hexadecimal';

  @override
  String get appColorHexInvalid =>
      'Introduce un color hexadecimal de 6 dígitos.';

  @override
  String get appColorHexOutOfRange =>
      'Elige un color con un brillo del 40 al 82 %.';

  @override
  String get appColorHueLabel => 'Tono';

  @override
  String get appColorSaturationLabel => 'Saturación';

  @override
  String get appColorBrightnessLabel => 'Brillo';

  @override
  String get appColorCancel => 'Cancelar';

  @override
  String get appColorApply => 'Aplicar';

  @override
  String get settingsFoodDbSectionTitle => 'Base de datos de alimentos';

  @override
  String get settingsFoodDbRegionTitle =>
      'Región de la base de datos de alimentos';

  @override
  String get settingsFoodDbRegionSubtitle =>
      'Selecciona la región del catálogo de productos de Open Food Facts que se usa en las búsquedas.';

  @override
  String get settingsFoodDbRegionCurrent => 'Región actual';

  @override
  String get settingsFoodDbRegionDialogTitle =>
      'Elegir región de la base de datos de alimentos';

  @override
  String get settingsFoodDbRegionDialogSubtitle =>
      'Esto cambia el catálogo de Open Food Facts que se usa en las búsquedas de productos.';

  @override
  String get settingsFoodDbRegionSearchPlaceholder => 'Buscar región…';

  @override
  String get settingsFoodDbRegionNoResults =>
      'No se ha encontrado ninguna región';

  @override
  String get settingsFoodDbRegionIssueHint =>
      'Si tu país aún no aparece, puedes abrir una incidencia en GitHub para solicitar que se añada.';

  @override
  String get settingsFoodDbRegionGermany => 'Alemania (DE)';

  @override
  String get settingsFoodDbRegionSwitzerland => 'Suiza (CH)';

  @override
  String get settingsFoodDbRegionUnitedStates => 'Estados Unidos (US)';

  @override
  String get settingsFoodDbRegionFrance => 'Francia (FR)';

  @override
  String get settingsFoodDbRegionItaly => 'Italia (IT)';

  @override
  String get settingsFoodDbRegionJapan => 'Japón (JP)';

  @override
  String get settingsFoodDbRegionAustria => 'Austria (AT)';

  @override
  String get settingsFoodDbRegionNetherlands => 'Países Bajos (NL)';

  @override
  String get settingsFoodDbRegionSpain => 'España (ES)';

  @override
  String get settingsFoodDbRegionAustralia => 'Australia (AU)';

  @override
  String get settingsColorfulMacroBadgesTitle =>
      'Insignias de macronutrientes en color';

  @override
  String get settingsColorfulMacroBadgesSubtitle =>
      'También usa en el diario el diseño de insignias en color de la verificación con IA.';

  @override
  String get settingsFoodDbRegionUnitedKingdom => 'Reino Unido (UK)';

  @override
  String settingsFoodDbRegionChanged(String region) {
    return 'Región de la base de datos de alimentos: $region. Los cambios se aplicarán al actualizar o importar el catálogo.';
  }

  @override
  String get searchBaseFoodHint => 'Buscar alimentos básicos';

  @override
  String get searchNoHits => 'No hay resultados.';

  @override
  String get onbSubtitleWelcome =>
      'Tu herramienta central para el entrenamiento, la nutrición y el progreso.';

  @override
  String get onbBodyWelcome =>
      'Te ayudamos a definir y seguir tus objetivos. Registra fácilmente entrenamientos, alimentación, suplementos y medidas corporales.';

  @override
  String get onbBodyNutritionVisual =>
      'Registra comidas con unos pocos toques. Controla las calorías, los macronutrientes y el agua para seguir tu objetivo sin esfuerzo.';

  @override
  String get onbBodyMeasurementsVisual =>
      'Visualiza tu progreso. Los gráficos de peso y perímetros muestran tus avances y te ayudan a mantener la motivación.';

  @override
  String get onbBodyWorkoutVisual =>
      'Crea rutinas y empieza a entrenar en segundos. Registra series, pesos y descansos para progresar al máximo.';

  @override
  String get onbTitleAppLayout => 'Navegación y acciones rápidas';

  @override
  String get onbBodyAppLayout =>
      'La barra inferior permite cambiar rápidamente de sección. Usa el botón [+] grande para registrar cualquier cosa al instante.';

  @override
  String get dataHubTitle => 'Centro de datos';

  @override
  String get resumeButton => 'Continuar';

  @override
  String get onboardingWelcomeTitle => 'Te damos la bienvenida a Train Libre';

  @override
  String get onboardingWelcomeSubtitle =>
      'Configuremos tu perfil para que obtengas los mejores resultados.';

  @override
  String get onboardingMissionTitle => 'Nuestra misión';

  @override
  String get onboardingMissionBody =>
      'Train Libre es para culturistas naturales comprometidos que buscan progresar con datos y basándose en la ciencia.';

  @override
  String get onboardingFeatureWorkoutTitle => 'Registro de entrenamiento';

  @override
  String get onboardingFeatureWorkoutBody =>
      'Registra series (RIR/RPE) y sigue la recuperación de tus músculos.';

  @override
  String get onboardingFeatureTdeeTitle => 'Gasto energético adaptativo';

  @override
  String get onboardingFeatureTdeeBody =>
      'Un filtro de Kalman integrado calcula tu gasto calórico real.';

  @override
  String get onboardingFeatureNutritionTitle => 'Nutrición y agua';

  @override
  String get onboardingFeatureNutritionBody =>
      'Controla tus macronutrientes y el agua, y usa opcionalmente el reconocimiento de imágenes con IA.';

  @override
  String get onboardingFeaturePrivacyTitle =>
      'Privacidad y almacenamiento local';

  @override
  String get onboardingFeaturePrivacyBody =>
      'Sin cuentas ni nube obligatoria. Tus datos son tuyos.';

  @override
  String get onboardingSettingsHint =>
      'Puedes cambiar cualquier ajuste más adelante.';

  @override
  String get adaptiveRatePerWeekLabel => 'Ritmo objetivo semanal';

  @override
  String get customTargetRateOption => 'Personalizado';

  @override
  String get customTargetRateDialogTitle =>
      'Establecer ritmo objetivo personalizado';

  @override
  String get onboardingNameTitle => '¿Cómo te llamas?';

  @override
  String get onboardingNameLabel => 'Tu nombre';

  @override
  String get onboardingProfilePhotoSubtitle =>
      'Si quieres, añade una foto de perfil para que sientas que este perfil es tuyo desde el principio.';

  @override
  String get onboardingProfilePhotoAdd => 'Añadir foto de perfil';

  @override
  String get onboardingNameError => 'Introduce tu nombre';

  @override
  String get onboardingDobTitle => '¿Cuándo naciste?';

  @override
  String get onboardingAgeTitle => '¿Cuántos años tienes?';

  @override
  String get onboardingDobLabel => 'Fecha de nacimiento';

  @override
  String get onboardingDobPlaceholder => 'Selecciona tu fecha de nacimiento';

  @override
  String get onboardingDobError => 'Selecciona tu fecha de nacimiento';

  @override
  String get onboardingDobUnderageError =>
      'Debes tener al menos 16 años para usar Train Libre.';

  @override
  String get onboardingWeightTitle => 'Peso actual';

  @override
  String get onboardingWeightLabel => 'Peso';

  @override
  String get onboardingWeightError => 'Introduce un peso válido';

  @override
  String get onboardingGoalsTitle => 'Tus objetivos de nutrición';

  @override
  String get onboardingGoalsSubtitle =>
      'Puedes cambiarlos más adelante en Ajustes.';

  @override
  String get onboardingGoalCalories => 'Calorías diarias (kcal)';

  @override
  String get onboardingGoalProtein => 'Proteínas (g)';

  @override
  String get onboardingGoalCarbs => 'Carbohidratos (g)';

  @override
  String get onboardingGoalFat => 'Grasas (g)';

  @override
  String get onboardingGoalWater => 'Agua';

  @override
  String get onboardingExperienceLevelTitle =>
      '¿Cuánta experiencia tienes entrenando?';

  @override
  String get onboardingExperienceLevelSubtitle =>
      'Adaptamos la terminología y las opciones de la interfaz de entrenamiento a tus conocimientos.';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingBack => 'Atrás';

  @override
  String get onboardingFinish => 'Empezar a registrar';

  @override
  String get onboardingAiHealthTitle => 'IA y salud';

  @override
  String get onboardingAiHealthSubtitle =>
      'Configuración opcional: configura la captura de comidas con IA mediante BYOK (trae tu propia clave) y elige qué datos de salud puede leer Train Libre.';

  @override
  String get onboardingOpenSettings => 'Abrir';

  @override
  String get onboardingUnitSystemTitle => 'Elige el sistema de unidades';

  @override
  String get onboardingUnitSystemSubtitle =>
      'Puedes cambiarlo más adelante en Ajustes.';

  @override
  String get onboardingUnitMetric => 'Métrico';

  @override
  String get onboardingUnitMetricSubtitle => 'kg, cm, ml';

  @override
  String get onboardingUnitImperial => 'Imperial';

  @override
  String get onboardingUnitImperialSubtitle => 'lb, pulg., oz líquidas';

  @override
  String get onboardingHeightLabel => 'Estatura';

  @override
  String get onboardingHeightTitle => '¿Cuánto mides?';

  @override
  String get onboardingHeightSubtitle =>
      'Arrastra la regla hacia arriba o hacia abajo para ajustar tu estatura.';

  @override
  String get onboardingGenderLabel => 'Género';

  @override
  String get onboardingBioDataInfo =>
      'Tu edad y sexo biológico determinan los tiempos de recuperación muscular de referencia y se tienen en cuenta en los algoritmos del motor de salud del sueño.';

  @override
  String get onboardingFieldCannotBeEmpty => 'Este campo no puede estar vacío.';

  @override
  String get onboardingPhysiologicalRangeWarning =>
      'Aviso: Este valor está fuera del rango fisiológico esperado. Los análisis de ciencias del deporte y los modelos heurísticos no están calibrados para valores extremos. Si es intencionado, pulsa «Siguiente» otra vez para continuar.';

  @override
  String get onboardingMeasurementsTitle => 'Medidas y valores iniciales';

  @override
  String get onboardingMeasurementsSubtitle =>
      'Indica tus valores actuales para la recomendación adaptativa.';

  @override
  String get onboardingMeasurementsDisclaimer =>
      'Puedes introducir y registrar tu peso, grasa corporal y otras medidas cuando quieras desde el panel.';

  @override
  String get onboardingActivityTitle => '¿Cuánto te mueves actualmente?';

  @override
  String get onboardingActivitySubtitle =>
      'Tu actividad diaria y el cardio que ya haces ayudan a estimar tu gasto energético de referencia. Los planes de entrenamiento futuros no se tienen en cuenta.';

  @override
  String get onboardingGoalDecisionTitle =>
      '¿Quieres fijar un objetivo personal de nutrición?';

  @override
  String get onboardingGoalDecisionSubtitle =>
      'Elige una dirección, un peso objetivo y un ritmo. También puedes omitir este paso y mantener tu peso actual.';

  @override
  String get onboardingGoalDecisionSetupNow => 'Configurar ahora';

  @override
  String get onboardingGoalDecisionSetupLater => 'Configurar más tarde';

  @override
  String onboardingWaterNeedLabel(String unit) {
    return 'Necesidad de agua ($unit)';
  }

  @override
  String get genderMale => 'Hombre';

  @override
  String get genderFemale => 'Mujer';

  @override
  String get genderDiverse => 'Diverso';

  @override
  String get vegan => 'Vegano';

  @override
  String get vegetarian => 'Vegetariano';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get aiSettingsTitle => 'Funciones de IA';

  @override
  String get aiSettingsDescription =>
      'Configura funciones de IA como el chat y el reconocimiento de comidas.';

  @override
  String get aiProviderSection => 'Proveedor de IA';

  @override
  String get aiProviderLabel => 'Proveedor';

  @override
  String get aiApiKeySection => 'Clave de API';

  @override
  String get aiApiKeyLabel => 'Clave de API';

  @override
  String get aiApiKeyHint => 'Pega aquí tu clave de API';

  @override
  String get aiSaveKey => 'Guardar clave';

  @override
  String get aiTestConnection => 'Probar';

  @override
  String get aiTestSuccess => '¡Conexión correcta!';

  @override
  String get aiKeySaved =>
      'La clave de API se ha guardado de forma segura en este dispositivo.';

  @override
  String get aiPrivacySection => 'Privacidad';

  @override
  String get aiPrivacyDisclosure =>
      'Las funciones de IA pueden enviar texto, imágenes y contexto al modelo utilizado. El chat puede recurrir a otro proveedor configurado. Los datos guardados requieren una autorización de acceso salvo que esté activa la aprobación automática. Consulta las condiciones del proveedor; las claves API usan el almacenamiento seguro de la plataforma.';

  @override
  String get aiMealCapture => 'Comida con IA';

  @override
  String get aiChatAction => 'Chat con IA';

  @override
  String get aiCaptureTitle => 'Registrar comida con IA';

  @override
  String get aiCaptureTabPhoto => 'Foto';

  @override
  String get aiCaptureTabText => 'Texto';

  @override
  String get aiCapturePhotoHint =>
      'Haz o selecciona hasta 4 fotos de tu comida.';

  @override
  String get aiCaptureTextHint =>
      'Describe tu comida (por ejemplo, «Pollo a la plancha con arroz y ensalada»)...';

  @override
  String get aiAnalyzeButton => 'Analizar';

  @override
  String get aiAnalyzing => 'Analizando tu comida…';

  @override
  String get aiReviewTitle => 'Revisar sugerencias';

  @override
  String aiReviewFoundItems(int count) {
    return 'La IA ha encontrado $count alimentos';
  }

  @override
  String get aiReviewNoMatch => 'Sin coincidencias: toca para buscar';

  @override
  String get aiValidationCandidateSelectionRequired =>
      'Revisa y edita los ingredientes antes de guardar.';

  @override
  String aiReviewUncertain(int percent) {
    return 'Incierto ($percent%)';
  }

  @override
  String get aiReviewConfidence => 'Confianza';

  @override
  String get aiReviewAddItem => 'Añadir alimento manualmente';

  @override
  String get aiReviewReplaceItem => 'Sustituir alimento';

  @override
  String get aiReviewSaveToDiary => 'Guardar en el diario';

  @override
  String aiReviewTokensUsed(int count) {
    return '$count tokens';
  }

  @override
  String get aiReviewTokensPending => 'actualizando…';

  @override
  String get aiReviewTokensUnknown => 'Uso de IA: no disponible';

  @override
  String get aiReviewPreliminaryNutrition =>
      'Información nutricional preliminar: aún se está comprobando.';

  @override
  String get aiReviewScanFailed =>
      'No se ha podido completar el análisis. Vuelve atrás e inténtalo de nuevo.';

  @override
  String get aiReviewScanTimedOut =>
      'La solicitud de IA ha tardado demasiado y el análisis se ha detenido. Vuelve atrás e inténtalo de nuevo.';

  @override
  String get aiReviewFeedbackHint => 'Describe qué ha interpretado mal la IA…';

  @override
  String get aiReviewRetryButton => 'Reintentar con correcciones';

  @override
  String get aiReviewFeedbackSection => 'Corrección';

  @override
  String get aiErrorNoKey =>
      'No hay ninguna clave de API configurada. Añade una en Ajustes → Funciones de IA.';

  @override
  String get aiErrorNetwork =>
      'Error de conexión. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get aiErrorAuth =>
      'Error de autenticación. Comprueba tu clave de API.';

  @override
  String get aiErrorParse =>
      'No se ha podido interpretar la respuesta de la IA. Inténtalo de nuevo.';

  @override
  String get aiErrorRateLimit =>
      'Has enviado demasiadas solicitudes. Espera un momento.';

  @override
  String get aiEnableTitle => 'Activar funciones de IA';

  @override
  String get aiEnableSubtitle =>
      'Activa funciones de IA como el chat y el reconocimiento de comidas. Si las desactivas, se ocultarán todos los accesos a ellas.';

  @override
  String get aiNutritionEngineLabel => 'Método para estimar la nutrición';

  @override
  String get aiNutritionEngineSubtitle =>
      'Las estimaciones directas crean valores nutricionales sin buscar coincidencias en la base de datos. El modo catálogo propone coincidencias en el catálogo local de alimentos.';

  @override
  String get aiNutritionEngineEstimate => 'Estimación directa con IA';

  @override
  String get aiNutritionEngineCatalog => 'Catálogo local de alimentos';

  @override
  String get aiDirectEstimateLabel => 'Estimación de IA';

  @override
  String get aiFloatingAssistantTitle => 'Mostrar el asistente flotante de IA';

  @override
  String get aiFloatingAssistantSubtitle =>
      'Muestra la nube de IA sobre la aplicación. Si la ocultas, podrás abrir el chat con IA desde el menú Añadir.';

  @override
  String get aiStatusAndFeaturesSectionTitle => 'Estado y funciones';

  @override
  String get aiProviderSectionTitle => 'Modelo y proveedor de IA';

  @override
  String get aiAdvancedOptionsTitle => 'Opciones avanzadas';

  @override
  String get aiCustomInstructionsTitle => 'Instrucciones generales para la IA';

  @override
  String get aiCustomInstructionsSubtitle =>
      'Indica reglas fijas para la IA (por ejemplo, alergias, alimentos que no quieres como «nada de boles» o intolerancias) que se aplicarán en cada registro.';

  @override
  String get aiValidationNoMatchedItemsSaveYet =>
      'Aún no se pueden guardar alimentos coincidentes.';

  @override
  String get aiValidationNoMatchedIngredientsSaveYet =>
      'Aún no se pueden guardar ingredientes coincidentes.';

  @override
  String get aiValidationSomeItemsNeedReviewTitle =>
      'Hay alimentos que debes revisar';

  @override
  String get aiValidationSomeIngredientsNeedReviewTitle =>
      'Hay ingredientes que debes revisar';

  @override
  String get aiValidationSaveMatchedItemsButton =>
      'Guardar alimentos coincidentes';

  @override
  String get aiValidationSaveMatchedIngredientsButton =>
      'Guardar ingredientes coincidentes';

  @override
  String get aiValidationValidationPassedTitle => 'Validación superada';

  @override
  String get aiValidationReviewSuggestedTitle => 'Se recomienda revisar';

  @override
  String get aiValidationMacroFitValidatedTitle => 'Macros validados';

  @override
  String get aiValidationNeedsReviewTitle => 'Requiere revisión';

  @override
  String get aiValidationRepairLimitReachedReview =>
      'Se ha alcanzado el límite de correcciones automáticas. Revisa antes de guardar.';

  @override
  String get aiValidationRecentMealContextIncluded =>
      'Se ha incluido el contexto de comidas recientes.';

  @override
  String get aiValidationGeneratedWithoutRecentMealHistory =>
      'Generado sin el historial de comidas recientes.';

  @override
  String get aiValidationApiKeyRequiredTitle => 'Se necesita una clave de API';

  @override
  String aiValidationScoreLabel(int score) {
    return 'Puntuación: $score/100';
  }

  @override
  String aiValidationDeltaSummary(
      int kcalDelta, int proteinDelta, int carbsDelta, int fatDelta) {
    return 'Diferencia: $kcalDelta kcal · $proteinDelta g de proteínas · $carbsDelta g de carbohidratos · $fatDelta g de grasas';
  }

  @override
  String aiValidationPartialSaveItemsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other:
          '$unmatchedCount alimentos no coinciden con la base de datos local y no se guardarán.',
      one:
          '1 alimento no coincide con la base de datos local y no se guardará.',
    );
    return '$_temp0 ¿Quieres guardar solo los alimentos coincidentes ($matchedCount)?';
  }

  @override
  String aiValidationPartialSaveIngredientsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other:
          '$unmatchedCount ingredientes no coinciden con la base de datos local y no se guardarán.',
      one:
          '1 ingrediente no coincide con la base de datos local y no se guardará.',
    );
    return '$_temp0 ¿Quieres guardar solo los ingredientes coincidentes ($matchedCount)?';
  }

  @override
  String get aiValidationEmptyItemName => 'Un alimento no tiene nombre.';

  @override
  String aiValidationDuplicateItemMerged(String name) {
    return 'Las entradas duplicadas de «$name» se han combinado antes de la validación.';
  }

  @override
  String get aiValidationInvalidQuantity =>
      'La cantidad debe ser superior a 0 g.';

  @override
  String get aiValidationTinyQuantity =>
      'La cantidad es muy pequeña; revisa el peso en gramos.';

  @override
  String get aiValidationExtremeQuantity =>
      'La cantidad parece demasiado alta para un alimento de una comida.';

  @override
  String get aiValidationLargeQuantity =>
      'La cantidad es inusualmente grande; revisa el peso en gramos.';

  @override
  String get aiValidationLowAiConfidence =>
      'La IA tiene poca confianza en este alimento.';

  @override
  String get aiValidationUnmatchedItem =>
      'No se ha encontrado ninguna coincidencia en la base de datos local.';

  @override
  String get aiValidationWeakDbMatch =>
      'La coincidencia con la base de datos local es poco fiable.';

  @override
  String get aiValidationPartialDbMatch =>
      'La coincidencia con la base de datos local es parcial.';

  @override
  String get aiValidationAmbiguousDbMatch =>
      'Hay varias coincidencias posibles con una probabilidad similar.';

  @override
  String get aiValidationStateMismatch =>
      'El estado del alimento propuesto por la IA puede no coincidir con el de la entrada de la base de datos.';

  @override
  String get aiValidationZeroNutritionMatch =>
      'La entrada coincidente no tiene datos nutricionales utilizables.';

  @override
  String get aiValidationImplausibleFoodDensity =>
      'El alimento coincidente tiene un valor de kcal por 100 g inusualmente alto.';

  @override
  String get aiValidationMacroEnergyMismatch =>
      'Los macronutrientes del alimento coincidente no concuerdan con sus kcal.';

  @override
  String get aiValidationImplausibleItemNutrition =>
      'Los valores nutricionales de esta cantidad son inusualmente altos.';

  @override
  String get aiValidationEmptyMeal =>
      'La IA no ha devuelto ningún alimento para la comida.';

  @override
  String get aiValidationAllItemsUnmatched =>
      'No se ha podido encontrar una coincidencia para ningún alimento en la base de datos local.';

  @override
  String aiValidationPartialUnmatchedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count alimentos no se pueden guardar hasta encontrar una coincidencia.',
      one: '1 alimento no se puede guardar hasta encontrar una coincidencia.',
    );
    return '$_temp0';
  }

  @override
  String get aiValidationZeroTotalKcal =>
      'Los alimentos coincidentes suman 0 kcal.';

  @override
  String get aiValidationCaptureTotalKcalExtreme =>
      'El total de kcal parece demasiado alto para una sola comida.';

  @override
  String get aiValidationCaptureTotalKcalHigh =>
      'El total de kcal es inusualmente alto; revisa las porciones.';

  @override
  String get aiValidationMacroTotalExtreme =>
      'El total de macronutrientes parece demasiado alto.';

  @override
  String get aiValidationMacroTotalHigh =>
      'El total de macronutrientes es inusualmente alto; revisa las porciones.';

  @override
  String aiValidationTargetKcalMismatch(int delta) {
    return 'Las calorías difieren del objetivo en $delta kcal.';
  }

  @override
  String aiValidationTargetProteinMismatch(int delta) {
    return 'Las proteínas difieren del objetivo en $delta g.';
  }

  @override
  String aiValidationTargetCarbsMismatch(int delta) {
    return 'Los carbohidratos difieren del objetivo en $delta g.';
  }

  @override
  String aiValidationTargetFatMismatch(int delta) {
    return 'Las grasas difieren del objetivo en $delta g.';
  }

  @override
  String aiValidationUnknownIssue(String code) {
    return 'Problema de validación: $code';
  }

  @override
  String get currentlyTracking => 'Actualmente';

  @override
  String get currentlyTrackingDesc =>
      'Mostrar en el panel de seguimiento diario';

  @override
  String get filter3Months => '3 meses';

  @override
  String get filter6Months => '6 meses';

  @override
  String get sectionConsistency => 'Constancia y frecuencia';

  @override
  String get metricsWorkoutsWeek => 'Entrenamientos (semana)';

  @override
  String get metricsCurrentStreak => 'Racha actual';

  @override
  String get metricsActiveWeeks => 'semanas activas';

  @override
  String get placeholderCalendarHeatmap => 'Vista de actividad en calendario';

  @override
  String get consistencyTrackerTitle => 'Ritmo de entrenamiento';

  @override
  String get consistencyTrackerComingSoon =>
      'Seguimiento de constancia y hábitos (próximamente)';

  @override
  String get sectionMuscleVolume => 'Grupos musculares y volumen';

  @override
  String get metricsTopTrained => 'Músculos más entrenados';

  @override
  String get metricsMostNeglected => 'Músculos menos entrenados';

  @override
  String get placeholderMuscleHeatmap => 'Mapa de calor muscular';

  @override
  String get muscleAnalyticsTitle => 'Análisis de grupos musculares';

  @override
  String get muscleAnalyticsComingSoon =>
      'Volumen muscular y mapas de calor (próximamente)';

  @override
  String get sectionPerformance => 'Rendimiento y marcas personales';

  @override
  String get metricsRecentPrs => 'Marcas personales recientes';

  @override
  String get metricsVolumeLifted => 'Volumen';

  @override
  String get metricsMostImproved => 'Mayor mejora';

  @override
  String get exerciseAnalyticsTitle => 'Análisis de ejercicios';

  @override
  String get exerciseAnalyticsSubtitle =>
      'Busca y analiza ejercicios concretos';

  @override
  String get prDashboardTitle => 'Panel de marcas personales';

  @override
  String get prDashboardComingSoon => 'Marcas y progreso (próximamente)';

  @override
  String get exerciseAnalyticsComingSoon =>
      'Búsqueda de ejercicios y tendencias específicas (próximamente)';

  @override
  String get sectionRecovery => 'Recuperación';

  @override
  String get metricsMuscleReadiness => 'Estado de recuperación muscular';

  @override
  String get recoveryTrackerTitle => 'Seguimiento de la recuperación';

  @override
  String get recoveryTrackerComingSoon =>
      'Recuperación muscular y fatiga (próximamente)';

  @override
  String get recoveryOverallMostlyRecovered => 'La mayoría ya está recuperada';

  @override
  String get recoveryOverallMixed => 'Recuperación desigual';

  @override
  String get recoveryOverallSeveralRecovering =>
      'Varios grupos musculares siguen recuperándose';

  @override
  String get recoveryOverallInsufficientData =>
      'Aún no hay datos suficientes para estimar la recuperación';

  @override
  String recoveryHubCountsSummary(int recovering, int ready, int fresh) {
    return 'En recuperación: $recovering  Listos: $ready  Recuperados: $fresh';
  }

  @override
  String get recoveryHubNoDataSummary =>
      'Sigue registrando entrenamientos para ver información sobre tu recuperación.';

  @override
  String get recoveryByMuscleTitle => 'Recuperación por músculo';

  @override
  String get recoveryStateRecovering => 'En recuperación';

  @override
  String get recoveryStateReady => 'Listo';

  @override
  String get recoveryStateFresh => 'Recuperado';

  @override
  String get recoveryStateUnknown => 'Desconocido';

  @override
  String recoveryReadyInHours(int hours) {
    return 'Se espera que esté listo en unas $hours h';
  }

  @override
  String recoveryFreshInHours(int hours) {
    return 'Se espera que esté recuperado en unas $hours h';
  }

  @override
  String get recoveryStillRecovering => 'Aún en recuperación';

  @override
  String get recoveryReadyForNormalTraining =>
      'Listo para entrenar con normalidad';

  @override
  String get recoveryFreshForFullTraining =>
      'Recuperado · listo para entrenar a pleno rendimiento';

  @override
  String get recoveryDetailLastSession => 'Última sesión';

  @override
  String get recoveryNoRecentLoad => 'No hay cargas significativas registradas';

  @override
  String get recoveryDetailEquivalentSets => 'series equivalentes';

  @override
  String get recoveryDataConfidence => 'Fiabilidad de los datos';

  @override
  String get recoveryDetailEligibleSets => 'series incluidas';

  @override
  String get recoveryDetailResidualLoad => 'carga residual';

  @override
  String get recoveryDetailDirectLoad => 'carga directa';

  @override
  String get recoveryDetailIndirectLoad => 'carga indirecta';

  @override
  String get recoveryDetailAverageRir => 'RIR medio';

  @override
  String get recoveryDetailAverageRpe => 'RPE medio';

  @override
  String get recoveryMovementPatterns => 'Patrones de movimiento';

  @override
  String get recoveryDetailForecast => 'Previsión';

  @override
  String get recoveryDetailRirData => 'Datos de RIR';

  @override
  String recoveryCompactHours(int hours) {
    return '≈ $hours h';
  }

  @override
  String recoverySessionLoadAndAge(String load, int hours) {
    return '$load unidades de carga · hace $hours h';
  }

  @override
  String recoveryLastSessionDetails(String load, int hours) {
    return 'Última sesión: $load unidades de carga · hace $hours h';
  }

  @override
  String recoveryRirCoverage(int covered, int total) {
    return 'RIR registrado en $covered de $total series';
  }

  @override
  String recoveryLastLoadedHours(int hours) {
    return 'Última carga significativa: hace $hours h';
  }

  @override
  String get recoveryFatigueContextHigh => 'Fatiga: alta fatiga en la sesión';

  @override
  String get recoveryFatigueContextBaseline =>
      'Fatiga: fatiga habitual en la sesión';

  @override
  String recoveryExplanationWithHighFatigue(String muscle, int hours) {
    return '$muscle: última carga significativa hace $hours h, con mucha fatiga en la sesión.';
  }

  @override
  String recoveryExplanationBasic(String muscle, int hours) {
    return '$muscle: última carga significativa hace $hours h.';
  }

  @override
  String get recoveryHeuristicDisclaimer =>
      'Es una estimación prudente basada en las cargas significativas recientes y el esfuerzo de las sesiones. No es una medición médica de la recuperación.';

  @override
  String get recoveryReadinessLabel => 'Preparación';

  @override
  String recoveryRecentLoad(String sets) {
    return 'Última carga: $sets series equivalentes';
  }

  @override
  String recoveryLastLoadPressure(String level) {
    return 'Exigencia de la última carga: $level';
  }

  @override
  String get recoveryPressureLow => 'baja';

  @override
  String get recoveryPressureModerate => 'moderada';

  @override
  String get recoveryPressureHigh => 'alta';

  @override
  String get recoveryPressureVeryHigh => 'muy alta';

  @override
  String recoveryCurrentWindow(int recoveringUpper, int readyUpper) {
    return 'Periodo actual: en recuperación hasta unas $recoveringUpper h y listo hasta unas $readyUpper h.';
  }

  @override
  String recoveryWindowHeuristic(int from, int to) {
    return 'Periodo actual: en recuperación hasta unas $from h y listo hasta unas $to h.';
  }

  @override
  String get recoveryRadarHeuristicCaption =>
      'Vista radial de la preparación actual de cada músculo. Los indicadores de estado son la referencia principal.';

  @override
  String get recoveryNoDataBody =>
      'Aún no se han registrado suficientes cargas significativas para estimar la recuperación muscular.';

  @override
  String get sectionBodyNutrition => 'Cuerpo y nutrición';

  @override
  String get statisticsSectionTraining => 'Entrenamiento';

  @override
  String get statisticsSectionBody => 'Cuerpo';

  @override
  String get statisticsEditCardsTitle => 'Editar estadísticas';

  @override
  String get statisticsPinnedTitle => 'Fijadas';

  @override
  String get statisticsAddCardsTitle => 'Más estadísticas';

  @override
  String get statisticsMicronutrientsTitle => 'Micronutrientes';

  @override
  String get statisticsMicronutrientsCoverage =>
      'Solo alimentos del BLS registrados en el diario';

  @override
  String get statisticsMicronutrientsPreviewSubtitle =>
      'Vitaminas, minerales y otros nutrientes';

  @override
  String get statisticsMicronutrientsNoData =>
      'Aún no hay alimentos del BLS registrados';

  @override
  String get statisticsAveragePerLoggedDay => 'Promedio por día registrado';

  @override
  String get statisticsMicronutrientsLoggedDays => 'días registrados';

  @override
  String statisticsMicronutrientsNutrientCoverage(int count) {
    return 'Valor registrado en $count días';
  }

  @override
  String get diaryMicronutrientsAction => 'Ver los micronutrientes de este día';

  @override
  String get statisticsWaterDailyAverage => 'Promedio diario';

  @override
  String get statisticsWaterNoData => 'Aún no hay bebidas registradas';

  @override
  String statisticsWaterGoalProgress(int percent) {
    return '$percent% del objetivo diario';
  }

  @override
  String get statisticsActivityCategory => 'Actividad';

  @override
  String get statisticsPinnedEmptyHint =>
      'Añade estadísticas abajo para mostrarlas aquí.';

  @override
  String get statisticsAllDataTitle => 'Todos los datos';

  @override
  String get statisticsAllDataAction => 'Mostrar todos los datos';

  @override
  String get statisticsRemoveCard => 'Quitar estadística';

  @override
  String get statisticsEnableStepTrackingHint =>
      'Activa el seguimiento de pasos en Ajustes';

  @override
  String get statisticsNoStepDataYet => 'Aún no hay datos de pasos';

  @override
  String get statisticsTotalSteps => 'Pasos totales';

  @override
  String get statisticsLast7Days => 'Últimos 7 días';

  @override
  String get statisticsLast30Days => 'Últimos 30 días';

  @override
  String get statisticsLast3Months => 'Últimos 3 meses';

  @override
  String get statisticsLast6Months => 'Últimos 6 meses';

  @override
  String get metricsCurrentWeight => 'Peso actual';

  @override
  String get metricsAvgCalories => 'Calorías promedio';

  @override
  String get placeholderWeightTrend => 'Gráfico de tendencia del peso';

  @override
  String get exerciseAnalyticsPrsLabel => 'RÉCORDS PERSONALES';

  @override
  String get exerciseAnalyticsTrendsLabel => 'TENDENCIAS';

  @override
  String get exerciseAnalyticsNoData =>
      'No hay datos registrados para este ejercicio.';

  @override
  String get exerciseAnalyticsNotEnoughData => 'No hay datos suficientes';

  @override
  String get exerciseAnalyticsChartWeight => 'Peso a lo largo del tiempo (kg)';

  @override
  String get exerciseAnalyticsChartVolume =>
      'Volumen a lo largo del tiempo (kg)';

  @override
  String get exerciseAnalyticsChartSets => 'Series a lo largo del tiempo';

  @override
  String get exerciseMetricMaxWeight => 'Peso máximo';

  @override
  String get exerciseMetricVolume => 'Volumen';

  @override
  String get exerciseMetricEst1RM => '1RM estimado';

  @override
  String get exerciseMetricDistance => 'Distancia';

  @override
  String get exerciseMetricDuration => 'Duración';

  @override
  String get exerciseMetricPace => 'Ritmo';

  @override
  String get prBannerBestMaxWeight => 'Mejor peso máximo';

  @override
  String get prBannerBestVolumeSet => 'Serie de mayor volumen';

  @override
  String get prBannerBest1RM => 'Mejor 1RM';

  @override
  String get newPersonalRecordLabel => 'Nuevo récord personal';

  @override
  String get prBadgeTooltip => '¡Nuevo récord personal!';

  @override
  String get workoutSummaryNewRecordsTitle => 'Nuevos récords';

  @override
  String get allTimeRecordsLabel => 'Récords históricos';

  @override
  String get recentActivityLabel => 'Actividad reciente';

  @override
  String get prsByRepRangeLabel => 'Mejor serie por rango de repeticiones';

  @override
  String get volumeAnalyticsTitle => 'Análisis del volumen';

  @override
  String get weeklyTonnageLabel => 'Tonelaje semanal';

  @override
  String get volumeByMuscleLabel => 'Por grupo muscular';

  @override
  String get topExercisesLabel => 'Ejercicios principales';

  @override
  String get thisWeekLabel => 'Esta semana';

  @override
  String get avgPerWeekLabel => 'Promedio semanal';

  @override
  String get streakLabel => 'Racha';

  @override
  String get trainingCalendarLabel => 'Calendario de entrenamiento';

  @override
  String get workoutsPerWeekLabel => 'Entrenamientos por semana';

  @override
  String get totalWorkoutsLabel => 'Total';

  @override
  String get weeksLabel => 'Semanas';

  @override
  String get tonnageKgLabel => 'Tonelaje (kg)';

  @override
  String get noWorkoutDataLabel =>
      'Aún no hay datos de entrenamiento. Empieza a registrar sesiones para ver tus estadísticas.';

  @override
  String get analyticsSectionVolumeMuscles => 'Volumen y grupos musculares';

  @override
  String get analyticsSectionPerformanceRecords => 'Rendimiento y récords';

  @override
  String get analyticsTopVolume => 'Más entrenados';

  @override
  String get analyticsLowestVolume => 'Menor volumen';

  @override
  String get analyticsRecentRecords => 'Récords recientes';

  @override
  String get analyticsNewBestPerformances => 'Nuevas marcas personales';

  @override
  String get analyticsTop => 'Mejores';

  @override
  String analyticsLastWeeks(int weeks) {
    return 'Últimas $weeks semanas';
  }

  @override
  String get analyticsMuscleGroups => 'Grupos musculares';

  @override
  String get analyticsStrongestBreakthrough => 'Mayor mejora';

  @override
  String get analyticsRecordOverview => 'Resumen de récords';

  @override
  String get analyticsRecentlySet => 'Más recientes';

  @override
  String get analyticsByRepetitionRange => 'Por repeticiones';

  @override
  String analyticsPerfWithReps(String weight, int reps, Object unit) {
    return '$weight $unit × $reps';
  }

  @override
  String get analyticsKgThisWeek => 'kg (esta semana)';

  @override
  String get analyticsRecoverySummary => '3 en recuperación, 8 listos';

  @override
  String get analyticsViewDetails => 'Ver detalles';

  @override
  String get analyticsRepRangeSuffix => ' repeticiones';

  @override
  String get analyticsNoRecordYet => 'Aún no hay récords';

  @override
  String get analyticsNoRecordsInPeriod =>
      'No hay marcas personales en este periodo';

  @override
  String get analyticsNotableImprovements => 'Mejoras destacadas';

  @override
  String get analyticsNoPrTrendInWindow =>
      'Aún no hay una tendencia clara de récords en este periodo.';

  @override
  String analyticsE1rmProgress(String previous, String recent, Object unit) {
    return '1RM estimado $previous → $recent $unit';
  }

  @override
  String get analyticsUnitKg => 'kg';

  @override
  String get analyticsUnitSets => 'series';

  @override
  String get analyticsViewLabel => 'Vista';

  @override
  String get analyticsViewChart => 'Gráfico';

  @override
  String get analyticsViewOverview => 'Resumen';

  @override
  String get analyticsVolumeWeeklyAverage => 'Promedio semanal';

  @override
  String get analyticsVolumeTotal => 'Total';

  @override
  String get analyticsSwitchToChart => 'Mostrar gráfico';

  @override
  String get analyticsSwitchToOverview => 'Mostrar resumen';

  @override
  String get analyticsViewWeek => 'Semana';

  @override
  String get analyticsViewMonth => 'Mes';

  @override
  String get analyticsViewByExercise => 'Por ejercicio';

  @override
  String get analyticsViewByMuscle => 'Por grupo muscular';

  @override
  String get analyticsMetricLabel => 'Métrica';

  @override
  String get analyticsMovedWeightKg => 'Peso movilizado (kg)';

  @override
  String get analyticsWorkSets => 'Series efectivas';

  @override
  String get analyticsVolumeContextWithSets =>
      'El peso movilizado = peso × repeticiones. Cambia a series efectivas para ver la carga por número de series.';

  @override
  String get analyticsVolumeContextTonnageOnly =>
      'Esta vista usa el peso movilizado (peso × repeticiones).';

  @override
  String get analyticsKpisHeader => 'Indicadores clave';

  @override
  String get analyticsTrainingDaysPerWeek => 'Días de entrenamiento por semana';

  @override
  String get analyticsLast4Weeks => 'últimas 4 semanas';

  @override
  String get analyticsRhythm => 'Ritmo';

  @override
  String get analyticsVsPrior4Weeks => 'frente a las 4 semanas anteriores';

  @override
  String get analyticsRollingConsistency => 'Constancia durante el periodo';

  @override
  String get analyticsWeeksAtLeast2Workouts =>
      'semanas con al menos 2 sesiones';

  @override
  String get analyticsInTimeframe => 'En el periodo';

  @override
  String get analyticsVsPriorPeriod => 'frente al periodo anterior';

  @override
  String get analyticsCalendarExplainer =>
      'El color indica las sesiones de cada día.';

  @override
  String get analyticsSelectDayPrompt =>
      'Selecciona un día para consultar el número de sesiones.';

  @override
  String analyticsSelectedDayWorkouts(String date, int count) {
    return '$date: $count sesiones';
  }

  @override
  String get analyticsTotalSessions => 'Sesiones totales';

  @override
  String get analyticsPlaceholderWeightValue => '82,5';

  @override
  String get analyticsPlaceholderWeightTrend => 'kg (-0,5)';

  @override
  String get analyticsPlaceholderCaloriesValue => '2.450';

  @override
  String get analyticsPlaceholderCaloriesUnit => 'kcal/día';

  @override
  String get analyticsMuscleWeeklySets => 'Series semanales';

  @override
  String get analyticsMuscleTopFrequency => 'Mayor frecuencia';

  @override
  String get analyticsPerWeekAbbrev => 'sem.';

  @override
  String get analyticsKeepTrackingUnlockInsights =>
      'Sigue registrando tus entrenamientos para descubrir información útil.';

  @override
  String get analyticsGuidanceNoClearWeakPoint =>
      'Orientación: no hay ningún punto débil claro en este periodo.';

  @override
  String analyticsGuidanceLowerEmphasis(String muscles) {
    return 'Orientación: menor énfasis reciente en $muscles.';
  }

  @override
  String get analyticsPeriodLabel => 'Periodo';

  @override
  String get analyticsCoverageMuscles => 'Músculos';

  @override
  String get analyticsCoverageMovementPatterns => 'Patrones de movimiento';

  @override
  String get analyticsWorkingSetsByMuscle => 'Series efectivas por músculo';

  @override
  String get analyticsWorkingSetsByPattern =>
      'Series efectivas por patrón de movimiento';

  @override
  String get analyticsPrimaryMuscleCoverageCaption =>
      'Muestra únicamente las series normales y al fallo completadas para los músculos principales.';

  @override
  String get analyticsMovementPatternCoverageCaption =>
      'Muestra las series normales y al fallo completadas por patrón de movimiento.';

  @override
  String get analyticsUnclassified => 'Sin clasificar';

  @override
  String get analyticsPatternOther => 'Otro';

  @override
  String analyticsAverageWorkingSetsPerWeek(String value) {
    return 'Promedio de $value series efectivas por semana';
  }

  @override
  String get analyticsFrequencyWorkingSetFooter =>
      'La frecuencia cuenta los días de entrenamiento con al menos una serie efectiva para ese músculo.';

  @override
  String analyticsAverageFrequencyPerWeek(String value) {
    return 'Frecuencia media: $value / sem.';
  }

  @override
  String analyticsTotalWorkingSets(String value) {
    return '$value series efectivas';
  }

  @override
  String get analyticsEquivalentSetsExplainer =>
      'Las series duras equivalentes ponderan los músculos principales ×1,0 y los secundarios ×0,3. La frecuencia solo cuenta los días que alcanzan al menos 1,0 serie equivalente.';

  @override
  String get analyticsWeeklySetsByMuscle =>
      'Promedio semanal de series por músculo';

  @override
  String get analyticsFrequencyByMuscle => 'Frecuencia por músculo';

  @override
  String get analyticsRecentDistributionHeatmap =>
      'Mapa de calor de la distribución reciente';

  @override
  String get analyticsRadarOverviewTitle => 'Vista general radial';

  @override
  String get analyticsRadarVolumeCaption =>
      'Muestra de un vistazo la distribución relativa del volumen entre los músculos.';

  @override
  String get analyticsGuidanceTitle => 'Orientación';

  @override
  String get analyticsGuidanceDirectionalDisclaimer =>
      'Es una orientación basada en la distribución reciente de tus series, no un diagnóstico absoluto.';

  @override
  String get analyticsGuidanceSoftenedDisclaimer =>
      'Las conclusiones se presentan con cautela hasta que haya suficientes datos.';

  @override
  String analyticsWeekTotalEquivalentSets(String value) {
    return 'Promedio de $value series equivalentes por semana';
  }

  @override
  String get analyticsFrequencyRuleFooter =>
      'La frecuencia solo cuenta los días en que el músculo alcanza al menos 1,0 series equivalentes.';

  @override
  String liveWorkoutE1rmCurrentSet(String value, Object unit) {
    return '1RM estimado $value $unit';
  }

  @override
  String liveWorkoutE1rmBestSession(String value, Object unit) {
    return 'Mejor 1RM estimado de esta sesión: $value $unit';
  }

  @override
  String liveWorkoutE1rmVsLastSession(String delta, Object unit) {
    return 'frente a la última sesión: $delta $unit';
  }

  @override
  String get bodyNutritionCorrelationTitle => 'Tendencias de peso y nutrición';

  @override
  String get metricsWeightChange => 'Cambio de peso';

  @override
  String get analyticsKcalPerDay => 'kcal/día';

  @override
  String get analyticsDaysWithWeightData => 'días con datos de peso';

  @override
  String get analyticsDayUnitLabel => 'días';

  @override
  String get analyticsPerDayLabel => 'por día';

  @override
  String get analyticsEffectiveRangeLabel => 'Intervalo efectivo';

  @override
  String get analyticsAxisXLabel => 'X';

  @override
  String get analyticsAxisYLabel => 'Y';

  @override
  String get analyticsHighConfidenceLabel => 'Patrón con mayor confianza';

  @override
  String get analyticsLowConfidenceLabel => 'Patrón con menor confianza';

  @override
  String get analyticsObservedPatternLabel => 'Patrón observado';

  @override
  String get analyticsBodyNutritionTrendContext =>
      'Evolución del peso y las calorías';

  @override
  String analyticsBodyNutritionTrendContextHint(Object unit) {
    return 'El gráfico ajusta cada serie para mostrarlas en el mismo espacio; las ayudas muestran los valores originales en $unit y kcal.';
  }

  @override
  String analyticsBodyNutritionNormalizedHint(Object unit) {
    return 'El gráfico ajusta el peso y las calorías para mostrarlos en el mismo espacio; las ayudas muestran los valores originales en $unit y kcal.';
  }

  @override
  String analyticsBodyNutritionTotalWeightLabel(Object unit) {
    return 'Peso total ($unit)';
  }

  @override
  String get analyticsBodyNutritionTotalCaloriesLabel =>
      'Calorías totales (kcal)';

  @override
  String analyticsWeightTrendLabel(String unit) {
    return 'Peso ($unit)';
  }

  @override
  String get analyticsCaloriesTrendLabel => 'Calorías (kcal)';

  @override
  String get analyticsInterpretationTitle => 'Interpretación';

  @override
  String get analyticsBodyNutritionConfidenceHighHint =>
      'La cobertura de datos de este periodo permite identificar tendencias con mayor fiabilidad.';

  @override
  String get analyticsBodyNutritionConfidenceModerateHint =>
      'La cobertura de datos es moderada. Las tendencias aportan contexto, pero sigue registrando datos para aumentar la confianza.';

  @override
  String get analyticsBodyNutritionConfidenceLowHint =>
      'La cobertura de datos de este periodo aún es limitada; toma estos resultados como una primera orientación.';

  @override
  String get analyticsBodyNutritionLowConfidenceNudge =>
      'Registra el peso y las calorías con regularidad para mejorar la fiabilidad.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceHigh =>
      'Confianza de la interpretación: alta. Úsala como contexto de tendencias, no como una relación directa de causa.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceLow =>
      'Confianza de la interpretación: baja. Tómala como una señal inicial y sigue registrando datos.';

  @override
  String get analyticsCorrelationDisclaimer =>
      'Esta vista aporta contexto sobre las tendencias. No demuestra que los cambios en las calorías hayan causado directamente los cambios de peso.';

  @override
  String get analyticsInsightStableWeightCaloriesUp =>
      'El peso se mantiene estable mientras ha aumentado el promedio de calorías.';

  @override
  String get analyticsInsightWeightUpCaloriesUp =>
      'El peso tiende a subir junto con un mayor consumo medio de calorías.';

  @override
  String get analyticsInsightCaloriesDownWeightStable =>
      'La reciente reducción de calorías aún no ha cambiado claramente la tendencia del peso.';

  @override
  String get analyticsInsightWeightDownCaloriesDown =>
      'El peso tiende a bajar junto con un menor consumo medio de calorías.';

  @override
  String get analyticsInsightMixedPattern =>
      'Las tendencias de peso y calorías son dispares y aún no muestran una relación clara.';

  @override
  String get analyticsInsightNotEnoughData =>
      'Aún no hay suficientes datos constantes para identificar una tendencia significativa.';

  @override
  String get analyticsModerateConfidenceLabel => 'Patrón de confianza moderada';

  @override
  String get analyticsInsufficientConfidenceLabel =>
      'Datos insuficientes para determinar la fiabilidad';

  @override
  String get analyticsTrendRising => 'En aumento';

  @override
  String get analyticsTrendFalling => 'En descenso';

  @override
  String get analyticsTrendStable => 'Estable';

  @override
  String get analyticsTrendUnclear => 'Sin tendencia clara';

  @override
  String get analyticsRelationshipAlignedCut =>
      'La menor ingesta y la bajada de peso coinciden.';

  @override
  String get analyticsRelationshipAlignedBulk =>
      'La mayor ingesta y la subida de peso coinciden.';

  @override
  String get analyticsRelationshipStableMaintenance =>
      'El peso y la ingesta se mantienen bastante estables.';

  @override
  String get analyticsRelationshipMixed =>
      'Las señales son diversas o aparecen con retraso.';

  @override
  String get analyticsRelationshipInsufficient =>
      'Aún no hay suficientes datos coincidentes y constantes para clasificar el patrón.';

  @override
  String analyticsBasedOnDataCoverage(int weightDays, int calorieDays) {
    return 'Según $weightDays días con pesaje y $calorieDays días con datos de calorías';
  }

  @override
  String get restTimerNotificationTitle => 'Descanso terminado';

  @override
  String get restTimerNotificationBody =>
      'El temporizador de descanso ha terminado. Ya puedes hacer la siguiente serie.';

  @override
  String get onboardingContinueSetup => 'Configurar perfil';

  @override
  String get onboardingRestoreFromBackup =>
      'Restaurar desde una copia de seguridad';

  @override
  String get onboardingRestoreImporting => 'Importando copia de seguridad…';

  @override
  String get onboardingRestoreSuccess =>
      '¡Copia de seguridad restaurada correctamente!';

  @override
  String get onboardingRestoreFailed =>
      'No se ha podido importar. Comprueba el archivo e inténtalo de nuevo.';

  @override
  String get onboardingRestoreFromICloud => 'Restaurar desde iCloud';

  @override
  String get onboardingRestoreICloudSuccess =>
      '¡Copia de seguridad de iCloud restaurada correctamente!';

  @override
  String get onboardingRestoreICloudFailed =>
      'No se ha podido restaurar desde iCloud. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get finishWorkoutTitleLabel => 'Título del entrenamiento';

  @override
  String get finishWorkoutNotesLabel => 'Notas (opcional)';

  @override
  String get finishWorkoutNotesHint => '¿Qué tal ha ido el entrenamiento?';

  @override
  String get sleepSectionTitle => 'Sueño';

  @override
  String get sleepSectionSubtitleDayEntry =>
      'Resumen del día y detalles ampliados';

  @override
  String get sleepSectionSubtitleAllEntry =>
      'Desde aquí puedes consultar el sueño por día, semana o mes';

  @override
  String get sleepScopeDay => 'Día';

  @override
  String get sleepScopeWeek => 'Semana';

  @override
  String get sleepScopeMonth => 'Mes';

  @override
  String get sleepWeekSummaryTitle => 'Resumen semanal';

  @override
  String get sleepMonthSummaryTitle => 'Resumen mensual';

  @override
  String get sleepSleepWindowTitle => 'Periodo de sueño';

  @override
  String get sleepDailyScoreTitle => 'Puntuación diaria';

  @override
  String get sleepMonthDailyScoreStatesTitle =>
      'Estados de la puntuación diaria';

  @override
  String sleepMeanScoreLabel(String value) {
    return 'Puntuación media: $value';
  }

  @override
  String get sleepHubScoreLabel => 'Puntuación del sueño';

  @override
  String get sleepHubAverageLabel => 'Promedio';

  @override
  String get sleepHubBedtimeLabel => 'Hora de acostarse';

  @override
  String get sleepHubInterruptionsLabel => 'Interrupciones';

  @override
  String sleepHubInterruptionsSummary(int count, String duration) {
    return '$count despertares, $duration en total';
  }

  @override
  String sleepWeekdayAvgDurationLabel(String value) {
    return 'Duración media entre semana: $value';
  }

  @override
  String sleepWeekendAvgDurationLabel(String value) {
    return 'Duración media en fin de semana: $value';
  }

  @override
  String get sleepWeekNoScoredNights =>
      'Aún no hay noches con puntuación esta semana.';

  @override
  String get sleepMonthNoScoredNights =>
      'Aún no hay noches con puntuación este mes.';

  @override
  String get sleepSettingsSectionTitle => 'Sueño';

  @override
  String get sleepEnableTrackingTitle => 'Activar el seguimiento del sueño';

  @override
  String get sleepEnableTrackingSubtitle =>
      'Leer los datos del sueño y la frecuencia cardíaca nocturna de Health Connect / HealthKit';

  @override
  String get sleepHealthConnectionStatusTitle =>
      'Estado de la conexión de salud';

  @override
  String get sleepRequestAccessTitle => 'Solicitar acceso';

  @override
  String get sleepRequestAccessSubtitle =>
      'Solicitar o volver a solicitar permisos para el sueño y la frecuencia cardíaca';

  @override
  String get sleepImportNowTitle => 'Importar datos del sueño ahora';

  @override
  String get sleepImportNowSubtitle =>
      'Importar todos los datos del sueño disponibles';

  @override
  String get sleepRawImportsTitle => 'Ver importaciones de sueño sin procesar';

  @override
  String get sleepRawImportsSubtitle =>
      'Mostrar los datos recientes de Health Connect';

  @override
  String get sleepDataStatusTitle => 'Estado de los datos';

  @override
  String get sleepDataStatusSubtitle =>
      'Permisos concedidos. Si aún no aparecen datos de sueño, inicia una importación manual abajo.';

  @override
  String get sleepDataStatusSubtitleIos =>
      'Conexión activa. Si faltan datos (0 sesiones importadas), comprueba manualmente los permisos de lectura en la app Salud de Apple.';

  @override
  String get sleepNoPermissionSubtitle =>
      'Se necesitan permisos para leer el sueño y la frecuencia cardíaca e importar los datos del sueño.';

  @override
  String get sleepFeatureUnavailableTitle => 'Función no disponible';

  @override
  String get sleepFeatureUnavailableSubtitle =>
      'La importación del sueño no está disponible en este dispositivo o Health Connect no está instalado.';

  @override
  String get sleepNoRawImportsFound =>
      'Aún no hay importaciones de sueño sin procesar.';

  @override
  String get sleepRawImportsSheetTitle =>
      'Importaciones de sueño sin procesar (más recientes)';

  @override
  String sleepImportFinishedSessions(int count) {
    return 'Importación del sueño completada ($count sesiones).';
  }

  @override
  String get sleepImportUnavailableCheckPermissions =>
      'No se puede importar el sueño. Comprueba los permisos.';

  @override
  String get sleepStatusChecking => 'Comprobando el estado de los permisos…';

  @override
  String get sleepStatusReady => 'Listo';

  @override
  String get sleepStatusDenied => 'Denegado';

  @override
  String get sleepStatusPartial => 'Acceso parcial';

  @override
  String get sleepStatusUnavailable => 'No disponible en este dispositivo';

  @override
  String get sleepStatusNotInstalled => 'Health Connect no está instalado';

  @override
  String get sleepStatusTechnicalError => 'Error técnico';

  @override
  String get sleepConnectHealthDataTitle => 'Conectar datos de salud';

  @override
  String get sleepConnectHealthDataMessage =>
      'Conecta HealthKit o Health Connect para importar registros del sueño.';

  @override
  String get sleepPermissionDeniedTitle => 'Permiso denegado';

  @override
  String get sleepPermissionDeniedMessage =>
      'Se han denegado los permisos del sueño. Abre los ajustes para conceder el acceso.';

  @override
  String get sleepSourceUnavailableTitle => 'Fuente no disponible';

  @override
  String get sleepSourceUnavailableMessage =>
      'La fuente de datos del sueño no está disponible o no está instalada en este dispositivo.';

  @override
  String get sleepEmptyDayNoData => 'No hay datos del sueño para este día.';

  @override
  String get sleepEmptyDayConnectMessage =>
      'Conecta Health Connect / HealthKit en Ajustes e importa los datos recientes del sueño.';

  @override
  String get sleepOpenSettingsButton => 'Abrir ajustes';

  @override
  String get sleepImportNowButton => 'Importar ahora';

  @override
  String get sleepImportFinishedRefreshing =>
      'Importación del sueño completada. Actualizando…';

  @override
  String get sleepImportUnavailableSettingsHint =>
      'No se puede importar el sueño. Comprueba los permisos en Ajustes.';

  @override
  String get sleepTimelineTitle => 'Cronología';

  @override
  String get sleepTimelineUnavailable =>
      'No hay una cronología de las fases disponible para esta noche.';

  @override
  String get sleepSessionTypeCore => 'Sueño esencial';

  @override
  String get sleepSessionTypeNap => 'Siesta';

  @override
  String get sleepIntervalsDrawerTitle => 'Intervalos de sueño';

  @override
  String get sleepStageDeepLabel => 'Profundo';

  @override
  String get sleepStageLightLabel => 'Ligero';

  @override
  String get sleepStageRemLabel => 'REM';

  @override
  String get sleepStageAwakeLabel => 'Despierto';

  @override
  String get sleepScoreCardTitle => 'Calidad del sueño';

  @override
  String get sleepScoreUnavailableForNight =>
      'No hay puntuación disponible para esta noche.';

  @override
  String sleepScoreCompletenessLabel(String value) {
    return 'Completitud de la puntuación: $value';
  }

  @override
  String get sleepQualityGood => 'Buena';

  @override
  String get sleepQualityAverage => 'Normal';

  @override
  String get sleepQualityPoor => 'Baja';

  @override
  String get sleepQualityUnavailable => 'No disponible';

  @override
  String get sleepQualitySubtitleGood =>
      'Las señales de recuperación nocturna fueron favorables.';

  @override
  String get sleepQualitySubtitleAverage =>
      'El sueño fue aceptable, aunque hay margen de mejora.';

  @override
  String get sleepQualitySubtitlePoor =>
      'Las señales de recuperación fueron bajas esta noche.';

  @override
  String get sleepQualitySubtitleUnavailable =>
      'No hay datos suficientes para puntuar esta noche.';

  @override
  String get sleepQualityRegularityNotContributing =>
      'La regularidad no se ha tenido en cuenta (menos de 5 días válidos).';

  @override
  String get sleepQualityRegularityPreliminary =>
      'La regularidad es provisional (5-6 días válidos).';

  @override
  String sleepQualityRegularityStable(int days) {
    return 'La regularidad es estable ($days días).';
  }

  @override
  String sleepRegularityNightView(int count) {
    return 'Vista de $count noches';
  }

  @override
  String get sleepMetricUnavailable => 'No disponible';

  @override
  String get sleepMetricDurationTitle => 'Duración';

  @override
  String get sleepMetricHeartRateTitle => 'Frecuencia cardíaca';

  @override
  String get sleepMetricRegularityTitle => 'Regularidad';

  @override
  String get sleepMetricDepthTitle => 'Profundidad';

  @override
  String get sleepMetricInterruptionsTitle => 'Interrupciones';

  @override
  String get sleepMetricDepthLowConfidence => 'Baja fiabilidad';

  @override
  String get sleepMetricDepthStagesAvailable => 'Fases disponibles';

  @override
  String get sleepDurationUnavailable =>
      'No hay datos disponibles sobre la duración.';

  @override
  String get sleepDurationStatusWithinTarget => 'Dentro del objetivo';

  @override
  String get sleepDurationStatusBelowTarget => 'Por debajo del objetivo';

  @override
  String get sleepDurationSubtitle =>
      'La duración total de tu sueño esta noche.';

  @override
  String get sleepDurationBenchmarkHint =>
      'A muchos adultos les va bien dormir entre 7 y 9 horas. Esta referencia te ayuda a ver dónde queda tu noche dentro de ese intervalo.';

  @override
  String get sleepDepthUnavailable =>
      'No hay datos disponibles sobre la profundidad del sueño.';

  @override
  String get sleepDepthConfidenceTooLow =>
      'La fiabilidad de las fases es demasiado baja para desglosar la profundidad del sueño.';

  @override
  String get sleepDepthBreakdownUnavailable =>
      'No hay un desglose de la duración de las fases para esta noche.';

  @override
  String get sleepDepthRatingRestorative => 'Reparador';

  @override
  String get sleepDepthRatingLightLeaning => 'Predominio de sueño ligero';

  @override
  String sleepDepthStageConfidenceLabel(String value) {
    return 'Fiabilidad de las fases: $value';
  }

  @override
  String get sleepDepthSubtitle =>
      'Distribución de las fases según los segmentos de la cronología calculada.';

  @override
  String get sleepInterruptionsUnavailable =>
      'No hay datos disponibles sobre las interrupciones.';

  @override
  String get sleepInterruptionsStatusNoneDetected => 'No se detectaron';

  @override
  String get sleepInterruptionsStatusDetected => 'Detectadas';

  @override
  String get sleepInterruptionsSubtitle =>
      'Despertares nocturnos que cumplen los criterios.';

  @override
  String get sleepInterruptionsTotalWakeDuration => 'Duración total despierto';

  @override
  String get sleepInterruptionsFootnote =>
      'Esta vista solo incluye las interrupciones que cumplen los criterios del análisis derivado.';

  @override
  String get sleepRegularityUnavailable =>
      'No hay datos disponibles sobre la regularidad.';

  @override
  String sleepRegularityNightRange(int count) {
    return 'Intervalo de $count noches';
  }

  @override
  String get sleepRegularityStatusSufficientTrend =>
      'Datos suficientes para ver la tendencia';

  @override
  String get sleepRegularityStatusLimitedTrend =>
      'Datos de tendencia limitados';

  @override
  String get sleepRegularitySubtitle =>
      'Horas de acostarse y despertarse de las noches recientes.';

  @override
  String get sleepRegularityAverageBedtime => 'Hora media de acostarse';

  @override
  String get sleepRegularityAverageWake => 'Hora media de despertarse';

  @override
  String get sleepHeartRateUnavailable =>
      'No hay datos disponibles sobre la frecuencia cardíaca durante el sueño.';

  @override
  String get sleepHeartRateStatusNoSampleSeries =>
      'No hay una serie de mediciones para esta noche';

  @override
  String get sleepHeartRateStatusBaselineNotEstablished =>
      'Aún no hay un valor de referencia establecido';

  @override
  String get sleepHeartRateStatusComparisonUnavailable =>
      'No se puede comparar con el valor de referencia';

  @override
  String get sleepHeartRateStatusBelowBaseline =>
      'Por debajo del valor de referencia';

  @override
  String get sleepHeartRateStatusAboveBaseline =>
      'Por encima del valor de referencia';

  @override
  String get sleepHeartRateNoSamplesText =>
      'No hay mediciones guardadas de la frecuencia cardíaca durante el sueño para esta noche.';

  @override
  String get sleepHeartRateBaselineNotEstablishedText =>
      'Aún no hay un valor de referencia establecido. Al principio es normal y no indica ningún problema.';

  @override
  String get sleepHeartRateComparisonUnavailableText =>
      'La comparación con el valor de referencia no está disponible esta noche.';

  @override
  String sleepHeartRateDeltaText(String direction, String delta, String unit) {
    return 'La frecuencia cardíaca durante el sueño está $direction del valor de referencia por $delta $unit.';
  }

  @override
  String get sleepHeartRateDirectionBelow => 'por debajo';

  @override
  String get sleepHeartRateDirectionAbove => 'por encima';

  @override
  String get sleepHeartRateComparedBaselineSubtitle =>
      'Comparación con tu valor de referencia establecido durante el sueño.';

  @override
  String get sleepHeartRateNoBaselineSubtitle =>
      'Aún no hay un valor de referencia establecido. Esto es normal.';

  @override
  String get sleepHeartRateSamplesUnavailable =>
      'No se guardaron muestras de frecuencia cardíaca para esta noche. El gráfico de tendencias no está disponible.';

  @override
  String sleepHeartRateDashedLineHint(String value, String unit) {
    return 'La línea discontinua muestra la referencia ($value $unit).';
  }

  @override
  String get sleepBpmUnit => 'lpm';

  @override
  String get sleepRawImportImportedAt => 'Importado el';

  @override
  String get sleepRawImportStatus => 'Estado';

  @override
  String get sleepRawImportSource => 'Fuente';

  @override
  String get sleepRawImportApp => 'App';

  @override
  String get sleepRawImportConfidence => 'Confianza';

  @override
  String get sleepRawImportPayload => 'Datos';

  @override
  String get adaptiveBodyweightTargetSectionTitle =>
      'Objetivo de peso corporal adaptativo';

  @override
  String get adaptiveRecommendationSettingsSectionTitle =>
      'Ajustes de las recomendaciones';

  @override
  String get adaptiveGoalDirectionLabel => 'Objetivo';

  @override
  String get adaptiveGoalLose => 'Perder peso';

  @override
  String get adaptiveGoalMaintain => 'Mantener el peso';

  @override
  String get adaptiveGoalGain => 'Ganar peso';

  @override
  String adaptiveRatePerWeek(String value, Object unit) {
    return '$value $unit/semana';
  }

  @override
  String get adaptivePriorActivityLabel => 'Actividad diaria habitual';

  @override
  String get adaptivePriorActivityLow => 'Actividad baja';

  @override
  String get adaptivePriorActivityModerate => 'Actividad moderada';

  @override
  String get adaptivePriorActivityHigh => 'Actividad alta';

  @override
  String get adaptivePriorActivityVeryHigh => 'Actividad muy alta';

  @override
  String get adaptivePriorActivityHelpIntro =>
      'Solo la actividad diaria habitual (sin contar el cardio adicional):';

  @override
  String get adaptivePriorActivityHelpLowLine =>
      'Baja: mayormente sentado, como en clase o en una oficina.';

  @override
  String get adaptivePriorActivityHelpModerateLine =>
      'Moderada: alternas entre estar sentado, caminar y estar de pie.';

  @override
  String get adaptivePriorActivityHelpHighLine =>
      'Alta: pasas mucho tiempo de pie o caminando, o tienes un trabajo físicamente activo.';

  @override
  String get adaptivePriorActivityHelpVeryHighLine =>
      'Muy alta: rutina o trabajo con mucho movimiento y actividad diaria intensa y constante.';

  @override
  String get adaptiveExtraCardioLabel =>
      'Cardio o resistencia adicional fuera de la app';

  @override
  String get adaptiveExtraCardioOption0 => '0 h/semana';

  @override
  String get adaptiveExtraCardioOption1 => '1 h/semana';

  @override
  String get adaptiveExtraCardioOption2 => '2 h/semana';

  @override
  String get adaptiveExtraCardioOption3 => '3 h/semana';

  @override
  String get adaptiveExtraCardioOption5 => '5 h/semana';

  @override
  String get adaptiveExtraCardioOption7Plus => '7+ h/semana';

  @override
  String get adaptiveExtraCardioHelp =>
      'Incluye salir a trotar, correr, montar en bici, nadar u otras sesiones de resistencia que no registres como entrenamientos en Train Libre.';

  @override
  String get onboardingAdaptiveGoalTitle =>
      'Recomendación nutricional adaptativa';

  @override
  String get onboardingAdaptiveGoalSubtitle =>
      'Elige tu objetivo y ritmo semanal. Calcularemos una recomendación inicial prudente y la iremos ajustando según tus registros.';

  @override
  String get adaptiveRecommendationGenerating => 'Generando…';

  @override
  String get adaptiveRecommendationRefresh => 'Actualizar recomendación';

  @override
  String get onboardingAdaptiveSummaryEmpty =>
      'Configura tu objetivo y toca Actualizar para ver una recomendación inicial.';

  @override
  String get onboardingAdaptiveSummaryTitle =>
      'Vista previa de la recomendación';

  @override
  String onboardingAdaptiveSummaryCalories(int value) {
    return 'Calorías: $value kcal';
  }

  @override
  String onboardingAdaptiveSummaryProtein(int value) {
    return 'Proteínas: $value g';
  }

  @override
  String onboardingAdaptiveSummaryCarbs(int value) {
    return 'Carbohidratos: $value g';
  }

  @override
  String onboardingAdaptiveSummaryFat(int value) {
    return 'Grasas: $value g';
  }

  @override
  String onboardingAdaptiveSummaryConfidence(String value) {
    return 'Base de datos: $value';
  }

  @override
  String get onboardingAdaptiveSummaryApply =>
      'Aplicar a los objetivos diarios';

  @override
  String get onboardingAdaptiveSummaryApplied =>
      'Aplicado a los objetivos diarios';

  @override
  String get onboardingBodyFatPageTitle => 'Grasa corporal %';

  @override
  String get onboardingBodyFatPageSubtitle =>
      'Paso opcional: introduce una estimación aproximada si la conoces.';

  @override
  String get onboardingBodyFatOptionalLabel => 'Grasa corporal % (opcional)';

  @override
  String get onboardingBodyFatOptionalHelper =>
      'Opcional: introduce un valor solo si lo conoces aproximadamente. Puedes dejarlo vacío. Nos ayuda a personalizar la recomendación inicial.';

  @override
  String get onboardingBodyFatHelpAction => '¿Cómo puedo estimarlo?';

  @override
  String get bodyFatGuidanceTitle =>
      'Guía sobre el porcentaje de grasa corporal';

  @override
  String get bodyFatGuidanceIntro =>
      'El porcentaje de grasa corporal solo se puede estimar de forma aproximada por el aspecto físico. Sirve como orientación, no como diagnóstico preciso.';

  @override
  String get bodyFatGuidanceDisclaimer =>
      'El aspecto físico puede variar mucho con el mismo porcentaje de grasa corporal por la masa muscular, la distribución de la grasa, la genética, la retención de líquidos, la postura y la iluminación.';

  @override
  String get bodyFatGuidanceSexLabel => 'Sexo de referencia';

  @override
  String bodyFatGuidancePercent(int percent) {
    return '$percent%';
  }

  @override
  String get bodyFatGuidanceMale10 => 'Muy definido, con poca grasa.';

  @override
  String get bodyFatGuidanceMale15 => 'Atlético y visiblemente definido.';

  @override
  String get bodyFatGuidanceMale20 => 'Aspecto deportivo, algo menos definido.';

  @override
  String get bodyFatGuidanceMale25 =>
      'Menos definición y algo más de grasa en la cintura y el abdomen.';

  @override
  String get bodyFatGuidanceMale30 =>
      'Aspecto claramente más suave y redondeado.';

  @override
  String get bodyFatGuidanceMale35 =>
      'Aspecto muy suave, casi sin definición visible.';

  @override
  String get bodyFatGuidanceMale40 =>
      'Aspecto mucho más redondeado, sin definición visible.';

  @override
  String get bodyFatGuidanceFemale15 => 'Muy definida, con poca grasa.';

  @override
  String get bodyFatGuidanceFemale20 => 'Delgada y atlética.';

  @override
  String get bodyFatGuidanceFemale25 => 'En forma, con una ligera suavidad.';

  @override
  String get bodyFatGuidanceFemale30 =>
      'Aspecto suave y saludable, entre atlético y normal.';

  @override
  String get bodyFatGuidanceFemale35 => 'Aspecto visiblemente más suave.';

  @override
  String get bodyFatGuidanceFemale40 =>
      'Aspecto general claramente más suave y redondeado.';

  @override
  String get adaptiveRecommendationCardTitle => 'Recomendación adaptativa';

  @override
  String get adaptiveRecommendationEmptyBody =>
      'Registra tu peso y alimentación durante aproximadamente una semana para obtener tu primera recomendación semanal.';

  @override
  String adaptiveRecommendationGoalLine(String goal, String rate) {
    return 'Objetivo: $goal ($rate)';
  }

  @override
  String adaptiveRecommendationMaintenanceLine(int value) {
    return 'Mantenimiento estimado: $value kcal';
  }

  @override
  String adaptiveRecommendationMaintenanceRangeLine(int lower, int upper) {
    return 'Intervalo probable: $lower-$upper kcal';
  }

  @override
  String get adaptiveRecommendationUncertaintyHintNarrow =>
      'El intervalo probable de mantenimiento es bastante preciso. Es normal que haya pequeñas variaciones de un día a otro.';

  @override
  String get adaptiveRecommendationUncertaintyHintModerate =>
      'El intervalo probable de mantenimiento es moderado por ahora. Es normal que varíe algo de una semana a otra.';

  @override
  String get adaptiveRecommendationUncertaintyHintWide =>
      'El intervalo probable de mantenimiento aún es amplio. Es normal mientras reunimos datos más constantes.';

  @override
  String get adaptiveRecommendationStabilizingHint =>
      'Aún estamos ajustando el cálculo a tu fase reciente, así que la estimación puede variar más de lo habitual.';

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
    return 'Base de datos: $value';
  }

  @override
  String adaptiveRecommendationDataBasisLine(
      int windowDays, int weightLogs, int intakeDays) {
    return 'Base de datos: $windowDays días, $weightLogs registros de peso, $intakeDays días de alimentación';
  }

  @override
  String adaptiveRecommendationActiveCaloriesLine(int value) {
    return 'Calorías activas actuales: $value kcal';
  }

  @override
  String adaptiveRecommendationCalculatedAtLine(String value) {
    return 'Calculado el: $value';
  }

  @override
  String adaptiveRecommendationNextDueLine(String value) {
    return 'Próxima recomendación adaptativa: $value';
  }

  @override
  String adaptiveRecommendationNextDueShort(String value) {
    return 'Próxima: $value';
  }

  @override
  String get adaptiveRecommendationDueNowLine =>
      'Esta semana toca una nueva recomendación adaptativa.';

  @override
  String get adaptiveRecommendationDueNowShort => 'Toca esta semana';

  @override
  String get adaptiveRecommendationMaintenanceLabel => 'Mantenimiento estimado';

  @override
  String get adaptiveRecommendationWhyTitle => '¿Por qué esta recomendación?';

  @override
  String get adaptiveRecommendationWhySubtitle =>
      'Estimación de mantenimiento, calidad de los datos y detalles del cálculo';

  @override
  String get adaptiveRecommendationMaintenanceSourceLabel =>
      'Datos previos del perfil + registros recientes';

  @override
  String get adaptiveRecommendationMaintenanceUnit => 'kcal/día';

  @override
  String get adaptiveRecommendationMacroTargetsLabel =>
      'Objetivos recomendados';

  @override
  String get adaptiveRecommendationAlreadyActive => 'Ya está activo';

  @override
  String adaptiveRecommendationTargetChange(String value) {
    return '$value respecto al objetivo actual';
  }

  @override
  String get adaptiveRecommendationTargetCaloriesLabel => 'Objetivo de kcal';

  @override
  String get adaptiveRecommendationDataQualityLabel => 'Calidad de los datos';

  @override
  String adaptiveRecommendationTrajectoryCorrectionLine(String value) {
    return 'Ajuste de tendencia: $value kcal/día';
  }

  @override
  String get adaptiveRecommendationTrajectoryCorrectionExplanation =>
      'Un ajuste limitado ayuda a acercar el ritmo reciente de cambio de peso a tu objetivo.';

  @override
  String get adaptiveRecommendationRecalculateNowAction => 'Recalcular ahora';

  @override
  String get adaptiveRecommendationRecalculating => 'Recalculando…';

  @override
  String get adaptiveRecommendationApplying => 'Aplicando…';

  @override
  String get adaptiveRecommendationApplyAction => 'Aplicar recomendación';

  @override
  String get adaptiveRecommendationWarningCalorieFloor =>
      'La recomendación está limitada por un mínimo de calorías por seguridad. Revisa los datos de tu perfil y tus registros recientes antes de aplicarla.';

  @override
  String get adaptiveRecommendationWarningUnresolvedFood =>
      'No se pudieron calcular por completo las calorías de algunos alimentos. Revisa tus registros recientes antes de aplicar la recomendación.';

  @override
  String get adaptiveRecommendationWarningLargeAdjustment =>
      'Se ha detectado un ajuste grande. Revisa que tus registros recientes estén completos antes de aplicarlo.';

  @override
  String get adaptiveRecommendationWarningMacroConstrained =>
      'El reparto de macronutrientes está limitado por el presupuesto de calorías. Comprueba si tu ritmo objetivo es demasiado exigente.';

  @override
  String get adaptiveRecommendationWarningConservative =>
      'Se recomienda revisar la propuesta: se ha ajustado con prudencia debido a la variabilidad de los datos.';

  @override
  String get adaptiveRecommendationDataBasisHintDefault =>
      'Se basa en los registros recientes y en su grado de detalle.';

  @override
  String get adaptiveRecommendationDataBasisHintPriorOnly =>
      'Solo se basa en los datos previos del perfil. Añade registros recientes de peso y alimentación para ajustar la recomendación.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeight =>
      'Hay pocos registros recientes de peso, por lo que la tendencia es menos fiable.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseIntake =>
      'Hay pocos registros recientes de alimentación, por lo que la estimación de mantenimiento es menos fiable.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeightAndIntake =>
      'Hay pocos registros recientes de peso y alimentación, por lo que esta recomendación es más prudente.';

  @override
  String get adaptiveConfidenceNotEnoughData => 'Solo datos previos del perfil';

  @override
  String get adaptiveConfidenceLow => 'Pocos registros recientes';

  @override
  String get adaptiveConfidenceMedium => 'Registros recientes suficientes';

  @override
  String get adaptiveConfidenceHigh => 'Registros recientes sólidos';

  @override
  String get adaptiveRecommendationRecalculatedSnack =>
      'Recomendación recalculada.';

  @override
  String get adaptiveRecommendationAppliedToGoalsSnack =>
      'Recomendación aplicada a los objetivos activos.';

  @override
  String get adaptiveRecommendationNotAvailableSnack =>
      'No hay ninguna recomendación disponible para aplicar.';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsAppearanceSubtitle =>
      'Ajusta el tema, el aspecto y la respuesta háptica';

  @override
  String get settingsShowSugarInDiaryOverviewTitle =>
      'Mostrar azúcar en el resumen del diario';

  @override
  String get settingsShowSugarInDiaryOverviewSubtitle =>
      'Muestra el azúcar en la sección superior del resumen diario';

  @override
  String get settingsOverviewExtraNutrientTitle =>
      'Nutriente adicional en el resumen';

  @override
  String get settingsOverviewExtraNutrientSubtitle =>
      'Añade una tercera tarjeta de nutrientes al resumen diario';

  @override
  String get settingsSectionHealthTracking => 'Salud y seguimiento';

  @override
  String get healthSettingsTitle => 'Salud';

  @override
  String get onboardingHealthSettingsDescription =>
      'Gestiona los pasos, el sueño, el pulso y Apple Health o Health Connect';

  @override
  String get healthSettingsStepActive =>
      'El seguimiento de pasos está activado';

  @override
  String get healthSettingsStepAvailable => 'Hay datos de pasos disponibles';

  @override
  String get healthSettingsStepUnavailable =>
      'No hay datos de pasos disponibles';

  @override
  String get healthSettingsSyncSteps => 'Sincronizar pasos ahora';

  @override
  String get healthSettingsSyncExport => 'Exportar ahora';

  @override
  String healthSettingsStepsSyncResult(int count) {
    return 'Se han actualizado $count segmentos de pasos';
  }

  @override
  String healthSettingsSleepSyncResult(int count) {
    return 'Se han importado $count sesiones de sueño';
  }

  @override
  String get settingsStepsSubtitle =>
      'Seguimiento, política de fuentes y proveedores';

  @override
  String get settingsSleepSubtitle =>
      'Importación, permisos y estado del sueño';

  @override
  String get settingsPulseSubtitle =>
      'Análisis del pulso opcional y acceso a la frecuencia cardíaca';

  @override
  String get settingsHealthExportSubtitle =>
      'Gestiona las exportaciones a Apple Health y Health Connect';

  @override
  String get settingsSectionNutritionAndData => 'Nutrición y datos';

  @override
  String get settingsSectionSupportAbout => 'Ayuda e información';

  @override
  String get settingsHapticFeedbackTitle => 'Respuesta háptica';

  @override
  String get settingsHapticFeedbackSubtitle =>
      'Vibraciones suaves para confirmar acciones y durante la espera de la IA';

  @override
  String get stepsSettingsEnableTrackingTitle =>
      'Activar el seguimiento de pasos';

  @override
  String get stepsSettingsEnableTrackingSubtitle =>
      'Leer los datos de pasos de Apple Health o Health Connect';

  @override
  String get stepsSettingsSourcePolicyTitle => 'Política de origen';

  @override
  String get stepsSettingsSourcePolicyAutoDominant =>
      'Automático (fuente predominante)';

  @override
  String get stepsSettingsSourcePolicyAutoDominantSubtitle =>
      'Recomendado: usar una sola fuente al día para evitar contar pasos solapados.';

  @override
  String get stepsSettingsSourcePolicyMaxPerHour =>
      'Combinar (máximo por hora)';

  @override
  String get stepsSettingsSourcePolicyMaxPerHourSubtitle =>
      'Combina las fuentes tomando el valor horario más alto.';

  @override
  String get stepsSettingsProviderFilterTitle => 'Filtro de proveedores';

  @override
  String get pulseTitle => 'Pulso';

  @override
  String get pulseChartTitle => 'Evolución del pulso';

  @override
  String get pulseRangeLabel => 'Intervalo';

  @override
  String get pulseAverageLabel => 'Media';

  @override
  String get pulseRestingLabel => 'En reposo';

  @override
  String get pulseInsufficientData =>
      'Hay muy pocas muestras de pulso para mostrar un gráfico fiable.';

  @override
  String get pulseMethodNote =>
      'El pulso medio se pondera por tiempo. El pulso en reposo se estima de forma conservadora a partir del 20 % de las muestras más bajas del periodo seleccionado.';

  @override
  String pulseSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count muestras',
      one: '1 muestra',
      zero: 'Sin muestras',
    );
    return '$_temp0';
  }

  @override
  String get pulseQualityReady => 'Cobertura adecuada';

  @override
  String get pulseQualityLimited => 'Datos limitados';

  @override
  String get pulseQualityInsufficient => 'Muy pocos datos';

  @override
  String get pulseQualityNoData => 'Sin datos';

  @override
  String get pulseNoDataDisabled =>
      'El análisis del pulso está desactivado en Ajustes.';

  @override
  String get pulseNoDataPermissionDenied =>
      'Se necesita permiso para acceder a la frecuencia cardíaca y mostrar el análisis del pulso.';

  @override
  String get pulseNoDataUnavailable =>
      'Los datos del pulso no están disponibles en este dispositivo.';

  @override
  String get pulseNoDataQueryFailed =>
      'No se pudieron leer los datos del pulso.';

  @override
  String get pulseNoDataDefault =>
      'No se encontraron muestras de pulso para este periodo.';

  @override
  String get pulseSettingsEnableTitle => 'Activar el análisis del pulso';

  @override
  String get pulseSettingsEnableSubtitle =>
      'Solo leeremos los datos de frecuencia cardíaca para mostrar el pulso si activas esta opción.';

  @override
  String get pulseSettingsPermissionTitle =>
      'Permitir el acceso a la frecuencia cardíaca';

  @override
  String get pulseSettingsPermissionSubtitle =>
      'Abre Apple Health o Health Connect para que Train Libre pueda leer las muestras de pulso.';

  @override
  String get pulseSettingsAnalysisSubtitle =>
      'Muestra el intervalo, la media ponderada por tiempo y una estimación conservadora del pulso en reposo. No es un diagnóstico médico.';

  @override
  String get pulseSettingsPermissionGranted =>
      'El acceso a la frecuencia cardíaca está listo.';

  @override
  String get pulseSettingsPermissionFailed =>
      'No se concedió el acceso a la frecuencia cardíaca.';

  @override
  String get pulseOptInChip => 'Opcional';

  @override
  String get statisticsPulseDescription =>
      'Intervalo, media ponderada por tiempo y pulso en reposo para los periodos seleccionados.';

  @override
  String get statisticsPulseOpenCaption => 'Abre el análisis del pulso';

  @override
  String get healthExportTitle => 'Exportación de datos de salud';

  @override
  String get healthExportAppleHealthTitle => 'Exportación a Apple Health';

  @override
  String get healthExportHealthConnectTitle => 'Exportación a Health Connect';

  @override
  String get healthExportDomainNutritionHydration => 'Nutrición e hidratación';

  @override
  String get healthNutritionImportTitle => 'Importar nutrición';

  @override
  String get healthNutritionImportSubtitle =>
      'Importa los totales diarios de Apple Health o Health Connect a tu diario.';

  @override
  String get healthNutritionImportPolicy =>
      'Las entradas manuales se mantienen separadas. Los días importados no se sobrescriben tras editarlos localmente ni se vuelven a crear después de eliminarlos.';

  @override
  String get healthExportDomainWorkouts => 'Entrenamientos';

  @override
  String get healthExportStateIdle => 'Inactiva';

  @override
  String get healthExportStateExporting => 'Exportando';

  @override
  String get healthExportStateSuccess => 'Correcta';

  @override
  String get healthExportStateFailed => 'Error';

  @override
  String get healthExportStatePermissionRequired => 'Se necesita permiso';

  @override
  String get healthExportStateDisabled => 'Desactivada';

  @override
  String get healthExportResultComplete => 'Exportación completada';

  @override
  String get healthExportResultFailed => 'Error al exportar';

  @override
  String get healthExportAppleHealthSubtitle =>
      'Exportación unidireccional a Apple Health. Train Libre solo lee los registros que ha exportado, por lo que puede sustituirlos de forma segura al editarlos.';

  @override
  String get healthExportHealthConnectSubtitle =>
      'Exportación unidireccional de Train Libre a Health Connect';

  @override
  String get healthExportAppleHealthStatusTitle =>
      'Estado de la exportación a Apple Health';

  @override
  String get healthExportHealthConnectStatusTitle =>
      'Estado de la exportación a Health Connect';

  @override
  String get healthConnectWeightImportTitle =>
      'Importar medidas corporales de Health Connect';

  @override
  String get healthConnectWeightImportSubtitle =>
      'Importa el peso y el porcentaje de grasa corporal de básculas y otras apps. Se ignoran los registros de Train Libre.';

  @override
  String get appleHealthWeightImportTitle =>
      'Importar medidas corporales de Apple Health';

  @override
  String get appleHealthWeightImportSubtitle =>
      'Importa el peso, la grasa corporal y la cintura de Apple Health. Se ignoran los registros de Train Libre.';

  @override
  String get healthConnectWeightImportReady =>
      'Acceso al historial completo activado';

  @override
  String get healthConnectWeightImportLimited =>
      'Limitado al historial reciente disponible';

  @override
  String get healthConnectWeightImportUnavailable =>
      'Health Connect no está disponible';

  @override
  String get healthConnectWeightImportNow => 'Importar ahora';

  @override
  String healthConnectWeightImportResult(int imported, int updated) {
    return 'Importados: $imported; actualizados: $updated';
  }

  @override
  String get settingsBaseFoodLanguageTitle => 'Idioma de los alimentos básicos';

  @override
  String get settingsBaseFoodLanguageSubtitle =>
      'Elige el idioma de los nombres de los alimentos básicos.';

  @override
  String get settingsBaseFoodLanguageFollowApp => 'Seguir el idioma de la app';

  @override
  String get settingsBaseFoodLanguageEnglish => 'Inglés';

  @override
  String get settingsBaseFoodLanguageGerman => 'Alemán';

  @override
  String get settingsBaseFoodLanguageFrench => 'Francés';

  @override
  String get settingsBaseFoodLanguageItalian => 'Italiano';

  @override
  String get settingsBaseFoodLanguageJapanese => 'Japonés';

  @override
  String get settingsBaseFoodLanguageSpanish => 'Español';

  @override
  String get settingsBaseFoodLanguageDutch => 'Neerlandés';

  @override
  String get aiModelLabel => 'Modelo';

  @override
  String get aiModelListFallbackTitle =>
      'Se muestra la lista de modelos integrada';

  @override
  String get aiModelListRetry => 'Volver a cargar los modelos';

  @override
  String get aiModelListErrorMissingKey =>
      'Guarda tu clave de API para cargar los modelos actuales del proveedor.';

  @override
  String get aiModelListErrorNetwork =>
      'No se pudo conectar con el proveedor. Comprueba tu conexión a internet.';

  @override
  String get aiModelListErrorTimeout =>
      'El proveedor no respondió dentro del tiempo de espera configurado.';

  @override
  String aiModelListErrorAuth(Object status) {
    return 'El proveedor rechazó tu clave de API (HTTP $status). Comprueba la clave y sus permisos.';
  }

  @override
  String aiModelListErrorRateLimit(Object status) {
    return 'El proveedor está limitando las solicitudes o se ha agotado tu cuota (HTTP $status). Inténtalo de nuevo dentro de unos instantes.';
  }

  @override
  String aiModelListErrorHttp(Object status) {
    return 'El proveedor respondió con HTTP $status.';
  }

  @override
  String get aiModelListErrorResponse =>
      'No se pudo leer la lista de modelos del proveedor.';

  @override
  String get autoBackupStoragePickerUnavailable =>
      'El selector de almacenamiento no está disponible. Reinicia o reinstala la app por completo después de actualizarla.';

  @override
  String autoBackupFolderPickerFailed(Object error) {
    return 'No se pudo abrir el selector de carpetas: $error';
  }

  @override
  String get healthExportPermissionDenied => 'Permiso denegado';

  @override
  String get healthExportAdapterUnavailable => 'Adaptador no disponible';

  @override
  String get healthExportPlatformUnavailable => 'Plataforma no disponible';

  @override
  String get healthExportPlatformNotInstalled => 'Plataforma no instalada';

  @override
  String get healthExportExportDisabled => 'Exportación desactivada';

  @override
  String get onboardingMacrosStepTitle => 'Macronutrientes';

  @override
  String get onboardingMacrosStepSubtitle =>
      '¿Cómo se compone tu alimentación?';

  @override
  String get statisticsProviderAppleHealth => 'Apple Health';

  @override
  String get statisticsProviderHealthConnect => 'Health Connect';

  @override
  String get statisticsProviderWithings => 'Withings';

  @override
  String get statisticsProviderGarmin => 'Garmin';

  @override
  String get statisticsProviderFitbit => 'Fitbit';

  @override
  String get statisticsProviderLocal => 'Local';

  @override
  String get unit_milliliters => 'ml';

  @override
  String get unit_kilograms => 'kg';

  @override
  String get mealEditorHintExample => 'p. ej., bol de pollo';

  @override
  String get mealEditorNoIngredientsYet =>
      'Todavía no hay ingredientes; llegarán más adelante';

  @override
  String get foodDetailSavedBaseDb => 'Guardado (base de datos)';

  @override
  String foodDetailExportError(Object error) {
    return 'Error al exportar: $error';
  }

  @override
  String get stepsModulePrevious => 'Anterior';

  @override
  String get stepsModuleNext => 'Siguiente';

  @override
  String get stepsModuleTotalSteps => 'Pasos totales';

  @override
  String get stepsModuleThisWeek => 'Esta semana';

  @override
  String get stepsModuleThisMonth => 'Este mes';

  @override
  String stepsModuleUpdated(String time) {
    return 'Actualizado: $time';
  }

  @override
  String get stepsModuleScopeSwitcherSemantics => 'Cambiar el periodo de pasos';

  @override
  String get stepsModuleDay => 'Día';

  @override
  String get stepsModuleWeek => 'Semana';

  @override
  String get stepsModuleMonth => 'Mes';

  @override
  String get stepsModuleHourlyTimeline => 'Cronología por hora';

  @override
  String get stepsModuleTotal => 'Total';

  @override
  String get stepsModuleActiveHours => 'Horas activo';

  @override
  String get stepsModulePeakHour => 'Hora punta';

  @override
  String get stepsModuleAvgPerDay => 'Media diaria';

  @override
  String get stepsModuleGoalHit => 'Objetivo alcanzado';

  @override
  String get stepsModuleGoalDays => 'Días con objetivo alcanzado';

  @override
  String get diarySyncingSteps => 'Sincronizando pasos…';

  @override
  String get diaryLoadingSleep => 'Cargando datos del sueño…';

  @override
  String get unit_milligrams => 'mg';

  @override
  String get scannerPermissionRequired =>
      'Se necesita acceso a la cámara para escanear códigos de barras.';

  @override
  String get scannerPermissionPermanentlyDenied =>
      'Se ha denegado permanentemente el acceso a la cámara. Actívalo en Ajustes para escanear códigos de barras.';

  @override
  String get scannerOpenSettings => 'Abrir Ajustes';

  @override
  String get scannerGrantPermission => 'Continuar';

  @override
  String get scannerAlignInstruction =>
      'Alinea el código de barras en horizontal dentro de la línea láser roja';

  @override
  String get scannerToggleFlash => 'Activar o desactivar la linterna';

  @override
  String get about_train_libre => 'Acerca de Train Libre';

  @override
  String get legal_notice => 'Aviso legal';

  @override
  String get privacy_policy => 'Política de privacidad';

  @override
  String get terms_of_service => 'Condiciones del servicio';

  @override
  String get view_in_browser => 'Ver en el navegador';

  @override
  String get legal_document_version => 'Versión';

  @override
  String get legal_document_last_updated => 'Última actualización';

  @override
  String get used_libraries => 'Bibliotecas utilizadas';

  @override
  String get licensing_info => 'Información sobre licencias';

  @override
  String get project_website => 'Sitio web del proyecto';

  @override
  String get github_repository => 'Repositorio de GitHub';

  @override
  String get health_permission_dialog_title => 'Datos de salud y privacidad';

  @override
  String get health_permission_dialog_body =>
      'Train Libre usa los pasos para estadísticas diarias y semanales. Los datos importados también pueden incluirse en copias de seguridad o compartirse con la IA al usar esa función. Gestiona el acceso a Salud en los ajustes del dispositivo.';

  @override
  String get health_permission_continue => 'Continuar';

  @override
  String get health_permission_not_now => 'Ahora no';

  @override
  String get welcome_privacy_title => 'Bienvenida y privacidad';

  @override
  String get welcome_privacy_body =>
      'Para ofrecer el seguimiento de entrenamientos y estadísticas, tratamos tus datos de actividad física tal como se describe en nuestra Política de privacidad.';

  @override
  String get i_agree_to_privacy_policy =>
      'Doy mi consentimiento expreso para tratar mis datos de actividad física y salud con el fin de registrar entrenamientos y ofrecer estadísticas, tal como se describe en la Política de privacidad. Si tengo preguntas sobre cómo retirar mi consentimiento, puedo contactar con feedback@schotte.me.';

  @override
  String get i_agree_to_optional_telemetry =>
      '(Opcional) Quiero compartir estadísticas de uso seudónimas. Los eventos pueden incluir identificadores técnicos y métricas de uso que pueden ser datos personales o de salud incluso sin mi nombre.';

  @override
  String get welcome_back_updated_legal_title =>
      'Te damos la bienvenida y te informamos de los cambios en las políticas';

  @override
  String legal_update_body(String version) {
    return 'Hemos actualizado nuestra Política de privacidad y las Condiciones del servicio (versión $version). Para seguir usando Train Libre, debes aceptar las condiciones actualizadas. Todos tus datos actuales siguen guardados de forma segura en tu dispositivo.';
  }

  @override
  String i_agree_to_updated_privacy_policy(String version) {
    return 'Acepto expresamente la Política de privacidad actualizada (v$version) y el tratamiento de mis datos de actividad física y salud.';
  }

  @override
  String get accept_and_continue => 'Aceptar y continuar';

  @override
  String get by_tapping_accept_continue =>
      'Al pulsar «Aceptar y continuar», aceptas la versión actualizada de';

  @override
  String get acceptTermsPrompt => 'Acepto las Condiciones del servicio';

  @override
  String get viewTermsInline => 'Condiciones del servicio';

  @override
  String get accept_and_get_started => 'Aceptar y empezar';

  @override
  String get by_tapping_accept => 'Al pulsar «Aceptar y empezar», aceptas';

  @override
  String get and_acknowledge => 'y confirmas que has leído';

  @override
  String get about_section => 'Acerca de';

  @override
  String get legal_section => 'Legal';

  @override
  String get aiSettingsInstructionTitle => 'Cómo funcionan las funciones de IA';

  @override
  String get aiSettingsInstructionBody =>
      'Las funciones de IA incluyen chat y reconocimiento de comidas. Los mensajes, imágenes y contexto se envían al modelo utilizado. El chat puede recurrir a otro proveedor. Los registros guardados requieren aprobación salvo que esté activa la aprobación automática.';

  @override
  String get aiSettingsSetupGuideTitle => 'Guía de configuración';

  @override
  String get aiSettingsSetupGuideBody =>
      'Para usar esta función, necesitas una clave API de un proveedor de IA. Usamos Google Gemini como ejemplo principal porque actualmente ofrece un plan gratuito para desarrolladores y usuarios.';

  @override
  String get aiSettingsGetApiKeyButton => 'Ver guía de configuración';

  @override
  String get legal_document_version_value => '1.2';

  @override
  String get legal_document_last_updated_value => '20 de mayo de 2026';

  @override
  String get muscleChest => 'Pecho';

  @override
  String get muscleBack => 'Espalda';

  @override
  String get muscleShoulders => 'Hombros';

  @override
  String get muscleBiceps => 'Bíceps';

  @override
  String get muscleTriceps => 'Tríceps';

  @override
  String get muscleQuads => 'Cuádriceps';

  @override
  String get muscleHamstrings => 'Isquiotibiales';

  @override
  String get muscleLegs => 'Piernas';

  @override
  String get muscleArms => 'Brazos';

  @override
  String get muscleGlutes => 'Glúteos';

  @override
  String get muscleCalves => 'Gemelos';

  @override
  String get muscleLowerBack => 'Zona lumbar';

  @override
  String get muscleAbs => 'Abdominales';

  @override
  String get muscleAdductors => 'Aductores';

  @override
  String get muscleForearms => 'Antebrazos';

  @override
  String get sleepDetailAnalysisHeader => 'Análisis detallado';

  @override
  String get sleepMetricDurationLabel => 'Duración del sueño';

  @override
  String get sleepMetricContinuityLabel => 'Continuidad (WASO/SE)';

  @override
  String get sleepMetricDepthLabel => 'Profundidad de las fases del sueño';

  @override
  String get sleepMetricTimingLabel => 'Ritmo circadiano';

  @override
  String get sleepMetricRegularityLabel => 'Regularidad';

  @override
  String get sleepBannerTstBottleneck =>
      'Penalización por duración del sueño: dormiste menos de las 6,5 horas óptimas para la recuperación, lo que limita la liberación de hormonas anabólicas.';

  @override
  String get sleepBannerRemBottleneck =>
      'Penalización por falta de sueño REM: dormiste menos de 60 minutos en fase REM. Esto perjudica la recuperación neuronal y la agilidad mental.';

  @override
  String get sleepBannerN3Bottleneck =>
      'Penalización por falta de sueño profundo: no alcanzaste los 70 minutos mínimos de sueño profundo N3. La reparación del tejido muscular puede ser insuficiente.';

  @override
  String get sleepBannerTimingBottleneck =>
      'Penalización por desfase circadiano: el punto medio de tu sueño fue después de las 05:30. Dormir fuera de tu ritmo interno reduce la calidad del sueño y la sensibilidad a la insulina.';

  @override
  String get sleepBannerDefaultPenalty =>
      'Penalización protectora: la duración del sueño fue insuficiente (menos de 6 h) o el horario de inicio estuvo muy desfasado. Se ha limitado la puntuación total.';

  @override
  String get infoTdeeTitle => 'Estimador adaptativo de calorías y TDEE';

  @override
  String get infoTdeeExplanation =>
      'Estima tu gasto energético diario total (TDEE) a partir de tu perfil, las comidas registradas y los cambios de peso.';

  @override
  String get infoTdeeKeyPoints =>
      '• Usa tus registros de peso y alimentación de los últimos 14 días para estimar el mantenimiento.\n• Tiene en cuenta como incertidumbre adicional las fluctuaciones de peso al cambiar de fase.\n• Aplica un ajuste independiente y limitado si tu ritmo se desvía de forma persistente de tu objetivo.';

  @override
  String get infoTdeeTechnicalTitle =>
      'Filtrado recursivo bayesiano y suavizado metabólico';

  @override
  String get infoTdeeTechnicalExplanation =>
      'Train Libre estima el mantenimiento como un estado oculto dinámico mediante un filtro de Kalman recursivo. La incertidumbre semanal del proceso permite que la estimación siga los cambios metabólicos reales, mientras que la incertidumbre de las observaciones evita reaccionar en exceso al peso del agua y a los registros incompletos. Un controlador de tendencia independiente y limitado puede ajustar el objetivo calórico tras dos desviaciones constantes del ritmo, sin cambiar la estimación de mantenimiento.';

  @override
  String get infoRecoveryTitle => 'Estimador de recuperación muscular';

  @override
  String get infoRecoveryExplanation =>
      'Estima la preparación y las curvas de recuperación de cada músculo según el volumen y la intensidad del entrenamiento y la proximidad al fallo.';

  @override
  String get infoRecoveryKeyPoints =>
      '• Tiene en cuenta la carga compartida entre músculos (por ejemplo, el press de banca trabaja pecho, tríceps y hombros).\n• Ajusta la velocidad de recuperación según las repeticiones en reserva (RIR) o el esfuerzo percibido (RPE), y amplía el plazo si llegas al fallo.\n• Calibra los plazos de recuperación según el tamaño y las características metabólicas de cada grupo muscular.';

  @override
  String get infoRecoveryTechnicalTitle =>
      'Fatiga por series equivalentes y modelo de decaimiento por tramos';

  @override
  String get infoRecoveryTechnicalExplanation =>
      'Calcula la preparación dinámica mediante curvas de decaimiento no lineales. El seguimiento del volumen distribuye automáticamente la carga entre grupos musculares principales y secundarios. La velocidad de recuperación depende de la proximidad al fallo (RIR) y amplía el plazo de forma estricta cuando las series llegan al fallo absoluto.';

  @override
  String get infoScientificReferencesButton =>
      'Ver referencias y fuentes científicas';

  @override
  String get infoScientificDisclaimer =>
      'Esta función se basa en literatura consolidada sobre ciencias del deporte y modelos metabólicos. La lista completa de fuentes revisadas por pares está disponible en nuestro sitio web.';

  @override
  String get infoAiMealTitle => 'Centro de registro de comidas con IA';

  @override
  String get infoAiMealExplanation =>
      'En el modo de catálogo, las sugerencias de IA se comparan con alimentos locales. El modo de estimación directa puede usar valores nutricionales estimados por IA. Revisa los resultados antes de guardarlos.';

  @override
  String get infoAiMealKeyPoints =>
      'En el modo de catálogo, las sugerencias de IA se comparan con alimentos locales. El modo de estimación directa puede usar valores nutricionales estimados por IA. Revisa los resultados antes de guardarlos.';

  @override
  String get infoAiMealTechnicalTitle =>
      'IA híbrida con BYOK y comparación Jaro-Winkler';

  @override
  String get infoAiMealTechnicalExplanation =>
      'En el modo de catálogo, las sugerencias de IA se comparan con alimentos locales. El modo de estimación directa puede usar valores nutricionales estimados por IA. Revisa los resultados antes de guardarlos.';

  @override
  String get infoSleepTitle => 'Calidad del sueño (SHS v3.5)';

  @override
  String get infoSleepExplanation =>
      'Calcula un índice global de sueño a partir de la cantidad, continuidad, profundidad, horario y regularidad diaria.';

  @override
  String get infoSleepKeyPoints =>
      '• Combina cinco dimensiones clínicas mediante una suma ponderada.\n• Ajusta automáticamente los requisitos si tu dispositivo no proporciona datos de determinadas fases o de la eficiencia del sueño.\n• Te protege con multiplicadores de límite flexible que restringen la puntuación total si una dimensión crítica, como el sueño REM o profundo, está comprometida.';

  @override
  String get infoSleepTechnicalTitle =>
      'Referencia ponderada y límites flexibles continuos';

  @override
  String get infoSleepTechnicalExplanation =>
      'Combina cinco dimensiones principales mediante una suma lineal ponderada: duración (30 %), continuidad (20 %), estructura (25 %), horario (15 %) y regularidad (10 %). Para evitar promedios engañosos cuando una dimensión clínica está comprometida, la puntuación final se reduce si se detectan problemas importantes en las fases del sueño o en el ritmo circadiano.';

  @override
  String get tdeeRecalculationNotificationTitle => 'TDEE recalculado';

  @override
  String tdeeRecalculationNotificationBody(
      int calories, int protein, int carbs, int fat) {
    return 'Nuevos objetivos diarios: $calories kcal | $protein g de proteínas | $carbs g de carbohidratos | $fat g de grasas';
  }

  @override
  String recommendationBannerText(String delta) {
    return 'Hay nuevos objetivos disponibles ($delta kcal).';
  }

  @override
  String get recommendationBannerApply => 'Aplicar';

  @override
  String get cancelingAndRollingBack =>
      'Cancelando y revirtiendo los cambios de forma segura…';

  @override
  String get sleepSyncTitle => 'Sincronizando el historial de sueño…';

  @override
  String get backupExportTitle => 'Exportando copia de seguridad…';

  @override
  String get backupImportTitle => 'Importando copia de seguridad…';

  @override
  String progressImportingNight(int index, int total) {
    return 'Importando noche $index/$total…';
  }

  @override
  String progressExportingTable(String table) {
    return 'Exportando $table…';
  }

  @override
  String progressImportingTable(String table) {
    return 'Restaurando $table…';
  }

  @override
  String get shareDailyLogTitle => 'Registro diario';

  @override
  String get shareSleepStartTime => 'Hora de inicio';

  @override
  String get shareSleepEndTime => 'Hora de finalización';

  @override
  String get shareSleepDeep => 'Sueño profundo';

  @override
  String get shareSleepLight => 'Sueño ligero';

  @override
  String get shareSleepRem => 'Sueño REM';

  @override
  String get shareSleepAwake => 'Despierto/interrupciones';

  @override
  String get shareTotalWater => 'Agua y líquidos totales';

  @override
  String get shareNutritionSummary => 'Resumen nutricional total';

  @override
  String get shareSleepEfficiency => 'Eficiencia';

  @override
  String get shareSleepRestingHeartRate => 'Frecuencia cardíaca en reposo';

  @override
  String get shareAsTextOrCopy => 'Compartir/copiar como texto';

  @override
  String get editExercise => 'Editar ejercicio';

  @override
  String exerciseCopyCreated(String exerciseName) {
    return 'Se ha creado una copia de «$exerciseName».';
  }

  @override
  String get copySystemExerciseTitle => 'Copiar ejercicio del sistema';

  @override
  String get copySystemExerciseBody =>
      'Este ejercicio lo proporciona la aplicación y no se puede editar directamente. ¿Quieres crear una copia personalizada para editarla?';

  @override
  String get createCopyAndEdit => 'Crear copia y editar';

  @override
  String get profileEdit => 'Editar perfil';

  @override
  String get selectBirthday => 'Seleccionar fecha de nacimiento';

  @override
  String get exerciseNoteTitle => 'Nota del ejercicio';

  @override
  String get exerciseNoteHint => 'Escribe notas o indicaciones…';

  @override
  String get editExerciseNotes => 'Añadir o editar nota';

  @override
  String get workoutNoteAddHint => 'Añade una nota aquí…';

  @override
  String get noteTypeTitle => 'Tipo de nota';

  @override
  String get pinnedExerciseNoteTitle => 'Nota fija del ejercicio';

  @override
  String get pinnedExerciseNoteDescription =>
      'Se rellena cada vez que registras este ejercicio.';

  @override
  String get pinnedRoutineNoteTitle => 'Nota fija de la rutina';

  @override
  String get pinnedRoutineNoteDescription =>
      'Solo se rellena para este ejercicio dentro de esta rutina.';

  @override
  String get workoutExerciseNoteTitle =>
      'Nota del ejercicio en el entrenamiento';

  @override
  String get workoutExerciseNoteDescription =>
      'Solo se aplica a este ejercicio en este entrenamiento.';

  @override
  String get deleteNoteTooltip => 'Eliminar nota';

  @override
  String get emptyStateAddFirstExerciseSubtitle =>
      'Añade un ejercicio para empezar a registrarlo.';

  @override
  String get syncRoutineTitle => '¿Actualizar rutina?';

  @override
  String get syncRoutineSubtitle =>
      'Se han detectado cambios en la estructura o el orden.';

  @override
  String syncRoutineBody(String routineName) {
    return '¿Quieres actualizar la rutina «$routineName» con los datos del entrenamiento actual (ejercicios, orden y series)?';
  }

  @override
  String get discard => 'Descartar';

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String get syncRoutineSuccess => 'Rutina actualizada correctamente.';

  @override
  String syncRoutineError(String error) {
    return 'Error al actualizar la rutina: $error';
  }

  @override
  String createRoutineError(String error) {
    return 'Error al crear la rutina: $error';
  }

  @override
  String nutritionPerQuantity(String quantity) {
    return 'Nutrientes por $quantity g';
  }

  @override
  String get settingsLocalModelName => 'Nombre del modelo local';

  @override
  String get settingsCustomBaseUrl => 'URL base personalizada';

  @override
  String get settingsCustomModelName => 'Nombre del modelo personalizado';

  @override
  String get settingsAiFoodNameLanguage =>
      'Idioma de los nombres de alimentos de la IA';

  @override
  String get settingsRequestTimeout => 'Tiempo de espera de la solicitud';

  @override
  String settingsSeconds(int seconds) {
    return '$seconds segundos';
  }

  @override
  String get semanticsApplyRecommendation => 'Aplicar recomendación';

  @override
  String get semanticsDismissBanner => 'Descartar aviso';

  @override
  String get importedWorkout => 'Entrenamiento importado';

  @override
  String get unknownExercise => 'Ejercicio desconocido';

  @override
  String get devExportBaseDb => 'Exportar base de datos principal';

  @override
  String get initCheckingExercises => 'Comprobando ejercicios…';

  @override
  String get initLoadingRemoteManifest => 'Cargando manifiesto remoto…';

  @override
  String get initExercisesUpToDate => 'Los ejercicios están actualizados';

  @override
  String get initNoDownloadRequired =>
      'No se requiere ninguna descarga remota.';

  @override
  String get initLoadingExercises => 'Cargando ejercicios…';

  @override
  String initDownloadingRemoteCatalog(String version) {
    return 'Descargando catálogo remoto de ejercicios $version…';
  }

  @override
  String get initPreparingImport => 'Preparando la descarga para importarla…';

  @override
  String get initExercisesReady => 'Ejercicios listos';

  @override
  String initImportingRemoteCatalog(String version) {
    return 'Importando catálogo remoto de ejercicios $version…';
  }

  @override
  String initCheckingProductDatabase(String country) {
    return 'Comprobando base de datos de productos ($country)…';
  }

  @override
  String get initProductDatabaseUpToDate =>
      'La base de datos de productos está actualizada';

  @override
  String get initLoadingProductDatabase =>
      'Cargando base de datos de productos…';

  @override
  String initDownloadingProductBundle(String version) {
    return 'Descargando paquete remoto de productos $version…';
  }

  @override
  String get initProductDatabaseReady => 'Base de datos de productos lista';

  @override
  String initImportingProductBundle(String version) {
    return 'Importando paquete de productos $version…';
  }

  @override
  String get initNoOffBundle =>
      'No hay ningún paquete de Open Food Facts ni acceso remoto disponible. Los datos locales existentes de Open Food Facts no se han modificado.';

  @override
  String initEntriesProgress(String processed, String totalCount) {
    return '$processed / $totalCount entradas';
  }

  @override
  String initUpdateTask(String task) {
    return 'Actualizar $task';
  }

  @override
  String initCheckingTask(String task) {
    return 'Comprobando $task…';
  }

  @override
  String initTaskUpToDate(String task) {
    return '$task está actualizado';
  }

  @override
  String get initInitializing => 'Inicializando…';

  @override
  String get initPreparation => 'Preparando…';

  @override
  String get initReady => 'Listo';

  @override
  String yearsOld(int age) {
    return '$age años';
  }

  @override
  String get customFoodsTitle => 'Alimentos personalizados';

  @override
  String get deleteFoodConfirmTitle => 'Eliminar alimento';

  @override
  String get deleteFoodConfirmBody =>
      '¿Seguro que quieres eliminar este alimento personalizado? Los registros anteriores no se verán afectados.';

  @override
  String get foodItemDeleted => 'Alimento eliminado';

  @override
  String get copySystemFoodTitle => 'Copiar alimento del sistema';

  @override
  String get copySystemFoodBody =>
      'Los alimentos del sistema no se pueden editar directamente. ¿Quieres crear una copia personalizada y editarla?';

  @override
  String foodCopyCreated(String name) {
    return 'Copia creada: $name';
  }

  @override
  String get nutritionPer100g => 'Información nutricional por 100 g';

  @override
  String nutritionPerPortion(int grams) {
    return 'Información nutricional por porción ($grams g)';
  }

  @override
  String get workoutConflictTitle => 'Entrenamiento en curso';

  @override
  String get workoutConflictContent =>
      'Ya tienes una sesión de entrenamiento activa. ¿Quieres reanudarla o descartarla para empezar una nueva?';

  @override
  String get resumeWorkoutButton => 'Reanudar entrenamiento';

  @override
  String get discardAndStartButton => 'Descartar y empezar';

  @override
  String get profileTapToSetUp => 'Toca para configurar';

  @override
  String get customLabel => 'Personalizado';

  @override
  String get noData => 'Sin datos';

  @override
  String get languageAuto => 'Automático';

  @override
  String aiValidationCostEstimation(num tokenCount) {
    return 'Coste: ~$tokenCount tokens';
  }

  @override
  String showAllWithCount(num count) {
    return 'Mostrar todo ($count)';
  }

  @override
  String repsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repeticiones',
      one: '1 repetición',
    );
    return '$_temp0';
  }

  @override
  String get offDownloadTitle => 'Descargar catálogos de bases de datos';

  @override
  String get offDownloadBody =>
      'Para usar alimentos básicos sin conexión, buscar productos envasados, escanear códigos de barras, consultar ejercicios y relacionar comidas con la IA, descarga los catálogos locales. El catálogo de ingredientes BLS 4.0 ocupa unos 25,6 MB; los catálogos de alimentos y ejercicios se descargan por separado.';

  @override
  String get offDownloadConfirm => 'Descargar ahora';

  @override
  String get offDownloadCancel => 'Ahora no';

  @override
  String get offDownloadCTA => 'Descargar base de datos';

  @override
  String get offPlaceholderText =>
      'Las funciones de nutrición requieren el catálogo de la base de datos local.';

  @override
  String get backupImportLockedTitle =>
      'Se necesita el catálogo de la base de datos';

  @override
  String get backupImportLockedBody =>
      'Antes de importar una copia de seguridad, hay que descargar e inicializar por completo los catálogos de ejercicios y nutrición para evitar inconsistencias. Descarga primero las bases de datos necesarias.';

  @override
  String get wgerPlaceholderText =>
      'Las funciones del catálogo de ejercicios requieren la base de datos local.';

  @override
  String get onboardingRegionTitle => 'Selecciona una región';

  @override
  String get onboardingRegionExplanation =>
      'Selecciona el país donde haces la compra. Así descargaremos la base de datos de Open Food Facts adecuada para los productos de tu zona.';

  @override
  String get onboardingRegionSettingsHint =>
      'Puedes cambiarlo más adelante en Ajustes → Nutrición → Región de la base de datos.';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String rollingDaysLabel(int days) {
    return 'Últimos $days días (móviles)';
  }

  @override
  String get muscleTraps => 'Trapecios';

  @override
  String get muscleObliques => 'Oblicuos';

  @override
  String get icloudSyncErrorTitle => 'Error al sincronizar con iCloud';

  @override
  String get icloudSyncErrorHelp =>
      'Comprueba que iCloud Drive esté activado en Ajustes del sistema de iOS: Ajustes -> [Tu nombre] -> iCloud -> iCloud Drive.';

  @override
  String get icloudSyncErrorCopyLog => 'Copiar registro técnico del error';

  @override
  String get icloudSyncErrorClose => 'Cerrar';

  @override
  String get icloudSyncErrorCopied =>
      '¡Registro de errores copiado al portapapeles!';

  @override
  String icloudLastSynced(String date) {
    return 'Última sincronización: $date';
  }

  @override
  String get icloudNeverSynced => 'Nunca sincronizado';

  @override
  String get emptyStateDiaryColdStartTitle =>
      '¡Te damos la bienvenida a tu diario!';

  @override
  String get emptyStateDiaryColdStartSubtitle =>
      'Registra aquí tu alimentación e hidratación.';

  @override
  String get emptyStateActiveGapOverlay =>
      'No hay datos disponibles para este periodo';

  @override
  String get emptyStateDiaryColdStartCallToAction =>
      'Registra aquí tu primera entrada';

  @override
  String get statisticsColdStartTitle =>
      '¡Te damos la bienvenida a tus estadísticas!';

  @override
  String get statisticsColdStartSubtitle =>
      'Tu progreso aparecerá aquí cuando registres tus primeros entrenamientos o comidas, o empieces a hacer seguimiento de tus pasos y sueño.';

  @override
  String get statisticsActiveGapTitle => 'No hay datos disponibles';

  @override
  String get reviewPromptTitle => '¿Te gusta Train Libre?';

  @override
  String get reviewPromptSubtitle =>
      'Tu opinión nos ayuda a mejorar la app continuamente, sin anuncios ni rastreadores.';

  @override
  String get reviewPromptYes => 'Sí, me gusta';

  @override
  String get reviewPromptNo => 'No mucho';

  @override
  String get reviewPromptLater => 'Recordármelo más tarde';

  @override
  String get updateAvailableTitle => 'Actualización disponible';

  @override
  String get statusReady => 'Listo';

  @override
  String get statusRequired => 'Obligatorio';

  @override
  String get updatesAvailableBody =>
      'Hay actualizaciones para tus catálogos locales. ¿Quieres actualizarlos ahora?';

  @override
  String get exerciseCatalogWger => 'Catálogo de ejercicios (OpenExerciseDB)';

  @override
  String get nutritionCatalogOff => 'Catálogo de nutrición (OFF)';

  @override
  String get workoutImportZeroNew =>
      'Se han importado 0 entrenamientos nuevos (ya existían todos).';

  @override
  String get telemetryDeleteDialogTitle => '¿Eliminar datos de telemetría?';

  @override
  String get telemetryDeleteDialogBody =>
      'Train Libre intentará restablecer los identificadores y contadores locales y solicitar su eliminación a PostHog. La solicitud puede fallar, no confirma la eliminación en el servidor y puede no incluir identificadores anteriores o copias de seguridad.';

  @override
  String get telemetryDeleteConfirmButton => 'Eliminar datos ahora';

  @override
  String get telemetryConsentTitle => '¿Ayudas a mejorar Train Libre?';

  @override
  String get telemetryConsentBody =>
      'Train Libre es una app independiente, creada por una sola persona, sin cuentas ni anuncios. Si quieres, puedes compartir estadísticas de uso seudonimizadas. Me ayudan a saber qué funciones se usan y cómo mejorar la app.';

  @override
  String get telemetryConsentPointAnonymous =>
      'Seudónimas: los eventos pueden incluir identificadores técnicos, contexto de la app y el dispositivo, uso de pantallas y funciones, recuentos exactos y duración de entrenamientos, recuentos de registros de comida, estado de solicitudes de IA e indicadores derivados de funciones relacionadas con nutrición o peso. Incluso sin tu nombre, pueden ser datos personales o de salud.';

  @override
  String get telemetryConsentPointNotSold =>
      'Sin publicidad en la app: Train Libre no muestra anuncios. Los eventos de uso se envían para estadísticas de la app; el tratamiento y el alojamiento dependen de la configuración del servicio.';

  @override
  String get telemetryConsentPointRevocable =>
      'Voluntarias: puedes desactivar los envíos futuros en Ajustes. La opción de eliminación restablece los identificadores y contadores locales e intenta enviar una solicitud, pero no confirma la eliminación en el servidor.';

  @override
  String get telemetryConsentAccept => 'Sí, compartir datos de uso';

  @override
  String get telemetryConsentDecline => 'No, gracias';

  @override
  String get settingsTelemetryToggleTitle =>
      'Compartir estadísticas de uso seudonimizadas';

  @override
  String get settingsTelemetryToggleSubtitle =>
      'Las estadísticas opcionales pueden incluir identificadores técnicos y métricas que pueden ser datos personales o de salud incluso sin tu nombre.';

  @override
  String get settingsTelemetryDeleteTitle => 'Eliminar datos de telemetría';

  @override
  String get settingsTelemetryDeleteSubtitle =>
      'Restablece los identificadores locales e intenta enviar una solicitud de eliminación; no se confirma la eliminación en el servidor.';

  @override
  String liveActivitySetPosition(int index, int total) {
    return 'Serie $index de $total';
  }

  @override
  String get liveActivityOverdueLabel => 'retraso de';

  @override
  String get liveActivityRirLabel => 'RIR';

  @override
  String get liveActivityRpeLabel => 'RPE';

  @override
  String get liveActivityAddExercise => 'Añadir ejercicio';

  @override
  String get liveActivityOpenApp => 'Abrir app';

  @override
  String get unit_pounds => 'lb';

  @override
  String get unit_kilometers => 'km';

  @override
  String get unit_miles => 'mi';

  @override
  String get liveActivitySkipShort => 'Saltar';

  @override
  String get whatsNewTitle => 'Novedades';

  @override
  String get whatsNewSubtitle =>
      'Esto es lo que ha cambiado desde la última actualización.';

  @override
  String whatsNewVersionHeader(String version) {
    return 'Versión $version';
  }

  @override
  String get whatsNewCta => 'Empezar';

  @override
  String get whatsNewAboutRow => 'Novedades';

  @override
  String get whatsNewAboutRowSubtitle =>
      'Cambios destacados de esta versión y de las anteriores';

  @override
  String get mealAnalysisPreparing => 'Preparando la captura';

  @override
  String get mealAnalysisAnalyzing => 'Analizando la comida';

  @override
  String get mealAnalysisMatching => 'Relacionando los ingredientes';

  @override
  String get mealAnalysisRepairing => 'Afinando el resultado';

  @override
  String get mealAnalysisFailed => 'No se ha podido completar';

  @override
  String get mealAnalysisProcessingTag => 'PROCESAMIENTO VISUAL CON IA';

  @override
  String get aiScannerTitle => 'Escáner con IA';

  @override
  String get aiCaptureAnalyzing => 'Analizando…';

  @override
  String aiCaptureAnalyzeMeal(int count) {
    return 'Analizar comida ($count)';
  }

  @override
  String get aiCaptureAnalyzeText => 'Analizar texto';

  @override
  String get aiCaptureDescribeHint =>
      'Describe la comida (p. ej., 2 huevos con tostadas)…';

  @override
  String get aiCaptureBarcodeDetected => 'Código de barras detectado';

  @override
  String get aiCaptureLogBarcode => 'Registrar';

  @override
  String aiCaptureBarcodeFallback(String code) {
    return 'Código de barras $code';
  }

  @override
  String get aiCaptureMoveCloser => 'Acerca un poco el dispositivo';

  @override
  String get aiCaptureMoveAway => 'Aleja un poco el dispositivo';

  @override
  String get aiCaptureOpenSettings => 'Abrir ajustes';

  @override
  String get voiceDictationTitle => 'Dictar comida';

  @override
  String get voiceHoldToTalk => 'Mantén pulsado para hablar';

  @override
  String get voiceSpeakNow => 'Habla ahora; suelta para terminar';

  @override
  String get voiceExampleStandalone =>
      'p. ej., «Un kebab de verduras con pan plano y salsa de ajo»';

  @override
  String get voiceExampleWithPhoto =>
      'Añade lo que no se ve en la foto; p. ej., «frito con dos cucharadas de aceite de oliva»';

  @override
  String get voiceNetworkNotice =>
      'Este dispositivo no puede reconocer voz localmente. La grabación se envía al servicio de reconocimiento de voz del sistema para transcribirla.';

  @override
  String get voiceTapToRecord => 'Toca para empezar a grabar';

  @override
  String get voiceTapToFinish => 'Escuchando; toca para terminar';

  @override
  String get aiChatAddImage => 'Añadir imagen';

  @override
  String get aiChatTakePhoto => 'Hacer una foto';

  @override
  String get aiChatChoosePhoto => 'Elegir de la biblioteca';

  @override
  String get aiChatRemoveImage => 'Eliminar imagen';

  @override
  String get aiChatCameraUnavailable =>
      'La cámara no está disponible en este dispositivo.';

  @override
  String get aiChatCameraPermission =>
      'Permite el acceso a la cámara para hacer una foto.';

  @override
  String get aiChatCapture => 'Hacer una foto';

  @override
  String get aiChatCameraOptions => 'Opciones de cámara';

  @override
  String get aiChatFlash => 'Flash';

  @override
  String get aiChatSwitchCamera => 'Cambiar cámara';

  @override
  String get aiChatImageLimit => 'Puedes adjuntar hasta 4 imágenes.';

  @override
  String get aiChatImageQuestion =>
      'Si la imagen muestra comida o bebida, estima sus nutrientes y prepara una entrada para que la revise. Si no, describe brevemente lo que aparece.';

  @override
  String get aiChatImageUnsupported =>
      'El modelo de IA seleccionado no admite imágenes. El borrador sigue en el editor.';

  @override
  String get voiceStarting => 'Preparando…';

  @override
  String get voiceTidyingUp => 'Organizando lo que has dicho…';

  @override
  String get voiceNothingHeard =>
      'No se ha reconocido nada. Inténtalo de nuevo o escríbelo.';

  @override
  String get voiceLanguage => 'Idioma';

  @override
  String get voiceLanguageTitle => 'Idioma del dictado';

  @override
  String get voiceLanguageSystem => 'Seguir el dispositivo';

  @override
  String get voiceLanguageHint =>
      'Elige el idioma en el que hablas, no el idioma de la app.';

  @override
  String get voiceCleanedNotice => 'Se han eliminado las muletillas';

  @override
  String get voiceRetake => 'Grabar de nuevo';

  @override
  String voiceTidiedIn(String seconds) {
    return 'La IA lo ha ordenado en $seconds s';
  }

  @override
  String get aiDepthImageTitle => 'Enviar también el mapa de profundidad';

  @override
  String get aiDepthImageSubtitle =>
      'Adjunta una imagen en relieve con colores falsos como segunda imagen para que el modelo pueda valorar la altura además del contorno. Cuesta una imagen adicional por análisis.';

  @override
  String get aiVoiceTidyTitle => 'Ordenar el dictado con IA';

  @override
  String get aiVoiceTidySubtitle =>
      'Al terminar de hablar, se corrige la transcripción y se divide en viñetas. Cuesta una solicitud y unos segundos.';

  @override
  String get voicePermissionTitle => 'Micrófono y reconocimiento de voz';

  @override
  String get voicePermissionBody =>
      'Para dictar una comida, Train Libre necesita usar el micrófono mientras mantienes pulsado el botón y el reconocimiento de voz para transcribir lo que dices. Siempre que sea posible, el reconocimiento se ejecuta en el dispositivo. No se graba ni se guarda nada.';

  @override
  String get voicePermissionContinue => 'Continuar';

  @override
  String get voiceApplyText => 'Usar este texto';

  @override
  String get voiceTranscriptHint => 'Texto reconocido — puedes editarlo aquí';

  @override
  String get voiceUnavailablePermission =>
      'El dictado necesita acceso al micrófono y al reconocimiento de voz. También puedes escribir el texto.';

  @override
  String get voiceUnavailableUnsupported =>
      'Este dispositivo no ofrece reconocimiento de voz. Puedes escribir el texto.';

  @override
  String get voiceUnavailableFailed =>
      'No se pudo iniciar el reconocimiento de voz. Puedes escribir el texto.';

  @override
  String get mealFallbackTitle => 'Comida';

  @override
  String mealIngredientCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredientes',
      one: '1 ingrediente',
    );
    return '$_temp0';
  }

  @override
  String get mealDetailOptions => 'Opciones';

  @override
  String get mealDetailViewMode => 'Vista';

  @override
  String get mealDetailAddIngredient => 'Añadir ingrediente';

  @override
  String get mealDetailSaveAsTemplate => 'Guardar como plantilla';

  @override
  String get mealDetailSavedAsTemplate => 'Guardado como plantilla de comida.';

  @override
  String get mealDetailChangeMealType => 'Cambiar tipo de comida';

  @override
  String get mealDetailSelectMealType => 'Seleccionar tipo de comida';

  @override
  String get mealDetailAmountInGrams => 'Cantidad en gramos';

  @override
  String get mealDetailApply => 'Aplicar';

  @override
  String get mealDeleteQuestion => '¿Qué quieres hacer con esta comida?';

  @override
  String get mealDeleteUngroupTitle => 'Quitar solo la agrupación';

  @override
  String mealDeleteUngroupBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se eliminarán la foto y la agrupación. Las $count entradas seguirán en el diario por separado; el total diario no cambiará.',
      one:
          'Se eliminarán la foto y la agrupación. La entrada seguirá en el diario por separado; el total diario no cambiará.',
    );
    return '$_temp0';
  }

  @override
  String get mealDeleteAllTitle => 'Eliminar la comida y sus entradas';

  @override
  String mealDeleteAllBody(int count, int kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'La foto, la agrupación y las $count entradas desaparecerán del diario. Se restarán $kcal kcal del total del día.',
      one:
          'La foto, la agrupación y la entrada desaparecerán del diario. Se restarán $kcal kcal del total del día.',
    );
    return '$_temp0';
  }

  @override
  String get reanalysisTitle => 'Nuevo resultado';

  @override
  String get reanalysisSubtitle => 'Tú decides qué se guarda.';

  @override
  String get reanalysisPrevious => 'ACTUAL';

  @override
  String get reanalysisNew => 'NUEVO';

  @override
  String get reanalysisKeepPrevious => 'Conservar el actual';

  @override
  String get reanalysisApplyNew => 'Usar el nuevo';

  @override
  String get reanalysisDiffHint => 'Marcado = distinto de lo guardado';

  @override
  String get aiReviewDiscardTitle => '¿Descartar esta comida?';

  @override
  String get aiReviewDiscardBody =>
      'El análisis no se ha guardado y se perderá.';

  @override
  String get aiLidarScaleTitle => 'Enviar escala LiDAR';

  @override
  String get aiLidarScaleSubtitle =>
      'Mide la distancia y el tamaño del encuadre en centímetros y se los envía a la IA. Desactívala para comparar si realmente mejora la estimación.';

  @override
  String get mealPhotoStorageSection => 'Fotos de comidas (almacenamiento)';

  @override
  String get mealPhotoRetentionTitle => 'Periodo de conservación';

  @override
  String get mealPhotoRetentionBody =>
      'Las fotos se eliminan automáticamente al terminar el periodo. Las entradas nutricionales del diario se conservan.';

  @override
  String mealPhotoRetentionDays(int days) {
    return '$days días';
  }

  @override
  String get mealPhotoRetentionDefaultSuffix => '(predeterminado)';

  @override
  String get mealPhotoRetentionUnlimited => 'Sin límite';

  @override
  String get mealPhotoRetentionSaved => 'Periodo de conservación guardado.';

  @override
  String get mealPhotoDeleteAll => 'Eliminar todas las fotos locales';

  @override
  String get mealPhotoDeleteAllTitle => '¿Eliminar todas las fotos de comidas?';

  @override
  String get mealPhotoDeleteAllBody =>
      'Solo se eliminarán del dispositivo los archivos de imagen. Las entradas y las calorías del diario no cambiarán.';

  @override
  String get mealPhotoDeleted => 'Fotos eliminadas.';

  @override
  String get speechSectionTitle => 'Entrada por voz y dictado';

  @override
  String get speechOnDeviceActive =>
      'Reconocimiento de voz en el dispositivo activo';

  @override
  String get speechOnDeviceBody =>
      'Las comidas dictadas («2 huevos con tostadas y café») se convierten en texto directamente en el dispositivo y se mantienen privadas.';

  @override
  String get aiCaptureTourStepShutterTitle => 'Haz fotos de la comida';

  @override
  String get aiCaptureTourStepShutterDesc =>
      'Haz hasta 4 fotos de la comida desde distintos ángulos con el obturador. En dispositivos compatibles, LiDAR captura automáticamente datos de profundidad para estimar las porciones con más precisión.';

  @override
  String get aiCaptureTourStepBarcodeTitle =>
      'Detección automática de códigos de barras';

  @override
  String get aiCaptureTourStepBarcodeDesc =>
      'Coloca alimentos envasados frente a la cámara: los códigos de barras se reconocen automáticamente en tiempo real. Usa este botón para activar o desactivar el escáner en cualquier momento.';

  @override
  String get aiCaptureTourBarcodeDemoProduct =>
      'Copos de avena ecológicos 500 g';

  @override
  String get aiCaptureTourBarcodeDemoHint =>
      '¡Así se ve al escanear un código de barras!';

  @override
  String get aiCaptureTourStepGalleryTitle => 'Selecciona de la fototeca';

  @override
  String get aiCaptureTourStepGalleryDesc =>
      '¿Ya has hecho fotos de la comida? Elige hasta 4 imágenes directamente de la fototeca.';

  @override
  String get aiCaptureTourStepVoiceTitle => 'Dictado por voz';

  @override
  String get aiCaptureTourStepVoiceDesc =>
      'Toca el micrófono para dictar ingredientes, marcas o cantidades (p. ej., «200 g de pechuga de pollo con arroz»). La IA ordena y analiza el dictado automáticamente.';

  @override
  String get aiCaptureTourStepTextTitle => 'Texto y notas';

  @override
  String get aiCaptureTourStepTextDesc =>
      'Añade notas escritas o describe la comida solo con texto si no quieres hacer una foto.';

  @override
  String get aiCaptureTourStepAnalyzeTitle => 'Análisis inteligente con IA';

  @override
  String get aiCaptureTourStepAnalyzeDesc =>
      'Cuando tengas una foto, una transcripción de voz o un texto, toca Analizar. La IA identifica los alimentos, estima las porciones y los compara con tus objetivos nutricionales.';

  @override
  String get aiCaptureTourReplayTooltip => 'Volver a ver la guía de captura';

  @override
  String get workoutPhotoAdd => 'Añadir foto';

  @override
  String get workoutPhotoTake => 'Hacer foto';

  @override
  String get workoutPhotoFromLibrary => 'Elegir de la fototeca';

  @override
  String get workoutPhotoRemove => 'Quitar foto';

  @override
  String get workoutPhotoRemoveConfirm =>
      '¿Seguro que quieres quitar esta foto?';

  @override
  String get workoutPhotoLimitReached => 'Se alcanzó el máximo de 4 fotos';

  @override
  String workoutPhotoPagination(int current, int total) {
    return '$current de $total';
  }

  @override
  String get catalogFilterTitle => 'Filtrar';

  @override
  String get catalogFilterBodyRegion => 'Zona del cuerpo';

  @override
  String get catalogFilterEquipment => 'Equipamiento';

  @override
  String get catalogFilterUsage => 'Uso';

  @override
  String get catalogFilterReset => 'Restablecer';

  @override
  String get catalogFilterCombineHint =>
      'Varias selecciones en una sección amplían los resultados; las selecciones de distintas secciones los reducen.';

  @override
  String get catalogFilterDifficulty => 'Dificultad';

  @override
  String get catalogFilterMechanic => 'Mecánica';

  @override
  String get catalogFilterLaterality => 'Lados';

  @override
  String get catalogFilterAlreadyDone => 'Realizados anteriormente';

  @override
  String get catalogTrainedBadge => 'Entrenado';

  @override
  String get catalogLastTrainedToday => 'Entrenado hoy';

  @override
  String get catalogLastTrainedYesterday => 'Entrenado ayer';

  @override
  String catalogLastTrainedDaysAgo(int days) {
    return 'Hace $days d';
  }

  @override
  String catalogLastTrainedOn(String date) {
    return 'Entrenado el $date';
  }

  @override
  String get noTrainedExercisesFound =>
      'No se encontraron ejercicios realizados anteriormente.';

  @override
  String get exerciseDifficultyBeginner => 'Principiante';

  @override
  String get exerciseDifficultyIntermediate => 'Intermedio';

  @override
  String get exerciseDifficultyAdvanced => 'Avanzado';

  @override
  String get exerciseMechanicCompound => 'Compuesto';

  @override
  String get exerciseMechanicIsolation => 'Aislamiento';

  @override
  String get exerciseLateralityBilateral => 'Ambos lados';

  @override
  String get exerciseLateralityUnilateral => 'Un lado';

  @override
  String get exerciseLateralityAlternating => 'Alterno';

  @override
  String get exerciseClassificationTitle => 'Clasificación';

  @override
  String get exerciseMovementPatternLabel => 'Patrón de movimiento';

  @override
  String get exerciseForceVectorLabel => 'Dirección de la fuerza';

  @override
  String get exerciseMechanicLabel => 'Tipo de ejercicio';

  @override
  String get exerciseLateralityLabel => 'Lateralidad';

  @override
  String get exerciseDifficultyLabel => 'Dificultad';

  @override
  String get exerciseClassificationNotSpecified => 'Sin especificar';

  @override
  String get exercisePatternOther => 'Otro';

  @override
  String get exerciseUsageWarmup => 'Calentamiento';

  @override
  String get exerciseUsageActivation => 'Activación';

  @override
  String get exerciseUsageMainLift => 'Ejercicio principal';

  @override
  String get exerciseUsageAccessory => 'Accesorio';

  @override
  String get exerciseUsageConditioning => 'Acondicionamiento';

  @override
  String get exerciseUsageFinisher => 'Finalizador';

  @override
  String get exerciseUsageCooldown => 'Vuelta a la calma';

  @override
  String get exerciseUsagePrehab => 'Prehabilitación';

  @override
  String get exerciseForcePush => 'Empuje';

  @override
  String get exerciseForcePull => 'Tracción';

  @override
  String get exerciseForceStatic => 'Estático';

  @override
  String get exercisePatternHorizontalPush => 'Empuje horizontal';

  @override
  String get exercisePatternHorizontalPull => 'Tracción horizontal';

  @override
  String get exercisePatternVerticalPush => 'Empuje vertical';

  @override
  String get exercisePatternVerticalPull => 'Tracción vertical';

  @override
  String get exercisePatternSquat => 'Sentadilla';

  @override
  String get exercisePatternHinge => 'Bisagra de cadera';

  @override
  String get exercisePatternLunge => 'Zancada';

  @override
  String get exercisePatternGait => 'Marcha';

  @override
  String get exercisePatternCarry => 'Transporte';

  @override
  String get exercisePatternRotation => 'Rotación';

  @override
  String get exercisePatternAntiRotation => 'Antirrotación';

  @override
  String get exercisePatternAntiExtension => 'Antiextensión';

  @override
  String get exercisePatternAntiFlexion => 'Antiflexión';

  @override
  String get exercisePatternAntiLateralFlexion => 'Antiflexión lateral';

  @override
  String get exercisePatternSpinalFlexion => 'Flexión de columna';

  @override
  String get exercisePatternSpinalExtension => 'Extensión de columna';

  @override
  String get exercisePatternElbowFlexion => 'Flexión de codo';

  @override
  String get exercisePatternElbowExtension => 'Extensión de codo';

  @override
  String get exercisePatternShoulderFlexion => 'Flexión de hombro';

  @override
  String get exercisePatternShoulderAbduction => 'Abducción de hombro';

  @override
  String get exercisePatternScapularElevation => 'Elevación escapular';

  @override
  String get exercisePatternHipExtension => 'Extensión de cadera';

  @override
  String get exercisePatternHipAbduction => 'Abducción de cadera';

  @override
  String get exercisePatternHipAdduction => 'Aducción de cadera';

  @override
  String get exercisePatternKneeFlexion => 'Flexión de rodilla';

  @override
  String get exercisePatternKneeExtension => 'Extensión de rodilla';

  @override
  String get exercisePatternPlantarFlexion => 'Flexión plantar';

  @override
  String get exercisePatternDorsiflexion => 'Dorsiflexión';

  @override
  String get exercisePatternWristFlexion => 'Flexión de muñeca';

  @override
  String get exercisePatternWristExtension => 'Extensión de muñeca';

  @override
  String get settingsDeveloperTitle => 'Desarrollador';

  @override
  String get settingsDeveloperSubtitle =>
      'Diagnóstico y opciones experimentales';

  @override
  String get developerLabExperienceSection => 'Nivel de experiencia';

  @override
  String get developerLabExperienceLabel => 'Nivel de experiencia';

  @override
  String get developerLabExperienceHint =>
      'Solo para pruebas; todavía no se pregunta el nivel durante la configuración inicial.';

  @override
  String get experienceLevelBeginner => 'Principiante';

  @override
  String get experienceLevelAdvanced => 'Avanzado';

  @override
  String get experienceLevelPro => 'Profesional';

  @override
  String get experienceLevelBeginnerDescription =>
      'Ideal para empezar: se centra en lo esencial, el peso y las repeticiones. Usa términos musculares sencillos, como «hombros».';

  @override
  String get experienceLevelAdvancedDescription =>
      'Para quienes entrenan con regularidad: muestra detalles anatómicos de los músculos en el catálogo y los entrenamientos (p. ej., deltoides anterior, lateral y posterior).';

  @override
  String get experienceLevelProDescription =>
      'Solo recomendado para levantadores con experiencia y una buena percepción del fallo: añade el registro de intensidad mediante RIR (repeticiones en reserva) y zonas de intensidad cardiovascular.';

  @override
  String get diaryWeightLabel => 'Peso';

  @override
  String get diaryWeightPitch =>
      'Tu objetivo de calorías será más preciso si registras tu peso con regularidad.';

  @override
  String get diaryWeightStaleNudge =>
      'Hace tiempo que no lo registras: las entradas regulares mantienen preciso tu objetivo de calorías.';

  @override
  String get diaryWeightLog => 'Registrar';

  @override
  String get diaryWeightLogLong => 'Registrar peso';

  @override
  String diaryWeightDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'hace $days días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get diaryWeightToday => 'hoy';

  @override
  String get diaryWeightRange => 'Fuera del intervalo habitual';

  @override
  String get diaryWeightLoadError => 'No se pudo cargar el peso.';

  @override
  String get diaryWeightSaveError =>
      'No se pudo guardar el peso. Inténtalo de nuevo.';

  @override
  String get diaryWeightRetry => 'Intentar de nuevo';

  @override
  String get settingsTrainingExperienceTitle => 'Experiencia de entrenamiento';

  @override
  String get settingsTrainingExperienceSubtitle =>
      'Nivel de detalle de los términos musculares y las columnas de intensidad';

  @override
  String get settingsTrainingProgressionTitle => 'Progresión del entrenamiento';

  @override
  String get settingsTrainingProgressionSubtitle =>
      'Sugerencias de peso basadas en tu historial';

  @override
  String get progressionPromptTitle => '¿Activar el motor de progresión?';

  @override
  String get progressionPromptDescription =>
      'Train Libre encontró datos de entrenamientos anteriores. El motor de progresión puede sugerir automáticamente el peso ideal para tu próxima serie y adaptar tu progresión.';

  @override
  String get progressionPromptFeatureSmartWeights =>
      'Sugerencias automáticas de peso basadas en tus series recientes';

  @override
  String get progressionPromptFeatureStayInControl =>
      'Tú mantienes el control y puedes cambiar cualquier valor cuando quieras';

  @override
  String get progressionPromptEnableAction => 'Activar sugerencias';

  @override
  String get progressionPromptDismissAction => 'Ahora no';

  @override
  String get trainingProgressionOff => 'Desactivada';

  @override
  String get trainingProgressionSuggest => 'Sugerir';

  @override
  String get progressionTogether => 'Progresar las series en conjunto';

  @override
  String get progressionIndividually => 'Progresar las series por separado';

  @override
  String get progressionPolicy => 'Progresión por serie';

  @override
  String get progressionToggleEnabled => 'Progresión automática activada';

  @override
  String get progressionToggleDisabled => 'Progresión automática desactivada';

  @override
  String get workoutKeyboardInsertHyphen => 'Insertar signo menos';

  @override
  String get workoutKeyboardNextField => 'Ir al siguiente campo';

  @override
  String get workoutKeyboardClose => 'Cerrar teclado';

  @override
  String get progressionSetOutcome => 'Registrar la serie como';

  @override
  String get progressionDetails => 'Progresión y equipamiento';

  @override
  String get progressionLargeStep =>
      'La siguiente carga disponible supone un salto grande. Pruébala solo después de confirmarlo o mantén la carga actual.';

  @override
  String get progressionBridge =>
      'Objetivo temporal opcional: dos repeticiones por encima del límite superior del rango. Tu rango definido no cambia. Al alcanzarlo, volverá a ofrecerse el aumento de carga real.';

  @override
  String get progressionUnavailable =>
      'No hay otro nivel de carga disponible. Mantén la carga, corrige las cargas disponibles para usar microcargas o elige una nueva referencia.';

  @override
  String get progressionOvershoot =>
      'Este registro supera el límite superior por al menos tres repeticiones. Confirma la entrada y luego elige el siguiente nivel disponible o establece explícitamente una nueva referencia.';

  @override
  String get progressionStall =>
      'En tres sesiones comparables, este ejercicio quedó por debajo de su rango. Puedes elegir la carga más ligera propuesta, mantener el plan o editar el rango. Nada cambia automáticamente.';

  @override
  String get progressionBoundary =>
      'Nueva métrica y referencia. Confirma el cambio para este ejercicio: la asistencia, el peso corporal y la carga añadida son métricas distintas.';

  @override
  String get progressionAccept => 'Confirmar objetivo';

  @override
  String get progressionDecline => 'Mantener la carga actual';

  @override
  String get progressionDismiss => 'Descartar revisión';

  @override
  String get progressionRecalibrate => 'Elegir nueva referencia';

  @override
  String get progressionConfirmLog =>
      'Confirmar registro y revisar el siguiente nivel';

  @override
  String get progressionLoads =>
      'Cargas disponibles (separadas por punto y coma)';

  @override
  String get progressionEquipment => 'Identificación del equipo (opcional)';

  @override
  String get progressionContext => 'Contexto o motivo temporal (opcional)';

  @override
  String get progressionCompleted => 'Completada con normalidad';

  @override
  String get progressionAbandoned => 'Finalizada antes de tiempo';

  @override
  String get progressionPain => 'Detenida por dolor';

  @override
  String get progressionEquipmentInterrupted =>
      'El equipo o la configuración interfirieron';

  @override
  String get progressionPainGuidance =>
      'Detén esta serie. Plantéate una evaluación adecuada antes de continuar; no se sugerirá ninguna carga.';

  @override
  String get progressionUserLadder => 'Tus cargas disponibles';

  @override
  String get progressionEquipmentLadder => 'Escala de cargas del equipo';

  @override
  String get progressionFallback => 'Incremento alternativo del equipo';

  @override
  String get progressionHold =>
      'Mantén la carga; las repeticiones siguen el rango y el historial de esta posición.';

  @override
  String get progressionOrdinary =>
      'Has alcanzado el límite superior: usa la siguiente carga disponible y vuelve al mínimo de repeticiones del rango.';

  @override
  String get progressionAnchor =>
      'Las posiciones vinculadas mantienen la diferencia de carga de hoy respecto a la sesión anterior.';

  @override
  String get progressionNewPosition =>
      'Nueva posición: referencia provisional basada en la serie de trabajo completada hoy, no en el historial de progresión.';

  @override
  String get progressionWithheld =>
      'No hay datos comparables para sugerir una carga.';

  @override
  String get progressionOffered => 'Ofrecida';

  @override
  String get progressionAccepted => 'Aceptada';

  @override
  String get progressionRejected => 'Rechazada';

  @override
  String get progressionInvalidLoads =>
      'Introduce cargas no negativas; debes indicar al menos un valor disponible.';

  @override
  String get progressionBodyweight => 'Peso corporal';

  @override
  String get progressionWeighted => 'Peso corporal con carga';

  @override
  String get progressionAssisted => 'Con asistencia';

  @override
  String get createGoalTitle => 'Crear un objetivo';

  @override
  String get goalConfirmCreateButton => 'Activar objetivo';

  @override
  String get goalStep1Question => '¿Qué quieres conseguir?';

  @override
  String get goalStep1Description =>
      'Elige una dirección o describe el hito con tus propias palabras.';

  @override
  String goalStepProgress(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get goalStartingPointAndTargetTitle =>
      'Tu punto de partida y tu destino';

  @override
  String get goalStartingPointAndTargetDescription =>
      'Confirma dónde empiezas y elige un objetivo que siga la dirección que buscas.';

  @override
  String get goalTargetDirectionLoseError =>
      'Para perder peso, elige un objetivo inferior a tu peso inicial.';

  @override
  String get goalTargetDirectionGainError =>
      'Para ganar peso, elige un objetivo superior a tu peso inicial.';

  @override
  String get goalDriverSettingDescription =>
      'Train Libre usa este objetivo para adaptar tus objetivos diarios de calorías y macronutrientes.';

  @override
  String get goalPresetLoseWeight => 'Perder peso';

  @override
  String get goalPresetLoseWeightDescription =>
      'Reducir la grasa corporal y el peso objetivo de forma controlada.';

  @override
  String get goalPresetGainWeight => 'Ganar peso';

  @override
  String get goalPresetGainWeightDescription =>
      'Aumentar gradualmente la masa muscular y el peso corporal.';

  @override
  String get goalPresetMaintainWeight => 'Mantener el peso';

  @override
  String get goalPresetMaintainWeightDescription =>
      'Mantener el peso corporal dentro de un intervalo equilibrado.';

  @override
  String get goalPresetRecomposition => 'Recomposición corporal';

  @override
  String get goalPresetRecompositionDescription =>
      'Perder grasa y ganar músculo al mismo tiempo.';

  @override
  String get goalPresetCustom => 'Objetivo personalizado';

  @override
  String get goalPresetCustomDescription =>
      'Define un hito abierto con tus propias palabras.';

  @override
  String get goalCustomTitleLabel => 'Nombre del objetivo';

  @override
  String get goalCustomTitleHint =>
      'Por ejemplo: ponerse en forma para el verano o preparar una media maratón';

  @override
  String get goalStep2Question => '¿Cómo quieres medir el progreso?';

  @override
  String get goalStep2Description =>
      'Elige la métrica principal para seguir tu objetivo.';

  @override
  String get goalMetricWeightTitle => 'Peso corporal';

  @override
  String get goalMetricWeightSubtitle =>
      'Registra tu peso con mediciones periódicas en kg o lb.';

  @override
  String get goalMetricBodyFatTitle => 'Porcentaje de grasa corporal';

  @override
  String get goalMetricBodyFatSubtitle =>
      'Sigue la evolución de tu porcentaje de grasa corporal.';

  @override
  String get goalMetricCircumferenceTitle => 'Medidas corporales / perímetros';

  @override
  String get goalMetricCircumferenceSubtitle =>
      'Registra la cintura u otras medidas corporales.';

  @override
  String get goalMetricDirectionalOnlyTitle => 'Solo dirección';

  @override
  String get goalMetricDirectionalOnlySubtitle =>
      'Sigue el proceso sin fijar una cifra como objetivo.';

  @override
  String get goalStep3Question => 'Ritmo y parámetros';

  @override
  String get goalStep3Description =>
      'Si quieres, indica un valor objetivo y el ritmo semanal.';

  @override
  String get goalCustomDirectionPrompt =>
      '¿Este objetivo debe ajustar tus objetivos de nutrición?';

  @override
  String get goalCustomDirectionNone => 'Solo como referencia';

  @override
  String get goalTargetValueOptionalLabel => 'Valor objetivo (opcional)';

  @override
  String get goalWeeklyRateLabel => 'Ritmo semanal previsto';

  @override
  String get goalStep4Question => '¿Tienes una fecha objetivo?';

  @override
  String get goalStep4Description =>
      'La fecha objetivo es totalmente opcional. Train Libre nunca te presiona.';

  @override
  String get goalNoDeadlineOption => 'Sin fecha objetivo';

  @override
  String get goalSelectDatePrompt => 'Seleccionar fecha';

  @override
  String get goalRemoveDeadlineChip => 'Quitar fecha objetivo';

  @override
  String get goalStep5Question => 'Fecha de inicio y referencia';

  @override
  String get goalStep5Description =>
      '¿Cuándo empieza o empezó este objetivo? Train Libre buscará automáticamente la medición de referencia.';

  @override
  String get goalStartDateLabel => 'Fecha de inicio';

  @override
  String get goalBaselineFoundTitle => 'Se encontró la medición de referencia';

  @override
  String get goalBaselineNotFoundTitle =>
      'No se encontró una medición de referencia';

  @override
  String get goalBaselineNotFoundDescription =>
      'El objetivo tendrá el estado «En espera de una medición» hasta que registres tu primer peso.';

  @override
  String get goalStep6Question => '¿Por qué es importante para ti?';

  @override
  String get goalStep6Description =>
      'Tu motivación personal te ayuda a mantener el rumbo. Se guarda solo en tu dispositivo.';

  @override
  String get goalStepBaselineQuestion => 'Fecha de inicio y peso de referencia';

  @override
  String get goalStepBaselineDescription =>
      '¿Cuándo empieza este objetivo? Train Libre usa el peso de esa fecha como referencia inicial.';

  @override
  String get goalStepTargetWeightQuestion => '¿Cuál es tu peso objetivo?';

  @override
  String get goalStepTargetWeightDescription =>
      'Introduce el peso que quieres alcanzar.';

  @override
  String get goalStepTrajectoryQuestion =>
      'Planifica el ritmo y la fecha objetivo';

  @override
  String get goalStepTrajectoryDescription =>
      'Elige una fecha objetivo o un ritmo semanal; el otro valor se calculará al instante.';

  @override
  String goalEnterBaselineWeightPrompt(String unit) {
    return 'Introduce el peso inicial ($unit)';
  }

  @override
  String goalTargetWeightLabel(String unit) {
    return 'Peso objetivo ($unit)';
  }

  @override
  String get goalWeightDifferenceLabel => 'Cambio previsto';

  @override
  String get goalPlanByDate => 'Planificar según la fecha objetivo';

  @override
  String get goalPlanByRate => 'Planificar según el ritmo semanal';

  @override
  String get goalEstimatedDailyDelta => 'Ajuste diario de calorías';

  @override
  String goalEstimatedDuration(int weeks) {
    return 'Duración: $weeks semanas';
  }

  @override
  String get goalRateGentle => 'Suave (0,25 kg/semana)';

  @override
  String get goalRateModerate => 'Moderado (0,50 kg/semana)';

  @override
  String get goalRateAthletic => 'Deportivo (0,75 kg/semana)';

  @override
  String get goalRateAggressive => 'Intenso (1,00 kg/semana)';

  @override
  String get goalRateCustom => 'Ritmo personalizado (control deslizante)';

  @override
  String get goalDurationCustom => 'Fecha objetivo personalizada...';

  @override
  String get goalPaceFeedbackSafe =>
      'Ritmo recomendado y sostenible (0,5 %–1,0 % del peso corporal por semana).';

  @override
  String get goalPaceFeedbackAggressive =>
      'Ritmo intenso. Presta mucha atención a consumir suficiente proteína y recuperarte bien.';

  @override
  String get goalPaceFeedbackGentle =>
      'Ritmo muy gradual y fácil de mantener a largo plazo.';

  @override
  String get goalPaceFeedbackMaintain =>
      'Mantén el peso con una ingesta energética equilibrada.';

  @override
  String get goalReasonSuggestionHealth => 'Salud y vitalidad';

  @override
  String get goalReasonSuggestionFitness => 'Forma física y rendimiento';

  @override
  String get goalReasonSuggestionShape => 'Peso cómodo y aspecto físico';

  @override
  String get goalReasonSuggestionEvent => 'Competición o evento deportivo';

  @override
  String get goalReasonSuggestionEnergy => 'Más energía en el día a día';

  @override
  String get goalReasonSuggestionStrength => 'Fuerza y desarrollo muscular';

  @override
  String get goalReasonSuggestionConfidence => 'Confianza y bienestar';

  @override
  String get goalReasonSuggestionLongevity => 'Longevidad y prevención';

  @override
  String get goalReasonSuggestionHabits => 'Rutina saludable y constancia';

  @override
  String get goalReasonSuggestionClothing => 'Sentirte bien con tu ropa';

  @override
  String get goalReasonPlaceholder =>
      'p. ej., Quiero volver a sentirme en forma y con más agilidad…';

  @override
  String get goalReasonPrivacyNotice =>
      'Tu nota se guarda en la aplicación y puede incluirse en copias de seguridad o en una solicitud de IA autorizada.';

  @override
  String get goalStep7Question => 'Revisar y activar';

  @override
  String get goalStep7Description =>
      'Revisa los parámetros antes de activar el objetivo.';

  @override
  String get goalAreaLabel => 'Área del objetivo';

  @override
  String get goalStartLabel => 'Punto de partida';

  @override
  String get goalWaitingForMeasurementShort => 'Esperando una medición';

  @override
  String get goalTargetLabel => 'Objetivo';

  @override
  String get goalDirectionalOnly => 'Enfocado en el proceso';

  @override
  String get goalTargetDateLabel => 'Fecha objetivo';

  @override
  String get goalDriverSettingLabel => 'Influye en la nutrición';

  @override
  String get noActiveGoalTitle => 'No hay ningún objetivo activo';

  @override
  String get noActiveGoalSubtitle =>
      'Train Libre funciona perfectamente sin objetivos predefinidos.';

  @override
  String get noActiveGoalDescription =>
      'Puedes crear en cualquier momento un objetivo de peso, grasa corporal o un hito personalizado para seguir tu evolución y recibir revisiones semanales.';

  @override
  String get createGoalButton => 'Crear un objetivo';

  @override
  String get goalWaitingForBaselineLabel => 'Esperando una medición';

  @override
  String get goalBaselineHeader => 'Inicio (referencia)';

  @override
  String get goalCurrentHeader => 'Actual';

  @override
  String get goalTargetHeader => 'Objetivo';

  @override
  String get goalProgressSectionTitle => 'Progreso';

  @override
  String goalRemainingDistanceLabel(String distance) {
    return 'Faltan $distance';
  }

  @override
  String get weekShort => 'semana';

  @override
  String get goalNoTargetDateShort => 'Sin fecha objetivo';

  @override
  String get reviewStatusOnTrack => 'Según lo previsto';

  @override
  String get reviewStatusSlower => 'Más lento de lo previsto';

  @override
  String get reviewStatusFaster => 'Más rápido de lo previsto';

  @override
  String get reviewStatusCalibrating => 'Ajustando';

  @override
  String get reviewStatusBehind => 'Por detrás del plan';

  @override
  String get reviewStatusAhead => 'Por delante del plan';

  @override
  String get reviewStatusTargetReached => 'Objetivo alcanzado';

  @override
  String get reviewStatusTargetDateNeedsReview =>
      'Hay que revisar la fecha objetivo';

  @override
  String reviewOverallSummary(String overall, String momentum) {
    return 'En general: $overall. Últimos 7 días: $momentum.';
  }

  @override
  String get reviewMomentumMatchingPlan => 'siguiendo el plan';

  @override
  String get reviewMomentumCatchingUp => 'recuperando terreno';

  @override
  String get reviewMomentumFallingBehind => 'quedándose cada vez más atrás';

  @override
  String get reviewMomentumMovingFaster => 'avanzando más rápido';

  @override
  String get reviewMomentumMovingSlower => 'avanzando más despacio';

  @override
  String get reviewMomentumUnclear => 'aún no está claro';

  @override
  String reviewNextAnalysisScheduled(String date) {
    return 'Próxima revisión adaptativa: $date (mín. 3 pesajes y 4 días con registro de calorías)';
  }

  @override
  String get weeklyReviewCardHeaderBadge => 'Revisión semanal';

  @override
  String get weeklyReviewCardOverallLabel => 'Progreso general';

  @override
  String get weeklyReviewCardRecentLabel => 'Últimos 7 días';

  @override
  String get weeklyReviewPendingDefaultExplanation =>
      'El sistema adaptativo compara la tendencia de los últimos 7 días con la trayectoria objetivo.';

  @override
  String get weeklyReviewNutritionSectionTitle => 'Recomendación nutricional';

  @override
  String get weeklyReviewCaloriesTitle => 'Objetivo diario de calorías';

  @override
  String get weeklyReviewCaloriesCurrent => 'Actual';

  @override
  String get weeklyReviewCaloriesRecommended => 'Recomendado';

  @override
  String weeklyReviewCaloriesChange(String change) {
    return '$change kcal/día';
  }

  @override
  String weeklyReviewCaloriesComparison(
      String current, String recommended, String change) {
    return '$current → $recommended kcal/día ($change)';
  }

  @override
  String get weeklyReviewWeightProgressTitle => 'Progreso del objetivo de peso';

  @override
  String get weeklyReviewWeightPlannedLabel => 'Previsto hasta hoy';

  @override
  String get weeklyReviewWeightTrendLabel => 'Tendencia reciente';

  @override
  String get weeklyReviewAdjustPlanTitle => 'Ajustar tu plan';

  @override
  String get weeklyReviewAdjustRate => 'Ajustar el ritmo semanal';

  @override
  String get weeklyReviewAdjustDate => 'Cambiar la fecha objetivo';

  @override
  String get weeklyReviewDetailsTitle => 'Detalles del progreso';

  @override
  String get weeklyReviewDecisionTitle => 'Tu siguiente paso';

  @override
  String get weeklyReviewContinueLogging => 'Seguir registrando';

  @override
  String get weeklyReviewPreviewNoChanges =>
      'Vista previa de prueba: no se ha guardado ningún cambio.';

  @override
  String get reviewOpenDetailsButton => 'Ver revisión';

  @override
  String get applyRecommendationButton => 'Aplicar recomendación';

  @override
  String get weeklyReviewScreenTitle => 'Revisión semanal del objetivo';

  @override
  String get reviewSufficiencyGateTitle => 'Datos (últimos 7 días)';

  @override
  String get reviewWeighInsCountLabel => 'Pesajes';

  @override
  String get reviewLoggedDaysCountLabel => 'Días con registro de nutrición';

  @override
  String get reviewTrajectoryComparisonTitle => 'Comparación de la trayectoria';

  @override
  String get reviewPlanVsRealityTitle => 'Plan y realidad';

  @override
  String get reviewExpectedByNowLabel => 'Esperado hasta hoy';

  @override
  String get reviewSmoothedCurrentLabel => 'Valor actual suavizado';

  @override
  String get reviewTrajectoryGapLabel => 'Diferencia respecto al plan';

  @override
  String get reviewRequiredRateLabel => 'Ritmo necesario a partir de ahora';

  @override
  String get reviewProjectedDateLabel => 'Fecha objetivo prevista';

  @override
  String get reviewNutritionAdjustTargets =>
      'Tu tendencia de peso difiere del ritmo previsto. Los días que has registrado aportan datos suficientes para recomendar un cambio en tus objetivos diarios.';

  @override
  String get reviewNutritionKeepTargetsIntakeDiffers =>
      'Tus objetivos actuales siguen siendo adecuados. Tu ingesta registrada difiere de ellos, así que cambiar el plan no resolvería la principal desviación.';

  @override
  String get reviewNutritionKeepTargets =>
      'Esta semana no se recomienda cambiar tus objetivos diarios.';

  @override
  String get reviewNutritionTrajectoryChangeNeeded =>
      'El ritmo necesario para mantener la fecha actual no es un ajuste nutricional razonable. Cambia el objetivo, el ritmo o la fecha.';

  @override
  String get reviewNutritionInsufficientData =>
      'Sigue registrando con normalidad. Todavía no hay suficientes datos recientes para recomendar un ajuste nutricional fiable.';

  @override
  String get reviewObservedRateLabel => 'Tendencia observada';

  @override
  String get reviewTargetRateLabel => 'Ritmo previsto';

  @override
  String get reviewEstimatedTDEELabel => 'Mantenimiento estimado (TDEE)';

  @override
  String get reviewRecommendationTitle => 'Objetivos diarios recomendados';

  @override
  String get reviewActionApplyRecommendation =>
      'Aplicar los objetivos diarios recomendados';

  @override
  String get weeklyReviewApplyTargetsAction => 'Aplicar objetivos';

  @override
  String get weeklyReviewDateExtensionTitle => 'Fecha objetivo aplazada';

  @override
  String weeklyReviewDateExtensionContent(String rate, String date) {
    return 'El ritmo necesario para alcanzar tu fecha objetivo actual no sería seguro para tu salud. El ritmo semanal se ha limitado a $rate y la fecha objetivo se ha cambiado a $date para proteger tu salud.';
  }

  @override
  String get weeklyReviewRateTitle => 'Ritmo semanal';

  @override
  String get weeklyReviewDateTitle => 'Fecha objetivo';

  @override
  String get weeklyReviewRateNoChange => 'Sin cambios';

  @override
  String get weeklyReviewDateOnTrack => 'Según lo previsto';

  @override
  String weeklyReviewDateDaysChange(String days) {
    return '$days días';
  }

  @override
  String get weeklyReviewPlanUpdatedSnack =>
      'Se han actualizado los objetivos y la trayectoria del objetivo.';

  @override
  String get reviewActionAdjustTrajectory => 'Ajustar objetivo y trayectoria';

  @override
  String get reviewActionKeepCurrent =>
      'Mantener el objetivo y actualizar los objetivos diarios';

  @override
  String get weeklyReviewKeepGoalAction => 'Mantener el objetivo';

  @override
  String get reviewDismissedSnack =>
      'Revisión descartada. Los objetivos actuales siguen activos.';

  @override
  String get adjustGoalTitle => 'Ajustar objetivo';

  @override
  String get adjustGoalDescription =>
      'Ajusta el peso objetivo, la fecha o el ritmo semanal. Las demás variables se recalculan al instante.';

  @override
  String get adjustGoalFixOptionKeepDate => 'Mantener fecha';

  @override
  String get adjustGoalFixOptionKeepRate => 'Mantener ritmo';

  @override
  String get adjustGoalExtremeRateWarning =>
      'Aviso: este ritmo se desvía considerablemente de las recomendaciones fisiológicas habituales.';

  @override
  String get adjustGoalApplyAsSuccessorButton =>
      'Aplicar como objetivo sucesor';

  @override
  String get adjustGoalConfirmTitle => '¿Actualizar el plan?';

  @override
  String get adjustGoalConfirmContent =>
      'Tu progreso y todas tus mediciones se conservarán. La trayectoria revisada empieza hoy.';

  @override
  String get adjustGoalUpdatePlanButton => 'Actualizar plan';

  @override
  String get adjustGoalAcceptRecommendationAndUpdatePlan =>
      'Aceptar la recomendación y actualizar el plan';

  @override
  String get adjustGoalRecommendedTitle => 'Ajuste recomendado';

  @override
  String adjustGoalRecommendedPlan(String date, String rate) {
    return 'Mantén un ritmo realista y cambia la fecha objetivo a $date ($rate).';
  }

  @override
  String adjustGoalRecommendedKeepDatePlan(String date, String rate) {
    return 'Mantén la fecha objetivo del $date y ajusta el ritmo a $rate.';
  }

  @override
  String get adjustGoalSelectRecommendedPlan => 'Elegir recomendación';

  @override
  String get adjustGoalConfirmButton => 'Aplicar';

  @override
  String get adjustGoalTargetWeightLabel => 'Peso objetivo';

  @override
  String get adjustGoalTargetDateLabel => 'Fecha objetivo';

  @override
  String get adjustGoalWeeklyRateLabel => 'Ritmo semanal previsto';

  @override
  String get goalDetailScreenTitle => 'Detalles del objetivo';

  @override
  String get retireGoalDialogTitle => '¿Archivar el objetivo?';

  @override
  String get retireGoalDialogContent =>
      'El objetivo se archivará y dejará de influir en la nutrición adaptativa. Puedes volver a activarlo cuando quieras.';

  @override
  String get retireGoalConfirmButton => 'Archivar objetivo';

  @override
  String get goalRetiredSuccessSnack => 'El objetivo se ha archivado.';

  @override
  String get resumeGoalDialogTitle => '¿Reactivar el objetivo?';

  @override
  String get resumeGoalDialogContent =>
      'Este objetivo volverá a ser el activo e influirá en la nutrición adaptativa.';

  @override
  String get resumeGoalConfirmButton => 'Reactivar';

  @override
  String get goalResumedSuccessSnack =>
      'El objetivo se ha reactivado correctamente.';

  @override
  String get goalStatusActive => 'Activo';

  @override
  String get goalStatusRetired => 'Archivado';

  @override
  String get goalStatusSuperseded => 'Sustituido';

  @override
  String goalStartedOnLabel(String date) {
    return 'Inicio: $date';
  }

  @override
  String get goalDrivesNutritionBadge => 'Influye en la nutrición';

  @override
  String get goalDocumentationOnlyBadge => 'Solo informativo';

  @override
  String get goalWaitingForBaselineCalloutTitle =>
      'Se necesita una medición de referencia';

  @override
  String get goalWaitingForBaselineCalloutDescription =>
      'No hay ninguna medición en la fecha de inicio o antes. Registra tu primer pesaje para calcular el progreso y la trayectoria.';

  @override
  String get recordFirstMeasurementButton => 'Registrar primera medición';

  @override
  String get goalWeightHistoryChartTitle => 'Tendencia de peso y objetivo';

  @override
  String get goalPersonalMotivationTitle => 'Tu motivación';

  @override
  String get retireGoalButton => 'Archivar objetivo';

  @override
  String get resumeGoalButton => 'Reactivar objetivo';

  @override
  String get myGoalsOperativeTargetsBanner =>
      'Ir a los objetivos diarios (calorías, macros y agua)';

  @override
  String get myGoalsActiveGoalSectionHeader => 'Objetivo activo';

  @override
  String get myGoalsHistorySectionHeader => 'Historial de objetivos';

  @override
  String get goalsScreenToMyGoalsBannerTitle =>
      '¿Buscas objetivos a largo plazo?';

  @override
  String get goalsScreenToMyGoalsBannerSubtitle =>
      'Gestiona tus trayectorias de peso y revisiones semanales en «Mis objetivos».';

  @override
  String get dailyOperatingTargetsTitle => 'Objetivos diarios';

  @override
  String get dailyOperatingTargetsSubtitle =>
      'Calorías, macronutrientes y agua';

  @override
  String get adjustDailyTargetsButton => 'Ajustar objetivos diarios';

  @override
  String get targetCaloriesLabel => 'Objetivo diario';

  @override
  String get goalNotificationSettingsTitle =>
      'Notificaciones de objetivos y revisiones';

  @override
  String get goalNotificationWeeklyReviewTitle => 'Revisión semanal disponible';

  @override
  String get goalNotificationWeeklyReviewSubtitle =>
      'Te avisamos cuando haya una revisión de 7 días disponible.';

  @override
  String get goalNotificationAdaptiveDueTitle =>
      'Recomendación adaptativa pendiente';

  @override
  String get goalNotificationAdaptiveDueSubtitle =>
      'Te avisa cuando haya ajustes disponibles para tus objetivos diarios.';

  @override
  String get goalNotificationTargetDateTitle => 'Aviso sobre la fecha objetivo';

  @override
  String get goalNotificationTargetDateSubtitle =>
      'Un recordatorio amable cuando se acerque la fecha objetivo, sin presiones.';

  @override
  String get goalNotificationPrivacyNotice =>
      'Todas las notificaciones se gestionan localmente en tu dispositivo. En la pantalla de bloqueo nunca aparecen datos privados de peso o calorías.';

  @override
  String get goalMaintainCorridor => '± 1,0 kg (mantenimiento)';

  @override
  String get goalNeedsFirstMeasurementPrompt =>
      'Registra tu primer peso para ver el progreso y la tendencia.';

  @override
  String goalRemainingDistanceText(String distance) {
    return 'Quedan $distance';
  }

  @override
  String get goalMaintenanceStable => 'Estable dentro del margen objetivo';

  @override
  String get goalMaintenanceDrifting => 'Ligera desviación del margen';

  @override
  String get goalJourneyInProgress => 'Tu objetivo está en marcha';

  @override
  String get goalJourneyTargetReached => 'Has alcanzado tu objetivo';

  @override
  String get goalNotifyWeeklyReviewTitle => 'Revisión semanal lista';

  @override
  String get goalNotifyWeeklyReviewSubtitle =>
      'Te avisa en cuanto esté disponible la revisión de 7 días.';

  @override
  String get goalNotifyRecommendationDueTitle =>
      'Nueva recomendación adaptativa';

  @override
  String get goalNotifyRecommendationDueSubtitle =>
      'Te avisa cuando haya ajustes disponibles para tus objetivos diarios.';

  @override
  String get goalNotifyTargetDateTitle => 'Aviso sobre la fecha objetivo';

  @override
  String get goalNotifyTargetDateSubtitle =>
      'Un recordatorio amable cuando se acerque la fecha objetivo, sin presiones.';

  @override
  String get goalNotifyPrivacyTitle => 'Privacidad y gestión local';

  @override
  String get goalNotifyPrivacyBody =>
      'Las notificaciones de objetivos y revisiones se gestionan localmente y pueden incluir detalles útiles sobre tus objetivos, peso o calorías. Usa los ajustes del sistema operativo para controlar las vistas previas en la pantalla de bloqueo y las horas de silencio.';

  @override
  String get goalNotificationSettingsSubtitle =>
      'Notificaciones locales de revisiones y fechas objetivo';

  @override
  String get notificationSettingsTitle => 'Notificaciones';

  @override
  String get notificationSettingsSubtitle =>
      'Recordatorios de entrenamientos, objetivos y revisiones';

  @override
  String get notificationExactAlarmTitle => 'Permitir temporizadores precisos';

  @override
  String get notificationExactAlarmSubtitle =>
      'Permite alarmas y recordatorios en Android para que el sonido de descanso suene a tiempo en segundo plano.';

  @override
  String get notificationLiveWorkoutSectionTitle => 'Entrenamiento en curso';

  @override
  String get notificationRestTimerTitle => 'Notificaciones de descanso';

  @override
  String get notificationRestTimerSubtitle =>
      'Mostrar una notificación del sistema al terminar el descanso.';

  @override
  String get notificationIgnoreSilentTitle => 'Ignorar modo silencio';

  @override
  String get notificationIgnoreSilentSubtitle =>
      'Reproducir el sonido de descanso en la app incluso en silencio. Las notificaciones en segundo plano siguen los ajustes del sistema.';

  @override
  String get notificationWorkoutSectionTitle => 'Plan de entrenamiento';

  @override
  String get notificationGoalsSectionTitle => 'Objetivos y revisiones';

  @override
  String get workoutPlanNotifyTitle => 'Avisarme los días de entrenamiento';

  @override
  String get workoutPlanNotifySubtitle =>
      'Solo los días de entrenamiento previstos. Sin recordatorios para recuperar sesiones ni reproches.';

  @override
  String get workoutPlanNotifyTimeTitle => 'Hora del recordatorio';

  @override
  String get workoutPlanNotifyNoActivePlan =>
      'Los recordatorios se activan cuando hay un plan de entrenamiento activo.';

  @override
  String get notificationPermissionDenied =>
      'Las notificaciones están desactivadas en los ajustes del sistema.';

  @override
  String get notificationPrivacyTitle => 'Local y bajo tu control';

  @override
  String get notificationPrivacyBody =>
      'Estos recordatorios se programan localmente. Gestiona las vistas previas en la pantalla de bloqueo y las horas de silencio en los ajustes del sistema operativo.';

  @override
  String get workoutPlanReminderTitle => 'Entrenamiento previsto';

  @override
  String workoutPlanReminderBody(String routineName, String planName) {
    return '$routineName es lo siguiente en $planName.';
  }

  @override
  String get weeklyGoalReviewNotificationTitle => 'Revisión semanal lista';

  @override
  String get weeklyGoalReviewNotificationBody =>
      'Tu nueva revisión de 7 días está disponible en el centro de nutrición.';

  @override
  String weeklyGoalReviewNotificationDetailedBody(
      String goalTitle, int calories) {
    return '$goalTitle: tu recomendación actualizada es de $calories kcal al día. Abre la revisión para ver todos los detalles.';
  }

  @override
  String get goalTargetDateReminderTitle => 'Fecha objetivo del objetivo';

  @override
  String goalTargetDateReachedBody(String goalTitle) {
    return 'Hoy es la fecha objetivo de «$goalTitle».';
  }

  @override
  String goalTargetDateApproachingBody(String goalTitle) {
    return 'Se acerca la fecha objetivo de «$goalTitle».';
  }

  @override
  String get back => 'Atrás';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get retry => 'Reintentar';

  @override
  String get saving => 'Guardando…';

  @override
  String get emptyStateMeasurements => 'Aún no hay medidas registradas.';

  @override
  String get goalTrackingModeTitle => '¿Cómo quieres planificarlo?';

  @override
  String get goalTrackingModeDescription =>
      'Elige qué definirá tu objetivo nutricional.';

  @override
  String get goalTrackingModeOpen => 'Objetivo abierto';

  @override
  String get goalTrackingModeOpenDescription =>
      'Sin peso objetivo, fecha ni ritmo semanal personalizado.';

  @override
  String get goalTrackingModeWeeklyRate => 'Ritmo semanal';

  @override
  String get goalTrackingModeWeeklyRateDescription =>
      'Indica cuánto peso quieres cambiar por semana.';

  @override
  String get goalTrackingModeTargetWeight => 'Peso objetivo';

  @override
  String get goalTrackingModeTargetWeightDescription =>
      'Establece un peso objetivo y, si quieres, una fecha.';

  @override
  String goalTrackingModeDefaultRateInfo(String rate) {
    return 'Se usa el ritmo seguro predeterminado de $rate, que también aparece en las recomendaciones.';
  }

  @override
  String get goalTrackingOpenReady =>
      'Tu objetivo abierto está listo. Las recomendaciones usan el ritmo seguro predeterminado para esta dirección.';

  @override
  String get goalTargetDateOptional => 'Fecha objetivo (opcional)';

  @override
  String get goalReplaceActiveTitle =>
      '¿Sustituir el objetivo nutricional activo?';

  @override
  String get goalReplaceActiveBody =>
      'Tu objetivo nutricional actual se completará y será sustituido. Los objetivos diarios no cambiarán hasta que apliques una recomendación.';

  @override
  String get goalReplaceActiveConfirm => 'Sustituir objetivo';

  @override
  String goalCreateError(String error) {
    return 'No se pudo guardar el objetivo: $error';
  }

  @override
  String goalAdjustError(String error) {
    return 'No se pudo ajustar el objetivo: $error';
  }

  @override
  String get reviewKeepAndApplyTitle =>
      '¿Mantener el objetivo y actualizar los objetivos diarios?';

  @override
  String get reviewKeepAndApplyBody =>
      'El objetivo no cambiará. Se volverá a calcular la recomendación y se aplicarán de inmediato los nuevos objetivos de calorías y nutrientes.';

  @override
  String reviewActionError(String error) {
    return 'La acción de revisión ha fallado: $error';
  }

  @override
  String get calculationBasisTitle => 'Base del cálculo';

  @override
  String get calculationBasisSubtitle => 'Actividad diaria y cardio adicional';

  @override
  String get estimatedOneRepMaxInfoTitle =>
      'Estimación del máximo de una repetición (fórmula de Brzycki)';

  @override
  String get estimatedOneRepMaxInfoExplanation =>
      'Estima la fuerza a partir de una serie completada para ayudar a seguir tu progreso.';

  @override
  String get estimatedOneRepMaxInfoPoints =>
      '1RM ≈ carga efectiva × (36 / (37 − repeticiones)), para 1–12 repeticiones.\nEs una estimación a partir de una serie completada, no una prueba directa del máximo.\nEn los ejercicios con peso corporal o asistencia se usa la carga efectiva, incluidos el peso corporal y la asistencia.';

  @override
  String get estimatedOneRepMaxInfoDetailsTitle =>
      'Detalles de la fórmula de Brzycki';

  @override
  String get estimatedOneRepMaxInfoDetails =>
      'Train Libre estima el máximo de una repetición (1RM) a partir de la carga efectiva de una serie mediante la fórmula de Brzycki: 1RM = carga efectiva × (36 / (37 − repeticiones)). No se usan series de más de 12 repeticiones. Es una estimación; la técnica y el rendimiento individuales pueden diferir del cálculo.';

  @override
  String get setTimerStart => 'Iniciar temporizador';

  @override
  String get setTimerRunning => 'Temporizador en marcha';

  @override
  String get setTimerStop => 'Detener temporizador';

  @override
  String get aiScanLogsTitle => 'Registros de análisis de comidas con IA';

  @override
  String get aiScanLogsPrivacy =>
      'Solo se guardan en este dispositivo. Sin texto de comidas, fotos ni claves. Máximo: 20 análisis.';

  @override
  String get aiScanLogsEmpty =>
      'Aún no hay análisis de comidas con IA registrados.';

  @override
  String aiScanLogsCount(int count) {
    return '$count análisis';
  }

  @override
  String get aiScanLogsCopyAll => 'Copiar todo';

  @override
  String get aiScanLogsClear => 'Borrar registros';

  @override
  String get aiScanLogsCopy => 'Copiar registro';

  @override
  String get aiScanLogsCopied => 'Registro copiado al portapapeles';

  @override
  String get aiScanLogsPhotos => 'Fotos';

  @override
  String get aiScanLogsFirstPass => 'Primera validación superada';

  @override
  String get aiScanLogsValidations => 'Validaciones seleccionadas / total';

  @override
  String get aiScanLogsRepairs => 'Reparaciones automáticas';

  @override
  String get aiScanLogsHedge => 'Solicitud paralela';

  @override
  String get aiScanLogsTokens => 'Tokens totales (entrada / salida)';

  @override
  String get aiScanLogsUnknown => 'Desconocido';

  @override
  String get aiScanLogsCalls => 'Solicitudes al proveedor';

  @override
  String get aiScanLogsReview => 'Resultado de la revisión';

  @override
  String get aiScanLogsCorrections => 'Correcciones del usuario con IA';

  @override
  String get aiScanLogsTimeline => 'Cronología';

  @override
  String get aiScanLogsInputText => 'Texto';

  @override
  String get aiScanLogsInputPhoto => 'Foto';

  @override
  String get aiScanLogsInputMixed => 'Foto + texto';

  @override
  String get aiScanLogsRunning => 'En curso';

  @override
  String get aiScanLogsAccepted => 'Aceptado';

  @override
  String get aiScanLogsNeedsRepair => 'Necesita reparación';

  @override
  String get aiScanLogsFailed => 'Fallido';

  @override
  String get aiScanLogsCancelled => 'Cancelado';

  @override
  String get aiScanLogsSavedUnchanged => 'Guardado sin cambios';

  @override
  String get aiScanLogsSavedEdited => 'Guardado tras editar';

  @override
  String get aiScanLogsSavedCorrected => 'Guardado tras corrección de IA';

  @override
  String get aiScanLogsDiscarded => 'Descartado';

  @override
  String get aiScanLogsStageRequested => 'Análisis iniciado';

  @override
  String get aiScanLogsStagePrepared => 'Preparación completada';

  @override
  String get aiScanLogsStagePrimary => 'Primera solicitud a IA iniciada';

  @override
  String get aiScanLogsStageHedge => 'Solicitud paralela a IA iniciada';

  @override
  String get aiScanLogsStageProvider => 'Respuesta de IA recibida';

  @override
  String get aiScanLogsStageValidation => 'Validación local completada';

  @override
  String get aiScanLogsStageRepairStart => 'Reparación con IA iniciada';

  @override
  String get aiScanLogsStageRepairEnd =>
      'Respuesta de reparación de IA recibida';

  @override
  String get aiScanLogsStageReview => 'Revisión visible';

  @override
  String get aiScanLogsStagePreliminaryNutrition =>
      'Primera estimación nutricional lista';

  @override
  String get aiScanLogsStageReviewReady => 'Revisión lista para guardar';

  @override
  String get aiScanLogsStageCorrectionStart =>
      'Corrección del usuario iniciada';

  @override
  String get aiScanLogsStageCorrectionEnd =>
      'Corrección del usuario completada';

  @override
  String get aiScanLogsClearConfirm =>
      '¿Borrar todos los registros de análisis de IA guardados localmente?';

  @override
  String get aiScanLogsStageSelected => 'Candidato seleccionado';

  @override
  String get aiScanLogsCandidatePrimary => 'Primera solicitud';

  @override
  String get aiScanLogsCandidateHedge => 'Solicitud paralela';

  @override
  String get aiScanLogsScore => 'Puntuación';

  @override
  String get aiScanLogsIssueSemantic => 'Elección del catálogo';

  @override
  String get aiScanLogsIssueCatalog => 'Coincidencia del catálogo';

  @override
  String get aiScanLogsIssueQuantity => 'Cantidad';

  @override
  String get aiScanLogsIssueNutrition => 'Referencia nutricional';

  @override
  String get aiScanLogsIssuePreparation => 'Estado de preparación';

  @override
  String get aiScanLogsIssueConfidence => 'Confianza';

  @override
  String get aiScanLogsIssueOther => 'Otra validación';

  @override
  String get aiScanLogsStageUsage => 'Uso comunicado por el proveedor';

  @override
  String get aiScanLogsCall => 'Solicitud';

  @override
  String get blsModificationsDetail =>
      'Aportaciones de Train Libre: traducciones, alias de búsqueda y categorías.';

  @override
  String get nutritionCatalogBls => 'Catálogo de alimentos básicos (BLS)';

  @override
  String get blsCatalogManagementDescription =>
      'Descarga y actualiza el catálogo local sin conexión de ingredientes BLS 4.0 (25,6 MB).';

  @override
  String get blsCatalogRefresh => 'Buscar actualizaciones del catálogo';

  @override
  String get blsCatalogUpdated => 'Catálogo BLS actualizado.';

  @override
  String get blsCatalogCurrent => 'El catálogo BLS está actualizado.';

  @override
  String get blsCatalogRefreshFailed =>
      'No se pudo actualizar el catálogo BLS. Inténtalo más tarde.';

  @override
  String get blsCompleteNutrientProfile => 'Perfil nutricional completo (BLS)';

  @override
  String blsNutrientCount(int count) {
    return '$count valores nutricionales por 100 g';
  }

  @override
  String get blsNutrientsUnavailable =>
      'Los detalles nutricionales no están disponibles hasta que se instale el catálogo BLS.';

  @override
  String get blsNutrientDetails => 'Detalles';

  @override
  String get blsNutrientOrigin => 'Medición o cálculo';

  @override
  String get blsNutrientReference => 'Referencia';

  @override
  String get blsFoodSourceLabel => 'Fuente y licencia';

  @override
  String get blsFoodSource =>
      'Bundeslebensmittelschlüssel (BLS) 4.0 — Max Rubner-Institut';

  @override
  String get blsFoodLicense => 'Datos BLS: CC BY 4.0';

  @override
  String get blsFoodModifications => 'Traducciones y categorías de Train Libre';

  @override
  String get developerAiOverlayDemoTitle => 'Superposición de IA';

  @override
  String get developerAiOverlayDemoSubtitle =>
      'Vista desplazable de la interfaz con tarjetas de ejemplo';

  @override
  String get aiOverlayDemoGlobalEnabledTitle =>
      'Mostrar el asistente de IA en toda la app';

  @override
  String get aiOverlayDemoGlobalEnabledSubtitle =>
      'Mostrar la nube flotante de IA en todas las pantallas.';

  @override
  String get aiOverlayDemoScreenTitle =>
      'Demostración de la superposición de IA';

  @override
  String get aiOverlayDemoIntroTitle => 'Vista previa del asistente';

  @override
  String get aiOverlayDemoIntroBody =>
      'Desplázate por contenido de ejemplo con el estilo de la app y prueba la vista previa de acceso.';

  @override
  String get aiOverlayDemoPreviewNote =>
      'Solo son datos de ejemplo. No se realizan consultas a la IA ni se accede a datos reales de entrenamiento o nutrición.';

  @override
  String get aiOverlayDemoTodaySection => 'Tu día';

  @override
  String get aiOverlayDemoNutritionSection => 'Nutrición';

  @override
  String get aiOverlayDemoActivitySection => 'Actividad';

  @override
  String get aiOverlayDemoWorkoutTitle => 'Entrenamiento de fuerza';

  @override
  String get aiOverlayDemoWorkoutSubtitle => 'Tren superior A · hace 2 horas';

  @override
  String get aiOverlayDemoWorkoutMeta => '47 min · 6 ejercicios · 12 series';

  @override
  String get aiOverlayDemoExerciseOne => 'Press de banca';

  @override
  String get aiOverlayDemoExerciseTwo => 'Remo en polea sentado';

  @override
  String get aiOverlayDemoStepsValue => '7.842 de 10.000 pasos';

  @override
  String get aiOverlayDemoWaterValue => '1,6 de 2,5 L';

  @override
  String get aiOverlayDemoAssistantSection => 'Acción con aprobación';

  @override
  String get aiOverlayNewChat => 'Nuevo chat';

  @override
  String get aiOverlayChatHistory => 'Historial de chats';

  @override
  String get aiOverlayAutoApprove =>
      'Aprobar automáticamente las solicitudes de datos';

  @override
  String get aiOverlayDemoAssistantMessage =>
      'Has entrenado tres veces esta semana. ¿Quieres que compare tu carga de entrenamiento?';

  @override
  String get aiOverlayDemoRequestLabel => 'Datos necesarios';

  @override
  String get aiOverlayDemoScope => 'Entrenamientos de los últimos 7 días';

  @override
  String get aiOverlayDemoScopeDetails =>
      'Duración y volumen del entrenamiento';

  @override
  String get aiOverlayDemoPurpose =>
      'Objetivo: comparar la carga de entrenamiento';

  @override
  String get aiOverlayDemoDeny => 'Rechazar';

  @override
  String get aiOverlayDemoAllowOnce => 'Permitir una vez';

  @override
  String get aiOverlayDemoApprovedFeedback =>
      'La aprobación se ha simulado en esta demostración.';

  @override
  String get aiOverlayDemoDeniedFeedback =>
      'La solicitud se ha rechazado en esta demostración.';

  @override
  String get aiOverlayDemoCloudHint =>
      'Arrastra la nube horizontalmente para moverla. Su posición se guarda.';

  @override
  String get aiOverlayDemoAssistantHint => 'Abrir el asistente de IA';

  @override
  String get aiOverlayDemoColorSectionTitle => 'Blanco y negro';

  @override
  String get aiOverlayDemoColorWhite => 'Blanco';

  @override
  String get aiOverlayDemoColorBlack => 'Negro';

  @override
  String get aiOverlayDemoLivelinessTitle => 'Movimiento de la nube';

  @override
  String get aiOverlayDemoLivelinessDescription =>
      'Controla el movimiento de la nube de IA expandida.';

  @override
  String get aiOverlayDemoSafeSpaceTitle =>
      'Mostrar los puntos del área segura';

  @override
  String get aiOverlayDemoSafeSpaceSubtitle =>
      'Mostrar las esquinas que se usan para cambiar el tamaño del área';

  @override
  String get aiOverlayDemoFullscreenTitle =>
      'Abrir directamente a pantalla completa';

  @override
  String get aiOverlayDemoFullscreenSubtitle =>
      'Omitir la vista intermedia al abrir la nube';

  @override
  String get developerNutritionLabSubtitle =>
      'Inspecciona la lógica nutricional y las recomendaciones adaptativas';

  @override
  String get appleFoundationReadyTitle => 'Disponible en este dispositivo';

  @override
  String get appleFoundationEnableTitle => 'Activar en Ajustes de iOS';

  @override
  String get appleFoundationNoTransferSubtitle =>
      'Sin transferencia de datos ni costes de API.';

  @override
  String get telemetryDeleteSuccess =>
      'Se intentó restablecer la telemetría. No se ha confirmado la eliminación en el servidor.';

  @override
  String aiAssistantAskModelHint(String model) {
    return 'Preguntar a $model';
  }

  @override
  String get aiStarterCheckNutritionTitle => 'Revisar la nutrición de hoy';

  @override
  String get aiStarterCheckNutritionPrompt =>
      '¿Cómo van hoy mi nutrición y mis macros? Muéstrame las calorías, proteínas, carbohidratos y grasas que he consumido, compáralas con mis objetivos diarios e indica cuánto me queda.';

  @override
  String get aiStarterCheckRecoveryTitle => 'Consultar la recuperación';

  @override
  String get aiStarterCheckRecoveryPrompt =>
      '¿Cuál es mi estado actual de recuperación? ¿Qué grupos musculares se han recuperado por completo y cuáles necesitan más descanso antes del próximo entrenamiento?';

  @override
  String get aiStarterSuggestMealTitle =>
      'Sugerir una comida para los macros restantes';

  @override
  String get aiStarterSuggestMealPrompt =>
      'Revisa mi diario de alimentación de hoy y los macros que me quedan. ¿Qué comidas he registrado ya y qué podría comer en la próxima para acercarme lo más posible a mis objetivos restantes de calorías y nutrientes?';

  @override
  String get aiAssistantThinking => 'Pensando…';

  @override
  String get aiAssistantProcessingData => 'Analizando los datos aprobados…';

  @override
  String get macroEntryButton => 'Macros';

  @override
  String get macroEntryTitle => 'Registrar macros';

  @override
  String get macroEntryName => 'Nombre (opcional)';

  @override
  String get macroEntryAmount => 'Cantidad (opcional)';

  @override
  String get macroEntryAmountTotalHint =>
      'Déjalo en blanco para introducir los valores del alimento completo.';

  @override
  String get macroEntryAmountPer100GramHint =>
      'Si indicas una cantidad, los valores nutricionales se expresan por cada 100 g.';

  @override
  String get macroEntryAmountPer100MlHint =>
      'Si indicas una cantidad, los valores nutricionales se expresan por cada 100 ml.';

  @override
  String get macroEntryCalculate => 'Calcular automáticamente';

  @override
  String get macroEntryInvalidValues =>
      'Estos valores no dan como resultado una cantidad válida de macronutrientes.';

  @override
  String get macroEntryLogAsFluid => 'Registrar también como bebida';

  @override
  String get macroEntryFluidAmountRequired =>
      'Introduce una cantidad en ml para registrar una bebida.';

  @override
  String get macroEntryExtraNutrients => 'Añadir más nutrientes';

  @override
  String get macroEntrySugar => 'Azúcar';

  @override
  String get macroEntryFiber => 'Fibra';

  @override
  String get macroEntrySalt => 'Sal';

  @override
  String get macroEntryCaffeine => 'Cafeína';

  @override
  String get macroEntryPer100 => 'Por cada 100';

  @override
  String get macroEntryPortion => 'Porción';

  @override
  String get macroEntrySaved => 'Macros registrados.';

  @override
  String get macroEntryDefaultName => 'Registro de macros';

  @override
  String get macroEntryDetailTitle => 'Nutrientes';

  @override
  String get macroEntryFillThreeValues =>
      'Introduce exactamente tres de los cuatro valores de macronutrientes.';

  @override
  String get macroEntryDeleteConfirm =>
      'Esta bebida está vinculada a un registro de macros. Si la eliminas, también se eliminará el registro de macros.';

  @override
  String get recoveryMixedReadyZoneTitle => 'Mixto / listo';

  @override
  String get feedbackReportDirectRequiresTelemetry =>
      'El envío directo requiere que estén activadas las estadísticas de uso seudónimas. Actívalas en Ajustes o utiliza el correo electrónico o la opción de compartir.';

  @override
  String get feedbackReportDirectSent =>
      'Informe de diagnóstico enviado directamente al desarrollador. ¡Gracias!';

  @override
  String get feedbackReportDirectSend => 'Enviar directamente al desarrollador';

  @override
  String get aiAssistantUpdateIntroTitle => 'Conoce el chat de IA';

  @override
  String get aiAssistantUpdateIntroBody =>
      'Pregunta sobre entrenamiento y nutrición o prepara borradores. Tu mensaje e imágenes se envían al modelo al enviarlos. El acceso a registros guardados requiere aprobación salvo que esté activa la aprobación automática. El destinatario puede cambiar si se usa otro proveedor.';

  @override
  String get aiAssistantUpdateIntroDemoLabel => 'Chat de ejemplo';

  @override
  String get aiAssistantUpdateIntroExampleQuestion =>
      '¿Qué puede hacer el nuevo chat de IA de Train Libre?';

  @override
  String get aiAssistantUpdateIntroExampleAnswer =>
      'El asistente puede preparar rutinas, planes y recetas como borradores. Revisa las sugerencias y comidas antes de aplicarlas o guardarlas.';

  @override
  String get aiAssistantUpdateIntroAiEnabled => 'Activar funciones de IA';

  @override
  String get aiAssistantUpdateIntroAiEnabledHint =>
      'Controla el chat de IA y las demás funciones de IA.';

  @override
  String get aiAssistantUpdateIntroLauncherEnabled =>
      'Mostrar el chat flotante de IA';

  @override
  String get aiAssistantUpdateIntroLauncherEnabledHint =>
      'Muestra u oculta la burbuja del chat. También puedes abrirlo desde el menú Añadir.';

  @override
  String get aiAssistantIntroAboutRow => 'Probar el chat de IA';

  @override
  String get aiAssistantIntroAboutRowSubtitle =>
      'Vuelve a abrir la presentación del nuevo chat de IA cuando quieras.';
}
