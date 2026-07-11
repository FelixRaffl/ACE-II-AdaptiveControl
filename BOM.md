# Bill of Materials – Adaptive Control DC Motor Aufbau

**Projekt**: Adaptive Control of a DC Motor (Example 7.6)

**Stand**: 2026-07-10

---

## Elektronik – Bestellliste

| # | Komponente | Produkt | Kompatibilität | ca. Preis | Status |
|---|---|---|---|---|---|
| E1 | **DC Getriebemotor mit Encoder** | Hyuduo 25GA371, 12V, mit integriertem Quadratur-Encoder (6 Drähte) | 12V, Encoder 3.3V-kompatibel mit ESP32 | ~14 € | ✅ ausgewählt |
| E2 | **ESP32 DevKit** | ESP32-WROOM-32 DevKit | PWM (LEDC) + Interrupt-Pins; am Board getestet (Raffl, 2026-07-06) | 7–10 € | ✅ im Einsatz |
| E3 | **Motortreiber L298N Mini** | DollaTek L298N Mini Dual H-Bridge (B07DK6Q8F9) | 5–35V Motor, 3.3V Logic von ESP32 ausreichend (VIH > 2.3V ✓) | ~5 € | ✅ ausgewählt |
| E4 | **Step-Down Converter** | APKLVSR DC-DC Buck, 4–40V → 1.25–37V, 3A, mit Display (B0D8SRX3NY) | Optional für Standalone-Betrieb — im Prototyp **nicht verbaut** (ESP32 läuft über USB bzw. Power-Backpack) | ~8 € | ✅ vorhanden, nicht verbaut |
| E5 | **Barrel Jack Buchse** | RUNCCI-YUN 5.5/2.1mm Hohlstecker-Buchse (B0CH7WX85X) | Standard Netzteil-Stecker | ~3 € | ✅ ausgewählt |
| E6 | **Netzteil** | 12V-Labornetzteil (strombegrenzt, Start 0,5–1 A) | 12 V direkt auf L298N VM, gemeinsame Masse | — | ✅ Labornetzteil |
| E7 | **Jumper Wire Set** | M-F + M-M, 20cm | — | ~3 € | ⏳ noch bestellen |

> ⚠️ **AS5600 Encoder entfällt** — der 25GA371 hat bereits integrierten Quadratur-Encoder (A, B Signale direkt an ESP32 Interrupt-Pins).

> ⚠️ **Getriebe entfernt** — das Getriebe des 25GA371 wurde physisch entfernt; der Motor läuft ohne Getriebe mit ~3000–8000 RPM (nicht 50 RPM laut Produktseite). RLS schätzt die effektiven Parameter a₀ und b₀ am Ausgang, der Regler passt sich automatisch an.

> ⚠️ **L298N Spannungsabfall**: ~4V Verlust über die H-Brücke. Bei 12V Versorgung kommen effektiv ~8V am Motor an. Mit dem Step-Down Converter lässt sich die Eingangsspannung anpassen.

---

## Verdrahtungsschema

```
Labornetzteil 12V (strombegrenzt 0,5–1 A)
    │
    ├──→ (optional, nur Standalone-Betrieb: Barrel Jack (E5) → Step-Down (E4) → 5V)
    │
    ├──→ L298N VM (Motor-Power 12V)
    │    L298N GND
    │    L298N ENA → ESP32 GPIO 14 (PWM)
    │    L298N IN1 → ESP32 GPIO 26 (Richtung)
    │    L298N IN2 → ESP32 GPIO 27 (Richtung)
    │    L298N OUT1/OUT2 → Motor 25GA371 (Motordrähte)
    │
    └──→ ESP32 via USB (Programmierung + 3.3V Logik)
              │
              ├── GPIO 32 (Interrupt) → Encoder Kanal A (25GA371)
              ├── GPIO 33 (Interrupt) → Encoder Kanal B (25GA371)
              ├── 3.3V → Encoder VCC (25GA371)
              └── GND  → Encoder GND (25GA371)
```

**25GA371 Pinbelegung (6 Drähte — bestätigt aus Datenblatt-Foto):**
| Drahtfarbe | Funktion | nach |
|---|---|---|
| Rot | Motor + | L298N OUT1 |
| Weiß | Motor − | L298N OUT2 |
| Blau | Encoder VCC | ESP32 **3.3V** (nicht 5V!) |
| Schwarz | Encoder GND | ESP32 GND |
| Dunkelgrün / Grün | Encoder Kanal A | ESP32 GPIO 32 |
| Gelb | Encoder Kanal B | ESP32 GPIO 33 |

GPIO-Belegung folgt Raffls am Board getestetem Modell (2026-07-06).

> ⚠️ Blau (+) / Schwarz (−) nicht vertauschen. Encoder mit **3.3V** versorgen — die
> ESP32-GPIOs sind nicht 5V-tolerant (VCC bestimmt den Pegel der A/B-Signale).
>
> Encoder-Auflösung: **11 PPR pro Kanal → ×4 Quadratur = 44 Counts/Motorumdrehung**
> (CPR-Startwert; im Lab empirisch nachmessen).

---

## Mechanik – Plexiglas (Laser-Cut, aus Lagerbestand)

| # | Bezeichnung | Abmessungen | Dicke | Masse | J |
|---|---|---|---|---|---|
| P1 | Grundplatte | 200 × 150 mm | **12 mm** | — | — |
| P2 | Schwungscheibe S (klein) | Ø 60 mm | **10 mm** | 33.6 g | 1.5 × 10⁻⁵ kgm² |
| P3 | Schwungscheibe L (groß) | Ø 120 mm | **15 mm** | 201.9 g | 3.6 × 10⁻⁴ kgm² |

**J-Verhältnis S zu L: ~24:1** → deutlich sichtbare Änderung der Systemdynamik für Adaptions-Demo.

> **Hinweis (Stand 2026-07-08):** Die Schwungscheiben sind für die Abgabe **nicht montiert**
> — der Prüfstand läuft mit dem Motor ohne Schwungscheibe. Der Trägheitswechsel
> (J ×24) wird in der Simulation `adaptive_dcmotor_sim.slx` demonstriert (Szenario
> S→L→S). Die Scheiben bleiben als Design/Aufbauoption dokumentiert.

---

## Mechanik – 3D-Druck (PLA oder PETG, ~60g Filament)

| # | Bezeichnung | Funktion | Bemerkung |
|---|---|---|---|
| D1 | Motorhalter | Befestigung 25GA371 auf Grundplatte | An Motorgehäuse-Maße anpassen |
| D2 | Nabenadapter S | Verbindet Ausgangswelle 25GA371 ↔ Schwungscheibe Ø60mm | Wellendurchmesser des 25GA371 prüfen |
| D3 | Nabenadapter L | Verbindet Ausgangswelle 25GA371 ↔ Schwungscheibe Ø120mm | Wellendurchmesser des 25GA371 prüfen |
| D4 | ESP32-Halterung | Aufnahme ESP32 DevKit auf Grundplatte | Nach Modell-Bestätigung anpassen |
| D5 | L298N-Halterung | Befestigung Motortreiber auf Grundplatte | 43×43mm Footprint |
| D6 | Step-Down-Halterung | Befestigung Step-Down-Modul auf Grundplatte | 61×34mm Footprint |

---

## Befestigungsmaterial

| # | Bezeichnung | Menge |
|---|---|---|
| B1 | M3 Schrauben (6/8/10/12 mm) | je 5 Stk |
| B2 | M3 Muttern | 20 Stk |
| B3 | M3 Gewindeeinsätze (Heißpresseinlagen) | 15 Stk |
| B4 | M3 Unterlegscheiben | 10 Stk |
| B5 | M2 Madenschrauben | 4 Stk (Nabenadapter) |

---

## Gesamtübersicht Kosten

| Kategorie | ca. Kosten |
|---|---|
| Elektronik (bereits ausgewählt) | ~30 € |
| Elektronik (noch offen: ESP32 + Netzteil + Kabel) | ~18–25 € |
| Plexiglas (Lagerbestand) | ~0–10 € |
| 3D-Druck Filament (~60g) | ~1–2 € |
| Befestigungsmaterial | ~3–5 € |
| **Gesamt** | **~52–72 €** |

---

## Offene Punkte

- [x] **ESP32 Modell bestätigt** — GPIO-Belegung 14/26/27/32/33 (Raffl, am Board getestet 2026-07-06)
- [x] **Netzteil geklärt** — 12 V Labornetzteil, strombegrenzt (0,5–1 A)
- [ ] **25GA371 Wellendurchmesser prüfen** → Nabenadapter (D2/D3) dimensionieren (nur falls Schwungscheiben montiert werden)
- [ ] **25GA371 Encoder Drahtfarben A/B prüfen** → Drehrichtungs-Vorzeichen-Test im Lab (TESTPLAN Stufe 2); BOM sagt A = grün / B = gelb, Diagramme sagen A = gelb / B = grün
- [ ] **CPR verifizieren** — 1-Umdrehungs-Test (erwartet ≈ 44; Raffls Modell nutzt effektiv 11)
- [ ] **Plexiglas Lagerbestand** bestätigen (10mm, 12mm, 15mm)
