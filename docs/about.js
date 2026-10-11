(() => {
  const copy = {
    en: {
      pageTitle: "About Train Libre | The story behind the app",
      pageDescription: "Why I started Train Libre, what I want it to be, and how I build and test it.",
      backHome: "Back to home", eyebrow: "The person behind the project", title: "A training app shaped by real use.",
      story1: "I started Train Libre because I wanted to build a real software project and because I wanted a better way to follow my own training. I enjoy going to the gym and want to make progress, but the apps I tried did not show me the metrics I cared about. I did not want to pay for a pile of features I would never use, or turn a training log into another social platform. I wanted to log a workout quickly, see the numbers that matter to me, and export my data whenever I choose.",
      story2: "I want Train Libre to stay a tool. No ads, no gamification, no social feed, and no server I have to run to use my own data. I decide what the app should solve, which features matter, and how the screens and everyday workflows should feel. I work with AI coding agents in natural language, explain what I want to achieve, and think through the options with them. They write most of the code. I rarely write code myself, but the product decisions, priorities, and final call on whether something works are mine.",
      story3: "I study Computer Science at TU Berlin. Data analysis and the structured way software projects are developed have influenced how I think about features and how to decide whether they are finished. I also bring my own experience with training and nutrition. Before I test a change myself, I run automated tests to make sure new work does not break existing features. Then I try it in the simulator with different test data, install it on my own device, and listen to feedback from friends who use the latest beta.",
      creatorLabel: "Created by", creatorMeta: "Computer Science student at TU Berlin", github: "View my GitHub profile",
      timelineEyebrow: "Release history", timelineTitle: "The app, release by release.", timelineLead: "The releases that brought meaningful changes to how Train Libre works for you.", allReleases: "Explore all releases", footer: "An independent project for people who want a focused training log and control over their data."
    },
    de: {
      pageTitle: "Über Train Libre | Die Geschichte hinter der App",
      pageDescription: "Warum ich Train Libre angefangen habe, was mir dabei wichtig ist und wie ich die App entwickle und teste.",
      backHome: "Zur Startseite", eyebrow: "Die Person hinter dem Projekt", title: "Eine Trainings-App aus der Praxis.",
      story1: "Angefangen habe ich Train Libre, weil ich ein richtiges Softwareprojekt umsetzen und mein eigenes Training besser verfolgen wollte. Ich gehe gern ins Gym und möchte Fortschritte machen. Dafür brauche ich bestimmte Kennzahlen, die ich in den Apps, die ich ausprobiert hatte, nicht gefunden habe. Ich wollte nicht für einen Haufen Funktionen bezahlen, die ich gar nicht brauche. Und ich hatte keine Lust auf Werbung, Gamification oder einen Social-Media-Feed. Ich wollte mein Workout schnell eintragen, die Zahlen sehen, die mich interessieren, und meine Daten jederzeit exportieren können.",
      story2: "Train Libre soll ein Werkzeug bleiben. Ohne Werbung, ohne Gamification, ohne Social-Media-Feed und ohne einen Server, den ich selbst betreiben muss, um meine Daten zu nutzen. Ich lege fest, welches Problem die App lösen soll, welche Funktionen Vorrang haben und wie sich die Bedienung anfühlen muss. Beim Programmieren arbeite ich mit KI-Agenten zusammen. Ich beschreibe in natürlicher Sprache, was ich erreichen will, und denke die Lösungswege mit ihnen durch. Sie schreiben den Großteil des Codes. Ich selbst schreibe nur selten Code. Die Produktentscheidungen, Prioritäten und die Verantwortung für das Ergebnis liegen trotzdem bei mir.",
      story3: "Ich studiere Informatik an der TU Berlin. Besonders Datenanalyse und das strukturierte Vorgehen in der Softwareentwicklung beeinflussen, wie ich Funktionen plane und ihre Abnahmekriterien festlege. Dazu kommt meine eigene Erfahrung mit Training und Ernährung. Bevor ich selbst eine Änderung teste, lasse ich automatisierte Tests laufen, damit neue Funktionen bestehendes Verhalten nicht beeinträchtigen. Danach prüfe ich sie im Simulator mit unterschiedlichen Testdaten, installiere sie auf meinem eigenen Gerät und hole Feedback von Freunden ein, die die aktuelle Beta testen.",
      creatorLabel: "Entwickler von Train Libre", creatorMeta: "Informatikstudent an der TU Berlin", github: "Mein GitHub-Profil ansehen",
      timelineEyebrow: "Release-Geschichte", timelineTitle: "Die App, Release für Release.", timelineLead: "Diese Veröffentlichungen haben spürbar verändert, was Train Libre für dich kann.", allReleases: "Alle Releases ansehen", footer: "Ein unabhängiges Projekt für alle, die Training fokussiert erfassen und die Kontrolle über ihre Daten behalten möchten."
    }
  };
  const releases = [
    ["0.1.0", "2025-09-23", "A solid starting point for everyday tracking", "Log workouts, food, and body measurements. Keep an eye on consistency and protect your records with encrypted backups.", "Der Einstieg ins tägliche Tracking", "Workouts, Essen und Körpermaße erfassen, die eigene Regelmäßigkeit im Blick behalten und Daten verschlüsselt sichern."],
    ["0.2.0", "2025-09-24", "More confidence during a workout", "Your active session now survives closing the app, and each set can show what you did the last time.", "Mehr Sicherheit beim Training", "Ein laufendes Workout bleibt nach dem Schließen der App erhalten. Zu jedem Satz siehst du auf Wunsch deine letzte Leistung."],
    ["0.3.0+2", "2025-09-26", "Get back to the workout you were doing", "Fixed workout restoration and navigation so an interrupted session is easier to pick up again.", "Zurück ins laufende Workout", "Verbesserte Wiederherstellung und Navigation, damit du ein unterbrochenes Training leichter fortsetzen kannst."],
    ["0.4.0", "2025-12-03", "Meals and drinks in the same diary", "Group foods into meals, track water and caffeine, and move through a redesigned interface.", "Mahlzeiten und Getränke im selben Tagebuch", "Lebensmittel zu Mahlzeiten gruppieren, Wasser und Koffein erfassen und eine neu gestaltete Oberfläche nutzen."],
    ["0.5.0", "2026-03-03", "Cardio joins strength training", "A rebuilt setup flow and support for cardio exercises make the app work for more kinds of training.", "Cardio ergänzt Krafttraining", "Eine neue Einrichtung und Unterstützung für Cardio-Übungen machen die App für weitere Trainingsarten nutzbar."],
    ["0.6.0", "2026-03-06", "Less searching when logging food", "Capture a meal with AI and get meal or drink suggestions based on your remaining nutrition targets.", "Essen schneller erfassen", "Mahlzeiten mit KI erfassen und Vorschläge für Essen oder Getränke passend zu den verbleibenden Tageszielen erhalten."],
    ["0.7.0", "2026-03-25", "A clearer view of your progress", "Explore workout consistency, personal records, muscle distribution, recovery, and body trends in one statistics hub.", "Fortschritt übersichtlich an einem Ort", "Trainingskonstanz, Bestleistungen, Muskelverteilung, Erholung und Körpertrends in einem Statistikbereich ansehen."],
    ["0.8.0", "2026-04-09", "Understand adaptive calorie targets", "See uncertainty ranges and diet phases behind recommendations, then choose when to apply a change.", "Adaptive Kalorienziele nachvollziehen", "Unsicherheitsbereiche und Ernährungsphasen bei Empfehlungen sehen und selbst entscheiden, ob du Ziele übernimmst."],
    ["0.9.0", "2026-05-05", "Train Libre brings the essentials together", "Workout routines, nutrition, hydration, supplements, measurements, statistics, and backups come together in one offline-first app.", "Die wichtigsten Bereiche in einer App", "Trainingsroutinen, Ernährung, Flüssigkeit, Supplements, Messwerte, Statistiken und Backups kommen in einer offline-first App zusammen."],
    ["1.0.0", "2026-08-08", "A more polished day-to-day experience", "Refined workout editing, exercise reordering, and scrolling across the app to make common tasks feel smoother.", "Rundere Abläufe im Alltag", "Workout-Bearbeitung, Übungsreihenfolge und Scrollverhalten wurden überarbeitet, damit häufige Abläufe flüssiger funktionieren."],
    ["1.1.0", "2026-08-12", "Your workout stays visible beyond the app", "Follow a live workout from the Lock Screen or Dynamic Island, and reach useful tracking views with home-screen widgets and shortcuts.", "Das Workout bleibt auch außerhalb der App sichtbar", "Das laufende Training auf Sperrbildschirm und Dynamic Island verfolgen sowie Tracking-Ansichten über Widgets und Kurzbefehle öffnen."],
    ["1.2.0", "2026-08-30", "Log a meal from a photo", "Capture food with the camera, barcode, or photos, review the suggested entries, and attach photos to completed workouts.", "Mahlzeiten per Foto erfassen", "Essen mit Kamera, Barcode oder Fotos erfassen, Vorschläge prüfen und abgeschlossene Workouts mit Fotos ergänzen."],
    ["1.3.0", "2026-09-07", "Supersets and more accurate exercise logging", "Link exercises into supersets, log bodyweight and assisted movements more accurately, and track bodyweight from the diary.", "Supersätze und genaueres Übungstracking", "Übungen zu Supersätzen verbinden, Körpergewichts- und unterstützte Übungen genauer erfassen und das Gewicht direkt im Tagebuch eintragen."],
    ["1.4.0", "2026-09-11", "Guidance for what to do next", "Opt into editable next-set suggestions, then review personal records, muscle groups, and a year of training rhythm in statistics.", "Hinweise für den nächsten Schritt", "Bearbeitbare Vorschläge für den nächsten Satz aktivieren und Bestleistungen, Muskelgruppen sowie den Trainingsverlauf in den Statistiken ansehen."],
    ["1.5.0", "2026-10-07", "Long-term goals with a visible path", "Set a nutrition and weight goal, follow your progress against a target pace, and choose the training experience that fits you.", "Langfristige Ziele mit erkennbarem Fortschritt", "Ernährungs- und Gewichtsziele festlegen, den Fortschritt am Zieltempo verfolgen und die passende Trainingserfahrung auswählen."]
  ];
  const siteLanguage = localStorage.getItem("lang");
  let lang = ["en", "de"].includes(siteLanguage) ? siteLanguage : (localStorage.getItem("aboutLang") || (navigator.language.toLowerCase().startsWith("de") ? "de" : "en"));
  if (!copy[lang]) lang = "en";
  function render() {
    document.documentElement.lang = lang;
    document.title = copy[lang].pageTitle;
    document.querySelector('meta[name="description"]').content = copy[lang].pageDescription;
    document.querySelector('meta[property="og:title"]').content = copy[lang].pageTitle;
    document.querySelector('meta[property="og:description"]').content = copy[lang].pageDescription;
    document.querySelectorAll("[data-about]").forEach((el) => { el.textContent = copy[lang][el.dataset.about]; });
    languageToggle.setAttribute("aria-label", lang === "de" ? "Sprache auswählen" : "Switch language");
    document.getElementById("theme-toggle").setAttribute("aria-label", lang === "de" ? "Darstellung wechseln" : "Toggle theme");
    document.querySelectorAll("[data-set-about-lang]").forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.setAboutLang === lang)));
    document.querySelectorAll("[data-set-about-lang]").forEach((button) => button.classList.toggle("is-active", button.dataset.setAboutLang === lang));
    document.getElementById("release-timeline").innerHTML = releases.map(([version, date, titleEn, descEn, titleDe, descDe]) => {
      const dateLabel = new Intl.DateTimeFormat(lang === "de" ? "de-DE" : "en-US", { month: "long", year: "numeric", timeZone: "UTC" }).format(new Date(`${date}T00:00:00Z`));
      return `<li class="about-milestone"><time datetime="${date}">${dateLabel}</time><h3><a href="https://github.com/rfivesix/train-libre/releases/tag/v${version}" target="_blank" rel="noreferrer">v${version}</a></h3><p class="milestone-title">${lang === "de" ? titleDe : titleEn}</p><p>${lang === "de" ? descDe : descEn}</p></li>`;
    }).join("");
  }
  const languageDropdown = document.getElementById("lang-dropdown");
  const languageToggle = languageDropdown.querySelector(".control-btn");
  const languageMenu = languageDropdown.querySelector(".dropdown-menu");
  languageToggle.addEventListener("click", (event) => {
    event.stopPropagation();
    const isOpen = languageMenu.classList.toggle("is-open");
    languageToggle.setAttribute("aria-expanded", String(isOpen));
  });
  document.querySelectorAll("[data-set-about-lang]").forEach((button) => button.addEventListener("click", () => {
    lang = button.dataset.setAboutLang;
    localStorage.setItem("aboutLang", lang);
    localStorage.setItem("lang", lang);
    languageMenu.classList.remove("is-open");
    languageToggle.setAttribute("aria-expanded", "false");
    render();
  }));
  document.addEventListener("click", (event) => {
    if (!languageDropdown.contains(event.target)) {
      languageMenu.classList.remove("is-open");
      languageToggle.setAttribute("aria-expanded", "false");
    }
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      languageMenu.classList.remove("is-open");
      languageToggle.setAttribute("aria-expanded", "false");
      languageToggle.focus();
    }
  });
  document.getElementById("theme-toggle").addEventListener("click", () => {
    const nextTheme = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.setAttribute("data-theme", nextTheme);
    localStorage.setItem("theme", nextTheme);
  });
  render();
})();
