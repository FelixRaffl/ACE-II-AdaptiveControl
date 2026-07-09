# Literaturrecherche — Adaptive Control

**Stand:** 2026-07-05 · **Zweck:** Einordnung unseres Projekts (RLS + Pole Placement + PI auf ESP32, ACE-II Example 7.6) in die Standardliteratur — was ist dort „richtig", was ist im Skript/Referenzmodell vereinfacht.

---

## 1. Wo unser Projekt in der Landkarte liegt

Die Literatur (seit Åströms Survey 1983) unterscheidet vier Grundansätze:

| Ansatz | Idee | Unser Projekt? |
|---|---|---|
| **Gain Scheduling** | Reglerparameter als feste Funktion messbarer Betriebsgrößen (Feedforward-Adaption, kein Lernen) | nein |
| **Model Reference Adaptive Control (MRAC)** | Referenzmodell definiert Wunschverhalten; Adaptionsgesetz (MIT-Rule/Lyapunov) minimiert Abweichung Modell↔Strecke — *direkt*, ohne explizite Streckenidentifikation | nein (aber: Găiceanu-Quelle unten) |
| **Self-Tuning Regulator (STR)** | Online-Identifikation (RLS) + Reglerentwurf nach dem Certainty-Equivalence-Prinzip in jedem Takt | **ja — indirekter STR** (RLS → Pole Placement → PI) |
| **Dual Control** | Stellgröße regelt *und* regt gezielt zur Identifikation an (stochastisch optimal) | nein (theoretisch elegant, praktisch kaum verwendet) |

Unser Aufbau ist damit ein Lehrbuch-STR nach Åström & Wittenmark (1973). Das 2nd-Order-Modell des Kollegen (4-Parameter-RLS + RST-Gesetz + Sylvester-System) entspricht Skript-Example 7.5 und dem „adaptive pole placement" in Landau et al.

## 2. Standardwerke (Bücher)

| # | Werk | Zugang | Warum relevant für uns |
|---|---|---|---|
| 1 | **Åström & Wittenmark: *Adaptive Control*, 2. Aufl.** (Addison-Wesley 1995, Dover-Reprint 2008) | Bibliothek / Dover günstig | *Das* Standardwerk zum STR (von den Erfindern). Kap. zu Real-Time-Estimation (RLS, Vergessensfaktor), Pole-Placement-STR, und ein eigenes Praxis-Kapitel (Start-up, Supervision, Windup, Bursting). |
| 2 | **Landau, Lozano, M'Saad, Karimi: *Adaptive Control — Algorithms, Analysis and Applications*, 2. Aufl.** (Springer 2011) | **frei: [arXiv:2406.07073](https://arxiv.org/abs/2406.07073)** (CC BY 4.0) | Beste frei verfügbare Gesamtdarstellung, durchgehend **zeitdiskret** (wie unser Projekt). Ausführlich: Parameter-Adaptions-Algorithmen inkl. Vergessensfaktor-Profilen, adaptive pole placement, Robustifizierung, Implementierung. |
| 3 | **Åström & Wittenmark: *Computer-Controlled Systems*, 3. Aufl.** (Prentice Hall 1997, Dover 2011) | Bibliothek / Dover | Nicht-adaptiv, aber die Grundlage: exakte ZOH-Diskretisierung (→ bestätigt unsere b₀-Korrektur), **RST-2-DOF-Struktur** und die Rolle von Nullstellen im geschlossenen Kreis (→ unser Überschwing-Befund). |
| 4 | **Ioannou & Sun: *Robust Adaptive Control*** (Prentice Hall 1995, Dover 2012) | frei: [Internet Archive](https://archive.org/details/ost-engineering-robust_adaptive_control) | Kontinuierliche Theorie; Referenz für **Robustheits-Modifikationen** (σ-Modification, Dead Zone, Projection) — relevant, sobald reale Störungen/unmodellierte Dynamik (L298N-Totzone, Quantisierung) auftreten. |
| 5 | **Sastry & Bodson: *Adaptive Control — Stability, Convergence, and Robustness*** (Prentice Hall 1989; freie überarbeitete PDF-Ausgabe vom Autor M. Bodson) | frei (Autorenseite Univ. of Utah) | Theorie-Referenz für **Persistent Excitation** und Konvergenzfragen (→ unser 2nd-Order-Parameterdrift). |
| 6 | **Ioannou & Fidan: *Adaptive Control Tutorial*** (SIAM 2006) | Bibliothek | Didaktische Aufbereitung, gute Einstiegsalternative zu 4. |
| 7 | **Goodwin & Sin: *Adaptive Filtering, Prediction and Control*** (Prentice Hall 1984, Dover 2009) | Bibliothek / Dover | Klassiker der zeitdiskreten adaptiven Regelung/Prädiktion. |
| 8 | **Isermann, Lachmann, Matko: *Adaptive Control Systems*** (Prentice Hall 1992) / R. Isermann: *Digitale Regelsysteme II* | Bibliothek | Deutsche Schule; praxisnah (Prozessautomatisierung). |

## 3. Schlüssel-Aufsätze (historische Linie)

1. Kalman (1958): *Design of a self-optimizing control system* — Uridee des selbstoptimierenden Reglers.
2. **Åström & Wittenmark (1973): *On self-tuning regulators*, Automatica 9** — Geburtsstunde des STR (Minimum-Variance-basiert).
3. Clarke & Gawthrop (1975): *Self-tuning controller* — verallgemeinerter STR.
4. **Åström (1983): [*Theory and applications of adaptive control — A survey*](https://www.sciencedirect.com/science/article/abs/pii/000510988390002X), Automatica 19(5), 471–486** — der klassische Überblick; MRAC und STR als zwei Seiten derselben Medaille.
5. **Rohrs et al. (1985): *Robustness of continuous-time adaptive control algorithms in the presence of unmodeled dynamics*, IEEE TAC** — das berühmte Gegenbeispiel: adaptive Regler ohne Robustifizierung können an unmodellierter Dynamik instabil werden → Auslöser der „robust adaptive control"-Welle (Bücher 4/5 oben).
6. Seborg, Edgar & Shah (1986): [*Adaptive control strategies for process control — A survey*](https://aiche.onlinelibrary.wiley.com/doi/abs/10.1002/aic.690320602), AIChE Journal — Anwendungsperspektive.

## 4. Vom Projektteam eingebrachte Quellen (Einordnung)

- **Găiceanu (2018): [*Matlab-Simulink-Based Compound Model Reference Adaptive Control for DC Motor*](https://cdn.intechopen.com/pdfs/58282.pdf)**, Kap. 7 in *Adaptive Robust Control Systems*, IntechOpen, DOI 10.5772/intechopen.71758 (CC BY 3.0).
  MRAC-Tutorial für den DC-Motor in Simulink, inkl. konventioneller Kaskadenregelung (Betrags-/Symmetrie-Optimum) als Vergleichsbasis und Stabilitätsnachweis des Adaptionsgesetzes. **Einordnung:** die *andere* Hauptschiene (MRAC, direkt) gegenüber unserem STR (indirekt) — gut als Abgrenzung/Ausblick und als Simulink-Referenz; verwendet **kein RLS** und kein Pole Placement, ist also kein direkter Vergleich zu Example 7.6.
- **MATLAB File Exchange 74917: [*Adaptive Control of DC Motor*](https://de.mathworks.com/matlabcentral/fileexchange/74917-adaptive-control-of-dc-motor)** (moh amed, 2020).
  Undokumentiertes Simulink-Modell (14.9 KB), Algorithmus nicht angegeben, Bewertung 2.0/5. **Einordnung:** als Literatur-/Zitierquelle ungeeignet; höchstens als Bastel-Vergleichsmodell nach Download-Prüfung.

## 5. Was die Literatur zu unseren konkreten Befunden sagt

| Befund aus unserer Simulation | Standardliteratur | Bewertung: richtig oder falsch? |
|---|---|---|
| **~42 % Überschwingen** trotz reeller Wunschpole (Nullstelle z₀ = −d₀/d₁ des PI im geschlossenen Kreis; Skript nennt es „phase error due to different numerator order") | 2-DOF-**RST-Struktur** mit T-Polynom/Referenzmodell ist der Normalfall des Pole-Placement-Entwurfs (Åström & Wittenmark *CCS* Kap. Pole Placement; Landau Kap. „Digital Control Strategies": tracking *and* regulation) | Skript/Referenzmodell sind **konsistent, aber vereinfacht** (1-DOF). Die Literatur würde die Führungsübertragung über ein T-Polynom/Vorfilter formen → genau unser Vorschlag F(z) = (1−z₀)/(z−z₀). Kein Fehler — eine bewusste Lehrbuch-Verkürzung. |
| **Wilde Start-Transiente** (u-Spikes ±900; 2nd Order: Ausschlag auf ~230) | „Praktische Aspekte"-Kapitel: Schätzer zuerst lernen lassen, Regler-Update verzögern/supervidieren; sinnvolle Initialisierung von P₀ und x̂₀ | Referenzmodell schließt den Kreis ab k = 0 → **nicht Stand der Praxis**. Skript-Example 7.5 macht es richtig (Pole Placement erst nach 50 Iterationen). Für den ESP32 übernehmen (Gain-Freeze ≈ 4 s). |
| **Vergessensfaktor α = 1.0** bei geplanter Schwungrad-Demo S → L | RLS mit α = 1: Adaptionsgain → 0, der Schätzer „schläft ein" und kann Parameteränderungen kaum noch folgen. Standard: α < 1 (typ. 0.95–0.99), variable/gerichtete Vergessensprofile oder Kovarianz-Reset (Landau, Kap. Parameter Adaptation Algorithms; Åström & Wittenmark *AC*) — Vorsicht: α < 1 ohne Anregung → „covariance windup"/Bursting | **Der kritischste Punkt fürs Projektziel:** Mit α = 1.0 wird die Adaptions-Demo (Schwungradwechsel im laufenden Betrieb) voraussichtlich **nicht** funktionieren — nach der Konvergenzphase reagiert RLS kaum noch. Empfehlung: α ≈ 0.95–0.99 **oder** Kovarianz-Reset beim Wechsel testen. |
| **2nd Order: RLS-Parameter driften**, konvergieren nicht zu den wahren Werten, Regelung funktioniert trotzdem | *Persistent Excitation*: n Parameter brauchen ausreichend reiche Anregung; Rechtecksignal + fast-Pol-Nullstellen-Kürzung ⇒ nicht identifizierbar. *Certainty Equivalence* erklärt, warum die Regelung dennoch funktioniert (Sastry & Bodson; Landau; Åström 1983) | **Bekanntes, dokumentiertes Verhalten** — kein Bug. Wer echte Parameterkonvergenz will, braucht reichere Anregung (z. B. PRBS-Overlay). Für die Regelung nicht nötig. |
| **b₀ = Km/J im Skript** vs. RLS-Konvergenz auf 0.0767 | Exakte ZOH-Diskretisierung (Tabellen in *Computer-Controlled Systems*): b₀ = (Km/b)(1 − e^(−bT/J)) ≈ Km·T/J | **Skript-Formel ist vereinfacht/fehlerhaft** (Faktor T fehlt). Unsere Simulation bestätigt den exakten Wert. Praktisch egal: RLS schätzt ohnehin den wahren Wert. |
| **u-Sättigung ±255 auf ESP32** nicht in der Simulation | Anti-Windup bei inkrementellen Reglern: saturiertes u als u(k−1) zurückführen (Åström & Wittenmark *AC*, Praxis-Kapitel) | In `firmware_model/PI_C.m` bereits **korrekt vorgesehen** ✅ |

## 6. Leseempfehlung (priorisiert)

1. **Einstieg/Überblick** (~2 h): Åström (1983), Survey — oder Kap. 1 aus Landau ([arXiv:2406.07073](https://arxiv.org/abs/2406.07073), frei).
2. **Unser Algorithmus verstehen**: Landau, Kapitel zu Parameter Adaptation Algorithms (RLS, Vergessensfaktoren!) und zu Adaptive Pole Placement — direkt auf unser Projekt übertragbar, zeitdiskret.
3. **Skript nochmal lesen** mit diesem Hintergrund: `aut5.pdf` S. 101–107 (Examples 7.5/7.6) — die Vereinfachungen fallen dann sofort auf.
4. **Kontrast MRAC**: Găiceanu (2018) überfliegen — zeigt, wie dieselbe Aufgabe (DC-Motor) ohne explizite Identifikation gelöst wird.
5. **Bei Hardware-Problemen** (Rauschen, Totzone, Instabilität): Robustifizierungs-Kapitel in Ioannou & Sun bzw. Landau.

---

*Erstellt im Rahmen der Simulations-Verifikation (siehe [README.md](README.md), Abschnitt „Simulation results"). Die Tabelle in §5 verbindet die Literatur mit den dort dokumentierten Messwerten.*
