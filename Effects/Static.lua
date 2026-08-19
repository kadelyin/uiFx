local ContentProvider = game:GetService("ContentProvider")

local Utils = require(
	script.Parent.Parent.Shared.Utils
)

local Static = {}

local IMAGES = {
	"rbxassetid://129539846017162",
	"rbxassetid://130020915925188",
	"rbxassetid://71371919306671",
	"rbxassetid://105596020523869",
}

local DEFAULT = {
	Interval = 0.05,
	Crossfade = 0.08,
	ZIndex = 10,

	Color = Color3.new(1, 1, 1),
	Transparency = 0,

	TileSize = UDim2.fromScale(
		0.25,
		0.25
	),
}

local states = setmetatable({}, {
	__mode = "k"
})

local FADE_INFO = TweenInfo.new(
	DEFAULT.Crossfade,
	Enum.EasingStyle.Linear
)

task.spawn(function()
	pcall(
		ContentProvider.PreloadAsync,
		ContentProvider,
		IMAGES
	)
end)

local function createTile(
	parent,
	image,
	color,
	transparency,
	z
)
	local tile = Instance.new("ImageLabel")

	tile.AnchorPoint = Vector2.new(
		0.5,
		0.5
	)

	tile.Position = UDim2.fromScale(
		0.5,
		0.5
	)

	tile.Size = UDim2.fromScale(
		1,
		1
	)

	tile.BackgroundTransparency = 1
	tile.BorderSizePixel = 0

	tile.Image = image
	tile.ImageColor3 = color
	tile.ImageTransparency = transparency

	tile.ResampleMode =
		Enum.ResamplerMode.Pixelated

	tile.ScaleType =
		Enum.ScaleType.Tile

	tile.TileSize =
		DEFAULT.TileSize

	tile.ZIndex = z

	tile.Parent = parent

	return tile
end

function Static.Bind(obj)
	if states[obj] then
		return
	end

	if #IMAGES == 0 then
		warn(
			"[UIEffects] Static has no images."
		)

		return
	end

	local interval = math.max(
		Utils.GetNumber(
			obj,
			"StaticInterval",
			DEFAULT.Interval
		),
		0.01
	)

	local fade = math.max(
		Utils.GetNumber(
			obj,
			"StaticCrossfadeTime",
			DEFAULT.Crossfade
		),
		0
	)

	local z = Utils.GetNumber(
		obj,
		"StaticZIndex",
		DEFAULT.ZIndex
	)

	local color = DEFAULT.Color

	local colorAttribute =
		obj:GetAttribute("StaticColor")

	if typeof(colorAttribute) == "string" then
		color =
			Utils.ColorFromHex(
				colorAttribute
			)
			or color
	end

	local canvas = Instance.new(
		"CanvasGroup"
	)

	canvas.Name = "Static"

	canvas.AnchorPoint = Vector2.new(
		0.5,
		0.5
	)

	canvas.Position = UDim2.fromScale(
		0.5,
		0.5
	)

	canvas.Size = UDim2.fromScale(
		1,
		1
	)

	canvas.BackgroundTransparency = 1
	canvas.ZIndex = z
	canvas.Parent = obj

	Utils.CopyCorners(
		obj,
		canvas
	)

	local first = createTile(
		canvas,
		IMAGES[1],
		color,
		0,
		z
	)

	local second = createTile(
		canvas,
		IMAGES[2] or IMAGES[1],
		color,
		1,
		z
	)

	Utils.CopyCorners(obj, first)
	Utils.CopyCorners(obj, second)

	local state = {
		canvas = canvas,
		running = true,
	}

	states[obj] = state

	task.spawn(function()
		local index = 1
		local current = first
		local nextTile = second

		while state.running
			and obj.Parent
		do
			task.wait(interval)

			if not state.running
				or not obj.Parent
			then
				break
			end

			index =
				index % #IMAGES + 1

			nextTile.Image =
				IMAGES[index]

			nextTile.ImageTransparency = 1

			if fade > 0 then
				local fadeIn = Utils.Tween(
					nextTile,
					TweenInfo.new(
						fade,
						Enum.EasingStyle.Linear
					),
					{
						ImageTransparency =
							DEFAULT.Transparency
					}
				)

				Utils.Tween(
					current,
					TweenInfo.new(
						fade,
						Enum.EasingStyle.Linear
					),
					{
						ImageTransparency = 1
					}
				)

				if fadeIn then
					fadeIn.Completed:Wait()
				end
			else
				nextTile.ImageTransparency =
					DEFAULT.Transparency

				current.ImageTransparency = 1
			end

			current, nextTile =
				nextTile, current
		end
	end)
end

function Static.Unbind(obj)
	local state = states[obj]

	if not state then
		return
	end

	state.running = false

	if state.canvas then
		state.canvas:Destroy()
	end

	states[obj] = nil
end

return Static