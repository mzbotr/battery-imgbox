Another laptop battery widget for awesome wm. Work in progress, but it will update battery status/absence with a small picture.

Meant to be used with awesome wm >= 3.5.
To add to the systray in rc.lua, drop the file and foler into 
${HOME}/.config/awesome/ and add the lines...
local battery=require("battery")
...
left/right_layout:add(battery.imgbx)
left/right_layout:add(battery.txtbx)

