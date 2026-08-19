local Utils = require(script.Parent.Parent.Shared.Utils)

local HoverLift = {}

local INFO = TweenInfo.new(
	0.12,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out
)

local states = setmetatable({}, {
	__mode = "k"
})

function HoverLift.Bind(obj)
	if states[obj] then
		return
	end

	local original = obj.Size

	local target = UDim2.new(
		original.X.Scale * 1.05,
		original.X.Offset * 1.05,
		original.Y.Scale * 1.05,
		original.Y.Offset * 1.05
	)

	local state = {
		original = original,
		target = target,
	}

	state.enter = obj.MouseEnter:Connect(function()
		Utils.Tween(
			obj,
			INFO,
			{Size = target}
		)
	end)

	state.leave = obj.MouseLeave:Connect(function()
		Utils.Tween(
			obj,
			INFO,
			{Size = original}
		)
	end)

	states[obj] = state
end

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