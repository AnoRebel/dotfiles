require("git"):setup()

require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})

require("folder-rules"):setup()

require("current-size"):setup({
	equal_ignore = { "~", "/", "/home" }, -- full path match
	-- sub_ignore = {"~/deskenv/master","~/deskenv/dev"} -- sub path match
})

function Status:name()
	local h = self._tab.current.hovered
	if not h then
		return ui.Line({})
	end

	local linked = ""
	if h.link_to ~= nil then
		linked = " -> " .. tostring(h.link_to)
	end
	return ui.Line(" " .. h.name .. linked)
end
