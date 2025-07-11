# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## 🧑‍🎨 Design Guidelines für VoidFiles

Bevor Änderungen an Views, Komponenten oder Styles vorgenommen werden, beachte bitte folgende Design-Richtlinien. Diese dienen als Grundlage für alle zukünftigen UI-Anpassungen – sowohl manuell als auch AI-gestützt (z. B. mit Cursor).

### 🎨 Farbpalette

Verwende ausschließlich die folgende Farbpalette:

| Farbe        | Hex-Code   | Verwendungszweck (Vorschlag)           |
|--------------|------------|----------------------------------------|
| Primär       | `#615EFF`  | Hauptbuttons, aktive Elemente, Icons   |
| Hintergrund  | `#101828`  | Body-Hintergrund                        |
| Sekundär     | `#1E2B49`  | Panels, Sektionen, Karten               |
| Text Hell    | `#FFFFFF`  | Haupttext auf dunklem Hintergrund       |
| Text Grau    | `#9299A5`  | Sekundärtext, Placeholder, Labels       |

### 🧱 Designprinzipien

- **TailwindCSS verwenden**: Alle Styles sollen über Tailwind-Klassen geschrieben werden – keine externen Stylesheets oder Inline-Styles.
- **Minimalistisch bleiben**: Verzichte auf unnötige visuelle Effekte oder komplexe Animationen.
- **Konzentration auf Klarheit**: Nutze klare Layouts, lesbare Schriftgrößen und ausreichend Whitespace.
- **Mobile-First**: Responsives Verhalten mit Tailwind's `sm:`/`md:`/`lg:` Breakpoints sicherstellen.

### ✅ Komponentenempfehlung

Falls neue UI-Komponenten erstellt werden:

- Nutze semantisches HTML (`<section>`, `<header>`, `<main>`, etc.)
- Verwende **Tailwind Utility-Klassen** konsequent für Spacing, Typografie, Farben, Layout.
- Optional: Verwende `@shadcn/ui`-Komponenten für konsistentes Verhalten.

---

> ⚠️ Hinweis für AI-basierte Unterstützung (z. B. Cursor): Bitte alle Änderungen an Layout oder Design im Einklang mit diesen Richtlinien umsetzen.
