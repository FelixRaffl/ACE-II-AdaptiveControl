# Simulink-Übergabe: adaptiver DC-Motor-Regler

## 1. Zweck

Diese Modelle sind die validierte Simulink-Seite des adaptiven DC-Motor-Reglers
mit RLS, Pol-Platzierung und inkrementellem PI bei `T = 0.08 s`. Sie wurden mit
[`matlab/build_stage_models.m`](../matlab/build_stage_models.m) programmatisch
gebaut und mit [`matlab/validate_stage_models.m`](../matlab/validate_stage_models.m)
headless validiert. Der zugehörige Plot liegt unter
[`img/simulation_stage3.png`](../img/simulation_stage3.png).

## 2. Ordnerübersicht

| Modell | Stufe | Zweck |
|---|---:|---|
| `encoder_test.slx` | 2 | Encoder → ω verifizieren und CPR kalibrieren; PWM-Pfad zum Mitdrehen enthalten |
| `adaptive_dcmotor_sim.slx` | 3 (Sim) | Gleicher Regler gegen eine simulierte Strecke mit S→L→S-Szenario; ohne Hardware gefahrlos per `sim()` ausführbar |
| `adaptive_dcmotor.slx` | 3 (HW) | Vollständiger Regelkreis auf ESP32-I/O für Monitor & Tune |

## 3. Voraussetzungen

- MATLAB **R2025b**
- Simulink Support Package for Arduino Hardware **25.2.9**
- Board **ESP32-WROOM (Arduino Compatible)**
- External Mode: XCP on Serial mit **921600 Baud**
- Solver: Fixed-step discrete, `T = 0.08 s`, `StopTime = inf`

## 4. Erststart und COM-Port

Die Modelle enthalten **COM9** aus der übernommenen Board-Konfiguration. Vor
dem ersten Lauf im Geräte-Manager den tatsächlichen Port des ESP32 ermitteln und
im Modell unter **Hardware Settings → Target hardware resources** anpassen. Diese
Einstellung ist auf jedem Labor-PC separat zu prüfen.

## 5. GPIO-Belegung

| Funktion | Anschluss |
|---|---:|
| PWM (`PWM GPIO14`) | GPIO 14 |
| H-Brücke IN1 (`IN1 GPIO26`) | GPIO 26 |
| H-Brücke IN2 (`IN2 GPIO27`) | GPIO 27 |
| `Encoder` A | GPIO 32 |
| `Encoder` B | GPIO 33 |
| Encoder-VCC | **3.3 V, nicht 5 V** |

Die Belegung ist identisch zu Raffls `code_gen_ac2.slx`.

## 6. Workflow `encoder_test.slx`

1. Im Hardware-Tab **Monitor & Tune** starten und die Verbindung abwarten.
2. Welle von Hand drehen. Das Display `Raw count N` muss je nach Richtung hoch-
   oder herunterzählen.
3. **CPR kalibrieren:** Welle exakt eine Umdrehung drehen und die Änderung von N
   ablesen. Erwartet werden ungefähr 44 Counts (11 PPR × 4-Quadratur). Offener
   Punkt: Raffls Modell verwendet effektiv 11 Counts/Umdrehung (`2π/11`-Gain),
   also einen Faktor 4 weniger. Maßgeblich ist der Ein-Umdrehungs-Test.
4. Danach den Gain-Block `Counts to rad_s` in **beiden** Modellen
   `encoder_test.slx` und `adaptive_dcmotor.slx` auf den gemessenen CPR-Wert
   einstellen: `2π/(0.08·CPR)`.
5. Für den Spin-up die Constant `duty` zunächst auf 0 lassen und langsam im
   Bereich 0…255 erhöhen. IN1 und IN2 sind fest auf Vorwärts geschaltet.
   `omega scope` und das Display `omega rad_s` müssen plausible Werte zeigen;
   3000–8000 RPM entsprechen ungefähr 314–838 rad/s.

## 7. Workflow `adaptive_dcmotor.slx`

1. Die Sicherheits-Checkliste aus Abschnitt 9 vollständig abhaken und die
   Regelung mit dem Motor ohne Schwungscheibe betreiben; Schwungscheibe S nur
   *(optional, falls montiert)* verwenden.
2. **Monitor & Tune** starten. Die tunable Constant `omega_ref` startet bei 0;
   den Sollwert nur in kleinen Schritten erhöhen.
3. Die Scopes verwenden gestapelte Achsen, damit Signale mit sehr
   unterschiedlichen Skalen lesbar bleiben. Im Hardware-Modell zeigt der
   `Adaptation scope` auf Achse 1 u, auf Achse 2 `a0_est` und `b0_est`, auf
   Achse 3 e und auf Achse 4 `traceP`. Der `Tracking scope` zeigt `omega_ref`
   und ω mit Legende.
4. Bei ausreichender Anregung soll RLS in weniger als 1 s konvergieren.
   `traceP` bleibt beschränkt; das Anregungs-Gate hält die Kovarianz im Stillstand
   konstant. Pro Sollwertschritt werden ungefähr 0.25–0.4 s Einschwingzeit
   erwartet.

**Schwungrad-Demo:** Am realen Prüfstand läuft für die Abgabe der Motor ohne
Schwungscheibe; der physische Scheibentausch entfällt. Die vollständige S→L→S-Demonstration ist
in der Simulation `adaptive_dcmotor_sim.slx` validiert: `a0_est` und `b0_est`
re-adaptieren bei α = 0.98, die Einschwingzeit bleibt ungefähr 250 ms, und die
kritische L→S-Richtung erzeugt keinen Grenzzyklus.

## 8. Tunable Parameter

Die Parameter liegen als Constants im Subsystem `Adaptive controller` oder auf
Top-Level und sind im External Mode live änderbar.

| Parameter | Block | Default | Bedeutung |
|---|---|---:|---|
| `omega_ref` | Top-Level Constant | 0 | Solldrehzahl [rad/s] |
| `alpha` | `Adaptive controller` / `alpha` | 0.98 | RLS-Vergessensfaktor; 1.0 birgt nach L→S Grenzzyklus-Gefahr |
| `q0`, `q1` | `Adaptive controller` / `q0`, `q1` | 0.06, −0.5 | Wunsch-Polpolynom q(z) = z² + q1·z + q0 |
| `b0 guard` | `Adaptive controller` / `b0 guard` | 1e-3 | Gain-Hold-Schwelle für \|b0\| |
| `Counts to rad_s` | Top-Level Gain | `2π/(0.08·44)` | Nach der CPR-Kalibrierung anpassen |
| `duty` | Top-Level Constant in `encoder_test.slx` | 0 | PWM-Duty für den Stufe-2-Spin-up |

`alpha = 1.0` ist für die Hardware-Demo nicht freigegeben. Die vorgesehenen
Werte sind `alpha = 0.98`, `q0 = 0.06` und `q1 = −0.5`.

## 9. Sicherheits-Checkliste

Vor jedem Lauf mit angeschlossenem Motor:

- [ ] Strombegrenzung am Netzteil auf 0,5–1 A eingestellt
- [ ] Gemeinsame Masse von ESP32, L298N und Netzteil hergestellt
- [ ] Encoder ausschließlich mit **3.3 V** versorgt
- [ ] ENA-Jumper am L298N entfernt
- [ ] Motor und Schwungscheibe mechanisch sicher fixiert

## 10. Troubleshooting

- **Keine Verbindung:** COM-Port gemäß Abschnitt 4, USB-Kabel und 921600 Baud
  prüfen. Monitor & Tune führt Build und Flash automatisch aus; diesen Vorgang
  vollständig abwarten.
- **N zählt nicht:** Verdrahtung an GPIO 32/33, Encoder-VCC mit 3.3 V und GND
  prüfen.
- **ω hat das falsche Vorzeichen:** A/B oder die Motorleitungen sind vertauscht.
  Die gefundene Farb-Zuordnung dokumentieren und nicht ohne Dokumentation
  umlöten; die A/B-Farbzuordnung ist ein bekannter offener Punkt.
- **Motor dreht trotz u ≠ 0 nicht:** Prüfen, ob der ENA-Jumper entfernt ist, die
  Strombegrenzung zu niedrig steht oder |u| noch unterhalb der Haftreibung liegt.
- **u chattert dauerhaft zwischen ±255:** Prüfen, ob `alpha` auf 1.0 geändert
  wurde, und auf 0.98 zurücksetzen.

## 11. Verweise

- [`firmware_model/TESTPLAN.md`](../firmware_model/TESTPLAN.md): Stufenplan und
  Sicherheits-Checkliste
- [Root-`README.md`](../README.md): Design-Study zu α = 0.98, Anregungs-Gate und
  b₀-Guard
- [`firmware_model/README.md`](../firmware_model/README.md): I/O-Spezifikation
