-- ViewController: animated screen switching with a shared root container.

local ViewController = {
	_current = nil,
	_screens = {},
	_stack = {},
}

function ViewController.Init(screens)
	ViewController._screens = screens or {}
end

function ViewController.Show(name: string, ...): boolean
	local screen = ViewController._screens[name]
	if not screen then
		warn("[ViewController] no screen named " .. name)
		return false
	end
	local prev = ViewController._current
	if prev and prev ~= screen then
		prev:Hide()
	end
	for _, s in pairs(ViewController._screens) do
		if s ~= prev and s ~= screen and typeof(s.Hide) == "function" then
			s:Hide()
		end
	end
	ViewController._current = screen
	screen:Show(...)
	return true
end

function ViewController.Push(name: string, ...)
	table.insert(ViewController._stack, ViewController._current and ViewController._current.Name or nil)
	ViewController.Show(name, ...)
end

function ViewController.Pop()
	local prev = table.remove(ViewController._stack)
	if prev then
		ViewController.Show(prev)
	end
end

function ViewController.GetCurrentName()
	return ViewController._current and ViewController._current.Name or nil
end

return ViewController