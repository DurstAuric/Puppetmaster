local ServerStorage = game.ServerStorage;
local ServerScriptService = game:GetService("ServerScriptService");
local CollectionService = game:GetService("CollectionService");

local WeaponHandler = require(ServerStorage:FindFirstChild("WeaponHandler", true));

local Resources = script.Parent:WaitForChild("Resources");
local Functions = {
	Client = Resources:FindFirstChild("Client", true) or Create("RemoteFunction", {Name = "Client", Parent = Resources.Functions});
	Server = Resources:FindFirstChild("Server", true) or Create("RemoteFunction", {Name = "Server", Parent = Resources.Functions});
}
local Events = {
	Sync = Resources:FindFirstChild("Sync", true) or Create("RemoteEvent", {Name = "Server", Parent = Resources.Events});
	
	AmmoChanged = ServerScriptService:FindFirstChild("AmmoChanged", true);
}

local ToolData = WeaponHandler.New("", script.Parent);

local CF = CFrame.new
local Angles = CFrame.Angles;
local Rad = math.rad;
--------------------
-- MISC FUNCTIONS --
--------------------
function Create(Object, Properties)
	local New = Instance.new(Object);
	
	for Property, Value in pairs(Properties) do
		New[Property] = Value;
	end
	
	return New;
end

function InvokeClient(Call)
	local ClientReturn = nil;
	
	pcall(function()
		ClientReturn = Functions.Client:InvokeClient(ToolData.Player, Call);
	end)
	
	return ClientReturn;
end

function DeactivateBullet(Bullet, Delay)
	delay(Delay, function()
		Bullet.ParticleEmitter.Enabled = false;
		wait(Bullet.ParticleEmitter.Lifetime.Max);
		Bullet:Destroy();
		ToolData.Tool.Enabled = true;
	end)
end
------------------
-- TOOL HANDLER --
------------------
local EffectAttachment = ToolData.Tool:FindFirstChild("EffectAttachment", true);

function OnServerInvoke(Player, Call)
	if ToolData.Stats["Equipped"] then
		if Call:lower() == "hasbullet" then
			if ToolData.Stats.Ammo >= 1 then
				return true;
				
			elseif ToolData.Stats.Ammo <= 0 then
				return false;
			end
		end
	end
end

function Fired()
	local function PlayEffects(Bullet)
		local ParticleEmitter = ToolData.Tool.Handle.ParticleEmitter:Clone()
		ParticleEmitter.Parent = Bullet;
		ParticleEmitter.Enabled = true;
		
		ToolData.Tool.Handle.PewPew:Play();
		Events.Sync:FireClient(ToolData.Player, "fired");
		
		spawn(function()
			EffectAttachment.FireEmitter.Enabled = true;
			wait(0.2);
			EffectAttachment.FireEmitter.Enabled = false;
		end)
		
		spawn(function()
			EffectAttachment.SmokeEmitter.Enabled = true;
			wait(0.1);
			EffectAttachment.SmokeEmitter.Enabled = false;
		end)
		
		wait(.05);
		
		spawn(function()
			EffectAttachment.FarLight.Enabled = true;
			wait(0.1);
			EffectAttachment.FarLight.Enabled = false;
		end)
		
		spawn(function()
			EffectAttachment.CloseLight.Enabled = true;
			wait(0.1);
			EffectAttachment.CloseLight.Enabled = false;
		end)
	end
	
	if (ToolData.Stats.Ammo >= 1 and ToolData.Tool.Enabled) then
		ToolData.Tool.Enabled = false;
		
		local MouseData = InvokeClient("MouseData");
		local Direction = (MouseData.Position - EffectAttachment.WorldCFrame.p).unit;
		
		local NewRay = Ray.new(EffectAttachment.WorldCFrame.p, Direction * 50);
		local Hit, Position = game.Workspace:FindPartOnRayWithIgnoreList(NewRay, {ToolData.Player.Character, ToolData.Tool.Handle}, false, true);
		local Distance = (EffectAttachment.WorldCFrame.p - Position).Magnitude;
		local SpawnDistance = CF(EffectAttachment.WorldCFrame.p, Position) * CF(0, 0, -Distance / 2);
		
		local Beam = Create("Part", {
			Name = "Bullet";
			Size = Vector3.new(0.2, 0.2, Distance);
			Anchored = true;
			Locked = true;
			Transparency = 1;
			CanCollide = false;
		});
		
		Beam.Parent = game.Workspace;
		Beam.CFrame = SpawnDistance;
		
		PlayEffects(Beam);
		if Hit then
			if (Hit:FindFirstAncestorOfClass("Model").Humanoid and CollectionService:HasTag(game.Players:GetPlayerFromCharacter(Hit:FindFirstAncestorOfClass("Model")), "Puppetmaster")) then
--			if ((Hit.Parent:FindFirstAncestorOfClass("Model").Humanoid or Hit.Parent:FindFirstChildOfClass("Humanoid")) and CollectionService:HasTag(game.Players:GetPlayerFromCharacter(Hit.Parent:FindFirstAncestorOfClass("Model")), "Puppetmaster")) then
--			if (Hit.Parent:FindFirstChildOfClass("Humanoid") and CollectionService:HasTag(Hit.Parent, "Puppetmaster")) then
				Hit = Hit:FindFirstAncestorOfClass("Model");
				Hit.Humanoid:TakeDamage(100);
--				Hit.Parent:BreakJoints();
			end
		end
		
		ToolData:ChangeAmmo(-1);
		DeactivateBullet(Beam, 0.5);
		delay(1, function()
			if ToolData.Stats.Ammo <= 0 then
				Events.Sync:FireClient(ToolData.Player, "unequip");
				wait(0.6);
				ToolData.Tool.Parent = ToolData.Player.Backpack;
			end
		end)
	end
end

ToolData.Tool.Equipped:Connect(function()
	if ToolData.Stats.Ammo <= 0 then
		Events.Sync:FireClient(ToolData.Player, "unequip");
		wait(0.6);
		ToolData.Tool.Parent = ToolData.Player.Backpack;
	end
end)

Events.Sync.OnServerEvent:Connect(function(Player, Call, Arg)
	if not Arg then Arg = "" end;
	
	if Call:lower() == "changefake" then
		if Player.Character:FindFirstChild("FalseTool") then
			Player.Character.FalseTool.Transparency = Arg;
		end
	elseif Call:lower() == "fired" then
		Fired();
	end
end)

Functions.Server.OnServerInvoke = OnServerInvoke;
