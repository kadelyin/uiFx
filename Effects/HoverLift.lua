local Utils = require(
	script.Parent.Parent.Shared.Utils
)

local HoverLift = {}

---------------------------------------------------------------------
-- EFFECT REGISTRATION
---------------------------------------------------------------------

HoverLift.Name = "HoverLift"
HoverLift.Tag = "HoverLift"

HoverLift.Attribute = "HoverStyle"

HoverLift.AttributeValues = {
	Lift = true,
	HoverLift = true,
}

---------------------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------------------

local INFO = TweenInfo.new(
	0.12,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out
)

local SCALE = 1.05

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------

local states = setmetatable({}, {
	__mode = "k",
})

---------------------------------------------------------------------
-- BIND
---------------------------------------------------------------------

function HoverLift.Bind(obj)
	if states[obj] then
		return
	end

	if not obj:IsA("GuiObject") then
		return
	end

	local original = obj.Size

	local target = UDim2.new(
		original.X.Scale * SCALE,
		original.X.Offset * SCALE,

		original.Y.Scale * SCALE,
		original.Y.Offset * SCALE
	)

	local state = {
		original = original,
		target = target,
	}

	state.enter = obj.MouseEnter:Connect(function()
		if not obj.Parent then
			return
		end

		Utils.Tween(
			obj,
			INFO,
			{
				Size = state.target,
			}
		)
	end)

	state.leave = obj.MouseLeave:Connect(function()
		if not obj.Parent then
			return
		end

		Utils.Tween(
			obj,
			INFO,
			{
				Size = state.original,
			}
		)
	end)

	states[obj] = state
end

---------------------------------------------------------------------
-- UNBIND
---------------------------------------------------------------------

function HoverLift.Unbind(obj)
	local state = states[obj]

	if not state then
		return
	end

	if state.enter then
		state.enter:Disconnect()
	end

	if state.leave then
		state.leave:Disconnect()
	end

	states[obj] = nil
end

return HoverLift