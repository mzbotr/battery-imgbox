local awful=require("awful")
local wibox=require("wibox")
local naughty=require("naughty")
local battery={}
local adapter="BAT0" --<-- battery directory here.
battery.imgbx=wibox.widget.imagebox()
battery.txtbx=wibox.widget.textbox()
battery.limits={ {25,5},{12,3},{7,1},{0} }
-- Picutres discharging
battery_full=(awful.util.getdir("config").."/config/battery_full.png")
battery_thre=(awful.util.getdir("config").."/config/battery_thre.png")
battery_half=(awful.util.getdir("config").."/config/battery_half.png")
battery_low=(awful.util.getdir("config").."/config/battery_low.png")
-- AC Power adapter
battery_fullc=(awful.util.getdir("config").."/config/battery_fullc.png")
battery_threc=(awful.util.getdir("config").."/config/battery_threc.png")
battery_halfc=(awful.util.getdir("config").."/config/battery_halfc.png")
battery_lowc=(awful.util.getdir("config").."/config/battery_lowc.png")
-- Battery is out to lunch
ac=(awful.util.getdir("config").."/config/ac.png")

-- Ease of reference
battery.images={
	{battery_full, battery_fullc},
	{battery_thre, battery_threc},
	{battery_half, battery_halfc},
	{battery_low, battery_lowc},
	{ac}}

function battery.get_battery(adapter)
	assert((tonumber(adapter))==nil) -- Only strings allowed
	-- Throw an error if adapter is not there.
	local fcur=assert(io.open("/sys/class/power_supply/"..adapter.."/energy_now","r"),nil)
	local fcap=assert(io.open("/sys/class/power_supply/"..adapter.."/energy_full","r"),nil)
	local fsta=assert(io.open("/sys/class/power_supply/"..adapter.."/status","r"),nil)
	local cur=fcur:read()
	local cap=fcap:read()
	local sta=fsta:read()
	fcur:close()
	fcap:close()
	fsta:close()
	battery.state=math.floor(cur/cap*100)
	local placeholder={ "Charging", "Discharging" }
	for indx,neg in pairs(placeholder) do
		if sta:match(neg) then
			battery.direction=neg
			if battery.direction:match(placeholder[2]) then
			  battery.dindex=1
			else
			  battery.dindex=2
			end
		end
	end
end

function battery.iterate_lims ()
	for indx,pair in pairs(battery.limits) do
		lim=pair[1]; step=pair[2]
		battery.cursor=battery.limits[indx+1][1] or 0
		if battery.state>battery.cursor then
			repeat
			 lim=lim-step
			until battery.state > lim
			if lim < battery.cursor then
			 lim=battery.cursor
			end
			return lim
		end
	end
end

function battery.callback(adapter)
	battery.cursor=battery.limits[1][1]
	-- Protected execution for get_battery under anonymous function call.
	-- If get_battery enters an error state (numeric input or disconnected
	-- battery), default to A/C condition.
	if pcall(function() battery.get_battery(adapter) end) then
		if battery.state <= battery.cursor then
			if battery.dindex==2
			  then print("bad shit pops up here")
			end
			battery.cursor=battery.iterate_lims()
		end
		battery.txtbx:set_text("| | "..battery.state.."%") 
		for indx,val in pairs(battery.limits) do
		  if battery.cursor==val[1] then
			battery.imgbx:set_image(battery.images[indx][battery.dindex])
		  end
		end
	else
		-- Adapter is no longer present at the expected directory.
		-- Default case for AC power and no battery.
		-- -- TODO: Set fields to nil here for wibox widgets (progress bars, timers)
		-- -- when relevant.
		battery.txtbox:set_text("A/C")
		battery.imgbox:set_image(battery.images[5][1])
	end
end
battery.callback(adapter)
battery_time=timer({timeout=5})
battery_time:connect_signal("timeout", function () battery.callback(adapter) end)
battery_time:start()
battery.imgbx:connect_signal(
	"mouse::enter",function() naughty.notify({
						text=battery.direction,
						timeout=1,
						hover_timeout=30,
						position="top_right"}) end)
return battery
