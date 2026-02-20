# PresenceCore Flow Notes

## QueueOrPlay

1. Ensure Init() if frame not yet created.
2. Guard: unknown typeName, combat (pri < 4).
3. If active: higher/equal pri → interrupt current, PlayCinematic; lower pri → queue (dedup by type+title).
4. Else: PlayCinematic directly.

## PlayCinematic

1. Resolve colours (resolveColors); set fonts, text, divider.
2. Quest icon: show when quest-related, opts.questID set, user has icons enabled.
3. Discovery line: if pendingDiscovery and zone/subzone, show "Discovered".
4. Phase: crossfade if old layer visible, else entrance.
5. F:SetScript("OnUpdate", PresenceOnUpdate); F:Show().

## PresenceOnUpdate (entrance / hold / exit)

1. **entrance**: Staggered reveal (title → divider → subtitle → discovery); easeOut; after ENTRANCE_DUR → hold.
2. **crossfade**: Fade old layer, run entrance on new; after ENTRANCE_DUR → hold, reset old.
3. **hold**: Wait anim.holdDur → exit.
4. **exit**: Fade out (easeIn); after EXIT_DUR → onComplete.

## onComplete

1. Clear OnUpdate, reset layers, F:Hide().
2. If queue non-empty: pick highest-priority entry, remove, PlayCinematic.
