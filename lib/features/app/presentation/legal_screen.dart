// lib/screens/legal_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../generated/app_localizations.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/frosted_container.dart';
import '../../../util/design_constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';

/// Single source of truth for the active Privacy Policy & Terms of Service version.
const String kCurrentLegalVersion = '1.6';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: 'legal_privacy'));
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final document = _legalDocumentFor(
      Localizations.localeOf(context).languageCode,
    );
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.legal_section),
      body: Stack(
        children: [
          _buildBackground(theme),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  DesignConstants.screenPaddingHorizontal,
                  topPadding + DesignConstants.spacingL,
                  DesignConstants.screenPaddingHorizontal,
                  DesignConstants.screenPaddingVertical,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMetadataHeader(document, theme, l10n),
                    const SizedBox(height: DesignConstants.spacingL),
                    _buildLegalNotice(document, l10n),
                    const SizedBox(height: DesignConstants.spacingXL),
                    _buildPrivacyPolicy(document, l10n),
                    const SizedBox(height: DesignConstants.spacingXL),
                    _buildTermsOfService(document, l10n),
                    const SizedBox(height: DesignConstants.spacingXXL),
                    _buildBrowserButton(l10n),
                    const SizedBox(height: DesignConstants.bottomContentSpacer),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
    );
  }

  Widget _buildMetadataHeader(
    _LegalDocument document,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return FrostedContainer(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(DesignConstants.spacingM),
      radius: DesignConstants.borderRadiusL,
      blurSigma: 18,
      child: Row(
        children: [
          Expanded(
            child: _metadataItem(
              l10n.legal_document_version,
              document.version,
              theme,
            ),
          ),
          const SizedBox(width: DesignConstants.spacingM),
          Expanded(
            child: _metadataItem(
              l10n.legal_document_last_updated,
              document.date,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataItem(String label, String value, ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXS),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalNotice(_LegalDocument document, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.legal_notice),
        const SizedBox(height: DesignConstants.spacingS),
        FrostedContainer(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(DesignConstants.spacingL),
          radius: DesignConstants.borderRadiusL,
          blurSigma: 18,
          child: _LegalText(data: document.legalNotice),
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicy(_LegalDocument document, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.privacy_policy),
        const SizedBox(height: DesignConstants.spacingS),
        ...document.privacyPolicySections.map(_LegalAccordion.new),
      ],
    );
  }

  Widget _buildTermsOfService(_LegalDocument document, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.terms_of_service),
        const SizedBox(height: DesignConstants.spacingS),
        ...document.termsOfServiceSections.map(_LegalAccordion.new),
      ],
    );
  }

  Widget _buildBrowserButton(AppLocalizations l10n) {
    return AppButton.primary(
      onPressed: () =>
          _handleLink('https://rfivesix.github.io/train-libre/privacy-policy/'),
      label: l10n.view_in_browser,
      tooltip: l10n.view_in_browser,
      icon: LucideIcons.globe,
    );
  }
}

class _LegalAccordion extends StatefulWidget {
  const _LegalAccordion(this.section);

  final _LegalSection section;

  @override
  State<_LegalAccordion> createState() => _LegalAccordionState();
}

class _LegalAccordionState extends State<_LegalAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: FrostedContainer(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        radius: DesignConstants.borderRadiusL,
        blurSigma: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusL),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingL,
                  vertical: DesignConstants.spacingL,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.section.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Icon(
                      _isExpanded
                          ? LucideIcons.chevron_up
                          : LucideIcons.chevron_down,
                      color: theme.colorScheme.primary,
                      size: DesignConstants.iconSizeL,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignConstants.spacingL,
                  0,
                  DesignConstants.spacingL,
                  DesignConstants.spacingL,
                ),
                child: _LegalText(data: widget.section.content),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegalText extends StatefulWidget {
  const _LegalText({required this.data});

  final String data;

  @override
  State<_LegalText> createState() => _LegalTextState();
}

class _LegalTextState extends State<_LegalText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.6);
    final paragraphs = widget.data.trim().split(RegExp(r'\n\s*\n'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < paragraphs.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  index == paragraphs.length - 1 ? 0 : DesignConstants.spacingM,
            ),
            child: _paragraphWidget(paragraphs[index].trim(), baseStyle),
          ),
      ],
    );
  }

  Widget _paragraphWidget(String paragraph, TextStyle? baseStyle) {
    final lines = paragraph.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < lines.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == lines.length - 1 ? 0 : DesignConstants.spacingS,
            ),
            child: lines[index].trim().startsWith('- ')
                ? _bulletItem(lines[index].trim().substring(2), baseStyle)
                : Text.rich(
                    TextSpan(
                      children: _linkifiedSpans(lines[index].trim(), baseStyle),
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    textWidthBasis: TextWidthBasis.parent,
                  ),
          ),
      ],
    );
  }

  Widget _bulletItem(String item, TextStyle? baseStyle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•', style: baseStyle),
        const SizedBox(width: DesignConstants.spacingM),
        Expanded(
          child: Text.rich(
            TextSpan(children: _linkifiedSpans(item, baseStyle)),
            softWrap: true,
            overflow: TextOverflow.visible,
            textWidthBasis: TextWidthBasis.parent,
          ),
        ),
      ],
    );
  }

  List<TextSpan> _linkifiedSpans(String text, TextStyle? baseStyle) {
    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'((?:https?:\/\/|www\.)[^\s<>)]+)|([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
    );
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final rawValue = match.group(0)!;
      final trailing =
          RegExp(r'[.,;:!?]+$').firstMatch(rawValue)?.group(0) ?? '';
      final value = trailing.isEmpty
          ? rawValue
          : rawValue.substring(0, rawValue.length - trailing.length);
      final href = value.contains('@') && !value.startsWith('http')
          ? 'mailto:$value'
          : value.startsWith('http')
              ? value
              : 'https://$value';
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _handleLink(href);
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: value,
          style: baseStyle?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.64),
          ),
          recognizer: recognizer,
        ),
      );
      if (trailing.isNotEmpty) {
        spans.add(TextSpan(text: trailing));
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return spans
        .map((span) => TextSpan(
              text: span.text,
              children: span.children,
              style: span.style ?? baseStyle,
              recognizer: span.recognizer,
            ))
        .toList();
  }
}

Future<void> _handleLink(String href) async {
  final uri = Uri.parse(href);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

_LegalDocument _legalDocumentFor(String languageCode) {
  return languageCode == 'de' ? _germanLegalDocument : _englishLegalDocument;
}

class _LegalDocument {
  const _LegalDocument({
    required this.version,
    required this.date,
    required this.legalNotice,
    required this.privacyPolicySections,
    required this.termsOfServiceSections,
  });

  final String version;
  final String date;
  final String legalNotice;
  final List<_LegalSection> privacyPolicySections;
  final List<_LegalSection> termsOfServiceSections;
}

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

const _germanLegalDocument = _LegalDocument(
  version: '1.6',
  date: '27. Juli 2026',
  legalNotice: '''
Angaben gemäß § 5 DDG:

Diensteanbieter / Verantwortlich für die App „Train Libre“:
Richard Georg Schotte
Bundesallee 114
12161 Berlin
Deutschland

Kontakt:
E-Mail: feedback@schotte.me
Telefon: (+49) 1520 6915571

Vertretungsberechtigte Person:
Richard Georg Schotte (Einzelentwickler)

Umsatzsteuer-ID:
Nicht vorhanden
''',
  privacyPolicySections: [
    _LegalSection(
      title: '1. Verantwortlicher',
      content: '''
Diese Datenschutzerklärung informiert Sie gemäß Art. 13 und 14 der Datenschutz-Grundverordnung (DSGVO) über die Verarbeitung personenbezogener Daten und gesundheitsbezogener Daten in der mobilen Applikation „Train Libre“.

Da Train Libre als Local-First-Applikation konzipiert ist, verbleibt die vollständige Kontrolle über Ihre Daten zu jedem Zeitpunkt direkt bei Ihnen. Wir betreiben keine zentralen Datenbank- oder Anwendungsserver zur Speicherung Ihrer Profile, Workouts oder Ernährungsprotokolle.

---

Verantwortlich für die Datenverarbeitung im Sinne des Art. 4 Nr. 7 DSGVO ist der Entwickler und Diensteanbieter:

Richard Georg Schotte
Bundesallee 114
12161 Berlin
Deutschland

E-Mail: feedback@schotte.me
Telefon: (+49) 1520 6915571

Da es sich bei dem Verantwortlichen um einen Einzelentwickler handelt und die gesetzlichen Voraussetzungen zur verpflichtenden Bestellung eines Datenschutzbeauftragten gemäß Art. 37 DSGVO bzw. § 38 BDSG nicht vorliegen, ist kein gesonderter Datenschutzbeauftragter bestellt. Sämtliche datenschutzbezogene Anfragen können direkt an die oben genannte E-Mail-Adresse gerichtet werden.
''',
    ),
    _LegalSection(
      title: '2. Grundphilosophie',
      content: '''
Train Libre beruht auf dem Prinzip des „Privacy by Design“ und des „Privacy by Default“ (Art. 25 DSGVO) sowie auf dem Grundsatz der Datensparsamkeit (Art. 5 Abs. 1 lit. c DSGVO).

- Keine Benutzerkonten: Für die Nutzung der App ist keine Registrierung und kein Erstellen eines Benutzerkontos erforderlich. Es werden keine E-Mail-Adressen, Passwörter oder Anmeldedaten auf externen Servern gespeichert.
- Local-First-Architektur: Sämtliche von Ihnen eingegebenen Profileinstellungen, sportlichen Aktivitäten, Ernährungsdaten, Vitalwerte und Messungen werden ausschließlich in einer lokalen SQLite-Datenbank auf Ihrem eigenen Endgerät gespeichert.
- Kein zentraler Backend-Server: Wir betreiben keine Cloud-Datenbanken und keine Anwendungsserver zur Speicherung oder Verarbeitung Ihrer Trainings- und Ernährungsdaten. Ihre Daten verbleiben in Ihrem physischen Besitz.
- Kein kommerzielles Tracking (Optionale anonyme Telemetrie): Train Libre verzichtet auf Werbenetzwerke, verhaltensbasierte Werbe-SDKs und Profiling. Es steht eine rein optionale, anonyme Nutzungsstatistik (PostHog EU) zur Verfügung, die standardmäßig deaktiviert ist und keinerlei personenbezogene Daten (PII) oder persönliche Workout-/Ernährungsinhalte überträgt.
''',
    ),
    _LegalSection(
      title: '3. Lokal verarbeitete Daten',
      content: '''
Durch die Nutzung der App verarbeitet das Betriebssystem Ihres Mobilgeräts Daten in einer lokalen SQLite-Datenbank (Drift/sqflite). Die Speicherung dient dem Betrieb der App und der Erfüllung der Kernfunktionen.

A. Kategorien verarbeiteter Daten

Die lokale Datenbank umfasst folgende Datenkategorien:

- 1. Profileinstellungen und Ziele: Benutzername, Geburtsdatum, Körpergröße, Geschlecht, Profilbild-Dateipfad sowie individuell festgelegte Tagesziele (Ziel-Kalorien, Ziel-Proteine, Ziel-Kohlenhydrate, Ziel-Fett, Ziel-Wasser, Ziel-Schritte).
- 2. Trainings- und Aktivitätsprotokolle (Workouts): Trainingspläne (Routinen), Übungsvorlagen, historische Workout-Protokolle (Start- und Endzeit, Notizen, Übungssätze mit rep- und Gewicht-Werten, RPE- und RIR-Werten, Pausenzeiten, kardiovaskuläre Aktivitäten inklusive Distanz, Dauer und verbrannten Kalorien).
- 3. Ernährungs- und Flüssigkeitsprotokolle (Nutrition & Fluids): Konsumierte Lebensmittel (Zeitpunkt, Menge in Gramm/Millilitern, Mahlzeitentyp), Wasser- und Getränkeprotokolle (Menge, Nährstoffgehalt, Koffeingehalt).
- 4. Lebensmittel- und Produktkatalog (User-Products): Individuell vom Benutzer angelegte Produkte mit Barcode, Produktname, Marke und Makro-/Mikronährwertangaben pro 100g/ml (Kalorien, Eiweiß, Kohlenhydrate, Fett, Zucker, Ballaststoffe, Salz, Koffein, Zutatenliste und Zusatzstoffe).
- 5. Supplemente (Nahrungsergänzungsmittel): Eingerichtete Supplemente (Name, Standarddosis, Einheit, Tagesziel und Tageslimit) sowie historische Supplement-Logeinträge mit Einnahme-Zeitpunkt und Menge.
- 6. Körpermaße und Messungen (Measurements): Historische Messwerte für das Körpergewicht und verschiedene Körperumfänge (z. B. Brust, Taille) inklusive Datum und Einheit.
- 7. Pulsdaten-Aggregate: Lokale stündliche Aggregationen der Herzfrequenz (minimale, maximale und durchschnittliche Schläge pro Minute sowie Stichprobenanzahl).
- 8. Schlafdaten-Analysen: Aufbereitete Schlafdaten inklusive Schlafphasen (Tiefschlaf, REM, Leichtschlaf, Wachphasen), Schlaf-Effizienz, Ruheherzfrequenz, Schlafunterbrechungen, Schlaf-Regularität sowie historische Rohdaten-Importe aus den System-Schnittstellen.
- 9. Lokale Schrittsegmente: Aus den System-Schnittstellen importierte Schrittzahlen mit genauen Start- und Endzeitpunkten sowie Kennungen der Datenquelle zur lokalen Bereinigung von Dubletten.

B. Rechtsgrundlagen der Verarbeitung

Da die Speicherung und Auswertung ausschließlich lokal auf Ihrem Endgerät stattfindet, liegt die datenschutzrechtliche Verfügungsgewalt und Datenverarbeitung in Ihrer eigenen Sphäre. Soweit die App im Rahmen der DSGVO betrachtet wird, gelten folgende Rechtsgrundlagen:

- Allgemeine Daten und Einstellungen (Art. 6 Abs. 1 lit. b DSGVO): Die Verarbeitung allgemeiner Profileinstellungen, Trainingspläne und App-Präferenzen erfolgt zur Erfüllung des Nutzungsverhältnisses (Bereitstellung der App-Funktionalitäten).
- Gesundheitsdaten (Art. 9 Abs. 2 lit. a DSGVO in Verbindung mit Art. 6 Abs. 1 lit. a DSGVO): Für die Verarbeitung von körperlichen Messwerten, Pulsdaten, Schlafanalysen und Ernährungsprotokollen (welche als gesundheitsbezogene Daten unter die besonderen Kategorien fallen) erteilen Sie mit der aktiven Eingabe bzw. der Aktivierung des Imports Ihre ausdrückliche Einwilligung. Sie können diese Einwilligung jederzeit durch Löschen der entsprechenden Einträge oder durch Zurücksetzen aller App-Daten widerrufen.
''',
    ),
    _LegalSection(
      title: '4. Drittanbieter-Integrationen / BYOK',
      content: '''
Um erweiterte Funktionen bereitzustellen, verfügt die App über Schnittstellen zu externen Diensten. Diese Funktionen sind optional und erfordern Ihre aktive Mitwirkung.

A. Bring-Your-Own-Key (BYOK) AI Meal Capture

Train Libre bietet die Möglichkeit, Mahlzeiten über Fotos oder Freitextbeschreibungen mittels Künstlicher Intelligenz analysieren zu lassen. Diese Funktion basiert auf dem „Bring-Your-Own-Key“-Prinzip (BYOK). Sie müssen hierfür Ihren eigenen API-Schlüssel eines unterstützten Anbieters in der App hinterlegen.

- Unterstützte Anbieter: OpenAI, Google Gemini, Anthropic Claude, Mistral AI, xAI Grok, Ollama sowie benutzerdefinierte OpenAI-kompatible Endpunkte.
- Sichere lokale Schlüsselverwahrung: Der von Ihnen eingegebene API-Schlüssel wird unter Verwendung des Pakets flutter_secure_storage mit AES-256-Verschlüsselung im gesicherten Speicherbereich des Betriebssystems abgelegt (iOS Keychain bzw. Android Keystore). Der Schlüssel verbleibt ausschließlich lokal auf Ihrem Gerät und wird niemals an uns übertragen.
- Eingeschränkte Datenübertragung: Bei der Nutzung der KI-Analyse sendet Ihr Gerät das aufgenommene Mahlzeiten-Foto bzw. die eingegebene Textbeschreibung direkt über eine verschlüsselte HTTPS-Verbindung an die API des ausgewählten KI-Anbieters. Es werden keinerlei personalisierte Kontodaten, Metadaten oder Profilinformationen aus Train Libre an diese externen Endpunkte übermittelt.
- Analytische KI-Verarbeitung (Kein generatives Coaching): Die KI-Analyse dient dem ausschließlichen analytischen Zweck, Mahlzeiten in ihre atomaren Bestandteile (Zutaten) zu zerlegen. Train Libre nutzt die KI nicht zur dynamischen Generierung oder zum Vorschlag von Rezepten, Ernährungsplänen oder automatisiertem Gesundheitscoaching.
- Hybride lokale Verifizierung: Um Ihre Privatsphäre maximal zu schützen, ist der systemweit hinterlegte Prompt der App so konfiguriert, dass der KI-Anbieter angewiesen wird, ausschließlich Lebensmittelkomponenten zu identifizieren und deren Gewicht in Gramm zu schätzen. Der KI-Anbieter wird ausdrücklich angewiesen, keine Nährwertberechnungen (wie Kalorien, Proteine, Fett oder Kohlenhydrate) durchzuführen. Die Ermittlung der Nährwerte erfolgt über einen hybriden Ansatz: Die erkannten Lebensmittelnamen werden über eine lokale Jaro-Winkler-basierte Matching-Engine (SQLite/Drift) vollständig offline auf Ihrem Gerät mit Ihrem lokalen Katalog abgeglichen.
- Local-First-Prinzip: Die Berechnung der Makronährstoffe, das Nutzer-Profiling sowie die Verlaufshistorie verbleiben strikt lokal auf Ihrem Endgerät und werden niemals für das Training globaler KI-Modelle verwendet.
- Verantwortlichkeit: Da Sie Ihren persönlichen API-Schlüssel verwenden, schließen Sie direkt ein Nutzungsverhältnis mit dem jeweiligen KI-Anbieter ab. Die Datenverarbeitung durch den KI-Anbieter unterliegt dessen jeweiligen Datenschutzbestimmungen. Bitte prüfen Sie die Datenschutzrichtlinien Ihres Anbieters (insbesondere bezüglich der Datenverwendung für Trainingszwecke und der Serverstandorte), bevor Sie die Funktion nutzen.

Bitte prüfen Sie die Datenschutzrichtlinien Ihres Anbieters hier:
• OpenAI: https://openai.com/policies/privacy-policy
• Google Gemini: https://policies.google.com/privacy
• Anthropic Claude: https://www.anthropic.com/privacy
• Mistral AI: https://mistral.ai/privacy-policy
• xAI Grok: https://x.ai/privacy-policy
• Ollama: https://ollama.com/privacy

Bei Übertragungen an Anbieter außerhalb der Europäischen Union (insbesondere in die USA) erfolgt dies auf Grundlage von Standardvertragsklauseln oder Angemessenheitsbeschlüssen, die Sie mit dem Anbieter vereinbart haben.

B. Offline-Katalog-Updates (Open Food Facts & Exercise Catalog)

Um Lebensmittel-Barcodes offline scannen und Übungen nachschlagen zu können, nutzt Train Libre lokale Produkt- und Übungskataloge. Diese Kataloge werden als vorkompilierte SQLite-Datenbankdateien direkt auf Ihr Gerät heruntergeladen.

- Funktionsweise: Die App prüft in regelmäßigen Abständen, ob Aktualisierungen für den Lebensmittelkatalog (basierend auf Open Food Facts) oder den Übungskatalog (basierend auf wger/GitHub) vorliegen. Die Prüfung und der anschließende Download der komprimierten Katalogdatenbanken erfolgen über eine verschlüsselte HTTPS-Verbindung direkt zu den Servern des Hosting-Dienstleisters (z. B. GitHub Pages / GitHub Inc. bzw. Open Food Facts).
- Datenminimierung: Beim Herunterladen der Katalog-Updates werden systembedingt technische Verbindungsdaten (insbesondere Ihre IP-Adresse, Datum/Uhrzeit des Zugriffs und der User-Agent der App) an den Hoster übertragen. Es werden zu keinem Zeitpunkt nutzergenerierte Daten, gescannte Barcodes oder persönliche Profileigenschaften an die Katalog-Hoster gesendet.
- Lokale Barcode-Zuordnung: Der Abgleich eines gescannten Barcodes oder die Suche nach Lebensmitteln und Übungen findet zu 100 Prozent offline auf Ihrem Gerät. Im Gegensatz to herkömmlichen Ernährungs-Apps wird beim Scannen eines Produkts keine Anfrage mit dem Barcode an einen Cloud-Server gesendet.
''',
    ),
    _LegalSection(
      title: '5. Gesundheitsdaten-Schnittstellen',
      content: '''
Train Libre kann mit den systemweiten Gesundheitsdatenbanken Ihres Betriebssystems (Apple HealthKit unter iOS bzw. Google Health Connect unter Android) interagieren. Diese Interaktion erfolgt ausschließlich lokal auf Ihrem Endgerät und erfordert Ihre ausdrückliche, jederzeit widerrufbare Freigabe in den Systemeinstellungen des jeweiligen Betriebssystems.

A. Daten-Import (Lesen)

Sofern Sie der App die Berechtigung erteilen, liest Train Libre Daten aus Apple HealthKit bzw. Google Health Connect aus, um diese lokal in der App anzuzeigen und zu verarbeiten:
- Schrittzahlen: Import der aufgezeichneten Schrittzahlsegmente zur Offline-Auswertung.
- Schlafdaten: Import von Schlafzeiträumen und Schlafphasen.
- Herzfrequenz: Import von Puls-Stichproben zur Berechnung lokaler stündlicher Aggregationen.

Der Import dient ausschließlich der Darstellung und lokalen Analyse innerhalb von Train Libre. Es findet kein Transfer dieser importierten Daten an externe Server statt.

B. Daten-Export (Schreiben & Idempotenz)

Auf Ihren Wunsch hin kann Train Libre manuell in der App erfasste Daten in die System-Gesundheitsdatenbanken (Apple HealthKit / Google Health Connect) exportieren:
- Körpermaße: Export von Gewichtsmessungen.
- Ernährung und Hydration: Export von konsumierten Nährwerten, Kalorien und Wassermengen.
- Workouts: Export von abgeschlossenen Trainingseinheiten.

- Lokaler Idempotenz-Schutz: Um zu verhindern, dass bei wiederholten Synchronisationen Daten mehrfach in Ihre System-Gesundheitsdatenbank geschrieben werden, verfügt Train Libre über ein lokales Protokollierungssystem. In der Tabelle health_export_records der lokalen SQLite-Datenbank wird für jeden erfolgreichen Schreibvorgang eine eindeutige ID, die Ziel-Plattform (Apple Health oder Health Connect), der Datenbereich (Domain) sowie ein eindeutiger Idempotenzschlüssel zusammen mit dem Export-Zeitstempel gespeichert. Dieser Abgleich findet rein lokal auf Ihrem Gerät statt und dient der Sicherstellung der Datenkonsistenz.
''',
    ),
    _LegalSection(
      title: '6. Datensicherheit & Backups',
      content: '''
Da sämtliche Daten lokal auf Ihrem Endgerät liegen, ist die Sicherheit des Geräts maßgeblich für den Schutz Ihrer Daten.

A. Lokale Datenisolation

Das Betriebssystem (iOS/Android) isoliert die App-Daten von Train Libre durch Sandbox-Mechanismen. Andere installierte Applikationen haben ohne Ihre Zustimmung keinen Zugriff auf die lokale SQLite-Datenbank oder die in den gesicherten App-Einstellungen hinterlegten API-Schlüssel.

B. Manuelle und automatische Backups

Die App bietet Ihnen Funktionen zur Sicherung Ihrer Daten, um Datenverlust bei Gerätewechsel oder -beschädigung vorzubeugen.

- 1. Dateigenerierung und Export: Sie können ein vollständiges Backup aller in der SQLite-Datenbank sowie in den Einstellungen gespeicherten Daten erzeugen. Dieses Backup wird als strukturierte JSON-Datei im temporären Speicherbereich des Betriebssystems generiert und über das systemeigene Teilen-Menü (Share Sheet) exportiert. Nach dem Export wird die temporäre Datei unverzüglich gelöscht.
- 2. Verschlüsselung: Zum Schutz Ihrer sensiblen Daten können Backups vor dem Export mit einem von Ihnen gewählten Passwort verschlüsselt werden. Die Verschlüsselung erfolgt lokal auf dem Gerät mittels starker kryptografischer Algorithmen. Unverschlüsselte Backups sollten stets an sicheren Speicherorten aufbewahrt werden.
- 3. Automatische Backups: Sie können automatische Backups in konfigurierbaren Intervallen aktivieren. Unter Android nutzt diese Funktion das Storage Access Framework (SAF) zur direkten Ablage in einem von Ihnen ausgewählten Zielordner. Alternativ erfolgt die Ablage im lokalen App-Dokumentenverzeichnis. Diese Backup-Dateien verbleiben auf Ihrem Gerät, es sei denn, Sie kopieren sie aktiv an einen externen Cloud-Speicherort (z. B. iCloud Drive oder Google Drive).
- 4. System-Backups: Bitte beachten Sie, dass bei aktivierten systemweiten Geräte-Backups (z. B. über Apple iCloud oder Google Drive Backup) die Anwendungsdaten von Train Libre standardmäßig vom Betriebssystem in die jeweilige Cloud hochgeladen werden. Dies liegt außerhalb unseres Einflussbereichs und kann in den Systemeinstellungen Ihres Geräts für Train Libre deaktiviert werden.
- 5. iCloud-Backup (nur iOS): Train Libre bietet auf iOS eine optionale iCloud-Backup-Funktion an. Wenn Sie diese aktivieren, synchronisiert die App Ihre lokale Datenbank automatisch in Ihren persönlichen iCloud-Drive-Ordner über die iCloud-Infrastruktur von Apple. Diese Funktion ist strikt optional und wird ausschließlich über Ihre Apple-ID und die iOS-Systemeinstellungen gesteuert – Train Libre aktiviert, plant oder greift ohne Ihr Zutun nicht darauf zu. Backup-Daten werden von Apples iCloud-Infrastruktur verschlüsselt (im Ruhezustand und bei der Übertragung); Train Libre speichert, hostet, verarbeitet oder hat keinen Zugriff auf Ihre Backup-Dateien oder Verschlüsselungsschlüssel auf externen Unternehmensservern. Der Datenschutz für diese Funktion unterliegt Apples iCloud-Datenschutzrichtlinie (https://www.apple.com/legal/privacy/).

C. Optionale anonyme Telemetrie

Train Libre bietet eine rein optionale, datenschutzfreundliche Nutzungsstatistik zur Verbesserung der App-Stabilität und Feature-Nutzung an, betrieben über PostHog EU (https://eu.i.posthog.com).

- 1. Strikter Opt-In-Standard: Die Telemetrie ist standardmäßig vollständig deaktiviert. Es werden keinerlei Daten oder Netzwerkverbindungen aufgebaut, bevor Sie die Funktion nicht ausdrücklich in den Einstellungen unter Support & Info durch Aktivieren von „Anonyme Nutzungsstatistiken teilen“ einschalten.
- 2. Keine personenbezogenen Daten (Zero PII): Es werden keinerlei persönliche Identifikatoren, Namen, E-Mail-Adressen, IP-Adressen, Körpergewichte, Übungs-Wiederholungen oder Mahlzeitennamen erfasst. IP-Adressen werden unmittelbar bei der Verarbeitung verworfen.
- 3. Grobe aggregierte Buckets: Erfasste Metriken werden ausschließlich in grobe, nicht-identifizierbare Bereiche zusammengefasst (z. B. App-Version, Betriebssystem-Plattform, grobe Workout-Dauerbereiche wie 15-30min, Übungsanzahl-Bereiche wie 4-7, KI-Anfrage-Latenzbereiche sowie Schema-Migrationsstatus).
- 4. Jederzeitiger Widerruf: Sie können Ihre Zustimmung jederzeit in den Einstellungen widerrufen, wodurch alle Übertragungen sofort gestoppt werden.
- 5. Rechtsgrundlage: Die Verarbeitung von Telemetriedaten erfolgt ausschließlich auf Grundlage Ihrer ausdrücklichen Einwilligung gemäß Art. 6 Abs. 1 lit. a DSGVO.
- 6. Auftragsverarbeiter: Als Auftragsverarbeiter gemäß Art. 28 DSGVO fungiert die PostHog, Inc. (2261 Market St., #4008, San Francisco, CA 94114, USA). Ein Vertrag zur Auftragsverarbeitung (Data Processing Agreement, DPA) wurde geschlossen.
- 7. Speicherort, Speicherdauer & US-Zugriffe: Telemetriedaten werden ausschließlich auf EU-basierten Servern (AWS eu-central-1, Frankfurt am Main, Deutschland) gespeichert und nach maximal 12 Monaten automatisch gelöscht. Während alle Daten in der EU verbleiben, erfolgen eventuelle Fernzugriffe für technischen Support durch PostHog, Inc. auf Grundlage geeigneter Garantien unter dem EU-US Data Privacy Framework (DPF).
''',
    ),
    _LegalSection(
      title: '7. Betroffenenrechte',
      content: '''
Als betroffene Person stehen Ihnen im Rahmen der DSGVO weitreichende Rechte zu. Da Train Libre eine Local-First-App ist, können Sie den Großteil dieser Rechte direkt und selbstbestimmt innerhalb der App ausüben, ohne auf unsere Mitwirkung angewiesen zu sein.

- Recht auf Auskunft (Art. 15 DSGVO) & Datenübertragbarkeit (Art. 20 DSGVO): Sie haben das Recht zu erfahren, welche Daten in der App gespeichert sind. Sie können Ihre vollständige Datenbank jederzeit selbst einsehen und über die integrierte Backup-Exportfunktion in einem maschinenlesbaren Format (JSON-Datei) exportieren. Zudem können Sie Berichte in Standardformaten (wie CSV) exportieren.
- Recht auf Berichtigung (Art. 16 DSGVO): Sie können sämtliche von Ihnen manuell erfassten Profildaten, Workouts, Ernährungsprotokolle, Körpergewichte und Einstellungen jederzeit direkt in den Benutzeroberflächen der App korrigieren oder ändern.
- Recht auf Löschung / „Recht auf Vergessenwerden“ (Art. 17 DSGVO): Sie können einzelne Datensätze (z. B. ein bestimmtes Workout oder ein Lebensmittel-Log) manuell in der App löschen.
- Unwiderrufliche Datenlöschung (AppData Reset): Die App verfügt über eine integrierte Löschfunktion für alle lokalen Anwendungsdaten. In den Einstellungen können Sie die Funktion zur vollständigen Datenlöschung ausführen. Dieser Prozess löscht unwiderruflich:
◦ Alle SharedPreferences-Einstellungen und App-Zustände.
◦ Alle aufgezeichneten Trainingsprotokolle, benutzerdefinierten Übungen und Routinen.
◦ Alle Ernährungsprotokolle, Mahlzeitenvorlagen und benutzerdefinierten Lebensmittel.
◦ Alle eingetragenen Körpermaße, Supplement-Logbücher und historischen Tagesziele.
◦ Sämtliche lokal zwischengespeicherten Puls- und Schlafanalysestufen.
◦ Alle in der sicheren Betriebssystem-Ablage hinterlegten API-Schlüssel für KI-Anbieter.

Nach Ausführung dieser Funktion befindet sich die App im Auslieferungszustand. Bitte beachten Sie, dass bereits an Apple Health oder Google Health Connect exportierte Daten durch diese appinterne Funktion nicht gelöscht werden können, da diese in der Hoheit des Betriebssystems liegen. Sie können diese exportierten Daten jedoch jederzeit direkt in den systemeigenen Health-Apps von Apple oder Google löschen.
- Rechte bezüglich Telemetriedaten: Sofern Sie in die anonyme Telemetrie eingewilligt haben, können Sie Ihre Betroffenenrechte (Auskunft, Löschung, Widerspruch) bezüglich der verarbeiteten Telemetriedaten jederzeit per E-Mail an feedback@schotte.me ausüben. Auf Ihre Anfrage hin werden alle Ihre Telemetrie-Events unverzüglich von den PostHog-Servern gelöscht.
- Recht auf Beschwerde bei einer Aufsichtsbehörde (Art. 77 DSGVO): Unbeschadet der appinternen Kontrollmöglichkeiten haben Sie das Recht, Beschwerde bei einer zuständigen Datenschutz-Aufsichtsbehörde einzulegen. Dies kann beispielsweise die Aufsichtsbehörde Ihres üblichen Aufenthaltsortes, Ihres Arbeitsplatzes oder des Sitzes des Verantwortlichen sein (z. B. die Berliner Beauftragte für Datenschutz und Informationsfreiheit).
''',
    ),
  ],
  termsOfServiceSections: [
    _LegalSection(title: '1. Keine medizinische Beratung', content: '''
Alle gesundheitsbezogenen Einschätzungen, Körpergewichtsziele, Makronährstoffziele, Berechnungen des täglichen Gesamtenergiebedarfs (TDEE), Muskel-Erholungs-Scores und andere gesundheitsbezogene Annäherungen, die von Train Libre bereitgestellt werden, sind statistische Schätzungen auf der Grundlage mathematischer Modelle der Allgemeinbevölkerung (wie Mifflin-St Jeor und Katch-McArdle). Sie stellen keine medizinische, ernährungsphysiologische oder sportliche Beratung dar und dürfen keinesfalls die Konsultation einer qualifizierten Fachkraft oder eines Arztes ersetzen. Die Nutzung dieser Funktionen erfolgt ausschließlich auf eigene Gefahr.
'''),
    _LegalSection(
        title: '2. Haftungsausschluss / As-Is-Gewährleistung', content: '''
Train Libre wird im Ist-Zustand („as is“) ohne jegliche ausdrückliche oder stillschweigende Gewährleistung zur Verfügung gestellt, einschließlich, aber nicht beschränkt auf die Gewährleistung der Marktgängigkeit, der Eignung für einen bestimmten Zweck und der Nichtverletzung von Rechten Dritter. Der Entwickler haftet nicht für Datenverluste, Geräteanomalien, unterbrochene Funktionalität oder direkte, indirekte, zufällige oder Folgeschäden, die aus der Nutzung der kompilierten ausführbaren Anwendung (Binary) oder des Quellcodes entstehen.
'''),
    _LegalSection(title: '3. Datenautonomie', content: '''
Alle vom Nutzer erstellten Daten, Profilparameter, Trainingsprotokolle, Ernährungsverläufe und lokalen Datenbankeinträge (Drift/SQLite) verbleiben ausschließlich in der Sandbox Ihres lokalen Endgeräts. Der Entwickler hat keinen Fernzugriff auf diese Daten, betreibt keine Backend-Server, um sie zu sammeln, und übernimmt keine Verantwortung für die Datenwiederherstellung, Datensicherung, Migration oder Datenverluste. Sie sind allein für die Sicherung Ihres Geräts und die Verwaltung Ihrer manuellen oder automatischen Datenexporte verantwortlich.
'''),
    _LegalSection(title: '4. Open-Source-Regelung', content: '''
Der Quellcode von Train Libre wird unter der GNU General Public License v3.0 (GPL-3.0) verbreitet, wie im Repository des Projekts veröffentlicht. Diese Nutzungsbedingungen regeln ausschließlich die Nutzung der kompilierten ausführbaren Anwendung (Binary) und schränken keine Rechte ein, die Ihnen durch die GPL-3.0 gewährt werden, einschließlich des Rechts auf Zugriff, Änderung und Weiterverbreitung des Quellcodes unter denselben Lizenzbedingungen.
'''),
  ],
);

const _englishLegalDocument = _LegalDocument(
  version: '1.6',
  date: 'July 27, 2026',
  legalNotice: '''
Information according to § 5 DDG:

Service Provider / Responsible for the App “Train Libre”:
Richard Georg Schotte
Bundesallee 114
12161 Berlin
Germany

Contact:
E-Mail: feedback@schotte.me
Phone: (+49) 1520 6915571

Authorized Representative:
Richard Georg Schotte (Sole Developer)
''',
  privacyPolicySections: [
    _LegalSection(
      title: '1. Controller',
      content: '''
This privacy policy informs you in accordance with Articles 13 and 14 of the General Data Protection Regulation (GDPR) about the processing of personal data and health-related data in the mobile application "Train Libre".

Since Train Libre is designed as a local-first application, full control over your data remains directly with you at all times. We do not operate any central database or application servers to store your profiles, workouts, or nutrition logs.

---

The controller for data processing within the meaning of Article 4(7) of the GDPR is the developer and service provider:

Richard Georg Schotte
Bundesallee 114
12161 Berlin
Germany

Email: feedback@schotte.me
Phone: (+49) 1520 6915571

Since the controller is an individual developer and the statutory requirements for the mandatory appointment of a data protection officer pursuant to Article 37 of the GDPR and Section 38 of the German Federal Data Protection Act (BDSG) are not met, no separate data protection officer has been appointed. All data protection-related inquiries can be directed directly to the email address provided above.
''',
    ),
    _LegalSection(
      title: '2. Core Philosophy',
      content: '''
Train Libre is based on the principles of "privacy by design" and "privacy by default" (Article 25 of the GDPR) as well as the principle of data minimization (Article 5(1)(c) of the GDPR).

- No User Accounts: No registration or creation of a user account is required to use the app. No email addresses, passwords, or login credentials are stored on external servers.
- Local-First Architecture: All profile settings, athletic activities, nutrition data, vital signs, and measurements entered by you are stored exclusively in a local SQLite database on your own end device.
- No Central Backend Server: We do not operate any cloud databases or application servers to store or process your training and nutrition data. Your data remains in your physical possession.
- No Commercial Tracking (Optional Anonymous Telemetry): Train Libre dispenses with advertising networks, commercial tracking, and behavior profiling. A purely optional, anonymous usage statistics integration (PostHog EU) is disabled by default and captures zero personally identifiable information (PII) or personal workout/meal contents.
''',
    ),
    _LegalSection(
      title: '3. Locally Processed Data',
      content: '''
By using the app, your mobile device's operating system processes data in a local SQLite database (Drift/sqflite). This storage is necessary for the operation of the app and to fulfill its core functions.

A. Categories of Processed Data

The local database includes the following data categories:

- 1. Profile Settings and Goals: Username, date of birth, body height, gender, profile picture file path, and individually defined daily goals (target calories, target protein, target carbohydrates, target fat, target water, target steps).
- 2. Training and Activity Logs (Workouts): Training plans (routines), exercise templates, historical workout logs (start and end times, notes, exercise sets with rep and weight values, RPE and RIR values, rest times, cardiovascular activities including distance, duration, and calories burned).
- 3. Nutrition and Fluid Logs (Nutrition & Fluids): Consumed food items (timestamp, amount in grams/milliliters, meal type), water and beverage logs (amount, nutrient content, caffeine content).
- 4. Food and Product Catalog (User-Products): Products individually created by the user, including barcode, product name, brand, and macro/micronutrient information per 100g/ml (calories, protein, carbohydrates, fat, sugar, dietary fiber, salt, caffeine, list of ingredients, and additives).
- 5. Supplements: Set up supplements (name, default dose, unit, daily goal, and daily limit) as well as historical supplement log entries with intake timestamp and amount.
- 6. Body Dimensions and Measurements (Measurements): Historical measurement values for body weight and various body circumferences (e.g., chest, waist) including date and unit.
- 7. Heart Rate Data Aggregates: Local hourly aggregations of heart rate (minimum, maximum, and average beats per minute, as well as sample count).
- 8. Sleep Data Analyses: Processed sleep data including sleep phases (deep sleep, REM, light sleep, waking phases), sleep efficiency, resting heart rate, sleep interruptions, sleep regularity, as well as historical raw data imports from system interfaces.
- 9. Local Step Segments: Step counts imported from system interfaces with precise start and end times as well as data source identifiers for local duplicate cleaning.

B. Legal Basis for Processing

Since storage and evaluation take place exclusively locally on your end device, control over data protection and data processing remains in your own sphere. Insofar as the app is considered within the scope of the GDPR, the following legal bases apply:

- General Data and Settings (Article 6(1)(b) of the GDPR): The processing of general profile settings, training plans, and app preferences is carried out to fulfill the user relationship (provision of app functionalities).
- Health Data (Article 9(2)(a) of the GDPR in conjunction with Article 6(1)(a) of the GDPR): For the processing of physical measurements, heart rate data, sleep analyses, and nutrition logs (which fall under special categories of data as health-related data), you grant your explicit consent by actively entering them or enabling the import. You can withdraw this consent at any time by deleting the corresponding entries or by resetting all app data.
''',
    ),
    _LegalSection(
      title: '4. Third-Party Integrations / BYOK',
      content: '''
To provide advanced features, the app has interfaces to external services. These functions are optional and require your active participation.

A. Bring-Your-Own-Key (BYOK) AI Meal Capture

Train Libre offers the option to analyze meals via photos or free-text descriptions using artificial intelligence. This function is based on the "Bring-Your-Own-Key" (BYOK) principle. You must store your own API key from a supported provider in the app to use this.

- Supported Providers: OpenAI, Google Gemini, Anthropic Claude, Mistral AI, xAI Grok, Ollama, and custom OpenAI-compatible endpoints.
- Secure Local Key Storage: The API key you enter is stored encrypted using AES-256 encryption via the flutter_secure_storage package in the operating system's secured storage area (iOS Keychain or Android Keystore). The key remains exclusively local to your device and is never transmitted to us.
- Restricted Data Transmission: When using the AI analysis, your device sends the captured meal photo or entered text description directly via an encrypted HTTPS connection to the API of the selected AI provider.
- Privacy Protection via System Prompt: To maximize your privacy, the app's globally stored system prompt is configured to instruct the AI provider to identify only food components and estimate their weight in grams. The AI provider is explicitly instructed not to perform any nutrient calculations (such as calories, protein, fat, or carbohydrates). The determination of nutrients is then performed completely locally and offline on your device by matching the recognized food names with your local offline catalog. Thus, no personal nutrition or health history is transmitted to the AI services.
- Responsibility: Since you are using your personal API key, you enter into a direct user relationship with the respective AI provider. Data processing by the AI provider is subject to their respective privacy policies. Please check your provider's privacy policy (especially regarding the use of data for training purposes and server locations) before using the function.

Please check your provider's privacy policy here:
• OpenAI: https://openai.com/policies/privacy-policy
• Google Gemini: https://policies.google.com/privacy
• Anthropic Claude: https://www.anthropic.com/privacy
• Mistral AI: https://mistral.ai/privacy-policy
• xAI Grok: https://x.ai/privacy-policy
• Ollama: https://ollama.com/privacy

For transmissions to providers outside the European Union (especially the USA), this occurs on the basis of standard contractual clauses or adequacy decisions that you have agreed with the provider.

B. Offline Catalog Updates (Open Food Facts & Exercise Catalog)

To scan food barcodes offline and look up exercises, Train Libre uses local product and exercise catalogs. These catalogs are downloaded directly to your device as precompiled SQLite database files.

- How it Works: The app checks at regular intervals whether updates are available for the food catalog (based on Open Food Facts) or the exercise catalog (based on wger/GitHub). The check and subsequent download of the compressed catalog databases are performed via an encrypted HTTPS connection directly to the servers of the hosting service provider (e.g., GitHub Pages / GitHub Inc. or Open Food Facts).
- Data Minimization: When downloading catalog updates, technical connection data (in particular your IP address, date/time of access, and the app's User-Agent) are transmitted to the host as a system requirement. No user-generated data, scanned barcodes, or personal profile characteristics are sent to the catalog hosts at any time.
- Local Barcode Mapping: The matching of a scanned barcode or the search for food and exercises takes place 100 percent offline on your device. Unlike conventional nutrition apps, scanning a product does not send a request with the barcode to a cloud server.
''',
    ),
    _LegalSection(
      title: '5. Health Data Interfaces',
      content: '''
Train Libre can interact with your operating system's system-wide health databases (Apple HealthKit on iOS or Google Health Connect on Android). This interaction takes place exclusively locally on your end device and requires your explicit approval, which can be revoked at any time, in the system settings of the respective operating system.

A. Data Import (Reading)

If you grant permission to the app, Train Libre reads data from Apple HealthKit or Google Health Connect to display and process it locally within the app:
- Step Counts: Import of recorded step count segments for offline evaluation.
- Sleep Data: Import of sleep intervals and sleep phases.
- Heart Rate: Import of heart rate samples to calculate local hourly aggregations.

The import is used exclusively for display and local analysis within Train Libre. No transfer of this imported data to external servers takes place.

B. Data Export (Writing & Idempotency)

At your request, Train Libre can export data manually recorded in the app to the system health databases (Apple HealthKit / Google Health Connect):
- Body Dimensions: Export of weight measurements.
- Nutrition and Hydration: Export of consumed nutritional values, calories, and water amounts.
- Workouts: Export of completed training sessions.

- Local Idempotency Protection: To prevent duplicate data from being written to your system health database during repeated synchronizations, Train Libre features a local logging system. In the health_export_records table of the local SQLite database, a unique ID, the target platform (Apple Health or Health Connect), the data domain, and a unique idempotency key are stored together with the export timestamp for every successful write operation. This comparison takes place purely locally on your device and serves to ensure data consistency.
''',
    ),
    _LegalSection(
      title: '6. Data Security & Backups',
      content: '''
Since all data resides locally on your end device, the security of the device is critical to protecting your data.

A. Local Data Isolation

The operating system (iOS/Android) isolates Train Libre's app data using sandbox mechanisms. Other installed applications do not have access to the local SQLite database or the API keys stored in the secured app settings without your consent.

B. Manual and Automatic Backups

The app offers functions to back up your data in order to prevent data loss in the event of device replacement or damage.

- 1. File Generation and Export: You can generate a complete backup of all data stored in the SQLite database and in the settings. This backup is generated as a structured JSON file in the operating system's temporary storage area and exported via the system's own share menu (Share Sheet). After the export, the temporary file is deleted immediately.
- 2. Encryption: To protect your sensitive data, backups can be encrypted with a password of your choice before export. The encryption is performed locally on the device using strong cryptographic algorithms. Unencrypted backups should always be stored in secure locations.
- 3. Automatic Backups: You can enable automatic backups at configurable intervals. On Android, this feature uses the Storage Access Framework (SAF) to save directly to a target folder selected by you. Alternatively, the file is saved in the local app document directory. These backup files remain on your device unless you actively copy them to an external cloud storage location (e.g., iCloud Drive or Google Drive).
- 4. System Backups: Please note that if system-wide device backups are enabled (e.g., via Apple iCloud or Google Drive Backup), Train Libre's application data will by default be uploaded to the respective cloud by the operating system. This is beyond our control and can be disabled for Train Libre in your device's system settings.
- 5. iCloud Backup (iOS only): Train Libre offers an optional iCloud Backup feature on iOS. If enabled by you, the app automatically syncs your local database to your personal iCloud Drive folder via Apple's iCloud infrastructure. This feature is strictly opt-in and controlled exclusively through your Apple ID and iOS system settings — Train Libre does not activate, schedule, or access it without your action. Backup data is encrypted at rest and in transit by Apple's iCloud infrastructure; Train Libre does not store, host, process, or have access to any of your backup files or encryption keys on any external company server. Your data privacy for this feature is governed by Apple's iCloud Privacy Policy (https://www.apple.com/legal/privacy/).

C. Optional Anonymous Telemetry

Train Libre includes an optional, privacy-focused usage metrics integration powered by PostHog EU (https://eu.i.posthog.com).

- 1. Strict Opt-In Default: Telemetry is disabled by default. No telemetry data or network requests are transmitted unless you explicitly opt in by toggling "Share anonymous usage statistics" to ON in Settings under Support & Info.
- 2. Zero Personally Identifiable Information (PII): Telemetry captures zero personal identifiers, user names, email addresses, IP addresses, body weights, set reps, or food item titles. IP addresses are discarded upon ingestion.
- 3. Coarse Aggregated Buckets: Event metrics are exclusively grouped into coarse, non-identifiable ranges (e.g., app version, OS platform, coarse workout duration buckets like 15-30min, exercise count ranges like 4-7, AI request latency buckets, and schema migration status).
- 4. Instant Revocation: You can withdraw your consent and disable telemetry at any time in Settings, which immediately halts all event transmissions.
- 5. Legal Basis: The processing of telemetry data is based exclusively on your explicit consent pursuant to Article 6(1)(a) of the GDPR.
- 6. Data Processor: PostHog, Inc. (2261 Market St., #4008, San Francisco, CA 94114, USA) acts as data processor pursuant to Article 28 of the GDPR. A Data Processing Agreement (DPA) is in place.
- 7. Storage Location, Retention & US Transfer Safeguards: Telemetry data is stored exclusively on EU-based infrastructure (AWS eu-central-1, Frankfurt, Germany) and retained for a maximum of 12 months, after which it is automatically deleted. While all primary storage remains strictly within the EU, technical support access by PostHog, Inc. may occur under the safeguards of the EU-US Data Privacy Framework (DPF).
''',
    ),
    _LegalSection(
      title: '7. Data Subject Rights',
      content: '''
As a data subject, you have extensive rights under the GDPR. Because Train Libre is a local-first app, you can exercise most of these rights directly and autonomously within the app, without relying on our involvement.

- Right of Access (Art. 15 GDPR) & Data Portability (Art. 20 GDPR): You have the right to know what data is stored in the app. You can view your entire database yourself at any time and export it in a machine-readable format (JSON file) using the built-in backup export feature. You can also export reports in standard formats (such as CSV).
- Right to Rectification (Art. 16 GDPR): You can manually correct or change all profile data, workouts, nutrition logs, body weights, and settings you have entered directly in the app's user interfaces at any time.
- Right to Erasure / "Right to be Forgotten" (Art. 17 GDPR): You can manually delete individual records (e.g., a specific workout or a food log) in the app.
- Irrevocable Data Deletion (AppData Reset): The app features a built-in deletion function for all local application data. In the settings, you can execute the function for complete data deletion. This process irrevocably deletes:
◦ All SharedPreferences settings and app states.
◦ All recorded training logs, custom exercises, and routines.
◦ All nutrition logs, meal templates, and custom food items.
◦ All entered body measurements, supplement logs, and historical daily goals.
◦ All locally cached heart rate and sleep analysis stages.
◦ All API keys for AI providers stored in the secure operating system repository.

After executing this function, the app is returned to its factory state. Please note that data already exported to Apple Health or Google Health Connect cannot be deleted by this internal app function, as these are under the control of the operating system. However, you can delete this exported data at any time directly in the native Health apps from Apple or Google.
- Telemetry Data Rights: If you have opted in to anonymous telemetry, you may exercise your rights (access, erasure, objection) regarding the processed telemetry data by contacting the controller at feedback@schotte.me. Upon request, all your telemetry events will be deleted from PostHog's servers.
- Right to Lodge a Complaint with a Supervisory Authority (Art. 77 GDPR): Without prejudice to the app's internal control options, you have the right to lodge a complaint with a competent data protection supervisory authority. This can be, for example, the supervisory authority of your habitual residence, place of work, or the place of the controller's establishment (e.g., the Berlin Commissioner for Data Protection and Freedom of Information).
''',
    ),
  ],
  termsOfServiceSections: [
    _LegalSection(title: '1. No Medical Advice', content: '''
All health-related estimations, bodyweight targets, macronutrient targets, Total Daily Energy Expenditure (TDEE) calculations, muscle recovery scores, and other health-related approximations provided by Train Libre are statistical estimates based on general population mathematical models (such as Mifflin-St Jeor and Katch-McArdle). They do not constitute medical, nutritional, or athletic advice and must never replace consultation with a qualified professional or physician. Use of these features is strictly at your own risk.
'''),
    _LegalSection(title: '2. As-Is Warranty Disclaimer', content: '''
Train Libre is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement. The developer is not liable for any data loss, device anomalies, interrupted functionality, or any direct, indirect, incidental, or consequential damages arising from the use of the compiled binary application or the source code.
'''),
    _LegalSection(title: '3. Data Autonomy', content: '''
All user-generated data, profile parameters, workout logs, nutrition history, and local database records (Drift/SQLite) reside exclusively within your local device's sandbox. The developer has no remote access to this data, does not operate any backend servers to collect it, and bears no responsibility for data recovery, backup, migration, or loss. You are solely responsible for securing your device and managing your manual or automatic data exports.
'''),
    _LegalSection(title: '4. Open Source Governing', content: '''
The source code for Train Libre is distributed under the GNU General Public License v3.0 (GPL-3.0) as published in the project's repository. These Terms of Service govern the use of the compiled binary application only and do not restrict, override, or limit any rights granted to you by the GPL-3.0, including the right to access, modify, and redistribute the source code under the same license terms.
'''),
  ],
);
