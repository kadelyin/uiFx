local Utils = require(
	script.Parent.Parent.Shared.Utils
)

local ClickPop = {}

---------------------------------------------------------------------
-- EFFECT REGISTRATION
---------------------------------------------------------------------

ClickPop.Name = "ClickPop"
ClickPop.Tag = "ClickPop"

---------------------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------------------

local INFO = TweenInfo.new(
	0.12,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out
)

local SCALE = 1.08
local RETURN_DELAY = 0.12

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------

local states = setmetatable({}, {
	__mode = "k",
})

---------------------------------------------------------------------
-- BIND
---------------------------------------------------------------------

function ClickPop.Bind(obj)
	if not obj:IsA("GuiButton") then
		return
	end

	if states[obj] then
		return
	end

	local original = obj.Size

	local pop = UDim2.new(
		original.X.Scale * SCALE,
		original.X.Offset * SCALE,

		original.Y.Scale * SCALE,
		original.Y.Offset * SCALE
	)

	local state = {
		original = original,
		pop = pop,
	}

	state.connection =
		obj.MouseButton1Click:Connect(function()
			if not obj.Parent then
				return
			end

			Utils.Tween(
				obj,
				INFO,
				{
					Size = state.pop,
				}
			)

			task.delay(
				RETURN_DELAY,
				function()
					if not obj.Parent
						or states[obj] ~= state
					then
						return
					end

					Utils.Tween(
						obj,
						INFO,
						{
							Size = state.original,
						}
					)
				end
			)
		end)

	states[obj] = state
end

---------------------------------------------------------------------
-- UNBIND
---------------------------------------------------------------------

function ClickPop.Unbind(obj)
	local state = states[obj]

	if not state then
		return
	end

	if state.connection then
		state.connection:Disconnect()
	end

	states[obj] = nil
end

return ClickPop