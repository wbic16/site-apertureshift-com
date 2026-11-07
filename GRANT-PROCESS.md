# The XP Grant Process — audit, privacy, and compliance design

Will's rulings: completing all 18 Roads to the Future games grants XP → disk space on
edit.phext.io as a **Volumen-class Wavefront** grant (2026-11-07, task 33.5.7/7.6.9/6.5.8).
The process must be auditable, must not leak personal information, and must comply with
GDPR and US regulations (this doc, task 22.5.7/6.6.9/6.5.8). Historic entries are all
**Incipit-class** grants and stay classified that way.

## Design stance

The strongest compliance posture is the one the suite already has: **the games and the
hub collect nothing.** No accounts, no cookies, no analytics, no network calls, no
third parties. The grant process is built so that this remains true end to end — the
only place personal data exists at all is inside edit.phext.io's existing account
system, at the moment a holder chooses to redeem, under that service's existing
privacy terms. Everything below follows from keeping it that way.

## Data inventory (complete)

| Datum | Where it lives | Contents | Retention |
|---|---|---|---|
| Game progress / stars | Player's device, browser localStorage | Per-game progress values only | Until the player clears it (wipe control on the hub) |
| XP stamps | Player's device, hub localStorage | The 18 game slugs + a stamped/not flag. No names, no timestamps, no scores | Same — player-controlled |
| Claim code | Generated on-device at full completion; shown to the player | See construction below | Exists only where the player keeps it |
| Grant receipt | A file the player may choose to download | Stamp manifest, SHA-256 of the claim code, suite version, generation date | User-held; the page keeps no copy |
| Redemption record | edit.phext.io, inside the existing claim system | SHA-256 of the claim code, grant class (Volumen), tier, redemption date; linked to the redeeming account inside that service only | Per edit.phext.io's own terms |
| Public grant ledger | Append-only, published with the site repo | Code-hash prefix, grant class, month of redemption (coarsened). Nothing else | Permanent audit record — see GDPR note |

No other data exists in the process. There is nothing to leak: the complete list above
fits on one page, and none of it is sold, shared, or sent anywhere by the games or hub.

## Claim code construction (no personal information by construction)

- At full completion the hub generates a **random 128-bit nonce on the device**
  (crypto.getRandomValues). It is not derived from the player, the device, the time,
  or the play history.
- Claim code = base32(nonce) + a 4-character checksum taken from
  SHA-256(suite version ‖ stamp manifest ‖ nonce), so a mistyped or invented code
  fails checksum before it ever reaches the server.
- The code is a bearer instrument, like a gift card: whoever presents it after
  signing in at edit.phext.io receives the grant. It identifies **no one**.
- One redemption per code: the server stores the code's SHA-256 and marks it
  redeemed; the code itself is never stored.

## Auditability

- **Player side:** the receipt (above) lets a holder prove what they were issued,
  and re-verify the code's checksum from the manifest at any time.
- **Server side:** the redemption record (hash, class, tier, date) sits in the claim
  system; the code itself cannot be reconstructed from what is stored.
- **Public side:** the append-only ledger lists every grant — historic Incipit-class
  entries and Volumen-class entries in the same format — by hash prefix, class, and
  month. Anyone holding a code can hash it and find their entry; no entry can be
  traced to a person without the code.
- **Rules side:** this document, the hub's legal copy, and the task records live in
  version-controlled public repos; every change to the process is a dated commit.
- **Honesty note (recorded, not hidden):** stamps are self-attested — the player
  stamps a game when they finish it. Verifying play server-side would require
  accounts and tracking, which this process refuses by design. The accepted risk is
  bounded: the prize is a disk-space tier, each code redeems once, and the checksum
  blocks invented codes. The trust model is a deliberate, documented choice.

## GDPR mapping

- **Personal data in the games/hub: none.** Local, anonymous state (progress,
  stamps, a random nonce) is never transmitted and is not linked to any identified
  or identifiable person. GDPR's material scope is not engaged by the suite itself.
- **Local storage:** the stored items are strictly necessary for the functionality
  the user invoked (remembering progress and stamps on their own device) — the
  ePrivacy strictly-necessary exemption applies; the storage is nonetheless
  disclosed in plain words in the Privacy panel, and a wipe control is provided.
- **Redemption:** signing in and claiming at edit.phext.io processes account data
  under that service's existing privacy terms; lawful basis is the user's own
  request to receive the grant (Art. 6(1)(b) posture). Data minimization holds:
  the claim system stores a hash, not the code; the grant link to the account is
  visible only inside that service.
- **Erasure:** device-side state is erasable at any time by the player (wipe
  control; also cleared with browser data). The public ledger entry is a hash
  prefix of a random nonce — it cannot identify anyone on its own, which is why
  it can remain as a permanent audit record without defeating erasure of the
  account-side record.
- **No transfers, no processors, no profiling, no automated decisions** anywhere
  in the process.

## US regulations mapping

- **COPPA:** the suite is played by children, so the design rule is absolute —
  no personal information is collected from anyone, of any age: no accounts, no
  names, no contact details, no chat, no persistent identifier ever leaves the
  device or is used to track or contact a child. Progress lives on the family
  device under the family's control. Redemption is performed by an account
  holder at edit.phext.io, a separate service with its own sign-in.
- **CCPA/CPRA and state privacy laws:** nothing is collected, sold, or shared;
  there is no data to disclose, delete on request, or opt out of — stated plainly
  in the Privacy panel.
- **Accessibility:** the chassis already requires meaning never carried by color
  alone, ≥56px targets (larger in young bands), and screen-reader text for
  addresses; the hub Road Card and receipt follow the same rules (ADA/WCAG 2.1 AA
  posture for a public-facing site).

## Open items (Will's calls, flagged not assumed)

1. The Volumen tier's disk quota inside the claim system (claim mode already
   defines free tiers — e.g. found accounts at 100 MiB; the Volumen grant's
   amount is Will's to set there, not assumed here).
2. Whether redemption requires the approved-editors list or any signed-in
   edit.phext.io account.
3. Where the public ledger is published (site repo file is the default plan).
