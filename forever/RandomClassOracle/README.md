# Random Class Dice

Minimal WoW Forever addon that rolls your next class when you level up, run out of rested XP, die or enter a rested area.

## Install

Copy the `RandomClassOracle` folder to your WoW Forever addons folder:

```text
World of Warcraft/_forever_/Interface/AddOns/RandomClassOracle
```

## How it works

When you level up or your rested XP runs out, the roll prompt pops up right away, anywhere, as long as you are out of combat. If you are in combat it waits until combat ends.

Level-ups only count from level 7 (dinging to 6 or below is ignored), and running out of rested XP only counts from level 6.

When you die, the roll prompt pops up once you are alive again (resurrected, or back at your corpse or a spirit healer). Deaths count at any level.

With "Wait until I'm in a rested area" enabled under Level up, a level-up does not prompt right away. The prompt shows when you enter a rested area afterwards, or right away if you level up inside one. The waiting level-up lasts through `/reload` but is dropped when you log out.

Entering a rested area (an inn or a city) can also show the roll prompt, from level 6. It is off by default. It only counts when you walk from outside a rested area into one, so already standing in one when you log in or `/reload` does not count. This prompt has the buttons "Roll dice" and "Keep playing" instead of "Roll" and "Skip". Choosing "Keep playing" means it does not show again until you leave and come back.

Each trigger (level-up, rested XP, rested area and death) can be turned on or off in the options. Turning a trigger off also drops a roll from that trigger that is still waiting.

## Time between prompts

Prompts need a minimum time between them, 30 minutes by default. The time counts from when you log in on the character and restarts every time you answer a prompt (roll or skip) or roll with `/rcd roll`. It lasts through `/reload` but starts over when you log in again. Set it to 0 in the options to turn it off.

Level-ups, running out of rested XP and entering rested areas during that time are ignored. A level-up waiting for a rested area is kept, and shows the next time you enter a rested area after the time has passed. Deaths always prompt.

The result window and chat show the rolled class together with "Log out at an inn if you can.", so the character you leave builds rested XP. That line is left out after a death when hardcore is enabled.

If you rolled outside a rested area, the first time you enter one afterwards you get "Noice, you're now in a rested-area. Time for <class>" on screen and in chat. It shows once per roll, only when the roll showed the inn line, and only during the current session.

Clicking "Skip" skips the roll entirely and restarts the time between prompts. The prompt does not come back.

Once you have rolled, no more roll prompts show for the rest of the session (until you log out or reload). Level-ups, running out of rested XP, deaths and entering rested areas in the meantime are ignored. Test rolls from `/rcd testding` and `/rcd testdeath` do not count.

A roll waiting for combat to end or for you to be alive again is saved per character, so it never pops up on another character. Class options, triggers, time between prompts, sound, hardcore and the minimap button are shared across the account.

## Minimap button

A dice button sits on the edge of the minimap. Left-click opens the result window, right-click opens a menu (roll, show result window, print last result, print status, sound, hardcore, options, reset pending roll, hide minimap button), and dragging moves it around the minimap. Hovering shows the last roll this session.

The button can be hidden with `/rcd minimap`, from its own menu, or from the options.

## Options

Options live in the game's AddOns settings under "Random Class Dice":

- **Random Class Dice:** sound, hardcore, show minimap button, which triggers show the roll prompt (level up with an optional wait for a rested area, rested XP runs out, entering a rested area, death), and minutes between prompts.
- **Classes:** which classes are included in rolls, plus "Enable All".

## Commands

```text
/rcd roll
/rcd result
/rcd options
/rcd minimap
/rcd testding
/rcd testdeath
/rcd show
/rcd status
/rcd sound
/rcd hardcore
/rcd reset
```

`/rcd roll` manually rolls a class anywhere and shows the result window. Both Paladin and Shaman are included regardless of your faction. It clears any pending roll and counts as this session's roll.

`/rcd result` prints the class from the last roll made since you logged in. It is empty until you have rolled this session.

`/rcd options` opens the addon's page in the game's AddOns settings.

`/rcd minimap` shows or hides the minimap button.

`/rcd testding` previews the level-up prompt without changing pending state.

`/rcd testdeath` previews the death prompt without changing pending state.

Every roll is fully random among the enabled classes, with no history. Death-triggered rolls exclude the class you died on. Level-up, rested XP, rested area and manual rolls can still choose your current class. If they do, the result says "Same class - keep going!" instead of the inn line, and the roll does not count as this session's roll, so the next prompt still shows.

`/rcd show` opens the result window.

`/rcd status` prints whether a roll is pending and why, whether WoW currently reports that you are in a rested area, the current rest state, your rested XP, whether you have rolled this session, whether hardcore is enabled, which triggers are enabled, and your zone/subzone.

`/rcd sound` toggles result sounds on or off.

`/rcd hardcore` toggles hardcore mode on or off. It can also be set in the options or the minimap menu. With hardcore enabled, the inn line is left out after a death. It is off by default.

`/rcd reset` clears any pending roll for the current character.
