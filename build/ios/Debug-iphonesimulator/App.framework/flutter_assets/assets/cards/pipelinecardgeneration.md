# Moira — Card Generation Pipeline

*The full technical and emotional specification for turning user words into cards.*

---

## Overview

Every card in Moira's collection is generated from something real the user said, felt, or did. The pipeline takes raw human input — a journal entry, a mirror conversation, a confession, a streak — and transforms it into a personal artifact she will keep forever.

Seven steps. No two cards the same. Ever.

---

## Step 1 — Signal detection

Every user action emits a typed signal. The system watches for these continuously.

| Signal type | Source feature | Example |
|---|---|---|
| Mirror message | Your Mirror conversation | "I don't think I've ever felt good enough" |
| Journal entry saved | Growth Log / ritual prompt | A completed evening wind-down with written reflection |
| Ritual completed | Daily Rituals | 7-day morning check-in streak closed |
| Confession flagged | Your Mirror | Message classified as first-time emotional disclosure |
| Growth log closed | Growth Log | An intention marked complete |
| Streak milestone | Any feature | 30-day consistency across rituals |

Signals carry: `source_feature`, `raw_text` (if applicable), `timestamp`, `user_id`, `session_context`.

---

## Step 2 — Emotional classifier

Claude reads the signal and classifies it across two axes: **card type** and **emotional weight score**.

Only signals scoring ≥ 5 proceed to card generation.

### Card type decision

| Detected pattern | Card type assigned |
|---|---|
| Recurring behavior or identity trait revealed | Character |
| A specific moment or date-stamped experience | Moment |
| Strength earned through sustained effort or difficulty | Power |
| A burden named, released, or recognized as not hers | Shadow |
| A unique personal breakthrough — no template fits | Legendary |

### Emotional weight scoring

| Signal quality | Score |
|---|---|
| Vulnerability language detected | +3 |
| First-time admission (not said before in session history) | +2 |
| Named emotion (not just described behavior) | +1 |
| Ritual consistency / streak milestone | +1 |
| Explicit breakthrough statement | +3 |

**Threshold to unlock: ≥ 5**

Legendary cards require a weight score of ≥ 9 AND a human-review flag before generation. They are rare by design.

---

## Step 3 — Inscription writer

Claude rewrites the user's words into the card's central truth — the inscription. This is the emotional core of the card. It is what she will screenshot. It is what will make her cry.

### Rules
- Second person ("you"), past or present tense
- 1–2 sentences maximum. Hard limit: 25 words
- Poetic, warm, unapologetic
- Her exact phrasing is preserved where it is already beautiful
- No clichés. No toxic positivity. No false resolution
- Shadow cards: do not resolve the pain — name it and honor it
- Legendary cards: reference the uniqueness of her journey explicitly

### System prompt

```
You are writing the inscription for a Moira card — a personal trading card 
unlocked through a moment of emotional growth or honest self-reflection.

Card type: {card_type}
Rarity: {rarity}
The user wrote or said: "{raw_text}"
Session context (if available): "{session_context}"

Your task:
Write one or two sentences in second person (you / your).
The inscription is a truth about this person, drawn from her own words.
It should feel like something she already knew but had never heard said out loud.

Tone: warm, poetic, unapologetic, grounded.
Not: clinical, therapeutic, motivational-poster, mystical-vague, falsely resolved.

Rules:
— Preserve her exact phrasing where it is already honest or beautiful.
— Do not explain. Do not comfort. Do not advise. Just name the truth.
— If this is a Shadow card: do not resolve the pain. Honor it as real.
— If this is a Legendary card: make clear this is specific to her journey.
— Maximum 25 words total.
— No quotation marks in your output. Just the inscription text.

Output only the inscription. Nothing else. No preamble. No label.
```

### Example

> User wrote: *"I kept apologizing for taking up space even in my own apartment"*
>
> **Inscription generated:** You apologized for existing in your own home. You do not do that anymore.

---

## Step 4 — Title generator

A second Claude call names the card. The title is what she remembers it by. It should feel like something earned — an archetype, a moment, a recognition. Never a label assigned to her.

### Rules
- 3–6 words
- Begins with "The" for Character, Moment, and Shadow cards
- Power and Legendary cards can break this convention
- Archetype-flavored but specific — not generic ("The Healer") but earned ("The Version Who Came Back")
- Never contains her name

### System prompt

```
You are naming a Moira card.

Card type: {card_type}
Rarity: {rarity}
Inscription: "{inscription}"
The user's original words: "{raw_text}"

Your task:
Write a card title — 3 to 6 words.
The title is what she will call this card forever.
It should feel like the name of something she earned, not a label assigned to her.

Tone: poetic, warm, archetypal. Specific, not generic.

Rules by card type:
— Character: a trait or identity recognized. E.g. "The Rebuilder", "The One Who Stayed"
— Moment: a specific experience named. E.g. "The Night She Stayed", "The Day She Stopped Waiting"
— Power: a strength earned through difficulty. Can drop "The". E.g. "Soft Strength", "The Long Way Through"
— Shadow: something released or named. E.g. "The Weight That Was Never Yours", "The Apology She Stopped Making"
— Legendary: one-of-a-kind. Must feel singular. E.g. "She Chose Herself First", "The Version No One Expected"

Output only the title. No punctuation at the end. No quotation marks. Nothing else.
```

### Example titles

| Card type | Example title |
|---|---|
| Character | The Rebuilder |
| Character | The One Who Stopped Shrinking |
| Moment | The Night She Stayed |
| Moment | The Day She Stopped Waiting |
| Power | Soft Strength |
| Power | The Long Way Through |
| Shadow | The Weight That Was Never Yours |
| Shadow | The Apology She Stopped Making |
| Legendary | She Chose Herself First |
| Legendary | The Version No One Expected |

---

## Step 5 — Image prompt builder

Claude converts the inscription and card type into a structured image generation prompt. The image is always abstract and symbolic — never a portrait, never a face, never text.

The art serves the words. Not the other way around.

### Image rules (hard constraints)
- No people. No faces. No bodies. No portraits.
- No text or lettering in the image.
- No AI-looking aesthetics — no lens flares, no HDR, no neon.
- Dark background always. The card palette bleeds into deep shadow.
- Abstract or symbolic scene only — candle, branch, knot, ripple, thread, light.
- Watercolor style: loose brushwork, layered washes, soft edges, grain.

### Color world per card type

| Card type | Background | Accent | Motifs |
|---|---|---|---|
| Character | Midnight plum `#12091c` | Gold `#c9a96e` | Candlelight, stars, small warm circles |
| Moment | Deep indigo `#0e0a14` | Rose `#d4a5a5` | Ripples, concentric circles, soft water forms |
| Power | Forest black `#080f06` | Sage `#7ab85a` | Single branch, upward growth, sparse leaves |
| Shadow | Void black `#0a0812` | Violet `#9b7dd4` | Knot unraveling, eye form, dissolving shape |
| Legendary | Dark amber `#0d0a05` | Gold `#edd48a` | Radiant burst, sun rays, center point of light |

### Image prompt template

```
Watercolor painting. Loose brushwork, emotional not precious. 
Painterly, layered washes, soft edges, fine grain texture.
Dark background: {bg_hex}.
Accent palette: {accent_palette}.
Scene: {symbolic_scene}
No people. No faces. No text. No portraits. No neon. No lens flare.
Subtle, warm, intimate. Like something painted for one person by hand.
Style reference: watercolor, expressionist washes, candlelight warmth, 
loose edges that don't resolve fully.
```

### Example symbolic scenes per type

**Character — "The Rebuilder"**
> A single candle in a very dark room. Warm gold wash bleeding into deep plum. The flame small but the light reaching further than expected.

**Moment — "The Night She Stayed"**
> Concentric rose-colored ripples expanding from a center point in dark indigo. Still, but moving. Like something just dropped into deep water.

**Power — "Soft Strength"**
> A single bare branch reaching upward in a forest-black space. Three small sage-colored leaves. Not abundant — just alive.

**Shadow — "The Weight That Was Never Yours"**
> A pale knot of thread slowly unraveling against a void-black background. Violet wisps at the edges. Nothing fully resolved. The knot still visible but loosening.

**Legendary — "She Chose Herself First"**
> A radiant burst of warm gold light from a single center point. Dark amber background. Rays soft and uneven, like they were painted by hand, not generated.

---

## Step 6 — Image generation

The prompt is sent to a generative image API. Output is cropped to card art dimensions, color-graded to match the card's palette, and composited into the card frame.

### Recommended stack

| Option | Model | Notes |
|---|---|---|
| Primary | FLUX.1 via fal.ai | Best watercolor fidelity, fast |
| Alternative | Stable Diffusion XL via Replicate | Good fallback, more controllable |
| Fallback | Static art library | 5 pre-made watercolors per type |

### Fallback strategy

If image generation fails, exceeds 8s, or returns an unusable output — serve a pre-made static art piece from the per-type library. The card is still 100% personal via inscription, title, and meta. The art is the cherry, not the cake.

**The user never waits. The card never fails to appear.**

---

## Step 7 — Card assembly and reveal

All fields are combined into the final card object, written to the user's deck in the database, and revealed with a deliberate slow-burn animation.

### Card object schema

```json
{
  "card_id": "uuid",
  "user_id": "uuid",
  "type": "shadow",
  "rarity": "rare",
  "number": 3,
  "title": "The Weight That Was Never Yours",
  "inscription": "You apologized for existing in your own home. You do not do that anymore.",
  "image_url": "cdn.moira.app/cards/u_sofia_003.webp",
  "color_world": "void_black_violet",
  "source_feature": "mirror_session",
  "source_text_preview": "I kept apologizing for taking up space...",
  "unlocked_at": "2026-02-08T21:34:00Z",
  "weight_score": 7,
  "is_legendary": false,
  "shared": false
}
```

### Reveal animation sequence

1. Card appears face-down. Slow pulse.
2. Flip begins. Art side revealed — blurred, sharpens over 2 seconds.
3. Inscription fades in line by line. 800ms delay between lines.
4. Her name and unlock date appear at the bottom. Fade in at 400ms.
5. Haptic feedback on mobile at each stage.
6. Card settles. Soft ambient sound optional.
7. "Tap to flip" prompt — back of card shows the source moment: *"You wrote this on February 8th."*

---

## Safety rails

| Rule | Applies to |
|---|---|
| Image prompt bans portraits, faces, people | All cards |
| Inscription tone guardrail — no toxic positivity, no spiritual bypassing, no false resolution | All cards |
| Shadow card confirmation gate: *"Are you ready to name this?"* — user must confirm before unlock proceeds | Shadow cards only |
| Legendary flag requires weight score ≥ 9 | Legendary cards |
| Source text is stored but never displayed in full — only a preview | All cards |
| Card generation is rate-limited: max 1 card per 24h per type | All cards |

---

## Key design principles

**The inscription comes before the image.** Write the truth first, then build the image to hold it. This is what separates Moira cards from AI-generated slop — the art serves the words.

**Her words seed the output.** Two users going through the same experience get completely different inscriptions and titles. The system preserves her specific phrasing wherever it is already honest or beautiful.

**Scarcity is sacred.** The weight threshold, the rate limit, and the Legendary gate exist to ensure that unlocking a card always means something. If everything unlocks a card, nothing does.

**The reveal is a ceremony.** The slow-burn animation, the flip, the fade — these are not decorative. They mark that something real just happened. The UX design communicates: *this was earned.*

---

*trymoira.app · trymoira.app/terms · trymoira.app/privacy*