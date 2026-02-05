# 🧠 VoidFiles

**Intelligente Analyse von Adobe Premiere Pro-Projektdateien**

VoidFiles ist ein SaaS-Tool zur Analyse von Adobe Premiere Pro-Projektdateien (.prproj). Es extrahiert alle verlinkten Medienpfade und klassifiziert sie als Used, Unused oder Missing - hilft dir dabei, Speicherplatz zu sparen und deine Videoprojekte effizient zu organisieren.

## ✨ Features

- **📁 XML-Parsing**: Automatische Extraktion aller Medienpfade aus .prproj-Dateien
- **⚡ Lokale Analyse**: Schnelle, deterministische Medienklassifikation ohne API-Kosten
- **📊 CSV-Integration**: Optional Upload von Medienlisten für präzise Analyse
- **🎯 Drei Kategorien**:
  - ✅ **Used Files** - Verwendete Mediendateien
  - 📁 **Unused Files** - Importierte aber ungenutzte Dateien
  - ❌ **Missing Files** - Fehlende referenzierte Dateien

## 🚀 Tech Stack

- **Backend**: Ruby on Rails 8
- **Database**: PostgreSQL
- **Frontend**: Tailwind CSS, Stimulus.js
- **Asset Pipeline**: esbuild
- **File Processing**: Nokogiri (XML), ActiveStorage

## 🛠️ Installation

### Voraussetzungen
- Ruby 3.2+
- PostgreSQL
- Node.js 18+
- Yarn

### Setup

1. **Repository klonen**
   ```bash
   git clone https://github.com/yourusername/voidfiles.git
   cd voidfiles
   ```

2. **Dependencies installieren**
   ```bash
   bundle install
   npm install
   ```

3. **Datenbank einrichten**
   ```bash
   rails db:create
   rails db:migrate
   ```

4. **Umgebungsvariablen konfigurieren**
   ```bash
   cp .env.example .env
   ```

5. **Server starten**
   ```bash
   bin/dev
   ```

Die Anwendung ist dann unter `http://localhost:3000` erreichbar.

## 🎨 Design System

VoidFiles verwendet ein konsistentes Farbsystem:

| Farbe | Hex-Code | Verwendung |
|-------|----------|------------|
| Navy | #00005B | Haupttexte, Überschriften |
| Blue | #3B63FB | Buttons, Links, Akzente |
| White | #FFFFFF | Hintergründe |
| Red | #EB1100 | Warnungen, Fehler |
| Black | #161616 | Sekundäre Texte |

## 📋 User Journey

1. **Projekt hochladen**: .prproj-Datei in die Anwendung ziehen
2. **Medienliste (optional)**: CSV-Datei mit tatsächlicher Medienablage hinzufügen
3. **Analyse starten**: Automatische Verarbeitung der Medienpfade
4. **Ergebnis erhalten**: Übersichtliche Tabelle mit Used/Unused/Missing-Kategorien
5. **Aktionen**: Export oder Löschung nicht verwendeter Dateien

## 🔧 Entwicklung

### Nützliche Commands

```bash
# Assets kompilieren
bin/dev

# Tests ausführen
rails test

# Code-Qualität prüfen
bundle exec rubocop

# Datenbank zurücksetzen
rails db:reset
```

### Projektstruktur

```
voidfiles/
├── app/
│   ├── controllers/     # Rails Controller
│   ├── models/         # Datenbankmodelle
│   ├── views/          # ERB Templates
│   ├── assets/         # CSS, JS, Bilder
│   └── services/       # Business Logic
├── config/             # Rails Konfiguration
├── db/                 # Datenbankmigrationen
└── test/               # Tests
```

## 🤝 Contributing

1. Fork das Repository
2. Erstelle einen Feature Branch (`git checkout -b feature/amazing-feature`)
3. Committe deine Änderungen (`git commit -m 'Add amazing feature'`)
4. Push zum Branch (`git push origin feature/amazing-feature`)
5. Öffne einen Pull Request

## 📄 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE) Datei für Details.

## 🙏 Danksagungen

- Adobe für Premiere Pro
- Ruby on Rails Community
- Tailwind CSS Team

---

**Entwickelt mit ❤️ für die Videoproduktions-Community**
