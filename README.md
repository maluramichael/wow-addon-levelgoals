# wow-addon-levelgoals

Ein WoW-Addon (TBC Classic), das mir beim Leveln sagt, wie viel XP ich heute noch machen muss, um bis zu einem festen Datum ein Ziellevel zu erreichen.

## Was es macht
Ich trage Ziellevel und Stichtag ein, das Addon rechnet daraus das Tagesziel: fehlende XP geteilt durch verbleibende Tage. Läuft ein Tag schlecht, verteilt sich die Restmenge automatisch auf die übrigen Tage neu. Zusätzlich zeigt es, wie viel XP pro Stunde bis Mitternacht nötig wären.

Die Session startet pro Tag neu und überlebt ein `/reload`, weil Startlevel und Start-XP pro Charakter gespeichert werden. Bei jedem eingestellten Prozentschritt gibt es eine Meldung im Chat.

Es gibt ein normales Fenster und einen kompakten Modus, beide verschiebbar und optional feststellbar.

## Befehle
```
/lg              Fenster ein- und ausblenden
/lg compact      zwischen normalem und kompaktem Fenster wechseln
/lg session      Tages-Session neu starten
/lg config       Einstellungen öffnen
/lg reset        Fensterposition zurücksetzen
/lg hide         beide Fenster ausblenden
```

## Aufbau
- `Core.lua`: Addon-Logik, Berechnung und die beiden Fenster
- `XPData.lua`: XP-Tabelle pro Level, die aktuelle Stufe wird zur Laufzeit aus der API korrigiert
- `Config.lua`: Optionsseite für AceConfig

Gebaut auf Ace3. Die Bibliotheken liegen nicht im Repo, sie werden über die `externals` in `.pkgmeta` beim Packen dazugeholt.

## Installation
Ordner als `LevelGoals` nach `Interface/AddOns` legen. Ohne Packager fehlen die Ace3-Bibliotheken unter `libs/`, die müssen dann von Hand dorthin.
