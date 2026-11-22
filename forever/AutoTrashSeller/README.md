# Auto Trash Seller

Minimal WoW Forever addon that automatically sells your trash when you open a merchant, and lets you decide what counts as trash.

## Install

Copy the `AutoTrashSeller` folder to your WoW Forever addons folder:

```text
World of Warcraft/_forever_/Interface/AddOns/AutoTrashSeller
```

## How it works

When you open a merchant, everything in your bags that counts as trash is sold automatically. Items are sold in small batches so none get lost, cheapest first. That way the most valuable items are sold last and are the ones left in the buyback tab. When it is done, chat lists every item that was sold, one per line with stack size and value, cheapest first. Only items that actually sold are listed, and the last line shows the total for the listed items. If something was sold by mistake, you can buy it back, but keep in mind that the buyback tab only holds the last 12 items, which are the last 12 lines in the list.

By default, grey (poor quality) items are trash and everything else is kept. Items without a sell value are never sold.

Ctrl+right-click an item in your bags to change that:

- On a grey item, it is marked as **keep** and will never be sold.
- On a non-grey item, it is marked as **trash** and will be sold.
- Ctrl+right-clicking a marked item again removes the mark, and the item goes back to the default.

Chat confirms every change. Marks apply to the item type, not the single item in your bag. Marking one Ruined Leather Scraps as keep means all Ruined Leather Scraps are kept, now and in the future. Items with random suffixes ("of the Bear", "of the Eagle") share the same type, so marking one variant marks all of them.

Marks are saved per character, since an item can be useful for one character's professions and trash for another. Grey items count as trash by default on every character, so only your own marks need to be made again on each character.

## Bag icons

Items that will be sold show the vendor value of the whole stack in the middle of the slot. Other items show no value, so check the tooltip when deciding whether to vendor or keep something. The value uses the highest coin type with two decimals for the next one, colored to match:

- 45 copper is shown as `45c`
- 1 silver 45 copper is shown as `1.45s`
- 3 gold 22 silver 15 copper is shown as `3.22g`
- Even amounts drop the decimals, so 1 silver is shown as `1s`

Items that will be sold get a coin icon. Everything else has no icon, so a grey item without a coin is one you have marked as keep. The item tooltip also shows the item's mark.

## Commands

```text
/ats list
/ats reset
```

`/ats` on its own lists the commands. `/autotrashseller` works the same as `/ats`.

`/ats list` prints all items marked as keep or trash.

`/ats reset` clears all marks, so every item goes back to the default.
