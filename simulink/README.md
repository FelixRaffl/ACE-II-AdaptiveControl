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
| `controller_block.slx` | Übergabe | Derselbe Regler als Anschlussblock: genau 1 Eingang (ω [rad/s]) / 1 Ausgang (u [±255]) — zum Kopieren ins eigene Modell (Abschnitt 8) |

**Klare Trennung — was ist Simulation, was ist Hardware-Code:**

| Kategorie | Modelle | Ausführung |
|---|---|---|
| **Simulation** | `adaptive_dcmotor_sim.slx` | grüner **Run**-Button, keine Hardware nötig — simulierte Strecke, gefahrlos |
| **Hardware (ESP32)** | `encoder_test.slx`, `adaptive_dcmotor.slx` | **nur Monitor & Tune** mit angeschlossenem Board — ein normaler Run ist nicht sinnvoll (echte I/O-Blöcke, keine Strecke im Modell) |
| **Übergabe** | `controller_block.slx` | nicht ausführen — Subsystem `Adaptive speed controller` ins eigene Modell kopieren (Abschnitt 8) |

Der Reglerkern (`Adaptive controller`-Subsystem) ist in allen vier Modellen
identisch und stammt aus demselben Builder — die Simulation validiert also
exakt den Code, der auf der Hardware läuft; nur die Strecke (simuliert vs.
echte I/O) unterscheidet sich.

Der Regler ist in allen Modellen dasselbe Subsystem `Adaptive controller`
mit zwei Eingängen (`reference`, `speed`) und fünf Ausgängen (`u_sat`, `a0_est`,
`b0_est`, `error`, `traceP`). Die vier Monitoring-Ausgänge sind bewusst Teil des
Interfaces: sie speisen die External-Mode-Scopes (Abschnitt 7) und die
quantitativen Asserts der headless Validierung. Für den gewünschten einfachen
Anschluss kapselt `controller_block.slx` genau dieses Subsystem hinter einer
1-Eingang/1-Ausgang-Boundary (ω_ref und Monitoring liegen innen, Abschnitt 8) —
die ESP32-I/O-Blöcke (PWM, Digital Output, Encoder) sind in
`adaptive_dcmotor.slx` bereits identisch zu Raffls am Board getestetem Modell
(`code_gen_ac2.slx`) verschaltet.

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
   Der `Bring-up scope` zeigt Raw count `N`, `ΔN` und ω auf gestapelten Achsen;
   `N` muss monoton in eine Richtung laufen, `ΔN` einseitig bleiben und das
   Display `omega rad_s` plausible Werte zeigen. 3000–8000 RPM entsprechen
   ungefähr 314–838 rad/s.

## 7. Workflow `adaptive_dcmotor.slx`

1. Die Sicherheits-Checkliste aus Abschnitt 10 vollständig abhaken und die
   Regelung mit dem Motor ohne Schwungscheibe betreiben; Schwungscheibe S nur
   *(optional, falls montiert)* verwenden.
2. **Monitor & Tune** starten. Die tunable Constant `omega_ref` startet bei 0;
   den Sollwert nur in kleinen Schritten erhöhen.
3. Die Scopes verwenden gestapelte Achsen, damit Signale mit sehr
   unterschiedlichen Skalen lesbar bleiben. Im Hardware-Modell zeigt der
   `Adaptation scope` auf Achse 1 u, auf Achse 2 `a0_est` und `b0_est`, auf
   Achse 3 e und auf Achse 4 `traceP`. Der `Tracking scope` zeigt `omega_ref`
   und ω mit Legende. Der `Bring-up scope` zeigt zusätzlich die Messkette und
   Richtung — Achse 1 Raw count `N`, Achse 2 `ΔN`, Achse 3 ω, Achse 4 `IN1` —
   für den Forward-only-Debug (siehe TESTPLAN Stufe 3).
4. Bei ausreichender Anregung soll RLS in weniger als 1 s konvergieren.
   `traceP` bleibt beschränkt; das Anregungs-Gate hält die Kovarianz im Stillstand
   konstant. Pro Sollwertschritt werden ungefähr 0.25–0.4 s Einschwingzeit
   erwartet.

**Forward-only-Bring-up (zuerst!):** Vor dem ersten Sollwertsprung die Messkette am
`Bring-up scope` prüfen (N monoton, ΔN einseitig, ω plausibel, IN1 vorwärts). Für den
ersten Unit-Step die Stellgrößen-Saturation im External Mode live auf `LowerLimit = 0`
setzen (erzwingt Vorwärtslauf), `omega_ref` einmal auf ~30 rad/s (oberhalb `ω_min`,
TESTPLAN Stufe 2b). Erst nach stabilem Step auf `LowerLimit = -255` zurück und die
Puls-Folge fahren. Vollständige Prozedur + Entscheidungsbaum: TESTPLAN Stufe 3 und
`../HARDWARE_BRINGUP_PLAN.md`.

**Schwungrad-Demo:** Am realen Prüfstand läuft für die Abgabe der Motor ohne
Schwungscheibe; der physische Scheibentausch entfällt. Die vollständige S→L→S-Demonstration ist
in der Simulation `adaptive_dcmotor_sim.slx` validiert: `a0_est` und `b0_est`
re-adaptieren bei α = 0.98, die Einschwingzeit bleibt im Bereich ≈ 0.25–0.4 s
(Designziel des Polpolynoms: 250 ms), und die kritische L→S-Richtung erzeugt
keinen Grenzzyklus. Eine gemessene Hardware-Einschwingzeit liegt noch nicht vor.

## 8. Workflow `controller_block.slx` (Anschlussblock, 1 In / 1 Out)

Übergabevariante: derselbe validierte Regler als Subsystem
`Adaptive speed controller` mit genau **einem Eingang** und **einem Ausgang**,
zum direkten Anschließen im eigenen Modell.

| Boundary | Signal | Bedeutung |
|---|---|---|
| IN | `omega_in` | gemessene Drehzahl in **rad/s** (davor: Encoder-Counts → ΔN → Gain `2π/(T·CPR)`) |
| OUT | `u_out` | vorzeichenbehafteter PWM-Befehl in **[−255, 255]** (dahinter: `\|u\|` → PWM GPIO14, `sign(u)` → IN1/IN2 — siehe `H-bridge map` in `adaptive_dcmotor.slx`) |

Verwendung:

1. `controller_block.slx` öffnen und das Subsystem `Adaptive speed controller`
   ins eigene Modell kopieren.
2. `omega_ref` liegt als tunable Constant **im** Subsystem (External Mode;
   Start 0, in kleinen Schritten erhöhen).
3. Monitoring (u, `a0_est`/`b0_est`, e, `traceP`) läuft auf einem internen
   4-Achsen-Scope im Subsystem — die Boundary bleibt 1-in/1-out.
4. Voraussetzungen: Fixed-step discrete mit **T = 0.08 s** (der gesamte
   Regler ist darauf ausgelegt); ω muss in rad/s ankommen — der CPR-Wert des
   Encoder-Gains ist der bekannte offene Punkt (Abschnitt 6).

## 9. Tunable Parameter

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

## 10. Sicherheits-Checkliste

Vor jedem Lauf mit angeschlossenem Motor:

- [ ] Strombegrenzung am Netzteil auf 0,5–1 A eingestellt
- [ ] Gemeinsame Masse von ESP32, L298N und Netzteil hergestellt
- [ ] Encoder ausschließlich mit **3.3 V** versorgt
- [ ] ENA-Jumper am L298N entfernt
- [ ] Motor und Schwungscheibe mechanisch sicher fixiert

## 11. Troubleshooting

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
- **ω-Spike-Pakete / Motor wechselt dauernd die Richtung** (Laborbefund 2026-07-11):
  Messketten- oder Skalierungsproblem bzw. Haftreibungs-Grenzzyklus, nicht die
  Modellordnung. Forward-only-Test nach TESTPLAN Stufe 2/2b/3 fahren, Regelkreis erst
  nach sauberer Messkette schließen; Entscheidungsbaum in `../HARDWARE_BRINGUP_PLAN.md`.

## 12. Verweise

- [`firmware_model/TESTPLAN.md`](../firmware_model/TESTPLAN.md): Stufenplan und
  Sicherheits-Checkliste
- [Root-`README.md`](../README.md): Design-Study zu α = 0.98, Anregungs-Gate und
  b₀-Guard
- [`firmware_model/README.md`](../firmware_model/README.md): I/O-Spezifikation
