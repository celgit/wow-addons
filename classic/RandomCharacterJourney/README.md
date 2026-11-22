# Random Character Journey

WoW Classic leveling addon that generates a randomized character journey.

It does not replace quest guides and does not tell you which NPCs, quests, grind spots, or routes to use. It only gives the character a next chapter, usually a zone, and leaves the actual play decisions to you.

## Commands

- `/rcj generate` - abandon the active journey and create a new one
- `/rcj next` - add the next chapter
- `/rcj reroll` - replace the current chapter without discarding earlier chapters
- `/rcj history` - show previous journeys for this character
- `/rcj show` - open the small journey window

## Behavior

- Stores data per realm and character in `RandomCharacterJourneyDB`.
- Uses character level, class, race, faction, current zone, active journey, and previous journey history.
- Class affects probability, but does not lock characters into class-specific journeys.
- A first chapter uses level, current location, class themes, and journey history.
- Every later chapter requires either a physical zone connection or a deliberately written travel bridge.
- Chapter text explains the actual road, class memory, or story hook that made the transition eligible.
- Completed class quests can unlock personal story bridges. A paladin who completed the Verigan's Fist chain can, for example, remember the earlier road through Southshore.
- Remembers zones the character actually visits while the addon is active; personal memories outweigh ordinary geographical connections.
- Uses a conservative level window: starting zones remain available through level 11; other zones become available two levels above their listed minimum and remain available until three levels beyond their listed maximum.
- Shows optional Alliance-relevant dungeon detours without adding them as journey chapters. Dungeon suggestions use practical Classic level ranges with two additional safety levels rather than portal entry requirements.
- Recognizes the Southshore paladin memory from an active or completed Verigan's Fist chain, or from carrying Verigan's Fist.
- The journey window shows newest chapters first, marks the latest entry as current, and scrolls for longer journeys.
- Adds Blasted Lands and Burning Steppes to keep the eastern leveling routes connected at higher levels.
- Avoids paths that repeat previous journeys when another connected option is available.
- `Reroll Chapter` replaces only the current chapter, including the first one, and excludes the rejected zone from that roll. `/rcj generate` is the explicit way to start the whole journey over.
- Journeys are only generated or replaced when the player runs a command.

## Dungeon range sources

- [Wowhead Classic Dungeons Overview](https://www.wowhead.com/classic/guide/classic-dungeons-overview) for practical dungeon ranges and individual Scarlet Monastery wings.
- [Icy Veins WoW Classic Leveling Guide](https://www.icy-veins.com/wow-classic/leveling-guide) for Alliance dungeon progression, conservative entry guidance, and the distinction between efficient Alliance routes and merely enterable instances.
