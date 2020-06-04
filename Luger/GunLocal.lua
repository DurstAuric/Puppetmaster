local RunService = game:GetService("RunService");
local ContextActionService = game:GetService("ContextActionService");
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local CameraShaker = require(game.ReplicatedStorage:FindFirstChild("CameraShaker", true));

local Resources = script.Parent:WaitForChild("Resources");

local Functions = {
	Client = Resources:FindFirstChild("Client", true);
	Server = Resources:FindFirstChild("Server", true);
}
local Events = {
	Sync = Resources:FindFirstChild("Sync", true);
}

local Tool = script.Parent;
local Player = game.Players.LocalPlayer;
local Character = Player.Character;
local Mouse = Player:GetMouse();
local Camera = game.Workspace.CurrentCamera;

local CF = CFrame.new;
local Angles = CFrame.Angles;
local Rad = math.rad;

local CurrentInput = UserInputService:GetLastInputType();
local InputDebounce = "";

local ColourTween = TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.In);

local MouseInput = {
	Enum.UserInputType.MouseButton1;
	Enum.UserInputType.MouseButton2;
	Enum.UserInputType.MouseButton3;
	Enum.UserInputType.MouseWheel;
	Enum.UserInputType.MouseMovement;
	Enum.UserInputType.Keyboard;
}

local GamepadInput = {
	Enum.UserInputType.Gamepad1;
	Enum.UserInputType.Gamepad2;
	Enum.UserInputType.Gamepad3;
	Enum.UserInputType.Gamepad4;
	Enum.UserInputType.Gamepad5;
	Enum.UserInputType.Gamepad6;
	Enum.UserInputType.Gamepad7;
	Enum.UserInputType.Gamepad8;
}

local ButtonKeys = {
	Keyboard = "F";
	Gamepad = "X";
	Touch = "";
}
--------------------
-- MISC FUNCTIONS --
--------------------
function Create(Object, Properties)
	if not Properties then Properties = {}; end;
	
	local New = Instance.new(Object);
	
	for Property, Value in pairs(Properties) do
		New[Property] = Value;
	end
	
	return New;
end

function InvokeServer(Call)
	local ServerReturn = nil;
	
	pcall(function()
		ServerReturn = Functions.Server:InvokeServer(Call);
	end)
		
	return ServerReturn;
end
--------------------
-- PLAYER HANDLER --
--------------------
-- << ANIMATIONS >> --
local Joints = {
	LowerTorso = Character:WaitForChild("LowerTorso");
};

local AnimationHandler = {Animations = {}};
local Animation = {};
Animation.__index = Animation;

function AnimationHandler.Load()
	local self = {};
	
	self.AnimationObject = "";
	
	for _, Anim in pairs(Tool.Resources.Animations:GetChildren()) do
		self.AnimationObject = Character.Humanoid:LoadAnimation(Anim);
		AnimationHandler.Animations[Anim.Name] = self;
	end
	
	setmetatable(self, Animation);
	
	return self;
end

function Animation:Play()
	self.AnimationObject:Play();
end

function Animation:Stop()
	self.AnimationObject:Stop();
end

AnimationHandler.Load();
Events.Sync:FireServer("createfake");
------------------
-- TOOL HANDLER --
------------------
local Equipped = false;
local FalseTool = Character:WaitForChild("FalseTool");

function Draw(ActionName, InputState, InputObject)
	local UI = Player.PlayerGui:FindFirstChild("SurvivorUI").HolderFrame;
	local GunFrame = UI.GunFrame;
	
	local FadeIn = TweenService:Create(GunFrame.Weapon.TextLabel, ColourTween, {TextColor3 = Color3.new(0.5, 0.5, 0.5)});
	local FadeOut = TweenService:Create(GunFrame.Weapon.TextLabel, ColourTween, {TextColor3 = Color3.new(1, 1, 1)});
	
	if InputState == Enum.UserInputState.Begin then
		GunFrame.Weapon.TextLabel:TweenSize(UDim2.new(0.25, 0, 0.25, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.1, true);
		FadeIn:Play();
	end
	if InputState == Enum.UserInputState.End then
		GunFrame.Weapon.TextLabel:TweenSize(UDim2.new(0.3, 0, 0.3, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.1, true);
		FadeOut:Play();
		
		if not Character:FindFirstChild(Tool.Name) then
			Tool.Parent = Character;
		elseif Character:FindFirstChild(Tool.Name) then
			ToolUnequip()
		end
	end
end

function ToolEquipped()
	if not Equipped then
		Equipped = true;
		FalseTool.Transparency = 1;
		Events.Sync:FireServer("changefake", 1)
	end
end

function ToolUnequip()
	if Equipped then
		Equipped = false;
		
		ContextActionService:UnbindAction("Fire");
		
		if Tool.Parent == Character then
			AnimationHandler.Animations["Unequip"]:Play();
			--Events.Sync:FireServer("PlayAnim", "Unequip");
			wait(0.6);
			Tool.Parent = Player.Backpack;
		end
		
		FalseTool.Transparency = 0;
		Events.Sync:FireServer("changefake", 0);
	end
end

function OnClientInvoke(Call)
	if Equipped and InvokeServer("HasBullet") then
		if Call:lower() == "mousedata" then
			return {Position = Mouse.Hit.p, Target = Mouse.Target};
		end
	end
end

function OnClientEvent(Call)
	if Call:lower() == "fired" then
		local CameraShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(ShakeCF)
			Camera.CFrame = Camera.CFrame * ShakeCF
		end)
		
		CameraShake:Start();
		
		CameraShake:Shake(CameraShaker.Presets.Fired);
		
		delay(0.4, function()
			CameraShake:Stop();
		end)
	elseif Call:lower() == "unequip" then
		ToolUnequip();
	end
end

Tool.Activated:Connect(function()
	if Equipped then
		Events.Sync:FireServer("fired");
	end
end)

Tool.Equipped:Connect(ToolEquipped);

Functions.Client.OnClientInvoke = OnClientInvoke;
Events.Sync.OnClientEvent:Connect(OnClientEvent);

ContextActionService:BindAction("Holster", Draw, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX);
-- << GUI >> --
local TouchGui = nil;

local MainGui = Player.PlayerGui:FindFirstChild("SurvivorUI").HolderFrame;
local GunFrame = MainGui.GunFrame;
local NewCamera = Create("Camera");
local NewFalseTool = FalseTool:Clone();
local NewModel = Create("Model", {Parent = GunFrame.Weapon, Name = "FalseToolModel"});
NewFalseTool.Parent = NewModel;
NewModel.PrimaryPart = NewFalseTool;

GunFrame.Weapon.CurrentCamera = NewCamera;
NewFalseTool.CFrame = NewFalseTool.CFrame * Angles(Rad(-90), Rad(0), Rad(0));

local ModPos, ModSize = NewModel:GetBoundingBox();

NewCamera.CFrame = ModPos * CF(0, 0, ModSize.Z - ModSize.X) * Angles(Rad(0), Rad(0), Rad(-30));
NewModel:SetPrimaryPartCFrame(NewModel.PrimaryPart.CFrame * Angles(Rad(0), Rad(-90), Rad(0)));

function UpdateIcon()
	if InputDebounce == "M&K" then
		GunFrame.Weapon.TextLabel.Text = ButtonKeys.Keyboard;
	elseif InputDebounce == "GP" then
		GunFrame.Weapon.TextLabel.Text = ButtonKeys.Gamepad;
	elseif InputDebounce == "MB" then
		GunFrame.Weapon.TextLabel.Text = ButtonKeys.Touch;
		
		if not TouchGui then 
			TouchGui = Player.PlayerGui.TouchGui;
		end
		
		CreateButton();
--		MainGui.Weapon.ButtonImage.Image = ButtonKeys.Keyboard;
	end
end

function GetCurrentInput()
	for _, InType in pairs(MouseInput) do
		if (CurrentInput == InType and InputDebounce ~= "M&K") then
			InputDebounce = "M&K";
			return
		end
	end
	
	for _, InType in pairs(GamepadInput) do
		if (CurrentInput == InType and InputDebounce ~= "GP") then
			InputDebounce = "GP";
			return
		end
	end
	
	if (CurrentInput == Enum.UserInputType.Touch and InputDebounce ~= "MB") then
		InputDebounce = "MB";
		
		if not TouchGui then 
			TouchGui = Player.PlayerGui.TouchGui;
		end
		
		return
	end
end

function CreateButton()
	ContextActionService:SetImage("Holster", "rbxassetid://4567790697");
	ContextActionService:SetPosition("Holster", UDim2.new(1, -90, 1, -140));
end

GetCurrentInput();
UpdateIcon();

UserInputService.LastInputTypeChanged:Connect(function(InputType)
	for _, InType in pairs(MouseInput) do
		if (InputType == InType and InputDebounce ~= "M&K") then
			CurrentInput = InputType;
			InputDebounce = "M&K";
			
			UpdateIcon();
			return
		end
	end
	
	for _, InType in pairs(GamepadInput) do
		if (InputType == InType and InputDebounce ~= "GP") then
			CurrentInput = InputType;
			InputDebounce = "GP";
			
			UpdateIcon();
			return
		end
	end
	
	if (InputType == Enum.UserInputType.Touch and InputDebounce ~= "MB") then
		CurrentInput = InputType;
		InputDebounce = "MB";
		
		UpdateIcon();
		return
	end
end)
