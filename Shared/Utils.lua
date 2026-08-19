local TweenService = game:GetService("TweenService")

local Utils = {}

function Utils.GetNumber(obj, name, default)
	local value = obj:GetAttribute(name)

	return typeof(value) == "number" and value or default
end

function Utils.GetBoolean(obj, name, default)
	local value = obj:GetAttribute(name)

	return typeof(value) == "boolean" and value or default
end

function Utils.Tween(obj, info, properties)
	if not obj.Parent then
		return
	end

	local tween = TweenService:Create(
		obj,
		info,
		properties
	)

	tween:Play()

	return tween
end

function Utils.ColorFromHex(hex)
	hex = tostring(hex):gsub("#", "")

	if #hex ~= 6 then
		return
	end

	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)

	if not r or not g or not b then
		return
	end

	return Color3.fromRGB(r, g, b)
end

function Utils.CopyCorners(source, target)
	for _, child in source:GetChildren() do
		if child:IsA("UICorner") then
			child:Clone().Parent = target
		end
	end
end

return Utils