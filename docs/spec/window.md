# Window, sidebar, search and grouped lists

Inventory items ST-NAV-01 to ST-NAV-05. Diagram:
[diagrams/window-layout.svg](diagrams/window-layout.svg).

## Window (ST-NAV-01)

| Item | Value |
| --- | --- |
| Width | **832**, fixed |
| Height | resizable; **727** by default |
| Toolbar | **52**; a back / forward capsule (two 36 pt segments) at x 269, then the title of the current pane |
| Title in the sidebar column | none |

## Sidebar (ST-NAV-02)

| Item | Light | Dark |
| --- | --- | --- |
| Width | **261** (divider at x 261) | same |
| Material | translucent, ≈ `#e3e4e6` | ≈ `#323335` |
| Search field | **241 × 28** at the top | same |
| Account cell | 168 × 38 under the search field | same |
| Rows | pitch **32**, row buttons 24 tall | same |
| Icons | coloured rounded squares | same |
| Groups | separated by ≈ 13 pt of extra space | same |
| Selected row | accent-coloured capsule, white text | same |

With reduced transparency the sidebar becomes solid and the selection turns `#2565f1`
(see [accessibility.md](accessibility.md)).

## Search (ST-NAV-03)

- Typing replaces the sidebar list with results. Each result is a two-line row with the
  pane icon: the name of the setting, then the path to it (pane → sub-pane) in secondary
  gray.
- The field shows a 3 pt accent focus ring and a clear button while it has text.
- Esc clears the query and brings the pane list back.
- Highlighting of the matched characters: *unmeasured*.

## Grouped list (ST-NAV-04)

Every pane is built from the same grouped list.

| Item | Light | Dark |
| --- | --- | --- |
| Content background | `#ffffff` | `#272728` |
| Group inset | **20** from the content edges (531 wide in the 832 window) | same |
| Group fill | `#f7f7f7` | `#2d2d2e` |
| Group corners | rounded (radius *unmeasured*) | same |
| Navigation row (icon, title, chevron) | **48** tall, pitch 49 | same |
| Row separator | 1 pt `#efefef`, inset to start at the text | `#424243` |
| Value row (switch, pop-up, slider) | 36–44 tall | same |
| Gap between groups | ≈ 10 | same |
| Section heading | bold 13 pt, above its group | same |
| Secondary text | gray, under the row title | same |
| Switch | **36 × 16** track, 21 pt white knob, 16 pt from the trailing edge | same |

### Header cards

Several panes (accessibility, general, notifications, privacy, the assistant, search) open
with a header card: a group holding a large icon, the pane title and a short description
ending in a "learn more" link. The general pane centres a large icon with its title and
text instead.

## Transitions (ST-NAV-05)

Pane and sub-pane transitions were not recorded: *unmeasured*.
