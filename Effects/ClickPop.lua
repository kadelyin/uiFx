local Utils = require(script.Parent.Parent.Shared.Utils)

local ClickPop = {}

local INFO = TweenInfo.new(
	0.12,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out
)

local states = setmetatable({}, {
	__mode = "k"
})

function ClickPop.Bind(obj)
	if not obj:IsA("GuiButton") then
		return
	end

	if states[obj] then
		return
	end

	local original = obj.Size

	local pop = UDim2.new(
		original.X.Scale * 1.08,
		original.X.Offset * 1.08,
		original.Y.Scale * 1.08,
		original.Y.Offset * 1.08
	)

	local state = {}

	state.connection = obj.MouseButton1Click:Connect(function()
		Utils.Tween(
			obj,
			INFO,
			{Size = pop}
		)

		task.delay(0.12, function()
			if obj.Parent then
				Utils.Tween(
					obj,
					INFO,
					{Size = original}
				)
			end
		end)
	end)

	states[obj] = state
end

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