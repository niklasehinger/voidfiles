# VoidFiles Color System

## Farbpalette

| Farbe | Hex-Code | Verwendung |
|-------|----------|------------|
| Navy | #00005B | Haupttexte, Überschriften, Footer |
| Blue | #3B63FB | Buttons, Links, Akzente |
| White | #FFFFFF | Hintergründe, Text auf dunklen Flächen |
| Red | #EB1100 | Warnungen, Fehler, Lösch-Aktionen |
| Black | #161616 | Sekundäre Texte, Borders |

## CSS-Klassen

### Button-Klassen
- `.btn-primary` - Hauptaktionen (blau)
- `.btn-secondary` - Sekundäre Aktionen (blau outline)
- `.btn-danger` - Gefährliche Aktionen (rot)

### Text-Klassen
- `.text-voidfiles-navy` - Haupttexte
- `.text-voidfiles-blue` - Links und Akzente
- `.text-voidfiles-red` - Warnungen

### Hintergrund-Klassen
- `.bg-voidfiles-navy` - Footer, dunkle Bereiche
- `.bg-voidfiles-blue` - Buttons, Akzente
- `.bg-voidfiles-red` - Warnungen

### Border-Klassen
- `.border-voidfiles-blue` - Akzent-Borders

## Tailwind-Klassen

Verwende die Tailwind-Klassen für direkten Zugriff:
- `text-voidfiles-navy`
- `bg-voidfiles-blue`
- `border-voidfiles-red`

## Verwendung

```html
<!-- Button -->
<button class="btn-primary">Hauptaktion</button>
<button class="btn-secondary">Sekundäre Aktion</button>
<button class="btn-danger">Löschen</button>

<!-- Text -->
<h1 class="text-voidfiles-navy">Überschrift</h1>
<a class="text-voidfiles-blue">Link</a>

<!-- Hintergrund -->
<footer class="bg-voidfiles-navy text-voidfiles-white">
``` 