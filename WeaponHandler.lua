----------
-- VARS --
----------
local ServerScriptService = game:GetService("ServerScriptService");
local CollectionService = game:GetService("CollectionService");

local module = {};
local Weapon = {}
Weapon.__index = Weapon;

local Functions = {
	AmmoChanged = ServerScriptService:FindFirstChild("AmmoChanged", true);
}
---------------
-- FUNCTIONS --
---------------
function module.New(Data, Tool)
	local self = {};
	
	self.ToolData = Data;
	self.Tool = Tool;
	
	self.Player = nil;
	
	self.Stats = {
		["Equipped"] = false;
		
		Ammo = 1;
	};
	
	self.Tool.Equipped:Connect(function()
		if self.Player == nil then
			self.Player = game.Players:GetPlayerFromCharacter(self.Tool.Parent);
		end
		
		if not self.Stats["Equipped"] then
			self.Stats["Equipped"] = true;
		end
	end)
	
	self.Tool.Unequipped:Connect(function()
		if self.Stats["Equipped"] then
			self.Stats["Equipped"] = false;
		end
	end)
	
	setmetatable(self, Weapon);
	return self;
end

function Weapon:Equipped(FUNC)
	if not FUNC then FUNC = function() end end;
	
	FUNC();
end

function Weapon:Unequipped(FUNC)
	if not FUNC then FUNC = function() end end;
	
	FUNC();
end

function Weapon:ChangeAmmo(Amount)
	self.Stats.Ammo = self.Stats.Ammo + Amount;
	
	if self.Stats.Ammo <= 0 then
		self.Player.PlayerGui:FindFirstChild("SurvivorUI"):FindFirstChild("Weapon", true).ImageColor3 = Color3.new(0, 0, 0);
		self.Stats.Ammo = 0;
		Functions.AmmoChanged:Fire(self.Player, 0);
		
	elseif (self.Stats.Ammo >= 1) then
		if self.Player.PlayerGui:FindFirstChild("SurvivorUI"):FindFirstChild("Weapon", true).ImageColor3 == Color3.new(0, 0, 0) then
			self.Player.PlayerGui:FindFirstChild("SurvivorUI"):FindFirstChild("Weapon", true).ImageColor3 = Color3.new(1, 1, 1);
			Functions.AmmoChanged:Fire(self.Player, Amount);
		end
	end
end

return module;
