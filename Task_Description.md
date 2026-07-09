# Task Description — Adaptive Control of a DC Motor

## Titel
Task Description — Adaptive Control of a DC Motor

## Ziel
- Kurze Demonstration adaptiver Regelung: RLS-basierte Parameterabschätzung + Pol-Platzierungs-PI auf ESP32 zur robusten Drehzahlregelung eines DC-Motors.

## Kontext
- Physikalisches Labor-Setup mit Hyuduo 25GA371 (integrierter Encoder), ESP32, L298N H-Bridge und wechselbaren Plexiglas-Schwungscheiben.
- Diskretes, erstes Ordnung Modell: G(z) = b0 / (z + a0). RLS schätzt a0, b0 online; Regler aktualisiert PI-Parameter per Pol-Platzierung.

## Hardware (Kernauswahl)
- Motor: Hyuduo 25GA371 (12V, Quadratur-Encoder)
- MCU: ESP32 DevKit (LEDC PWM, GPIO für Encoder-Interrupts)
- Treiber: L298N H-Bridge (≈4V Spannungsabfall)
- Mechanik: Schwungscheiben S (J=1.5e-5) und L (J=3.6e-4)

## Algorithmus / Anforderungen
- Estimator: RLS (P=100·I, xe=[-0.5;1.0], α=1.0)
- Pol-Platzierung: q(z)=z^2 −0.5z +0.06 (T=0.08s → Settling ≈250 ms)
- PI-Update: u(k)=u(k−1)+d1·e(k)+d0·e(k−1)
- Echtzeit: ISR für Encoder (IRAM_ATTR), PWM via `ledcWrite()`, `u` clamp in [−255,255]

## Deliverables
- Firmware für ESP32 mit RLS + adaptivem PI-Regler
- Test-Anleitung für Demo (S → L Schwungscheibe Wechsel)
- Diese Task-Description-Folie (Markdown + optional PPTX)

## Akzeptanzkriterien
- RLS-Konvergenz auf sinnvolle a0/b0 für beide Schwungscheiben
- Geschlossene Regelstrecke erreicht ~250 ms Einschwingzeit (annähernd)
- PWM-Signal korrekt (LEDC) und Richtung über IN1/IN2

## Risiken / Offene Punkte
- ESP32-Modell finalisieren (Pinout prüfen)
- Netzteil-Spannung (12V vs. 24V) und L298N Spannungsabfall beachten
- Wellendurchmesser für Nabenadapter prüfen

## Nächste Schritte
1. Firmware-Basis (Encoder ISR, RLS loop, PI update) implementieren
2. Hardware zusammenbauen und Encoder-CPR messen
3. Kalibrierungstest: S → L und Validierung der Konvergenz
