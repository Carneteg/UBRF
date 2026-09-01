# UBRF Pull Request

> Följ `docs/DELIVERY-PROTOCOL.md`. Implementerande agent får inte själv slutgodkänna PR:n.

## Status

- [ ] `DRAFT`
- [ ] `IMPLEMENTING`
- [ ] `IMPLEMENTED`
- [ ] `AUTOMATED_GREEN`
- [ ] `READY_FOR_CHATGPT_REVIEW`
- [ ] `CHANGES_REQUESTED`
- [ ] `READY_FOR_PRODUCT_ACCEPTANCE`
- [ ] `PRODUCT_ACCEPTED` — **endast Tobias**

## Acceptance Contract

### Goal
Vad ska spelaren/användaren konkret uppleva när detta är rätt?

### Observed state
Vad är faktiskt fel/saknas i basbranchen?

### Source of truth
Vilka produktbeslut, filer, data, foton, filmer, planer eller andra verifierade källor styr?

### Required change
Vad måste ändras?

### Out of scope
Vad ska uttryckligen inte byggas i denna PR?

### Acceptance tests
Vilka automatiska och manuella tester måste passera?

### Human gate
Krävs Tobias PASS i Roblox Studio, runtime, webb, visuell jämförelse eller game-feel-test? Beskriv exakt.

### Known uncertainty
Lista relevanta `VERIFIED` / `PLAN` / `FOTO` / `DERIVED` / `ASSUMPTION` / `REFERENCE GAP`.

---

## Changed

Exakta filer/system och deras ansvar.

## Source evidence

För fidelity: ange vilka bilder/filmer/planer som faktiskt granskats. Innan `REFERENCE GAP` får relevant råfilm i `references/video/` inte hoppas över.

## Tested

```text
<kommando> → exit <kod>
```

Runtime/Studio-observationer redovisas separat från headless tester.

## Falsified

Vilka medvetna mutationer gjordes för att visa att centrala tester verkligen blir röda?

| Mutation | Förväntat fel | Faktiskt utfall |
|---|---|---|
| | | |

## Not tested

Lista sådant som **inte faktiskt har verifierats**. Tom ruta betyder inte PASS.

## Remaining risk

Kända tekniska, produktmässiga, visuella eller datamässiga risker.

## Platform parity

Hur påverkas Roblox respektive HTML/webb? Om ej relevant, förklara kort varför.

## Human acceptance

- [ ] Ej relevant
- [ ] Krävs och väntar på Tobias
- [ ] Tobias PASS dokumenterat i PR:n

## Head SHA

`<exact-sha>`

---

### Merge gate

Merge först när relevant automatiserad gate är grön, blockerande ChatGPT-review är löst och eventuell human acceptance är utförd. Merge i sig betyder inte `PRODUCT_ACCEPTED`.
