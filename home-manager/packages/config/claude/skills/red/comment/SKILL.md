---
name: comment
model: opus
effort: low
description: Formulate any text that goes out to other people in the user's name — Gitea PR comments, line comments, replies to review comments, review bodies, Jira comments — and decide first whether anything gets posted at all or a 👍 is enough. Sober, direct, one to three sentences, no hedging, no reasoning chains. Two delivery modes — paste (the user posts, no marker) and post (Claude posts via MCP, mandatory `_Written by AI_` marker). Never posts itself; returns the finished text to the calling skill. Load before any skill or agent writes a comment for Gitea or Jira (e.g. "formulier die Antwort", "was schreiben wir in den PR", "Kommentar fürs Ticket").
argument-hint: "<channel> <mode> <occasion>: what happened, who reads it, what they need to know"
allowed-tools: Read Grep Glob
---

# Comment (red / work)

Produce a comment that respects the reader's time: one to three sentences that say
what the reader needs and cannot see in the diff or the ticket. The skill writes
text and returns it. **It posts nothing itself.**

Two delivery modes, set by the caller:

- **`paste`** — the user posts the text under their own name (e.g. from a
  `/review` file). No marker. The user has read and adopted the text.
- **`post`** — Claude posts the text directly via MCP. **Last line is always
  `_Written by AI_`**, alone, after a blank line. No exception, not for a
  one-liner, not for a bare link. Without the marker the text is not finished.
  Keep the underscores, they render italic in Gitea Markdown and Jira wiki alike.

If the caller does not say, assume `paste`.

## Voice

The register is the user's own short comments, stripped of softeners: „Bleibt so,
der Wert kommt aus der Validierung.", „Sind migriert.", „Hab das als eigenes
Ticket angelegt: <Link>". Direct, Du-Form as in the team, in the language of
the thread (German when the ticket or PR is German, otherwise English). The marker
stays English.

- **Sober, not soft.** No „Ich glaube", „vermutlich", „eventuell", „oder?",
  „vielleicht wäre es besser". Say what is wrong or what the question is. A
  genuine question is asked as a plain question, not wrapped in a hedge.
- **No emoji, no small talk, no thanks, no apology.** No self-description
  („ich habe geprüft", „bewusst", „sauber", „verifiziert").
- **Optional is stated as a fact, not as a plea.** „Kein Muss." or „Kann ein
  eigenes Ticket werden." are allowed as a single short sentence when the point
  is genuinely out of scope. Nothing beyond that.
- **Trivia carries `nit:`** in front. Everything else carries no tag, no
  severity, no `F<n>` id.

## Hard rules

- **One to three sentences.** Hard cap four. More only when the user explicitly
  asks for more on this exact comment, then at most six.
- **A comment is not documentation.** Test plans, queries, tables, step lists,
  verification logs go to a file in the repo, an attachment or a wiki page. The
  comment points at it in one sentence.
- **Deeper analysis stays out of the comment.** In `paste` mode it belongs in the
  `Kontext` block of the review file. If the point cannot stand without it, add
  it as a clearly attributed, explicitly optional block after the short comment
  („Laut KI …", „Muss nicht übernommen werden:"). In `post` mode the marker
  already attributes, so the block is just a second paragraph, and the six
  sentence cap applies to the whole text.
- **No punctuation decoration:** no em or en dashes, no semicolons, no
  parentheses with asides, no colon lead-ins like „Umgesetzt:" or „Vorschlag:".
  One thought, one sentence, one full stop.
- **No formatting:** no headings, no bold, no lists. Exception: the content *is* a
  list (tasks to tick off) or a replacement text the reader is meant to copy.
  Code only when the reader should copy it.
- **At most two identifiers** (class, method, file, column, config key): one to
  locate the spot and, if the fix is a rename or an existing class to use, one for
  the replacement. Never test method names, line numbers or call chains. When
  naming existing code as the fix, use its real name, not a paraphrase.
- **State the consequence, not the derivation.** A finding names what goes wrong
  and, if it is not obvious, the fix. A reply to a review point explains only a
  deviation or a rejection, in one verifiable sentence. Whoever did what was asked
  does not explain why it works.
- **No question the user can answer themselves.** „Sag Bescheid, wenn du
  getrennte Codes willst" goes to the user in the chat, not into the PR. Only
  what the other side genuinely has to decide goes into the PR, as exactly one
  question.
- **No correction chains.** Check before posting, then post. If an earlier
  comment turns out wrong, there is exactly one correction and its first sentence
  says what was wrong. No „Nachtrag zu meiner Antwort oben".
- **No repetition** of the comment being answered, no restating what the diff
  already shows.

## Decide first whether to post at all

The most common mistake is not the wrong text but a text nobody needed.

| Situation | Action |
| --- | --- |
| Review point implemented exactly as written | **👍 only** on the comment. No text. |
| Implemented differently, or with a consequence the reviewer must know | 👍 **and** text |
| Not implemented, stays as is | text, no 👍 |
| The reviewer has to decide something before work can continue | text with exactly one question, no 👍 |
| Intermediate state nobody is waiting for | **post nothing** |
| Process step others must see (PR is up, test done, script ran) | one sentence in Jira |
| The result is a document | store the document, one sentence with the reference |
| Review finding on a re-review round | only if it would hold up the merge, otherwise nothing |

A 👍 carries no marker. It is therefore allowed only for the one case where it
claims nothing beyond „done, can be checked".

## Templates

All examples are fictional. `<…>` gets replaced, the rest is the template. The
marker is shown for `post` mode and is dropped in `paste` mode.

**Review finding on code.** The problem in one sentence. A second sentence with
the fix only if it is not obvious. Questions as questions, without accusation.

```
each() überspringt hier Zeilen, weil dieselbe Spalte gefiltert und geändert wird.
eachById() verwenden.

_Written by AI_
```

```
Die Middleware hat keinen Effekt, die Liste in der Config ist statisch leer.
Brauchen wir sie?

_Written by AI_
```

```
nit: der Name sagt nicht, wofür die Terminals auswählbar sind.

_Written by AI_
```

**Review finding with attributed deep-dive (`paste` mode).** Short comment, then
the optional block.

```
Histogram statt Gauge, dann lässt sich die Verteilung abfragen.

Laut KI, muss nicht übernommen werden:
<Detailblock, gern mit PromQL-Beispiel>
```

**Implemented differently.** First what applies now, then one sentence why not as
asked.

```
Zusammengelegt zu einer Regel statt zwei, die zweite hätte denselben Zustand ein
zweites Mal geprüft. Heißt jetzt <Name>.

_Written by AI_
```

**Stays as is.** The reason must be verifiable, not persuasive.

```
Bleibt so. Der Zweig läuft nur, wenn kein anderer Mandant mehr übrig ist, dann
gibt es keinen Weg mehr zu diesem Konto.

_Written by AI_
```

**Question to the reviewer.** What is already settled in one sentence, then the
question.

```
Im Ticket steht nur der aktive Fall. Soll das auch für abgelaufene Verträge
gelten?

_Written by AI_
```

**Review body.** Only when there is a point beyond the line comments. Otherwise
the body stays empty.

```
Die Code-Kommentare in diesem PR bitte gegen die Kommentar-Richtlinie prüfen,
die meisten beschreiben, was der Code schon sagt.

_Written by AI_
```

**Status in Jira.** Past tense, one sentence, where it happened.

```
Skript auf develop und dem Aufrufkontext-Testserver ausgeführt.

_Written by AI_
```

**PR link in Jira.** Only the link.

```
https://<forge>/<owner>/<repo>/pulls/<nr>

_Written by AI_
```

**Message to a person in Jira.** Mention, core in two to three sentences, at most
one question, no greeting.

```
[~<user>], die Adresse wurde gelöscht, nicht umgezogen, deshalb lässt sie sich
nicht neu registrieren. Der bisherige Inhaber muss die Reaktivierung beim
Anbieter beantragen, danach können wir sie importieren. Gibt es dafür schon
eine Anleitung?

_Written by AI_
```

**Handing over a document.**

```
Testplan zum PR als Anhang: testplan-<ticket>.md. Priorität haben die Fälle
2a bis 4.

_Written by AI_
```

**Correction.** Exactly one, first sentence names the error.

```
Die Aussage oben zum Timeout war falsch, der Job-Timeout hat Vorrang vor dem
Worker-Timeout. Steht jetzt auf 70 Sekunden wie bei den anderen Update-Jobs.

_Written by AI_
```

## Before and after

> Brauchen wir diese Middleware und den dazugehörigen Config Eintrag? In der
> Config ist es eine statische leere Liste, das hat also keinen Effekt.

```
Die Middleware hat keinen Effekt, die Liste in der Config ist statisch leer.
Brauchen wir sie?
```

> Die `CollectorRegistry` wird im `MessageBrokerServiceProvider` quasi identisch
> nochmal gebaut. Vielleicht wäre es besser, diese nur einmal als Singleton zu
> definieren anstatt sie hier an die ServiceProvider-Instanz zu hängen.

```
Die CollectorRegistry wird im MessageBrokerServiceProvider ein zweites Mal
gebaut. Einmal als Singleton registrieren.
```

> Sind die Tests bewusst in dem `Unit` Verzeichnis gelandet? Ich glaube die
> Trennung wurde bisher nicht absolut konsistent durchgezogen …

```
Die Tests unter Unit nutzen die Datenbank. Nach Feature verschieben.
```

> nit: Hier wäre eventuell auch ein Name mit `_count` passender, oder?

```
nit: das ist ein Zähler, also Suffix _count.
```

> Umgesetzt in `9385bda5e`: es gibt jetzt eine Gauge `..._expiration_status`,
> deren Wert den Zustand kodiert — `1` = läuft bald ab, `2` = abgelaufen, aus dem
> neuen Enum … Beide Alert-Regeln bleiben getrennt und lesen dieselbe Metrik …
> Damit ist auch die Expression der Regel aus <Ticket> mitgeändert, die alte
> Gauge gibt es nicht mehr — das betrifft PR <nr>. Ein neuer Collector-Test …

```
Eine Metrik mit Zustandswert, beide Alarme lesen sie. Die alte Metrik ist weg,
das betrifft auch PR <nr>.

_Written by AI_
```

> Gelöscht, bis auf zwei Zeilen an `execute()`: warum das Paket vor den Dateien
> gelöscht wird (…). Wenn der Hinweis auch raus soll, nehme ich ihn mit.

The right action here was **no text**: delete the comment, set 👍. Whether the
rest should go too is a question for the user, not for the PR.

## Checklist before returning

Every point must hold, otherwise start over.

1. Does the reader need this text, or do they see it in the diff, the ticket or the 👍?
2. `post` mode: last line `_Written by AI_`, alone, blank line before it? `paste` mode: no marker?
3. At most three sentences (four hard cap, six on explicit request)?
4. No hedge words, no emoji, no thanks, no self-description?
5. No dash, semicolon, parenthesis, heading, bold, colon lead-in?
6. At most two identifiers, no test names, no line numbers?
7. No question the user could answer?
8. No reasoning except for a deviation, a rejection or a consequence not visible in the diff?
9. Not a follow-up to an earlier comment that was itself a follow-up?
10. Language of the thread?

## Return to the calling skill

The skill posts nothing. It returns exactly this, and the caller uses the text
**unchanged**, under whatever approval rules apply to the caller:

```
ACTION: text | reaction | nothing
CHANNEL: jira-comment | pr-comment | line-comment | review-body
MODE: paste | post
TEXT:
<the finished text, with marker in post mode, empty for reaction/nothing>
```

On `reaction` the caller sets 👍 on the named comment. On `nothing` the caller
does nothing and records why in its own report.
