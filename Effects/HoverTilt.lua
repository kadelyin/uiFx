local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Screen3D = require(
	game.ReplicatedStorage.controllers.Screen3D
)

local Utils = require(
	script.Parent.Parent.Shared.Utils
)

local HoverTilt = {}

---------------------------------------------------------------------
-- EFFECT REGISTRATION
---------------------------------------------------------------------

HoverTilt.Name = "HoverTilt"
HoverTilt.Tag = "HoverTilt"

HoverTilt.Attribute = "HoverStyle"

HoverTilt.AttributeValues = {
	Tilt = true,
	HoverTilt = true,
}

---------------------------------------------------------------------
-- DEFAULTS
---------------------------------------------------------------------

local DEFAULT = {
	FollowSpeed = 14,
	ReturnSpeed = 10,

	MaxYaw = 20,
	MaxPitch = 15,
	MaxRoll = 8,

	TopSensitivity = 0.8,
	BottomSensitivity = 1.1,

	ResponsePower = 1.25,
	SoftLimit = 0.98,

	Invert = false,
	DisplayDistance = 10,
}

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------

local states = setmetatable({}, {
	__mode = "k",
})

local active = {}

local screens = setmetatable({}, {
	__mode = "k",
})

---------------------------------------------------------------------
-- SCREEN 3D
---------------------------------------------------------------------

local function getScreen(gui, distance)
	local screen = screens[gui]

	if screen then
		return screen
	end

	local ok, result = pcall(
		Screen3D.new,
		gui,
		distance
	)

	if not ok then
		warn(
			"[UIEffects] HoverTilt Screen3D failed:",
			result
		)

		return
	end

	screens[gui] = result

	return result
end

---------------------------------------------------------------------
-- METRICS
---------------------------------------------------------------------

local function updateMetrics(state)
	local obj = state.object

	if not obj.Parent then
		return
	end

	local position = obj.AbsolutePosition
	local size = obj.AbsoluteSize

	state.center = position + size * 0.5
	state.size = size
end

---------------------------------------------------------------------
-- CLEANUP
---------------------------------------------------------------------

local function cleanup(index, state)
	for _, connection in state.connections do
		connection:Disconnect()
	end

	pcall(function()
		state.component:Disable()
	end)

	states[state.object] = nil

	table.remove(active, index)
end

---------------------------------------------------------------------
-- BIND
---------------------------------------------------------------------

function HoverTilt.Bind(obj)
	if states[obj] then
		return
	end

	if not obj:IsA("GuiObject") then
		return
	end

	local gui = obj:FindFirstAncestorOfClass("ScreenGui")

	if not gui then
		return
	end

	local screen = getScreen(
		gui,
		Utils.GetNumber(
			obj,
			"HoverDisplayDistance",
			DEFAULT.DisplayDistance
		)
	)

	if not screen then
		return
	end

	local component = screen:GetComponent3D(obj)

	if not component then
		return
	end

	local baseYaw = math.rad(
		Utils.GetNumber(
			obj,
			"HoverBaseYawDeg",
			0
		)
	)

	local base = CFrame.Angles(
		0,
		baseYaw,
		0
	)

	local state = {
		object = obj,
		component = component,

		base = base,
		current = base,

		center = Vector2.zero,
		size = Vector2.zero,

		hover = false,

		follow = Utils.GetNumber(
			obj,
			"HoverFollowSpeed",
			DEFAULT.FollowSpeed
		),

		returnSpeed = Utils.GetNumber(
			obj,
			"HoverReturnSpeed",
			DEFAULT.ReturnSpeed
		),

		yaw = Utils.GetNumber(
			obj,
			"HoverMaxYawDeg",
			DEFAULT.MaxYaw
		),

		pitch = Utils.GetNumber(
			obj,
			"HoverMaxPitchDeg",
			DEFAULT.MaxPitch
		),

		roll = Utils.GetNumber(
			obj,
			"HoverMaxRollDeg",
			DEFAULT.MaxRoll
		),

		top = Utils.GetNumber(
			obj,
			"HoverTopSensitivity",
			DEFAULT.TopSensitivity
		),

		bottom = Utils.GetNumber(
			obj,
			"HoverBottomSensitivity",
			DEFAULT.BottomSensitivity
		),

		power = Utils.GetNumber(
			obj,
			"HoverResponsePower",
			DEFAULT.ResponsePower
		),

		limit = Utils.GetNumber(
			obj,
			"HoverSoftLimit",
			DEFAULT.SoftLimit
		),

		invert = Utils.GetBoolean(
			obj,
			"HoverInvert",
			DEFAULT.Invert
		),
	}

	updateMetrics(state)

	-----------------------------------------------------------------
	-- METRICS
	-----------------------------------------------------------------

	local positionConnection =
		obj:GetPropertyChangedSignal(
			"AbsolutePosition"
		):Connect(function()
			updateMetrics(state)
		end)

	local sizeConnection =
		obj:GetPropertyChangedSignal(
			"AbsoluteSize"
		):Connect(function()
			updateMetrics(state)
		end)

	-----------------------------------------------------------------
	-- HOVER
	-----------------------------------------------------------------

	local enterConnection =
		obj.MouseEnter:Connect(function()
			state.hover = true
		end)

	local leaveConnection =
		obj.MouseLeave:Connect(function()
			state.hover = false
		end)

	-----------------------------------------------------------------
	-- SCREEN 3D
	-----------------------------------------------------------------

	local screenName =
		obj:GetAttribute("Screen3DName")

	pcall(function()
		if typeof(screenName) == "string"
			and screenName ~= ""
		then
			component:Enable(screenName)
		else
			component:Enable()
		end

		component.offset = base
	end)

	-----------------------------------------------------------------
	-- STORE
	-----------------------------------------------------------------

	state.connections = {
		positionConnection,
		sizeConnection,
		enterConnection,
		leaveConnection,
	}

	states[obj] = state

	active[#active + 1] = state
end

---------------------------------------------------------------------
-- UNBIND
---------------------------------------------------------------------

function HoverTilt.Unbind(obj)
	local state = states[obj]

	if not state then
		return
	end

	for i = #active, 1, -1 do
		if active[i] == state then
			cleanup(i, state)
			return
		end
	end
end

---------------------------------------------------------------------
-- ONE SHARED RENDER LOOP
---------------------------------------------------------------------

RunService.RenderStepped:Connect(function(dt)
	if #active == 0 then
		return
	end

	local mouse = UserInputService:GetMouseLocation()

	for i = #active, 1, -1 do
		local state = active[i]
		local obj = state.object

		if not obj.Parent then
			cleanup(i, state)
			continue
		end

		local target = state.base

		if state.hover
			and state.size.X > 0
			and state.size.Y > 0
		then
			local dx = math.clamp(
				(mouse.X - state.center.X)
					/ (state.size.X * 0.5),
				-1,
				1
			)

			local dy = math.clamp(
				(mouse.Y - state.center.Y)
					/ (state.size.Y * 0.5),
				-1,
				1
			)

			if state.invert then
				dx = -dx
				dy = -dy
			end

			dx =
				math.sign(dx)
				* math.abs(dx) ^ state.power

			dy =
				math.sign(dy)
				* math.abs(dy) ^ state.power

			dy *= dy < 0
				and state.top
				or state.bottom

			dy = math.clamp(
				dy,
				-state.limit,
				state.limit
			)

			target =
				CFrame.Angles(
					math.rad(
						dy * state.pitch
					),
					math.rad(
						dx * state.yaw
					),
					math.rad(
						-dx * state.roll
					)
				)
				* state.base
		end

		local speed =
			state.hover
				and state.follow
				or state.returnSpeed

		state.current =
			state.current:Lerp(
				target,
				math.min(
					dt * speed,
					1
				)
			)

		state.component.offset =
			state.current
	end
end)

return HoverTilt