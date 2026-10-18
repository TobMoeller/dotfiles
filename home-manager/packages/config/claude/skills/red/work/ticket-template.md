---
ticket: RTM-0000
title: <Jira-Titel>
type: bug            # bug | story | task
jira_status: <Status aus Jira>
---

# RTM-0000 — <Titel>

## Ticket in einem Satz

<Das Problem oder Ziel, fachlich, mit Umfang: was betroffen ist und was nicht. Keine Klassennamen.>

## Hergang

<Von außen nach innen. Wer oder was stößt den Fall an (UI-Aktion, Endpoint, Scheduler, Job, Event), welche Klassen löst das in welcher Reihenfolge aus (`file:line` je Station), und an welcher Stelle der Kette setzt das Ticket an. Bei einem Bug: wo die Kette heute falsch abbiegt. Bei einer Story: wo die neue Kette anschließt und wo sie endet. Das ist zugleich die Vollständigkeitsprüfung: ein Ticket, das sich nicht als Kette rekonstruieren lässt, hat eine Lücke.>

**Nachgestellt** (nur Bug): <der konkrete Auslöser mit Eingaben, die falsche Wirkung, der bestehende Test, der rot werden müsste, oder „kein Test deckt den Pfad". Ruht das Ticket auf einem Vorfall: „Beleg steht aus, Abfrage unter Für Tobias" und die Frage dazu unter Fragen (Klasse Daten).>

## DoD

- [ ] <Akzeptanzkriterium oder SOLL-Aussage, wörtlich aus dem Ticket; nichts erfunden · Nachweis: <Testname>, sobald der Loop fertig ist>

## Scope

- in: <…>
- out: <…, je mit Grund; auch Geschwister-Stellen mit demselben Muster, die das Ticket nicht nennt>

## Einstieg und Hinweise

- <Die 3–6 Stellen, an denen die Arbeit beginnt, `file:line`, je ein Halbsatz warum>
- <Vorbilder im Repo (`file:line`), Regeln der berührten Pfade (Datei), was der Hinweis Dev im Ticket schon vorgibt>
- <Stolpersteine: Fixtures, Fakes, Vertragslimits der Test-DB, bekannte Eigenheiten aus work-brain `pipeline-stolpersteine`. Die Test-DB selbst ist kein Hinweis: `wt testdb` kennt jeder Agent>
- <Migration oder Seeder im Spiel? Dann hier: „nach dem Anlegen `wt testdb`">

## Fragen

<Nur wenn es welche gibt, sonst „keine". Eine Frage, die Tobias gesehen hat, wird nie gelöscht oder gekürzt. Entschieden: Überschrift bekommt „— entschieden: <Option> (<Datum>)", die Antwort steht wörtlich in der Antwort-Zeile mit Quelle.>

### Frage 1 · <Titel>

**Klasse:** Lücke | Aufwand | Nutzer | Daten | Produkt | Umbau
**Hergang:** <An welcher Stelle der Kette das Ticket X sagt oder voraussetzt und der Code Y zeigt. Von außen nach innen, zwei bis vier Sätze.>
**Optionen:** A: <das Ticket wörtlich> → <Folge> · B: <…> → <Folge>
**Empfehlung:** <Option>, weil <…> · Risiko: <das eigene Risiko der Empfehlung>
**Belege:** <`file:line`, Ticketstelle; Vermutungen als `Vermutet:` mit Prüfweg>
**Antwort:**

---

## Für Tobias

- [ ] <nur was nur Tobias tun kann: Abfrage auf Live, PO fragen, Externe> · vor dem Bauen | vor dem Deploy · Warum: <…>

## Entscheidungen

- <YYYY-MM-DD> · <Entscheidung in einem Satz, mit Beleg> (Quelle: Tobias | Orchestrator | Implementer | Refactorer | Review)
