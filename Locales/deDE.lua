--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- Dejunk: deDE (German) localization file. 
-- Translation by pas06 (https://wow.curseforge.com/members/pas06).

local AddonName, AddonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(AddonName, 'deDE')
if not L then return end

L["ADDED_ITEM_TO_LIST"] = "Gegenstand %s wurde zu %s hinzugef\195\188gt."
L["AUTO_REPAIR_TEXT"] = "Autom. reparieren"
L["AUTO_REPAIR_TOOLTIP"] = "Repariert automatisch Gegenst\195\164nde, sobald ein H\195\164ndlerfenster ge\195\182ffnet wird.|n|nPriorisiert Reparatur auf Gildenkosten, falls verf\195\188gbar."
L["AUTO_SELL_TEXT"] = "Autom. verkaufen"
L["AUTO_SELL_TOOLTIP"] = "Verkauft automatisch Schrottgegenst\195\164nde, sobald ein H\195\164ndlerfenster ge\195\182ffnet wird."
L["CHARACTER_SPECIFIC_TEXT"] = "Charakterspezifische Einstellungen"
L["CHARACTER_SPECIFIC_TOOLTIP"] = "Klicke hier, um zwischen globalen Einstellungen und charakterspezifischen Einstellungen umzuschalten."
L["COMMON_TEXT"] = "Gew\195\182hnlich"
L["DEJUNK_BUTTON_TOOLTIP"] = "Rechtsklick, um die Einstellungen zu \195\182ffnen."
L["DEJUNK_OPTIONS_TEXT"] = "[DEJUNK Einstellungen]"
L["EPIC_TEXT"] = "Episch"
L["EXCLUSIONS_TEXT"] = "Behalten"
L["EXCLUSIONS_TOOLTIP"] = "Gegenst\195\164nde auf dieser Liste werden niemals verkauft."
L["INCLUSIONS_TEXT"] = "Verkaufen"
L["INCLUSIONS_TOOLTIP"] = "Gegenst\195\164nde auf dieser Liste werden immer verkauft."
L["ITEM_ALREADY_ON_LIST"] = "%s ist bereits auf %s."
L["ITEM_CANNOT_BE_SOLD"] = "%s kann nicht verkauft werden."
L["NO_CACHED_JUNK_ITEMS"] = "Es wurden keine Schrottgegenst\195\164nde im Zwischenspeicher gefunden. Versuche es sp\195\164ter noch einmal."
L["NO_JUNK_ITEMS"] = "Es gibt keine zu verkaufenden Schrottgegenst\195\164nde."
L["ONLY_SELLING_CACHED"] = "Manche Gegenst\195\164nde konnten nicht abgerufen werden. Es werden nur bereits zwischengespeicherte Schrottgegenst\195\164nde verkauft."
L["POOR_TEXT"] = "Schlecht"
L["RARE_TEXT"] = "Selten"
L["REMOVED_ITEM_FROM_LIST"] = "%s wurde von %s entfernt."
L["REPAIRED_ALL_ITEMS"] = "Alle Gegenst\195\164nde wurden f\195\188r %s repariert."
L["REPAIRED_ALL_ITEMS_GUILD"] = "Alle Gegenst\195\164nde wurden f\195\188r %s repariert (Gilde)."
L["REPAIRED_NO_ITEMS"] = "Nicht genug Geld f\195\188r Reparatur."
L["SAFE_MODE_MESSAGE"] = "Sicherer Modus aktiviert: Es werden nur 12 Gegenst\195\164nde verkauft."
L["SAFE_MODE_TEXT"] = "Sicherer Modus"
L["SAFE_MODE_TOOLTIP"] = "Verkauft nur bis zu 12 Gegenst\195\164nde gleichzeitig."
L["SCROLL_FRAME_ADD_TOOLTIP"] = "F\195\188ge einen Gegenstand hinzu, indem du ihn in das untenstehende Fenster ziehst. (Gegenst\195\164nde k\195\182nnen nur von deinem Inventar aus hinzugef\195\188gt werden.)"
L["SCROLL_FRAME_REM_TOOLTIP"] = "Du kannst einen Gegenstand entfernen, indem du einen Eintrag markierst und mit der rechten Maustaste klickst."
L["SELL_ALL_TEXT"] = "Alle verkaufen:"
L["SELL_ALL_TOOLTIP"] = "Verkauft alle Gegenst\195\164nde von dieser Qualit\195\164t."
L["SILENT_MODE_TEXT"] = "Lautlosmodus"
L["SILENT_MODE_TOOLTIP"] = "Deaktiviert Dejunk-Chatfensternachrichten."
L["SOLD_YOUR_JUNK"] = "Dein Schrott wurde f\195\188r %s verkauft."
L["UNCOMMON_TEXT"] = "Ungew\195\182hnlich"
L["VENDOR_DOESNT_BUY"] = "Dieser H\195\164ndler kauft nichts."