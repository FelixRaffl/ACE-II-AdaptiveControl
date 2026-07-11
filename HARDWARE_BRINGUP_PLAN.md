# Hardware Bring-up and Debug Plan

Stand: 2026-07-11

Dieses Dokument beschreibt die naechste Inbetriebnahme- und Debug-Reihenfolge fuer
den adaptiven DC-Motor-Regler auf dem ESP32. Ziel ist eine fachlich saubere,
nachvollziehbare und abgabereife Umsetzung.

## Zielbild

- Der Motor folgt einem kleinen Drehzahl-Sollwertsprung stabil.
- Encoder-Zaehler, Drehzahlberechnung, Richtungssignale und Reglerausgang sind
  einzeln nachvollziehbar.
- Offene Laborwerte werden gemessen und nicht geraten.
- Der Bericht trennt sauber zwischen Simulation, Designziel und realer Messung.

## Aktueller Reglerstand

Das aktuelle ESP32-Hardwaremodell verwendet bewusst ein Modell erster Ordnung:

```text
G(z) = b0 / (z + a0)
```

Geschaetzte Parameter:

```text
[a0, b0]
```

Reglerstruktur:

- RLS-Parameterschaetzung
- Polplatzierung fuer `q(z) = z^2 - 0.5 z + 0.06`
- inkrementeller PI-Regler
- Stellgroessenbegrenzung auf `[-255, 255]`
- Rueckfuehrung des saturierten Stellwerts als `u_prev`

Wichtige Parameter:

```text
T = 0.08 s
alpha = 0.98
P0 = 100 * I
xhat0 = [-0.5; 1.0]
b0Min = 1e-3
uMax = 255
```

## Modellordnung

### Erstes Ordnungssystem

Das aktuelle Hardwaremodell ist ein Modell erster Ordnung. Es ist die richtige
Basis fuer die erste stabile Inbetriebnahme, weil es weniger Parameter benoetigt
und Fehler in Encoder, Richtung, Skalierung und Rueckfuehrung schneller sichtbar
macht.

### Zweites Ordnungssystem

Ein Modell zweiter Ordnung ist ein moeglicher spaeterer Ausbauschritt:

```text
G(z) = (b1 z + b0) / (z^2 + a1 z + a0)
```

Dafuer werden benoetigt:

- 4-Parameter-RLS mit `[a1, a0, b1, b0]`
- Regressor mit `y(k-1)`, `y(k-2)`, `u(k-1)`, `u(k-2)`
- 4x4-Kovarianzmatrix
- RST-/Diophantine-Regler statt einfachem PI-Update
- numerische Schutzlogik fuer schlecht konditionierte Gleichungssysteme

Der Wechsel auf zweites Ordnungssystem sollte erst erfolgen, wenn die erste
Ordnung mit einem einfachen Sollwertsprung stabil laeuft.

## Empfohlene Inbetriebnahme-Reihenfolge

### 1. Open-loop Encoder- und PWM-Test

Zuerst den adaptiven Regelkreis umgehen oder stark entschaerfen.

Test:

- Positive PWM-Duty vorgeben.
- IN1/IN2 fest auf Vorwaertsrichtung setzen.
- Keine Rueckwaertsrichtung zulassen.
- Raw count `N` beobachten.
- `Delta N` beobachten.
- berechnetes `omega` beobachten.

Erwartung:

- Motor dreht in definierter Vorwaertsrichtung.
- Raw count `N` laeuft monoton in eine Richtung.
- `Delta N` ist ueberwiegend positiv.
- `omega` ist positiv und plausibel.

Wenn diese Stufe nicht sauber ist, den Regelkreis noch nicht schliessen.

### 2. CPR-Kalibrierung

Die Encoder-Skalierung muss im Labor gemessen werden.

Test:

- Welle exakt eine Umdrehung drehen.
- Aenderung von Raw count `N` ablesen.

Aktuelle Erwartung:

```text
CPR ca. 44 Counts/rev
```

Bekannte Unsicherheit:

```text
Ein vorhandenes Referenzmodell nutzte effektiv 11 Counts/rev.
```

Der gemessene CPR-Wert muss in den Gain eingetragen werden:

```text
omega = 2*pi*DeltaN / (T*CPR)
```

Betroffene Modelle:

- `encoder_test.slx`
- `adaptive_dcmotor.slx`

### 2b. Statische Drehzahlkennlinie

Vor dem Schliessen des Regelkreises die statische `duty -> omega`-Kennlinie des Motors
ohne Schwungscheibe aufnehmen.

Test:

- IN1/IN2 fest vorwaerts.
- `duty` in Stufen erhoehen (z.B. 0, 20, 40, 80, 160, 255).
- Pro Stufe `omega` ablesen und protokollieren.

Auszuwertende Werte (im Labor messen, nicht raten):

- Losbrech-Duty (kleinste Duty mit omega > 0)
- minimale stabile Drehzahl `omega_min`
- Duty-Bereich, ab dem omega naeherungsweise linear steigt

Bedeutung:

- Der Closed-loop-Sollwert muss oberhalb `omega_min` liegen. Ein Sollwert darunter ist
  mit dem blossen Motor stationaer nicht fahrbar und erzeugt einen Start-Stall-Grenzzyklus,
  der kein Reglerfehler ist.

### 3. Closed-loop mit einzelnem Sollwertsprung

Erst nach sauberem Open-loop-Test:

- `omega_ref = 0` starten.
- Monitor-and-Tune starten.
- `omega_ref` einmal auf ca. `30 rad/s` setzen.
- Wenn stabil, danach `50 rad/s` testen.

Zu beobachten:

- `omega_ref`
- `omega`
- `Raw count N`
- `Delta N`
- `u`
- `e`
- `a0_est`
- `b0_est`
- `traceP`
- IN1/IN2 oder `sign(u)`

Ein einzelner Sollwertsprung ist der erste sinnvolle Closed-loop-Test. Eine
Pulse-Folge wird erst danach verwendet.

### 4. Pulse- oder Step-Folge

Eine wiederholte Anregung ist fuer die adaptive Schaetzung sinnvoll, aber erst
nach erfolgreichem Unit-Step-Test.

Moegliche Sollwerte:

```text
0 <-> 50 rad/s
30 <-> 80 rad/s
```

Empfohlene Periodendauer:

```text
8 s bis 16 s
```

## Diagnose bei Richtungswechseln

Beobachtung:

- Sollwert ist positiv, z.B. `omega_ref = +30 rad/s`.
- Der Motor wechselt trotzdem dauernd die Richtung.
- Die gemessene Drehzahl erreicht den Sollwert nicht.

Bewertung:

Das ist fuer den ersten Bring-up nicht normal. Bei positivem Sollwert sollte der
Motor im einfachen Test nicht dauernd rueckwaerts schalten.

Wahrscheinliche Ursachen:

- Encoder-Vorzeichen falsch.
- Encoder A/B vertauscht.
- Gain-Vorzeichen falsch.
- CPR-Skalierung falsch.
- `Delta N` enthaelt Spruenge oder Vorzeichenwechsel.
- `omega`-Messung hat grosse positive/negative Peaks.
- `u_prev` verwendet nicht den saturierten Stellwert.
- Regler wird geschlossen, bevor die Messkette korrekt ist.

Empfohlene Massnahme:

- Rueckwaertsrichtung fuer den Debug-Test sperren.
- `u` temporaer auf `[0, 255]` begrenzen.
- IN1/IN2 fest auf Vorwaertsrichtung setzen.
- Erst Motor, Encoder und Drehzahlsignal validieren.

## Diagnose bei Omega-Spikes

Beobachtung:

- Der Sollwert ist nahezu konstant.
- Das gemessene `omega` zeigt grosse positive und negative Spike-Pakete.
- Der Motor folgt nicht sichtbar dem Sollwert.

Bewertung:

Das deutet eher auf ein Mess- oder Skalierungsproblem hin als auf ein
Modellordnungsproblem.

Wichtiger Zusammenhang:

```text
omega_per_count = 2*pi / (0.08*44) = 1.785 rad/s pro Count
```

Bei kleinen Drehzahlen ist die Messung daher deutlich quantisiert. Grosse
positive und negative Spike-Pakete koennen entstehen durch:

- springende Encoder-Counts
- falsches A/B-Vorzeichen
- falschen CPR-Wert
- Richtungsflattern
- unguenstige `Delta N`-Berechnung
- Reset- oder Datentyp-Probleme im Encoderpfad

Naechster Scope sollte mindestens zeigen:

```text
Raw count N
Delta N
omega
u
IN1 / IN2 oder sign(u)
omega_ref
```

## Entscheidungsbaum

### Fall A: Raw count N ist nicht monoton im Forward-only-Test

Pruefen:

- Encoder A/B Verdrahtung
- Encoder-Versorgung mit 3.3 V
- gemeinsame Masse
- Encoder-Block-Konfiguration
- mechanischer Sitz des Motors

Der Regler bleibt offen.

### Fall B: Raw count N ist monoton, aber Delta N oder omega haben Vorzeichenwechsel

Pruefen:

- Unit Delay fuer `N_prev`
- Subtraktion `Delta N = N(k) - N(k-1)`
- Datentyp-Konvertierung
- Reset-Verhalten des Encoder-Blocks
- Vorzeichen des Gains

Der Regler bleibt offen.

### Fall C: Omega ist plausibel, aber u kippt staendig das Vorzeichen

Pruefen:

- Fehlerdefinition `e = omega_ref - omega`
- Saturation `[-255, 255]`
- Rueckfuehrung des saturierten `u` als `u_prev`
- b0-Guard
- Anfangswerte der Schaetzung
- Reglergains nach der ersten Schaetzung

Erst danach wieder bidirektionalen Betrieb freigeben.

## Dokumentations- und Code-Regeln

### Dokumentation

- Keine ungemessenen Hardware-Ergebnisse behaupten.
- Simulation, Designziel und reale Messung getrennt formulieren.
- Offene Laborwerte explizit als offen markieren.
- CPR, Encoder-A/B-Farben und Deadband nur nach Messung finalisieren.
- Die reale Abgabe verwendet den Motor ohne montierte Schwungscheibe.
- Der Traegheitswechsel S -> L -> S wird in der Simulation gezeigt.
- Keine Hinweise auf interne Arbeitsablaeufe in Abgabe-Dateien schreiben.
- Keine Annahmen als Fakten dokumentieren.

### Versionsverwaltung

- Commit-Messages, Branch-Namen und Tags fachlich neutral halten.
- Keine nicht fachbezogenen Autoren- oder Herkunfts-Trailer einfuegen.
- Vor der Abgabe Commit-Historie, Diffs und exportierte Dateien auf interne
  Arbeitsmetadaten pruefen.
- Falls ein Abgabearchiv erstellt wird, nur fachlich relevante Projektdateien
  aufnehmen und interne Planungs-/Arbeitsdateien ausschliessen.

### Code und Modellaufbau

- Aenderungen bevorzugt im Builder-Skript vornehmen:
  `matlab/build_stage_models.m`
- Generierte Simulink-Modelle nicht manuell auseinanderziehen, wenn die Aenderung
  im Builder abbildbar ist.
- Funktionen klar trennen:
  - Encoderpfad
  - Drehzahlskalierung
  - Regler
  - H-Bruecken-Mapping
  - Monitoring/Scopes
- Kommentare kurz, fachlich und zweckgebunden halten.

## Zulässige Aussagen fuer Bericht und Praesentation

Zulaessig:

- Das Hardwaremodell basiert aktuell auf einem Modell erster Ordnung.
- Die Simulation zeigt die Re-Adaption beim S -> L -> S-Traegheitswechsel.
- Der reale Bring-up prueft zuerst Motor ohne Schwungscheibe.
- `alpha = 0.98` ist fuer Re-Adaption in der Simulation besser geeignet als
  `alpha = 1.0`.
- Die Hardware-Einschwingzeit wird erst nach sauberer Messung bewertet.

Nicht zulaessig ohne Messdaten:

- Der reale Motor erreicht sicher 250 ms Einschwingzeit.
- Der reale Schwungradwechsel wurde gefahren.
- CPR ist sicher 44, bevor die Ein-Umdrehungs-Messung erfolgt ist.
- Die Encoder-Drahtfarben sind sicher, bevor Richtung und Zaehlsinn geprueft sind.

## Naechste konkrete Arbeitspakete

1. Bring-up-Scopes in `encoder_test.slx` und `adaptive_dcmotor.slx` ueber den
   Builder bereitstellen.
2. CPR-Kalibrierung und statische `duty -> omega`-Kennlinie im Labor aufnehmen.
3. `omega_min` bestimmen und den ersten Closed-loop-Sollwert oberhalb davon waehlen.
4. Forward-only Unit-Step mit `LowerLimit = 0` fahren und `0 -> 30 rad/s` nur nutzen,
   wenn 30 rad/s oberhalb `omega_min` liegt.
5. Erst nach erfolgreichem Step-Test `LowerLimit = -255` wiederherstellen und
   Pulse-Folge fuer die Demo aktivieren.
6. 2nd-order-Erweiterung nur als geplanten Ausblick behandeln, nicht als
   Voraussetzung fuer die aktuelle Abgabe.
