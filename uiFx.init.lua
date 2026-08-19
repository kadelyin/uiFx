local CollectionService =
	game:GetService("CollectionService")

local EffectsFolder =
	script.Parent.Effects

local UIEffects = {}

UIEffects.VERSION = "0.3.0"

local effects = {}
local connections = {}

local function register(module)
	if not module:IsA("ModuleScript") then
		return
	end

	local ok, effect = pcall(require, module)

	if not ok then
		warn(
			"[UIEffects] Failed to load:",
			module.Name,
			effect
		)

		return
	end

	if typeof(effect) ~= "table" then
		warn(
			"[UIEffects] Invalid effect:",
			module.Name
		)

		return
	end

	local tag = effect.Tag

	if typeof(tag) ~= "string"
		or tag == ""
	then
		warn(
			"[UIEffects] Missing Tag:",
			module.Name
		)

		return
	end

	if typeof(effect.Bind) ~= "function" then
		warn(
			"[UIEffects] Missing Bind:",
			module.Name
		)

		return
	end

	if effects[tag] then
		warn(
			"[UIEffects] Duplicate tag:",
			tag
		)

		return
	end

	effects[tag] = effect

	-------------------------------------------------------------
	-- ADD
	-------------------------------------------------------------

	local added =
		CollectionService:GetInstanceAddedSignal(tag)

	connections[#connections + 1] =
		added:Connect(function(obj)
			if obj:IsA("GuiObject") then
				effect.Bind(obj)
			end
		end)

	-------------------------------------------------------------
	-- REMOVE
	-------------------------------------------------------------

	local removed =
		CollectionService:GetInstanceRemovedSignal(tag)

	connections[#connections + 1] =
		removed:Connect(function(obj)
			if effect.Unbind then
				effect.Unbind(obj)
			end
		end)

	-------------------------------------------------------------
	-- EXISTING
	-------------------------------------------------------------

	for _, obj in CollectionService:GetTagged(tag) do
		if obj:IsA("GuiObject") then
			effect.Bind(obj)
		end
	end
end

function UIEffects:Init()
	if self._initialized then
		return
	end

	self._initialized = true

	for _, module in EffectsFolder:GetChildren() do
		register(module)
	end
end

function UIEffects.Apply(obj, effectName)
	local effect = effects[effectName]

	if not effect then
		warn(
			"[UIEffects] Unknown effect:",
			effectName
		)

		return
	end

	effect.Bind(obj)
end

function UIEffects.Remove(obj, effectName)
	local effect = effects[effectName]

	if not effect then
		return
	end

	if effect.Unbind then
		effect.Unbind(obj)
	end
end

return UIEffects