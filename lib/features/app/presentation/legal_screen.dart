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
const String kCurrentLegalVersion = '1.8';

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
        .trackScreenView(screenName: ScreenName.legalPrivacy));
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
      onPressed: () => _handleLink('https://trainlibre.com/privacy.html'),
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

class _LegalAccordionState extends State<_LegalAccordion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotateAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _rotateAnimation =
        Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation);
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

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
              onTap: _toggle,
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
                    RotationTransition(
                      turns: _rotateAnimation,
                      child: Icon(
                        LucideIcons.chevron_down,
                        color: theme.colorScheme.primary,
                        size: DesignConstants.iconSizeL,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizeTransition(
              axis: Axis.vertical,
              alignment: Alignment.topCenter,
              sizeFactor: _expandAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignConstants.spacingL,
                    0,
                    DesignConstants.spacingL,
                    DesignConstants.spacingL,
                  ),
                  child: _LegalText(data: widget.section.content),
                ),
              ),
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
  version: '1.8',
  date: '8. Oktober 2026',
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
- Local-First-Architektur: Profil-, Trainings-, Ernährungs-, Gesundheits- und Messdaten werden grundsätzlich lokal auf Ihrem Gerät gespeichert. Optionale Funktionen können Daten wie nachfolgend beschrieben übertragen oder Kopien außerhalb des Geräts erstellen.
- Kein zentraler Backend-Server: Wir betreiben keine zentrale Cloud-Datenbank zur Speicherung Ihrer Trainings- und Ernährungsprotokolle. Optionale Dienste und Backups können jedoch Datenkopien erhalten oder speichern.
- Keine Werbung: Train Libre verwendet keine Werbenetzwerke und keine verhaltensbasierte Werbung. Optionale Nutzungsstatistiken sind standardmäßig deaktiviert. Wenn sie aktiviert sind, können Ereignisse technische Kennungen und Messwerte enthalten, darunter Zähler oder Kennzahlen aus Ernährungs- und Gewichtsbereichen. Solche Daten können auch ohne Ihren Namen personenbezogen oder gesundheitsbezogen sein. Einzelheiten stehen unter Ziffer 6 C.
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

Die Rechtsgrundlage hängt von der jeweiligen Funktion und dem Verarbeitungszweck ab. Für bestimmte Verarbeitungen stützt sich Train Libre auf Ihre Einwilligung; sie kann für die Zukunft widerrufen werden. Das Löschen einzelner Einträge oder das Zurücksetzen der App ist nicht automatisch ein Widerruf und macht bereits erfolgte Verarbeitung nicht rückgängig. Details zu optionalen Übermittlungen stehen in den jeweiligen Abschnitten dieser Erklärung. Die konkrete rechtliche Bewertung sollte anhand der tatsächlichen Konfiguration geprüft werden. Soweit die App im Rahmen der DSGVO betrachtet wird, können folgende Rechtsgrundlagen gelten:

- Allgemeine Daten und Einstellungen (Art. 6 Abs. 1 lit. b DSGVO): Die Verarbeitung allgemeiner Profileinstellungen, Trainingspläne und App-Präferenzen kann zur Bereitstellung der App-Funktionalitäten erforderlich sein.
- Gesundheitsdaten (Art. 9 Abs. 2 lit. a DSGVO in Verbindung mit Art. 6 Abs. 1 lit. a DSGVO): Für bestimmte Verarbeitungen gesundheitsbezogener Daten kann eine ausdrückliche Einwilligung erforderlich sein. Das bloße Eingeben eines Datensatzes oder Aktivieren eines Imports ist nicht automatisch eine Einwilligung für alle weiteren Zwecke, etwa eine spätere KI-Übermittlung. Wenn die Verarbeitung auf einer Einwilligung beruht, können Sie diese für die Zukunft widerrufen. Das Löschen von Einträgen oder das Zurücksetzen der App ist nicht automatisch ein Widerruf und macht bereits erfolgte Verarbeitung nicht rückgängig. Wenden Sie sich für Unterstützung an feedback@schotte.me.
''',
    ),
    _LegalSection(
      title: '4. Drittanbieter-Integrationen / BYOK',
      content:
          '''Optionale Funktionen können Daten an externe Dienste oder einen von Ihnen konfigurierten Endpunkt übertragen. Die Datenverarbeitung des jeweiligen Dienstes richtet sich nach dessen geltenden Bedingungen und Einstellungen.

A. KI: Chat, Mahlzeitenerkennung und Entwürfe

Train Libre bietet optionale KI-Funktionen für Chat, Mahlzeitenerkennung und Entwürfe wie Routinen, Trainingspläne und Rezepte. Schätzungen und Vorschläge können unvollständig oder falsch sein.

Ihre Nachricht. Wenn Sie eine Chatnachricht absenden, werden der von Ihnen eingegebene oder diktierte Text und angehängte Bilder an das Modell bzw. den Anbieter gesendet, der für diese Anfrage verwendet wird. Dies geschieht vor einer separaten Anfrage zum Lesen gespeicherter App-Daten. Die Nachricht oder ein Bild kann selbst personenbezogene oder Gesundheitsdaten enthalten. Die Anfrage kann begrenzten Gesprächskontext, Anweisungen, Modellangaben und frühere Inhalte enthalten. Nicht jede Anfrage enthält gespeicherte App-Daten; das Absenden einer Nachricht ist von der Freigabe solcher Daten zu unterscheiden. Diktierfunktionen können je nach Gerät und Einstellungen einen Spracherkennungsdienst verwenden. Die optionale Bereinigung von Mahlzeiten-Transkripten kann Text vor dem Absenden zur Verarbeitung übertragen.

Gespeicherte App-Daten. Der Assistent kann etwa Workouts, Ernährungstagebuch, Schritte, Schlaf, Erholung, Messwerte, Ziele, Profil, Supplemente, Rezepte, Übungen, Routinen und Trainingspläne anfragen. Frische Lesezugriffe sind grundsätzlich durch eine Freigabeanfrage geschützt. Auto-Freigabe ist standardmäßig aus; wenn sie aktiviert ist, können spätere Anfragen ohne erneute Entscheidung freigegeben werden. Eine Anfrage nennt Kategorien und Zeitraum, zeigt aber nicht zwingend jeden übermittelten Einzelwert. Ergebnisse lokaler Abfragen und zugehörige Werkzeugaufrufe können an das Modell gesendet werden. Das Ausschalten der Auto-Freigabe ruft bereits übermittelte Daten nicht zurück und stoppt nicht zwingend laufende Vorgänge.

Empfänger. Die Freigabe ist nicht an einen bestimmten Anbieter gebunden. Bei Textchat kann die App bei fehlender Verfügbarkeit oder Zugangsdaten auf einen anderen konfigurierten Anbieter ausweichen und den Anbieter nach der Freigabe erneut bestimmen. Dadurch kann ein anderer Empfänger verwendet werden. Die Datenfreigabekarte selbst nennt den Empfänger nicht. Unterstützt werden unter anderem Apple Foundation Models auf kompatiblen Geräten, OpenAI, Google, Anthropic, Mistral, xAI, DeepSeek, Ollama und eigene OpenAI-kompatible Endpunkte. Eigene Endpunkte können lokal oder remote betrieben werden und Daten weiterleiten. Train Libre kann Speicherung, menschliche Prüfung, Training, Weitergabe, Löschung und Verarbeitungsorte externer Anbieter nicht verifizieren. Prüfen Sie die Bedingungen des jeweiligen API-Angebots oder Serverbetreibers.

Verlauf und Löschung. Nachrichten, Antworten, Fehler, Anbieter- und Modellangaben, Freigabeinformationen sowie Verweise auf Anhänge können lokal gespeichert sein; Anhänge können als Dateien vorliegen. Das Löschen eines Chats versucht, Anhänge zu entfernen. Das Zurücksetzen löscht viele App-Daten und Anbieterschlüssel, garantiert aber nicht die Entfernung jeder Datei, jedes Caches oder jeder Konfiguration. Backups, Exporte, Health-Plattformen und bereits an Anbieter übermittelte Daten sind davon getrennt. Das Löschen des lokalen Verlaufs fordert keine Löschung beim KI-Anbieter an.

B. Offline-Katalog-Updates (Open Food Facts & Exercise Catalog)

Um Lebensmittel-Barcodes offline scannen und Übungen nachschlagen zu können, nutzt Train Libre lokale Produkt- und Übungskataloge. Diese Kataloge werden als vorkompilierte SQLite-Datenbankdateien direkt auf Ihr Gerät heruntergeladen.

* Funktionsweise: Die App prüft in regelmäßigen Abständen, ob Aktualisierungen für den Lebensmittelkatalog (basierend auf Open Food Facts) oder den Übungskatalog (basierend auf wger/GitHub) vorliegen. Die Prüfung und der anschließende Download der komprimierten Katalogdatenbanken erfolgen über eine verschlüsselte HTTPS-Verbindung direkt zu den Servern des Hosting-Dienstleisters (z. B. GitHub Pages / GitHub Inc. bzw. Open Food Facts).
* BLS-Katalog: Zusätzlich wird der Basis-Lebensmittelkatalog BLS 4.0 des Max Rubner-Instituts über GitHub geladen; er enthält Zutaten und Nährstoffwerte und wird lokal gespeichert.
* Datenminimierung: Beim Herunterladen der Katalog-Updates werden systembedingt technische Verbindungsdaten (insbesondere Ihre IP-Adresse, Datum/Uhrzeit des Zugriffs und der User-Agent der App) an den Hoster übertragen. Es werden zu keinem Zeitpunkt nutzergenerierte Daten, gescannte Barcodes oder persönliche Profileigenschaften an die Katalog-Hoster gesendet.
* Lokale Barcode-Zuordnung: Der Abgleich eines gescannten Barcodes oder die Suche nach Lebensmitteln und Übungen findet zu 100 Prozent offline auf Ihrem Gerät statt. Im Gegensatz zu herkömmlichen Ernährungs-Apps wird beim Scannen eines Produkts keine Anfrage mit dem Barcode an einen Cloud-Server gesendet.

---''',
    ),
    _LegalSection(
      title: '5. Gesundheitsdaten-Schnittstellen',
      content:
          '''Train Libre kann Apple HealthKit oder Google Health Connect nutzen, wenn Sie die Funktionen aktivieren und die Plattformberechtigungen erteilen. Sie können diese Berechtigungen in den Systemeinstellungen ändern. Importierte Daten werden in der App gespeichert und ausgewertet und können in Backups oder – nach den Freigaberegeln in Abschnitt 4 – in KI-Anfragen einfließen. Das Ändern der Plattformberechtigung löscht zuvor importierte oder exportierte Daten nicht automatisch. Die Freigabe für KI-Datenzugriffe ist unabhängig von der Health-Plattformberechtigung.''',
    ),
    _LegalSection(
      title: '6. Datensicherheit & Backups',
      content:
          '''Die Sicherheit Ihres Geräts ist wichtig, um lokale Daten und Zugangsdaten zu schützen.

A. Lokale Datenisolation

Das Betriebssystem (iOS/Android) isoliert die App-Daten von Train Libre durch Sandbox-Mechanismen. Andere installierte Applikationen haben ohne Ihre Zustimmung keinen Zugriff auf die lokale SQLite-Datenbank oder die in den gesicherten App-Einstellungen hinterlegten API-Schlüssel.

B. Manuelle und automatische Backups

Sie können Sicherungen oder Exporte erstellen und automatische Sicherungen an einem ausgewählten Speicherort aktivieren. Je nach Funktion können Datenbankeinträge, Einstellungen, KI-Verlauf und Medien enthalten sein. Ein passwortgeschützter Export ist verfügbar; schützen Sie Passwörter und unverschlüsselte Kopien. Der ausgewählte Speicherort oder das Betriebssystem kann Kopien in einem Cloud-Dienst speichern. Die optionale iCloud-Synchronisierung kann nach ihrer Aktivierung einen Datenbank-Snapshot und Medien hochladen. Prüfen Sie die Einstellungen und Datenschutzpraktiken des Speicheranbieters. Das Zurücksetzen der App löscht separat gespeicherte Backups, Exporte, Health-Plattform-Daten oder Anbieterkopien nicht. Temporäre Dateien und fehlgeschlagene Bereinigungen können weitere Kopien hinterlassen; eine sofortige vollständige Löschung kann nicht zugesichert werden.

C. Optionale Nutzungsstatistik

Nutzungsstatistiken sind standardmäßig deaktiviert. Bei Aktivierung verwendet die App den PostHog-EU-Eingang für pseudonyme Ereignisse. Diese können technische Kennungen, App- und Gerätekontext, Bildschirm- und Funktionsnutzung, genaue Trainingszähler und -dauer, Ernährungseintragszähler, den Status von KI-Anfragen sowie Kennzahlen aus Ernährungs- oder Gewichtsbereichen enthalten. Auch ohne Namen können solche Ereignisse personenbezogen oder gesundheitsbezogen sein. Die App konfiguriert IP- und Standortverarbeitungsoptionen; die tatsächliche Netzwerk- und Serververarbeitung hängt auch von der Dienstkonfiguration ab.

Sie können künftige Telemetrie in den Einstellungen ausschalten. Die Löschfunktion setzt lokale Kennungen und Zähler zurück und versucht, eine Löschanfrage zu senden; sie bestätigt keine serverseitige Löschung und erfasst möglicherweise nicht frühere Kennungen oder Sicherungskopien. Kontaktieren Sie feedback@schotte.me, wenn Sie Hilfe benötigen. Diagnoseberichte können außerdem über von Ihnen gewählte Wege geteilt werden; eine direkte Übermittlung an PostHog setzt aktivierte Telemetrie voraus. Prüfen Sie Inhalt und Empfänger vor dem Teilen. Angaben zu Aufbewahrung, Auftragsverarbeitung, Speicherorten und Drittlandtransfers müssen anhand der aktuellen Dienstkonfiguration und Vereinbarungen bestätigt werden.''',
    ),
    _LegalSection(
      title: '7. Betroffenenrechte',
      content:
          '''Je nach anwendbarem Recht können Sie Rechte auf Auskunft, Berichtigung, Löschung, Datenübertragbarkeit, Einschränkung oder Widerspruch sowie den Widerruf einer Einwilligung haben. Ein Widerruf macht bereits erfolgte Verarbeitung nicht rückgängig. Sie können sich außerdem bei einer zuständigen Aufsichtsbehörde beschweren. Wenden Sie sich mit einem Anliegen an feedback@schotte.me.

Viele Datensätze können Sie in der App bearbeiten oder löschen und Daten exportieren. Das lokale Zurücksetzen entfernt viele App-Daten, Einstellungen und Anbieterschlüssel, garantiert aber nicht die Entfernung jedes Anhangs, Caches oder jeder Konfiguration. Es löscht keine Kopien in Backups, Exporten, Apple Health, Health Connect oder externen KI-Diensten. Verwalten Sie diese Kopien gesondert und wenden Sie sich gegebenenfalls an den jeweiligen Anbieter. Die Telemetrie-Löschfunktion versucht eine Anfrage, bestätigt aber keine entfernte Löschung.''',
    ),
  ],
  termsOfServiceSections: [
    _LegalSection(title: '1. Keine medizinische Beratung', content: '''
Train Libre stellt Fitness- und Ernährungsinformationen bereit, darunter modellbasierte Schätzungen sowie optionale KI-Antworten, Mahlzeitenschätzungen und Entwürfe. Diese können unvollständig, ungenau oder für Sie ungeeignet sein. Sie sind keine medizinische, ernährungsbezogene oder professionelle Trainingsberatung und ersetzen keine qualifizierte Fachkraft. Prüfen Sie Zutaten, Allergene, Portionsgrößen, Nährwerte und Übungsanleitungen, bevor Sie sich darauf verlassen, und entscheiden Sie eigenverantwortlich.
'''),
    _LegalSection(
        title: '2. Haftungsausschluss / As-Is-Gewährleistung', content: '''
Train Libre wird im Ist-Zustand („as is“) ohne jegliche ausdrückliche oder stillschweigende Gewährleistung zur Verfügung gestellt, einschließlich, aber nicht beschränkt auf die Gewährleistung der Marktgängigkeit, der Eignung für einen bestimmten Zweck und der Nichtverletzung von Rechten Dritter. Der Entwickler haftet nicht für Datenverluste, Geräteanomalien, unterbrochene Funktionalität oder direkte, indirekte, zufällige oder Folgeschäden, die aus der Nutzung der kompilierten ausführbaren Anwendung (Binary) oder des Quellcodes entstehen.
'''),
    _LegalSection(title: '3. Datenautonomie', content: '''
Ihre Einträge werden hauptsächlich auf Ihrem Gerät gespeichert. Optionale KI-Dienste, Gesundheitsintegrationen, Telemetrie, Backups, Exporte und Freigaben können Informationen außerhalb der App übertragen oder Kopien erzeugen. Der KI-Chat kann Entwürfe für Mahlzeiten, Routinen, Pläne und Rezepte vorbereiten; der Vorschlagsablauf verlangt eine Bestätigung, bevor ein Entwurf übernommen wird, und die Mahlzeitenerfassung enthält einen Prüf- und Speicherschritt. Prüfen Sie Vorschläge, bevor Sie sie speichern oder anwenden. Externe Dienste haben eigene Bedingungen und Praktiken. Schützen Sie Ihr Gerät, Zugangsdaten und exportierte Kopien und prüfen Sie, ob ein Dienst für die von Ihnen freigegebenen Informationen geeignet ist.
'''),
    _LegalSection(title: '4. Open-Source-Regelung', content: '''
Der Quellcode von Train Libre wird unter der GNU General Public License v3.0 (GPL-3.0) verbreitet, wie im Repository des Projekts veröffentlicht. Diese Nutzungsbedingungen regeln ausschließlich die Nutzung der kompilierten ausführbaren Anwendung (Binary) und schränken keine Rechte ein, die Ihnen durch die GPL-3.0 gewährt werden, einschließlich des Rechts auf Zugriff, Änderung und Weiterverbreitung des Quellcodes unter denselben Lizenzbedingungen.
'''),
  ],
);

const _englishLegalDocument = _LegalDocument(
  version: '1.8',
  date: 'October 8, 2026',
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

Train Libre is designed as a local-first application; optional features can transmit data or create copies outside your device. We do not operate any central database or application servers to store your profiles, workouts, or nutrition logs.

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
- Local-First Architecture: Profile settings, activities, nutrition data, vital signs, and measurements are primarily stored in a local database on your device. Optional features can transmit or copy data as described below.
- No Central Backend Server: We do not operate any cloud databases or application servers to store or process your training and nutrition data. Optional services and backups can receive or store copies.
- No Advertising: Train Libre does not use advertising networks or behaviour-based advertising. Optional usage statistics are disabled by default. When enabled, events may include technical identifiers and measurements such as counts or indicators derived from nutrition and weight-related features; these can be personal or health-related even without your name. See section 6 C.
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

Core app storage is generally local to your device, while optional services can transmit or store copies as described in this policy. The legal basis depends on the purpose and context of each processing activity. Insofar as the app is considered within the scope of the GDPR, the following legal bases may apply:

- General Data and Settings (Article 6(1)(b) of the GDPR): The processing of general profile settings, training plans, and app preferences is carried out to fulfill the user relationship (provision of app functionalities).
- Health Data (Article 9(2)(a) of the GDPR in conjunction with Article 6(1)(a) of the GDPR): Some processing of health-related data may rely on your explicit consent. Entering a record or enabling an import is not, by itself, consent to every later purpose, such as transmission in an AI request. Where processing relies on consent, you may withdraw it for the future by contacting feedback@schotte.me or using the relevant platform permission controls. Deleting records or resetting the app does not automatically withdraw consent and does not undo processing that has already taken place.
''',
    ),
    _LegalSection(
      title: '4. Third-Party Integrations / BYOK',
      content: '''

To provide advanced features, the app has interfaces to external services. These functions are optional and require your active participation.

A. Artificial Intelligence: Chat, Meal Recognition and Drafts

Train Libre offers optional AI chat and meal recognition. The assistant can answer questions and prepare drafts such as meals, routines, training plans and recipes. Meal recognition can estimate portions and nutrition directly, or match suggested foods against a local catalog. Estimates and suggestions can be wrong and require your judgment.

Your submitted content. When you send a chat message, the text you type or dictate and the images you attach are sent to the model selected for the request. This happens before the separate request to read stored app records. Your message or image can itself contain personal or health information. The request can include system instructions, relevant documentation, the model identifier, limited earlier conversation context and images from the conversation. Follow-up context can include an earlier user question, categories and dates previously requested, or the name of a pending draft. An earlier data-backed answer is withheld until fresh overlapping access is approved and the provider matches. Not every request contains stored records, and entering a message is different from granting access to those records.

Dictation uses the device's speech-recognition service, which may use a network service depending on the device and settings. In meal dictation, an optional AI transcript-cleanup feature can send the transcript for processing before the meal is submitted; it can be disabled. Meal analysis sends the submitted description or photos, together with instructions and context needed for the analysis, to the model used for that feature.

Access to existing app records. The assistant can request categories including workouts, diary and nutrition, steps, sleep, recovery, measurements, goals, profile and daily targets, supplements, recipes, exercise catalog, routines and training plans. A request identifies categories and a period or current snapshot. Fresh reads of those records are gated by approval of the request; the app may request further categories separately. The assistant can query an approved local snapshot and send query results and related tool exchanges to the model. Approval does not mean that every record in a category is necessarily sent. The request card describes categories and period; it is not a complete preview of each value sent.

Automatic approval of data requests is off by default. If you enable it in the assistant, later requests, including additional categories, can be approved without a separate decision each time. Turn it off in the assistant to return to individual requests. Turning it off does not recall data already sent or necessarily stop work already in progress. Earlier conversation context, draft metadata, responses, retries and tool exchanges can still contain information from prior interactions.

Recipient and configuration. AI settings show the configured provider and model, and the assistant can display model information. The data-access card does not itself identify the recipient. Approval is not bound to a specific recipient: for text chat, the app can fall back to another configured provider when the selected one is unavailable or lacks credentials, and it resolves the provider again after approval. Changing configuration can therefore result in a different recipient. Image-bearing chat uses a separate selected-provider check instead of that implicit credential fallback. Requests may also retry with another model at the same provider.

Supported configurations include Apple Foundation Models on compatible devices, OpenAI, Google Gemini, Anthropic, Mistral, xAI, DeepSeek, Ollama and custom OpenAI-compatible endpoints. Apple Foundation Models are intended for on-device processing. Ollama normally connects to a local service; a custom endpoint may be local or remote and may forward data elsewhere. A local or self-hosted server is controlled by its operator, not verified by Train Libre. Network protection depends on the endpoint; a local HTTP connection is possible. API keys and AI configuration are stored using platform secure-storage facilities; credentials are used to authenticate with the configured service.

Train Libre cannot verify an external provider's or server operator's retention, human review, training, onward transfers or deletion practices. Review the applicable API terms and account settings before sending sensitive information. Provider and hosting locations, international transfers and safeguards depend on the service and configuration; do not assume a particular transfer mechanism applies. Train Libre does not operate a central service to receive these AI requests: the app communicates with the selected service or endpoint, or invokes the on-device model.

History and deletion. Chat messages, responses, errors, provider and model identifiers, access records and attachment references are stored locally; attachments can also be stored as files. Deleting a conversation attempts to remove its attachments. Local reset removes many records and provider keys, but does not establish that every attachment, cache or configuration item has been removed. Backups, exports, health-platform copies and information already sent to a provider are separate. Deleting local history does not request deletion from an AI provider. Contact the provider or server operator about its copies.

B. Offline Catalog Updates (Open Food Facts & Exercise Catalog)

To scan food barcodes offline and look up exercises, Train Libre uses local product and exercise catalogs. These catalogs are downloaded directly to your device as precompiled SQLite database files.

* How it Works: The app checks at regular intervals whether updates are available for the food catalog (based on Open Food Facts) or the exercise catalog (based on wger/GitHub). The check and subsequent download of the compressed catalog databases are performed via an encrypted HTTPS connection directly to the servers of the hosting service provider (e.g., GitHub Pages / GitHub Inc. or Open Food Facts).
* BLS catalog: The BLS 4.0 base-food catalog from the Max Rubner-Institut is also downloaded from GitHub; it contains ingredients and nutrient values and is stored locally.
* Data Minimization: When downloading catalog updates, technical connection data (in particular your IP address, date/time of access, and the app's User-Agent) are transmitted to the host as a system requirement. No user-generated data, scanned barcodes, or personal profile characteristics are sent to the catalog hosts at any time.
* Local Barcode Mapping: The matching of a scanned barcode or the search for food and exercises takes place 100 percent offline on your device. Unlike conventional nutrition apps, scanning a product does not send a request with the barcode to a cloud server.
''',
    ),
    _LegalSection(
      title: '5. Health Data Interfaces',
      content: '''

Train Libre can interact with Apple HealthKit or Google Health Connect when you enable the relevant features and grant the platform permissions. You can change these permissions in system settings. Imported data is stored and analyzed in the app, and may also be included in backups or in an AI request under the access rules in section 4. Changing system permissions does not automatically delete previously imported or exported records. App-data access approval for the assistant is separate from health-platform permission.

A. Data Import (Reading)

If you grant permission to the app, Train Libre reads data from Apple HealthKit or Google Health Connect to display and process it locally within the app:
* Body Measurements: Import of weight, body-fat percentage, and waist circumference (from smart scales or external tracking apps) for accurate tracking trends and adaptive TDEE calibration.
* Step Counts: Import of recorded step count segments for offline evaluation.
* Sleep Data: Import of sleep intervals and sleep phases.
* Heart Rate: Import of heart rate samples to calculate local hourly aggregations.

Imported data may also be included in backups or shared through optional AI features as described above.

B. Data Export (Writing & Idempotency)

At your request, Train Libre can export data manually recorded in the app to the system health databases (Apple HealthKit / Google Health Connect):
* Body Dimensions: Export of weight measurements.
* Nutrition and Hydration: Export of consumed nutritional values, calories, and water amounts.
* Workouts: Export of completed training sessions.

* Local Idempotency Protection: To prevent duplicate data from being written to your system health database during repeated synchronizations, Train Libre features a local logging system. In the health_export_records table of the local SQLite database, a unique ID, the target platform (Apple Health or Health Connect), the data domain, and a unique idempotency key are stored together with the export timestamp for every successful write operation. This comparison takes place purely locally on your device and serves to ensure data consistency.
''',
    ),
    _LegalSection(
      title: '6. Data Security & Backups',
      content: '''

Device security is important to protecting your local data and credentials.

A. Local Data Isolation

The operating system (iOS/Android) isolates Train Libre's app data using sandbox mechanisms. Other installed applications do not have access to the local SQLite database or the API keys stored in the secured app settings without your consent.

B. Manual and Automatic Backups

You can create and share backups or exports, and can enable automatic backups to a selected location. Depending on the option, backups can include database records, settings, AI history and media. Password-encrypted export is available; protect passwords and unencrypted copies. The selected location or operating system may store a copy in a cloud service. Optional iCloud sync can upload a database snapshot and media after it is enabled in the app. Review the settings and practices of the storage provider. Resetting the app does not remove separately stored backups, exports, health-platform data or provider copies. Temporary files and failed cleanup may leave additional copies; do not assume every copy is erased immediately.

C. Optional Pseudonymised Usage Statistics

Usage statistics are disabled by default. When enabled, the app uses the PostHog EU ingestion endpoint for pseudonymous events. Events can include technical identifiers, app and device context, screen and feature use, exact workout counts and duration, food-entry counts, AI request status, and indicators derived from nutrition or weight-related features. These events can be personal or health-related even without your name. The app configures IP and geographic-processing controls, but network and server handling depend on the service configuration.

You can turn off future telemetry in Settings. The deletion control resets local identifiers and counters and attempts a deletion request; it does not confirm server-side deletion, and historical identifiers or backups may not be covered. Contact feedback@schotte.me for help. A diagnostic report can also be shared by methods you choose; direct PostHog submission requires telemetry to be enabled. Review the report and its destination before sharing. Details of retention, processor arrangements, locations and international-transfer safeguards require confirmation with the service operator and applicable agreements.
''',
    ),
    _LegalSection(
      title: '7. Data Subject Rights',
      content: '''

Depending on applicable law, you may have rights of access, rectification, erasure, portability, restriction or objection, and the right to withdraw consent where processing is based on consent. Withdrawal does not undo processing that has already occurred. You may also complain to a competent supervisory authority. Contact feedback@schotte.me with a request.

You can edit or delete many records in the app and export data. The local reset removes many app records, settings and provider keys, but does not guarantee removal of every attachment, cache or configuration item. It does not remove copies in backups, exports, Apple Health, Health Connect or external AI services. Manage those copies separately and contact the provider where appropriate. The telemetry deletion action attempts a request; it does not confirm remote deletion.
''',
    ),
  ],
  termsOfServiceSections: [
    _LegalSection(title: '1. No Medical Advice', content: '''
Train Libre provides fitness and nutrition information, including model-based estimates and optional AI responses, meal estimates and drafts. These may be incomplete, inaccurate or unsuitable for you. They are not medical, nutritional or professional training advice and do not replace a qualified professional. Check ingredients, allergens, portions, nutrition values and exercise instructions before relying on them, and use your own judgment.
'''),
    _LegalSection(title: '2. As-Is Warranty Disclaimer', content: '''
Train Libre is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement. The developer is not liable for any data loss, device anomalies, interrupted functionality, or any direct, indirect, incidental, or consequential damages arising from the use of the compiled binary application or the source code.
'''),
    _LegalSection(title: '3. Data Autonomy', content: '''
Your records are primarily stored on your device. Optional AI services, health integrations, telemetry, backups, exports and sharing can transmit information or create copies outside the app. AI chat can prepare drafts of meals, routines, plans and recipes; the observed proposal flow asks for confirmation before applying a draft, and meal capture provides a review and save step. Check a suggestion before choosing to save or apply it. External services have their own terms and practices. Protect your device, credentials and exported copies, and check whether a service is appropriate for the information you choose to share.
'''),
    _LegalSection(title: '4. Open Source Governing', content: '''
The source code for Train Libre is distributed under the GNU General Public License v3.0 (GPL-3.0) as published in the project's repository. These Terms of Service govern the use of the compiled binary application only and do not restrict, override, or limit any rights granted to you by the GPL-3.0, including the right to access, modify, and redistribute the source code under the same license terms.
'''),
  ],
);
