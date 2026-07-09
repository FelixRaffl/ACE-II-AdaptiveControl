# Build- & Testplan — ESP32 Adaptive Control (Simulink External Mode)

Inkrementeller Aufbau in **3 Simulink-Modellen**. Jede Stufe wird **am Oszi/Scope
verifiziert**, bevor die nächste dazukommt. Nie alles auf einmal.

Board: **ESP32-WROOM (Arduino Compatible)**. Die ausgelieferten Modelle tragen
**COM9** aus der Donor-Config; der COM-Port ist **pro Labor-PC** im Geräte-Manager
zu prüfen und in den Modell-Hardware-Einstellungen anzupassen. Solver **Fixed-step
`discrete`, 0.08 s, Stop inf**. Lauf-Modus: **Monitor & Tune** (External Mode).

Die Pins folgen Raffls am Board getestetem Modell (2026-07-06); frühere
Draft-Belegungen sind obsolet.

---

## Namenskonvention (Modelldateien)

| Stufe | Datei | Inhalt |
|---|---|---|
| 1 | `pwm_test.slx` | PWM open-loop (Aktuator) — erledigt (Raffl, lief am Board) |
| 2 | [`encoder_test.slx`](../simulink/encoder_test.slx) | Encoder → ω (Sensor), fertiges Modell unter `../simulink/` |
| 3 | [`adaptive_dcmotor.slx`](../simulink/adaptive_dcmotor.slx) | voller Regelkreis (RLS + PolePlace + PI), fertiges Modell unter `../simulink/` |
| Simulation | [`adaptive_dcmotor_sim.slx`](../simulink/adaptive_dcmotor_sim.slx) | Simulations-Zwilling von Stufe 3: gleicher Regler, simulierte Strecke mit S→L→S-Szenario; zum gefahrlosen Testen ohne Hardware |

> Tipp: jede Stufe per **Save As** aus der vorigen ableiten → Board-/Solver-Settings
> bleiben erhalten.

---

## Stufe 1 — `pwm_test.slx`  (PWM open-loop) ← AKTUELL

**Blöcke**
```
[Slider]→[Constant2 = 128] ──► [PWM  Pin 14, 1000 Hz]
[Constant 1] ──► [Digital Output  Pin 26]   (IN1)
[Constant 0] ──► [Digital Output  Pin 27]   (IN2)
```
Slider an **Constant2:Value** gebunden, Min 0 / Max 255.

**Test (ohne Motor!)**
1. Save → Monitor & Tune.
2. Tastkopf **GPIO14** vs GND: 1-kHz-Rechteck; Duty 128 ≈ 50 %.
3. Slider 0→255 → Tastverhältnis 0→100 % live.
4. **GPIO26 = 3,3 V**, **GPIO27 = 0 V** prüfen.

**Akzeptanz:** Rechteck sichtbar, Duty folgt Slider, Richtungspins korrekt.

**Dann Motor dran:** OUT1/OUT2, Netzteil 12 V, **Strombegrenzung 0,5–1 A**.
ENA-Jumper am L298N entfernt. Slider langsam hoch → Motor dreht, Drehzahl folgt.

---

## Stufe 2 — `encoder_test.slx`  (Encoder → ω)

**Blöcke** (zusätzlich)
```
[Encoder  Pin A=32, Pin B=33] ─► N(k)
N(k) ─►(−)─► ΔN ─► [Gain 2π/(T·CPR)] ─► ω ─► [Scope/Display]
         └ [Unit Delay z⁻¹] ◄─ N(k)
```
Gain = `2π/(0.08·44) ≈ 1.785` (CPR=44 = 11 PPR ×4, **im Lab nachmessen**).

**Test**
1. Monitor & Tune. Welle **von Hand** drehen → N zählt hoch/runter (Richtung = Vorzeichen).
2. **CPR kalibrieren:** Welle exakt **1 Umdrehung** drehen → N muss ≈ 44 zählen.
   Sonst Gain anpassen.
3. Motor per Stufe-1-PWM laufen lassen → ω-Scope zeigt plausible rad/s
   (~3000–8000 RPM ⇒ ~314–838 rad/s).

> ⚠️ **CPR-Diskrepanz (offen, mit Raffl klären):** Raffls `code_gen_ac2.slx` nutzt
> den Speed-Gain `2π/11` (bei T = 5 ms) → wirksam 11 Counts/Umdrehung. Unsere
> Annahme ist CPR ≈ 44 (11 PPR × 4-Quadratur) → Faktor-4-Unterschied. **Nicht
> raten:** per 1-Umdrehungs-Test entscheiden (Welle exakt 1 Umdrehung von Hand,
> Display „Raw count N" ablesen). Danach den Gain `Counts to rad_s` in **beiden**
> Modellen (`encoder_test.slx` UND `adaptive_dcmotor.slx`) auf den gemessenen
> Wert setzen.

**Akzeptanz:** ω-Vorzeichen stimmt mit Drehrichtung, CPR verifiziert, ω plausibel.

Der `arduinosensorlib/Encoder`-Block (Simulink Support Package for Arduino Hardware
25.2.9) arbeitet interrupt-basiert mit ×4-Quadratur, liefert `int32` und läuft im
Mode `No reset`. Das reicht bei Demo-Drehzahlen aus. ESP32-PCNT via `coder.ceval`
bleibt bei Count-Verlust eine Zukunftsoption.

---

## Stufe 3 — `adaptive_dcmotor.slx`  (Regelkreis schließen)

> **Design-Entscheidungen aus der Simulationsstudie** (`matlab/design_study.m`, 2026-07-05,
> Details im [README](../README.md#design-study-for-the-esp32-implementation)):
> - **α = 0.98 statt 1.0** im RLS — mit α = 1.0 endet der Rückwärts-Wechsel L→S im
>   dauerhaften Grenzzyklus (u-Chattering ±255, ~12 Vorzeichenwechsel/s).
> - **Kein Gain-Freeze** beim Start nötig — Sättigung begrenzt u, RLS konvergiert in ~0.4 s.
>   Stattdessen **b₀-Guard**: Gains nur updaten, wenn `|b0_est| > ε` (sonst halten).
> - **Kein Vorfilter** nötig — die ±255-Sättigung eliminiert das Überschwingen bei
>   Demo-Amplituden praktisch von selbst (~1 % statt 42 % unbegrenzt).
> - Bei langen Konstantfahrten: Kovarianz-Windup beobachten → gelöst durch das
>   Anregungs-Gate im RLS-Block (P-Update pausiert ohne Anregung); `traceP` liegt
>   zur Überwachung auf dem Adaptions-Scope.

**Zusätzlich** (alles bei T = 0.08 s):
```
ω_ref (Slider/Constant) ─(+)─► e ──┬──────────────► [PI_C] ─► u ─► [Saturation ±255]
              ω ────────(−)─┘       └►[z⁻¹]► e_prev          │            │
                                                              │   ┌────────┴─ |u| ► PWM Pin14
y=ω ─┬─► [rls_estimator] ─► a0,b0 ─► [pole_placement] ─► d0,d1┘   └─ sign(u) ► IN1/IN2
     └►[z⁻¹]►y_prev                         (q0=0.06, q1=-0.5)
u_sat ─►[z⁻¹]► u_prev (zurück in PI_C)
```
MATLAB-Function-Blöcke = verbatim:
[`rls_estimator.m`](rls_estimator.m) · [`pole_placement_controller.m`](pole_placement_controller.m) · [`PI_C.m`](PI_C.m)

**I/O-Mapping** (Details siehe [`README.md`](README.md)):
- `|u|` → PWM GPIO14; `sign(u)` → IN1/IN2 (u≥0: 26=1,27=0).
- **saturiertes** u ist u_prev (Anti-Windup-konsistent).

**Test**
1. Strombegrenzung aktiv. ω_ref klein starten, langsam hoch.
2. Scopes live: `ω, ω_ref, u, e, a0_est, b0_est`.
3. *(optional, nur falls Schwungscheiben montierbar)* **Adaptions-Demo:** Schwungscheibe **S → L** → a0,b0 adaptieren, Settling bleibt ~250 ms.

Die vollständige S→L→S-Demonstration liegt in `adaptive_dcmotor_sim.slx`
validiert vor; der Kernablauf am Prüfstand verwendet den Motor ohne Schwungscheibe.

**Monitor-&-Tune-Checkliste**

1. Strombegrenzung aktiv (0,5 A). Normalfall: Motor ohne Schwungscheibe; Schwungscheibe S
   *(falls montiert)* montiert und gesichert.
2. COM-Port in den Modell-Einstellungen = Geräte-Manager-Port.
3. `adaptive_dcmotor.slx` öffnen → Hardware-Tab → **Monitor & Tune**,
   Verbindungsaufbau abwarten.
4. `omega_ref` startet auf 0 → in kleinen Schritten erhöhen, Tracking-Scope beobachten.
5. Adaptions-Scope prüfen: `a0_est`/`b0_est` konvergieren, `traceP` beschränkt
   (Gate hält es im Leerlauf konstant).
6. *(optional, nur falls Schwungscheiben montierbar)* Schwungrad-Demo: bei laufender Regelung S → L wechseln (Motor kurz stoppen!),
   Re-Adaption beobachten; danach L → S.

**Akzeptanz:** ω folgt ω_ref ohne bleibende Regelabweichung; Parameter konvergieren;
nach Massenwechsel re-adaptiert der Regler.

---

## Sicherheits-Checkliste (jede Stufe mit Motor)
- [ ] Strombegrenzung am Netzteil aktiv (Start 0,5 A)
- [ ] gemeinsame Masse ESP32 ↔ L298N ↔ Netzteil
- [ ] Encoder an **3,3 V** (GPIOs nicht 5V-tolerant)
- [ ] ENA-Jumper am L298N entfernt
- [ ] Motor mechanisch fixiert (Schwungscheibe **falls montiert**)
