# tlrt

first release

* command "PANIC" - plays a sound and shows system message on screen
* command "WARNING" - plays a sound and shows red warning message on screen
* command "NOTIFY" - only plays a sound

use it in chat:

/p ::WARNING::das ist ne warnung

or in macros/addons

/run SendRaidMessage("WARNING", {"name1", "name2"}, "Hilfe !!!")  -- use #2 true to show to all raid members
