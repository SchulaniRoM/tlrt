# tlrt

version 1.08

* command "SYNC" silently informs other clients using tlrt
* "new" UnitIDs implemented to use "tank", "assist" and "attack" like "raid", "party" and so on.
  * it is working with TargetUnit, FollowUnit, FocusUnit and CastSpellByName
  * all (?) other implementations coming soon
* command "GIVELEAD" implemented but not activated - there are still problems with the concept

first release

* command "PANIC" - plays a sound and shows system message on screen
* command "WARNING" - plays a sound and shows red warning message on screen
* command "NOTIFY" - only plays a sound

use it in chat:

/p ::WARNING::das ist ne warnung

or in macros/addons

/run SendRaidMessage("WARNING", {"name1", "name2"}, "Hilfe !!!")  -- use #2 true to show to all raid members
