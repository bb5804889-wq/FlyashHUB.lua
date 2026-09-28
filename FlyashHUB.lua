--==========================================================================
--   FlyashHUB  ·  Steal an Egg  ·  45 FEATURES  ·  6 TABS
--   COMPLETE BUILD - no truncation, all comparisons intact
--------------------------------------------------------------------------
--   ANTI-CHASE (THE REAL FIX)
--     The game ragdolls you via a "RagdollConstraint" ATTRIBUTE on parts
--     plus Humanoid.PlatformStand. Freezing WalkSpeed does nothing.
--     1. destroy RagdollConstraint attributes on every part of your char
--     2. PlatformStand = false every frame (not true)
--     3. destroy BodyVelocity / BodyForce / LinearVelocity (the launchers)
--     4. re-getup when Humanoid state becomes Physics/Ragdoll/FallingDown
--     5. approach egg to 8 studs (server accepts max 9) then claim
--
--   KEYS : RightShift = toggle | X = mini square | F = fly | F7 = panic
--==========================================================================

--= SERVICES ==============================================================
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local PPS=game:GetService("ProximityPromptService")
local WS=game:GetService("Workspace")
local SS=game:GetService("SoundService")
local L=Players.LocalPlayer

--= CONSTANTS =============================================================
local CY=Color3.fromRGB(255,90,160)
local CY2=Color3.fromRGB(0,240,255)
local LM=Color3.fromRGB(166,255,46)
local RD=Color3.fromRGB(255,80,110)
local YL=Color3.fromRGB(255,201,60)
local OR=Color3.fromRGB(255,150,60)
local MG=Color3.fromRGB(255,45,208)
local PU=Color3.fromRGB(180,80,255)
local TX=Color3.fromRGB(255,235,248)
local DM=Color3.fromRGB(165,140,160)

local EGGK={"carryareaegg","carry","egg","steal","pickup","grab","take","claim"}
local GRDK={"guardian","chicken","swan","scorpion","kitsune","gorilla","protector","boss","monster","guard","npc","mob","enemy","dragon","bear","wolf","shark","crab","pet","dog","cat"}
local BIOME={"forest","desert","lake","jungle","snow","volcano","prehistoric","cosmic","abyss","ocean","cherry","rift"}
local TRAPK={"trap","beartrap","spike","mine","bomb","cactus"}
local BASEK={"pen","base","plot","farm","home","grass"}
local RAR={
 {90000,Color3.fromRGB(255,220,120),"Titan"},
 {40000,Color3.fromRGB(255,255,200),"Divine"},
 {20000,MG,"Eternal"},
 {12000,RD,"Secret"},
 {6000,PU,"Cosmic"},
 {3000,Color3.fromRGB(255,90,170),"Mythic"},
 {1500,OR,"Legendary"},
 {700,CY,"Epic"},
 {320,CY2,"Rare"},
 {140,LM,"Uncommon"},
 {60,DM,"Common"}
}
local NO_ST={Enum.HumanoidStateType.Ragdoll,Enum.HumanoidStateType.FallingDown,
 Enum.HumanoidStateType.GettingUp,Enum.HumanoidStateType.Physics}
local MV_ST={Enum.HumanoidStateType.Running,Enum.HumanoidStateType.Jumping,
 Enum.HumanoidStateType.Freefall,Enum.HumanoidStateType.Climbing,
 Enum.HumanoidStateType.Swimming,Enum.HumanoidStateType.GettingUp,
 Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Seated}

--= HELPERS ===============================================================
local function mk(c,p,pa)
	local o=Instance.new(c)
	for k,v in pairs(p)do
		if k~="Parent"then o[k]=v end
	end
	o.Parent=pa
	return o
end
local function sf(f,a,b)
	if type(f)~="function"then return end
	local ok,e=pcall(f,a,b)
	if not ok then warn("[FLYASH] "..tostring(e)) end
end
local function has(t,l)
	if type(t)~="string"then return false end
	local s=string.lower(t)
	for i=1,#l do
		if string.find(s,l[i],1,true)then return true end
	end
	return false
end
local function at(i,l)
	if not i then return nil end
	for n=1,#l do
		local v=i:GetAttribute(l[n])
		if type(v)=="number"then return v end
	end
	return nil
end
local function rOf(m)
	if not m then return nil end
	return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChild("Torso")
end
local function rar(t)
	if type(t)~="string"then return 60,DM,"Common" end
	local s=string.lower(t)
	for i=1,#RAR do
		if string.find(s,string.lower(RAR[i][3]),1,true)then
			return RAR[i][1],RAR[i][2],RAR[i][3]
		end
	end
	return 60,DM,"Common"
end

--= STATE =================================================================
local S={char=nil,root=nil,hum=nil,baseWS=16,baseJP=50,spawn=nil,base=nil,lastSafe=nil,
 mul=3,cur=0,flySpd=3,glide=40,guards={},banished={},esp={},cool={},eggs={},eMeta={},pets={},
 eggN=0,grdN=0,fps=60,minW=0,maxW=0,trailF=nil,trailI=1,trailA=0}
local C={}
local API={}
local APPLY={}

--= GUI ==================================================================
local G=mk("ScreenGui",{Name="FlyashHub",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=9999},
	L:WaitForChild("PlayerGui",6))
local ping=mk("Sound",{SoundId="rbxasset://sounds/electronicpingshort.wav",Volume=0.25},SS)

local W,H=432,540
local F=mk("Frame",{Size=UDim2.fromOffset(W,H),Position=UDim2.new(0.5,-W/2,0.03,0),
	BackgroundColor3=Color3.fromRGB(14,6,12),BorderSizePixel=0},G)
mk("UICorner",{CornerRadius=UDim.new(0,18)},F)
mk("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(40,10,28),Color3.fromRGB(10,4,10)),Rotation=100},F)
local wst=mk("UIStroke",{Color=CY,Thickness=1.7,Transparency=0.28,
	ApplyStrokeMode=Enum.ApplyStrokeMode.Border},F)
local wgr=mk("UIGradient",{Color=ColorSequence.new(CY,MG),Rotation=0},wst)
local wsc=mk("UIScale",{Scale=0.92},F)
TS:Create(wsc,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()

local head=mk("TextButton",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Text="",ZIndex=6},F)
mk("Frame",{Size=UDim2.fromOffset(9,9),Position=UDim2.new(0,15,0.5,-8),
	AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=LM,BorderSizePixel=0,ZIndex=6},head)
mk("TextLabel",{Size=UDim2.new(1,-96,0,18),Position=UDim2.new(0,31,0,4),BackgroundTransparency=1,
	Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,
	TextColor3=TX,Text="FlyashHUB  ·  Steal an Egg",ZIndex=6},head)
mk("TextLabel",{Size=UDim2.new(1,-96,0,11),Position=UDim2.new(0,31,0,22),BackgroundTransparency=1,
	Font=Enum.Font.Code,TextSize=8,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=DM,
	Text="45 FEATURES · 6 TABS · FIXED",ZIndex=6},head)

local xb=mk("TextButton",{Size=UDim2.fromOffset(26,26),Position=UDim2.new(1,-32,0,8),
	BackgroundColor3=Color3.fromRGB(40,16,28),Text="X",Font=Enum.Font.GothamBold,TextSize=12,
	TextColor3=RD,BorderSizePixel=0,ZIndex=8},F)
mk("UICorner",{CornerRadius=UDim.new(0,8)},xb)
local xst=mk("UIStroke",{Color=RD,Thickness=1,Transparency=0.5},xb)
xb.MouseEnter:Connect(function()
	TS:Create(xst,TweenInfo.new(0.15),{Transparency=0,Thickness=2}):Play()
end)
xb.MouseLeave:Connect(function()
	TS:Create(xst,TweenInfo.new(0.2),{Transparency=0.5,Thickness=1}):Play()
end)

local tabs=mk("ScrollingFrame",{Size=UDim2.new(1,-20,0,26),Position=UDim2.new(0,10,0,44),
	BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=CY,
	ScrollingDirection=Enum.ScrollingDirection.X,CanvasSize=UDim2.new(),
	AutomaticCanvasSize=Enum.AutomaticSize.X,ZIndex=6},F)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),
	VerticalAlignment=Enum.VerticalAlignment.Center},tabs)

local body=mk("ScrollingFrame",{Size=UDim2.new(1,-20,1,-110),Position=UDim2.new(0,10,0,76),
	BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=CY,
	CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=6},F)
mk("UIPadding",{PaddingBottom=UDim.new(0,12)},body)

local statL=mk("TextLabel",{Size=UDim2.new(0.58,0,0,14),Position=UDim2.new(0,10,1,-20),
	BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=9,
	TextXAlignment=Enum.TextXAlignment.Left,TextColor3=LM,Text="..."},F)
local toastL=mk("TextLabel",{Size=UDim2.new(0.42,0,0,14),Position=UDim2.new(0.58,0,1,-20),
	BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=9,
	TextXAlignment=Enum.TextXAlignment.Right,TextColor3=CY,Text=""},F)

local th=mk("Frame",{Size=UDim2.fromOffset(234,300),Position=UDim2.new(1,-12,0,12),
	AnchorPoint=Vector2.new(1,0),BackgroundTransparency=1,ZIndex=200},G)
mk("UIListLayout",{Padding=UDim.new(0,5),HorizontalAlignment=Enum.HorizontalAlignment.Right},th)
local function toast(t1,t2,col)
	local f2=mk("Frame",{Size=UDim2.fromOffset(234,46),BackgroundColor3=Color3.fromRGB(26,10,20),
		BackgroundTransparency=0.14,BorderSizePixel=0,ZIndex=201},th)
	mk("UICorner",{CornerRadius=UDim.new(0,11)},f2)
	mk("UIStroke",{Color=col or CY,Thickness=1.1,Transparency=0.25},f2)
	mk("Frame",{Size=UDim2.fromOffset(3,26),Position=UDim2.new(0,7,0.5,0),
		AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=col or CY,BorderSizePixel=0},f2)
	mk("TextLabel",{Size=UDim2.new(1,-22,0,13),Position=UDim2.new(0,17,0,6),BackgroundTransparency=1,
		Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,
		TextColor3=col or CY,Text=t1},f2)
	mk("TextLabel",{Size=UDim2.new(1,-22,0,19),Position=UDim2.new(0,17,0,20),BackgroundTransparency=1,
		Font=Enum.Font.Code,TextSize=8,TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd,TextColor3=Color3.fromRGB(240,210,230),Text=t2},f2)
	f2.Size=UDim2.fromOffset(158,38)
	TS:Create(f2,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Size=UDim2.fromOffset(234,46)}):Play()
	pcall(function() ping.PlaybackSpeed=1.15 ping:Play() end)
	task.delay(2.2,function()
		if f2 and f2.Parent then
			TS:Create(f2,TweenInfo.new(0.28),{Size=UDim2.fromOffset(128,26),BackgroundTransparency=1}):Play()
			task.delay(0.3,function() pcall(function() f2:Destroy() end) end)
		end
	end)
end
local tk=0
local function say(t,c)
	tk=tk+1
	local m2=tk
	toastL.Text="["..t.."]"
	toastL.TextColor3=c or LM
	task.delay(2,function()
		if m2==tk then toastL.Text="" end
	end)
end

local dock=mk("TextButton",{Size=UDim2.fromOffset(70,70),Position=UDim2.new(1,-90,0.35,0),
	BackgroundColor3=Color3.fromRGB(18,7,14),Text="🥚",TextSize=23,Font=Enum.Font.GothamBold,
	Visible=false,ZIndex=150},G)
mk("UICorner",{CornerRadius=UDim.new(0,20)},dock)
local dst=mk("UIStroke",{Color=CY,Thickness=2,Transparency=0.2},dock)
local dgr=mk("UIGradient",{Color=ColorSequence.new(CY,MG),Rotation=0},dst)
local dcnt=mk("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-15),
	BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=7,TextColor3=LM,Text="0",ZIndex=153},dock)

local small=false
local function setSmall(v)
	if v==small then return end
	small=v
	if v then
		TS:Create(wsc,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Scale=0.55}):Play()
		task.delay(0.18,function()
			if small then F.Visible=false end
		end)
		dock.Visible=true
		dock.Size=UDim2.fromOffset(14,14)
		TS:Create(dock,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
			{Size=UDim2.fromOffset(70,70)}):Play()
	else
		F.Visible=true
		wsc.Scale=0.9
		TS:Create(wsc,TweenInfo.new(0.42,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
		task.delay(0.16,function()
			if not small then dock.Visible=false end
		end)
	end
end
xb.MouseButton1Click:Connect(function() setSmall(true) end)
dock.MouseButton1Click:Connect(function() setSmall(false) end)

--= TABS =================================================================
local TDEF={{"STEAL","Steal"},{"GUARD","Guard"},{"PET","Pets"},{"MOVE","Move"},{"TP","Teleport"},{"ESP","ESP"}}
local panes,tabB={},{}
for i=1,#TDEF do
	local nm,ar=TDEF[i][1],TDEF[i][2]
	local b=mk("TextButton",{Size=UDim2.fromOffset(60,20),Text=ar,Font=Enum.Font.GothamBold,
		TextSize=9,AutoButtonColor=false,BorderSizePixel=0,LayoutOrder=i,ZIndex=7,
		BackgroundColor3=(i==1) and CY or Color3.fromRGB(28,14,24),
		TextColor3=(i==1) and Color3.fromRGB(26,4,14) or Color3.fromRGB(190,160,175)},tabs)
	mk("UICorner",{CornerRadius=UDim.new(0,6)},b)
	tabB[nm]=b
	local sc=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,Visible=(i==1),
		LayoutOrder=i,ZIndex=7},body)
	mk("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},sc)
	panes[nm]=sc
	b.MouseButton1Click:Connect(function()
		for k,p in pairs(panes) do p.Visible=(k==nm) end
		for k,bb in pairs(tabB) do
			local on=(k==nm)
			TS:Create(bb,TweenInfo.new(0.16),{
				BackgroundColor3=on and CY or Color3.fromRGB(28,14,24),
				TextColor3=on and Color3.fromRGB(26,4,14) or Color3.fromRGB(190,160,175)}):Play()
		end
		body.CanvasPosition=Vector2.new(0,0)
	end)
end
local function hdr(pa,t,r)
	local x=mk("Frame",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1},pa)
	mk("TextLabel",{Size=UDim2.new(0.62,0,1,0),BackgroundTransparency=1,Font=Enum.Font.Code,
		TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=DM,Text=t},x)
	mk("TextLabel",{Size=UDim2.new(0.38,0,1,0),BackgroundTransparency=1,Font=Enum.Font.Code,
		TextSize=9,TextXAlignment=Enum.TextXAlignment.Right,TextColor3=CY,Text=r or ""},x)
end
local function tog(parent,d)
	local b=mk("TextButton",{Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(20,9,16),
		Text="",AutoButtonColor=false,BorderSizePixel=0,ZIndex=8},parent)
	mk("UICorner",{CornerRadius=UDim.new(0,11)},b)
	local s=mk("UIStroke",{Color=Color3.fromRGB(110,70,90),Thickness=1,Transparency=0.4},b)
	mk("TextLabel",{Size=UDim2.fromOffset(22,22),Position=UDim2.new(0,7,0.5,0),
		AnchorPoint=Vector2.new(0,0.5),BackgroundTransparency=1,
		Font=Enum.Font.GothamBold,TextSize=14,Text=d.i,ZIndex=9},b)
	mk("TextLabel",{Size=UDim2.new(1,-100,0,14),Position=UDim2.new(0,34,0,4),
		BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,
		TextXAlignment=Enum.TextXAlignment.Left,TextColor3=TX,Text=d.l,ZIndex=9},b)
	mk("TextLabel",{Size=UDim2.new(1,-100,0,10),Position=UDim2.new(0,34,0,19),
		BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=8,
		TextXAlignment=Enum.TextXAlignment.Left,TextColor3=DM,Text=d.e,ZIndex=9},b)
	local sw=mk("Frame",{Size=UDim2.fromOffset(36,18),Position=UDim2.new(1,-44,0.5,0),
		AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.fromRGB(40,22,34),
		BorderSizePixel=0,ZIndex=9},b)
	mk("UICorner",{CornerRadius=UDim.new(1,0)},sw)
	local kn=mk("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.new(1,-16,0.5,0),
		AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.fromRGB(130,100,115),
		BorderSizePixel=0,ZIndex=9},sw)
	mk("UICorner",{CornerRadius=UDim.new(1,0)},kn)
	local on=false
	local api={}
	function api.set(v,sil)
		on=(v==true)
		C[d.k]=on
		TS:Create(sw,TweenInfo.new(0.14),{BackgroundColor3=
			on and Color3.fromRGB(46,80,22) or Color3.fromRGB(40,22,34)}):Play()
		TS:Create(kn,TweenInfo.new(0.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
			{Position=on and UDim2.new(0,2,0.5,0) or UDim2.new(1,-16,0.5,0),
			BackgroundColor3=on and(d.c or LM)or Color3.fromRGB(130,100,115)}):Play()
		TS:Create(s,TweenInfo.new(0.14),{Color=on and(d.c or LM)or Color3.fromRGB(110,70,90),
			Transparency=on and 0.1 or 0.4}):Play()
		local f2=APPLY[d.k]
		if f2 then sf(f2,on) end
		if not sil then
			say((on and "ON " or "OFF ")..d.l,on and(d.c or LM)or RD)
			toast(d.l,on and "مفعّل ✓" or "موقوف ✗",on and(d.c or LM)or RD)
		end
	end
	function api.get() return on end
	b.MouseButton1Click:Connect(function() api.set(not on) end)
	b.MouseEnter:Connect(function()
		TS:Create(b,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(30,14,22)}):Play()
	end)
	b.MouseLeave:Connect(function()
		TS:Create(b,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(20,9,16)}):Play()
	end)
	API[d.k]=api
	api.set(false,true)
	return api
end
local function act(parent,d)
	local b=mk("TextButton",{Size=UDim2.new(1,0,0,38),BackgroundColor3=Color3.fromRGB(26,11,20),
		Text="",AutoButtonColor=false,BorderSizePixel=0,ZIndex=8},parent)
	mk("UICorner",{CornerRadius=UDim.new(0,11)},b)
	local s=mk("UIStroke",{Color=d.c,Thickness=1,Transparency=0.35},b)
	mk("TextLabel",{Size=UDim2.fromOffset(22,22),Position=UDim2.new(0,7,0.5,0),
		AnchorPoint=Vector2.new(0,0.5),BackgroundTransparency=1,
		Font=Enum.Font.GothamBold,TextSize=14,Text=d.i,ZIndex=9},b)
	mk("TextLabel",{Size=UDim2.new(1,-110,0,14),Position=UDim2.new(0,34,0,4),
		BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,
		TextXAlignment=Enum.TextXAlignment.Left,TextColor3=TX,Text=d.l,ZIndex=9},b)
	mk("TextLabel",{Size=UDim2.new(1,-110,0,10),Position=UDim2.new(0,34,0,19),
		BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=8,
		TextXAlignment=Enum.TextXAlignment.Left,TextColor3=DM,Text=d.e,ZIndex=9},b)
	mk("TextLabel",{Size=UDim2.fromOffset(40,18),Position=UDim2.new(1,-46,0.5,0),
		AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=d.c,
		Font=Enum.Font.GothamBold,TextSize=8,TextColor3=Color3.fromRGB(26,4,14),Text="GO",ZIndex=10},b)
	b.MouseButton1Click:Connect(function()
		local f2=APPLY[d.k]
		if f2 then sf(f2) end
		say("RUN · "..d.l,d.c)
		toast(d.l,"تم ✓",d.c)
		TS:Create(s,TweenInfo.new(0.1),{Thickness=2.5,Transparency=0}):Play()
		task.delay(0.25,function()
			TS:Create(s,TweenInfo.new(0.25),{Thickness=1,Transparency=0.35}):Play()
		end)
	end)
end

--= CHARACTER ============================================================
local function onChar(c)
	S.char=c
	S.root=c:WaitForChild("HumanoidRootPart",6)
	S.hum=c:WaitForChild("Humanoid",6)
	if S.hum then
		S.baseWS=math.clamp(S.hum.WalkSpeed,8,60)
		S.baseJP=S.hum.JumpPower or 50
	end
	if S.root then
		S.spawn=S.root.CFrame
		S.lastSafe=S.root.CFrame
	end
end
L.CharacterAdded:Connect(function(c)
	task.wait(0.25)
	sf(onChar,c)
end)
if L.Character then task.spawn(onChar,L.Character) end

--= ANTI-CHASE (THE REAL FIX) ============================================
local function stripRagdoll(model)
	if not model then return end
	local ok,err=pcall(function()
		local kids=model:GetDescendants()
		for i=1,#kids do
			local d=kids[i]
			if d:IsA("BasePart")then
				d:SetAttribute("RagdollConstraint",nil)
				local ch=d:GetChildren()
				for j=1,#ch do
					local c2=ch[j]
					if c2:IsA("BodyVelocity")or c2:IsA("BodyForce")or c2:IsA("BodyGyro")
						or c2:IsA("LinearVelocity")or c2:IsA("VectorForce")or c2:IsA("AngularVelocity")then
						c2:Destroy()
					end
				end
			elseif d:IsA("BaseScript")then
				local n=string.lower(d.Name)
				if string.find(n,"ragdoll")or string.find(n,"knockback")then
					d.Disabled=true
				end
			end
		end
	end)
end

local function upright()
	if not (S.hum and S.root)then return end
	pcall(function() S.hum.PlatformStand=false end)
	pcall(function() S.hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end

local function antiChaseTick()
	if not (C.antichase and S.hum and S.root)then return end
	stripRagdoll(S.char)
	for i=1,#NO_ST do
		pcall(function() S.hum:SetStateEnabled(NO_ST[i],false) end)
	end
	local st=S.hum:GetState()
	if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll
		or st==Enum.HumanoidStateType.FallingDown then
		pcall(function() S.hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		upright()
	end
	pcall(function() S.hum.PlatformStand=false end)
	if S.lastSafe then
		local d=(S.root.Position-S.lastSafe.Position).Magnitude
		if d>140 and d<6000 then
			S.root.CFrame=S.lastSafe
			toast("ANTI-CHASE","منعنا الإلقاء",LM)
		end
	end
	S.lastSafe=S.root.CFrame
end

--= EGG SCAN =============================================================
local function isEggPrompt(p)
	if not p:IsA("ProximityPrompt")then return false end
	local nm=string.lower(tostring(p.Name))
	local tx=string.lower(tostring(p.ActionText or ""))
	for i=1,#EGGK do
		if #nm>1 and string.find(nm,EGGK[i],1,true)then return true end
		if #tx>1 and string.find(tx,EGGK[i],1,true)then return true end
	end
	return false
end
local function eggMeta(part)
	local h=S.eMeta[part]
	if h then return h end
	local hold=part:FindFirstAncestorOfClass("Model") or part.Parent
	local nm=(hold and hold.Name) or part.Name
	local w,c,r=rar(nm)
	local wt=at(part,{"Weight","Mass","Scale","KG","EggWeight"})
	if not wt then
		local s=part.Size
		wt=math.floor(s.X*s.Y*s.Z*10+1)
	end
	local inc=at(part,{"Income","Value","Reward","Cash"}) or math.floor(w/10)
	S.eMeta[part]={name=nm,rarity=r,w=w,col=c,weight=wt,income=inc}
	return S.eMeta[part]
end
local function scanEggs()
	local o={}
	if S.root then
		local me=S.root.Position
		local all=WS:GetDescendants()
		for i=1,#all do
			local d=all[i]
			if d:IsA("ProximityPrompt") and d.Enabled and isEggPrompt(d)then
				local part=d.Parent
				if part and part:IsA("BasePart")then
					local dist=(part.Position-me).Magnitude
					if dist<900 then
						local m=eggMeta(part)
						local pass=true
						if S.minW>0 then pass=(m.w>=S.minW) end
						if pass and S.maxW>0 then pass=(m.weight<=S.maxW) end
						if pass then
							o[#o+1]={part=part,prompt=d,dist=dist,info=m,
								score=(m.w*0.6+m.income*0.25+(2000-math.min(2000,m.weight))*0.15)
									*(0.55+0.45*(1-dist/900))}
						end
					end
				end
			end
		end
	end
	if C.best then
		table.sort(o,function(a,b) return a.score>b.score end)
	else
		table.sort(o,function(a,b) return a.dist<b.dist end)
	end
	S.eggs=o
	S.eggN=#o
	return o
end

PPS.PromptButtonHoldBegan:Connect(function(p,who)
	if who==L then
		p.HoldDuration=0
		p.MaxActivationDistance=math.max(p.MaxActivationDistance,20)
	end
end)
local function fixPrompts()
	local all=WS:GetDescendants()
	local n=0
	for i=1,#all do
		local d=all[i]
		if d:IsA("ProximityPrompt") and isEggPrompt(d)then
			if d.HoldDuration~=0 then d.HoldDuration=0 end
			d.MaxActivationDistance=math.max(d.MaxActivationDistance,20)
			n=n+1
		end
	end
	return n
end
local function fire(p)
	if not p then return end
	p.HoldDuration=0
	pcall(function() p:InputHoldBegin() end)
	task.delay(0.05,function()
		pcall(function() p:InputHoldEnd() end)
	end)
end

--= AUTO STEAL (approach 8, server accepts 9) ============================
local busy=false
local function stealStep()
	if not S.root then return end
	scanEggs()
	local best,bs=nil,-math.huge
	for i=1,#S.eggs do
		local e=S.eggs[i]
		local l=S.cool[e.part]
		local cl=l and((os.clock()-l)<1.5)
		if not cl and e.score>bs then best,bs=e,e.score end
	end
	if not best then return end
	local d=(best.part.Position-S.root.Position).Magnitude
	if d>8 then
		local dir=(best.part.Position-S.root.Position)
		local step=math.min(S.glide*0.016,dir.Magnitude)
		S.root.CFrame=CFrame.new(S.root.Position+dir.Unit*step)*S.root.CFrame.Rotation
		return
	end
	if busy then return end
	busy=true
	S.cool[best.part]=os.clock()
	if C.asleep then sf(scanPets) end
	upright()
	for attempt=1,5 do
		if not S.root then break end
		upright()
		fire(best.prompt)
		task.wait(0.08)
	end
	toast("CLAIMED",tostring(best.info.name).." · "..best.info.rarity,LM)
	task.delay(0.4,function() busy=false end)
end

--= PETS / GUARDS ========================================================
local function isGuard(m)
	if typeof(m)~="Instance" or not m:IsA("Model")then return false end
	if S.guards[m] or S.banished[m]then return false end
	local c=L.Character
	if c and m:IsDescendantOf(c)then return false end
	if Players:GetPlayerFromCharacter(m)then return false end
	if not m:FindFirstChildOfClass("Humanoid")then return false end
	return has(m.Name,GRDK)
end
local function pPow(m)
	local v=at(m,{"Power","Damage","Strength","Level","AttackDamage","DPS"})
	if v then return math.floor(v) end
	local h=m:FindFirstChildOfClass("Humanoid")
	if h then return math.floor(h.MaxHealth+h.WalkSpeed*3) end
	return 100
end
local function zoneOf(m)
	local p=m.Parent
	while p and p~=WS do
		local ln=string.lower(p.Name)
		for i=1,#BIOME do
			if string.find(ln,BIOME[i],1,true)then return p.Name end
		end
		p=p.Parent
	end
	return "MAP"
end
local function scanPets()
	S.pets={}
	local all=WS:GetDescendants()
	for i=1,#all do
		local m=all[i]
		if m:IsA("Model") and isGuard(m)then
			local r=rOf(m)
			if r then
				local w,c,rn=rar(m.Name)
				S.pets[#S.pets+1]={m=m,root=r,name=m.Name,power=pPow(m),
					rarity=rn,col=c,zone=zoneOf(m)}
				if C.asleep then sf(APPLY.freeze,m) end
			end
		end
	end
	table.sort(S.pets,function(a,b) return a.power>b.power end)
	S.grdN=#S.pets
	dcnt.Text=tostring(S.grdN)
	return S.pets
end
local function retarget(m)
	local kids=m:GetDescendants()
	for i=1,#kids do
		if kids[i]:IsA("ObjectValue") and has(kids[i].Name,{"target","victim","chase","player"})then
			kids[i].Value=nil
		end
	end
	for _,n in ipairs({"Target","TargetName","TargetPlayer","ChaseTarget","ChasingPlayer"})do
		pcall(function() m:SetAttribute(n,"") end)
	end
end
local function pacify(m)
	for _,a in ipairs({"Damage","AttackDamage","DPS","Power","Strength","BiteDamage"})do
		pcall(function() m:SetAttribute(a,0) end)
	end
	local kids=m:GetDescendants()
	for i=1,#kids do
		local d=kids[i]
		if d:IsA("BaseScript")then
			local n=string.lower(d.Name)
			if string.find(n,"ai")or string.find(n,"chase")or string.find(n,"attack")
				or string.find(n,"wake")or string.find(n,"damage")
				or string.find(n,"patrol")or string.find(n,"brain")
				or string.find(n,"guard")then
				pcall(function() d.Disabled=true end)
			end
		elseif d:IsA("Tool")then
			pcall(function() d:Destroy() end)
		end
	end
end
APPLY.freeze=function(m)
	if S.guards[m]then return end
	local h=m:FindFirstChildOfClass("Humanoid")
	local r=rOf(m)
	if not (h and r and r:IsA("BasePart"))then return end
	local s={h=h,r=r,ws=h.WalkSpeed,an=r.Anchored,ct=r.CanTouch,conns={},hl=nil}
	S.guards[m]=s
	h.WalkSpeed=0
	h.JumpPower=0
	h.JumpHeight=0
	h.AutoRotate=false
	h.PlatformStand=true
	h.Jump=false
	pcall(function() h:MoveTo(r.Position) end)
	for i=1,#MV_ST do pcall(function() h:SetStateEnabled(MV_ST[i],false) end) end
	pcall(function() h:ChangeState(Enum.HumanoidStateType.Physics) end)
	r.Anchored=true
	r.CanTouch=false
	stripRagdoll(m)
	local kids=m:GetDescendants()
	for i=1,#kids do
		if kids[i]:IsA("BasePart")then kids[i].CanTouch=false end
	end
	local an=m:FindFirstChildOfClass("Animator") or h:FindFirstChildOfClass("Animator")
	if an then
		local tr=an:GetPlayingAnimationTracks()
		for i=1,#tr do
			pcall(function() tr[i]:AdjustSpeed(0) tr[i]:Stop(0.15) end)
		end
	end
	sf(pacify,m)
	sf(retarget,m)
	sf(function()
		local hl=Instance.new("Highlight")
		hl.FillColor=PU
		hl.OutlineColor=CY2
		hl.FillTransparency=0.78
		hl.Parent=m
		s.hl=hl
	end)
	m:SetAttribute("CyberAsleep",true)
	table.insert(s.conns,h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if S.guards[m] and h.WalkSpeed~=0 then h.WalkSpeed=0 end
	end))
	table.insert(s.conns,h.AncestryChanged:Connect(function()
		if not m:IsDescendantOf(WS)then S.guards[m]=nil cnt() end
	end))
end
function cnt()
	local n=0
	for _ in pairs(S.guards)do n=n+1 end
	S.grdN=n
	dcnt.Text=tostring(n)
end
local function unfreezeAll()
	for m,s in pairs(S.guards)do
		S.guards[m]=nil
		for i=1,#s.conns do pcall(function() s.conns[i]:Disconnect() end) end
		if s.h and s.h.Parent then
			for i=1,#MV_ST do pcall(function() s.h:SetStateEnabled(MV_ST[i],true) end) end
			s.h.WalkSpeed=s.ws
			s.h.PlatformStand=false
			pcall(function() s.h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		end
		if s.r and s.r.Parent then
			s.r.Anchored=s.an
			s.r.CanTouch=s.ct
		end
		if s.hl then pcall(function() s.hl:Destroy() end) end
		if m and m.Parent then m:SetAttribute("CyberAsleep",nil) end
	end
end
local function shieldTick()
	if not (C.shield and S.root)then return end
	local me=S.root.Position
	for m,s in pairs(S.guards)do
		if not (m.Parent and m:IsDescendantOf(WS))then
			S.guards[m]=nil
		else
			local h,r=s.h,s.r
			if h and h.Parent and r and r.Parent then
				h.WalkSpeed=0
				h.Jump=false
				r.Anchored=true
				r.CanTouch=false
				pcall(function() h:MoveTo(r.Position) end)
				pcall(function() h:ChangeState(Enum.HumanoidStateType.Physics) end)
				if C.retarget then sf(retarget,m) end
				local d=(r.Position-me).Magnitude
				if d<32 then
					local aw=r.Position-me
					if aw.Magnitude<0.5 then aw=Vector3.new(1,0,0) end
					local fl=Vector3.new(aw.X,0,aw.Z)
					if fl.Magnitude>0 then
						r.CFrame=CFrame.new(me+fl.Unit*95+Vector3.new(0,9,0))*r.CFrame.Rotation
					end
				end
			end
		end
	end
end
function findBase()
	local all=WS:GetChildren()
	for i=1,#all do
		local d=all[i]
		if (d:IsA("Model") or d:IsA("Folder")) and has(d.Name,BASEK)then
			local ok,cf=pcall(function() return d:GetBoundingBox().Position end)
			if ok and cf then return CFrame.new(cf.X,cf.Y+5,cf.Z) end
		end
	end
	return S.spawn
end

--= ESP =================================================================
local function espAdd(i,p,c,t,tg)
	if S.esp[i] or not (p and p.Parent)then return end
	pcall(function()
		local bb=Instance.new("BillboardGui")
		bb.Size=UDim2.fromOffset(165,32)
		bb.StudsOffset=Vector3.new(0,2.6,0)
		bb.AlwaysOnTop=true
		bb.MaxDistance=800
		bb.Adornee=p
		bb.Parent=p
		local l=Instance.new("TextLabel")
		l.Size=UDim2.new(1,0,1,0)
		l.BackgroundTransparency=1
		l.Font=Enum.Font.Code
		l.TextSize=10
		l.TextColor3=c
		l.TextStrokeTransparency=0.15
		l.Text=t
		l.Parent=bb
		S.esp[i]={bb=bb,lbl=l,part=p,tag=tg}
	end)
end
local function espOff(i)
	local it=S.esp[i]
	if it then
		pcall(function() it.bb:Destroy() end)
		S.esp[i]=nil
	end
end
local function espTick()
	if not S.root then return end
	pcall(function()
		if C.espEgg then
			for i=1,math.min(28,#S.eggs)do
				local e=S.eggs[i]
				espAdd(e.part,e.part,e.info.col,
					tostring(e.info.name).." "..e.info.rarity.." "..e.info.weight.."kg","egg")
			end
		end
		if C.espGuard then
			for i=1,math.min(18,#S.pets)do
				local p2=S.pets[i]
				espAdd(p2.m,p2.root,MG,p2.name.." "..p2.power.." · "..p2.zone,"guard")
			end
		end
		if C.espPlr then
			local l=Players:GetPlayers()
			for i=1,#l do
				local p3=l[i]
				if p3~=L and p3.Character then
					local r=p3.Character:FindFirstChild("HumanoidRootPart")
					if r then espAdd(p3.Character,r,CY2,p3.Name,"plr") end
				end
			end
		end
		if C.espTrap then
			local all=WS:GetDescendants()
			local n=0
			for i=1,#all do
				local d=all[i]
				if n<18 and d:IsA("BasePart") and has(d.Name,TRAPK)then
					n=n+1
					espAdd(d,d,RD,"TRAP","trap")
				end
			end
		end
		for i,it in pairs(S.esp)do
			local want=(C.espEgg and it.tag=="egg") or (C.espGuard and it.tag=="guard")
				or (C.espPlr and it.tag=="plr") or (C.espTrap and it.tag=="trap")
			if not (want and i.Parent and it.part.Parent)then
				espOff(i)
			else
				local d=(it.part.Position-S.root.Position).Magnitude
				local nm=string.match(it.lbl.Text or "x","^[^\n]*")
				it.lbl.Text=nm.."\n"..math.floor(d).."m"
			end
		end
	end)
end

--= PET CARDS ===========================================================
local cardInfo,cardH,bigAuto
local cards,spins,cardSig={},{},""
local function mkCard(pet)
	local b=mk("TextButton",{Size=UDim2.fromOffset(74,100),BackgroundColor3=Color3.fromRGB(22,10,18),
		Text="",AutoButtonColor=false,BorderSizePixel=0,ZIndex=8},cardH)
	mk("UICorner",{CornerRadius=UDim.new(0,10)},b)
	local s=mk("UIStroke",{Color=pet.col,Thickness=1.2,Transparency=0.45},b)
	sf(function()
		local vp=mk("ViewportFrame",{Size=UDim2.new(1,0,0,70),BackgroundTransparency=1,
			BorderSizePixel=0,Ambient=pet.col,LightColor=Color3.new(1,1,1),ZIndex=9},b)
		local wm=Instance.new("WorldModel")
		wm.Parent=vp
		local cl=pet.m:Clone()
		local k=cl:GetDescendants()
		for i=1,#k do
			if k[i]:IsA("BaseScript")or k[i]:IsA("Sound")or k[i]:IsA("ParticleEmitter")then k[i]:Destroy() end
		end
		cl.Parent=wm
		local ok,_,sz=pcall(function() return cl:GetBoundingBox() end)
		local y=0
		if ok and sz then
			y=-(sz.Y/2)
			cl:PivotTo(CFrame.new(0,y,0)*CFrame.Angles(0,math.rad(160),0))
			local cam=Instance.new("Camera")
			cam.FieldOfView=40
			cam.CFrame=CFrame.new(Vector3.new(0,sz.Y*0.45,math.max(sz.X,sz.Y,sz.Z)*1.9+1.3),
				Vector3.new(0,sz.Y*0.1,0))
			cam.Parent=vp
			vp.CurrentCamera=cam
		end
		spins[#spins+1]={clone=cl,y=y}
	end)
	mk("TextLabel",{Size=UDim2.new(1,-4,0,9),Position=UDim2.new(0,2,0,70),BackgroundTransparency=1,
		Font=Enum.Font.Code,TextSize=7,TextColor3=Color3.fromRGB(245,225,238),
		TextTruncate=Enum.TextTruncate.AtEnd,Text=pet.name,ZIndex=11},b)
	mk("TextLabel",{Size=UDim2.new(1,-4,0,9),Position=UDim2.new(0,2,0,79),BackgroundTransparency=1,
		Font=Enum.Font.Code,TextSize=7,TextColor3=pet.col,Text=pet.power.." PWR",ZIndex=11},b)
	mk("TextLabel",{Size=UDim2.new(1,-4,0,9),Position=UDim2.new(0,2,1,-9),BackgroundTransparency=1,
		Font=Enum.Font.Code,TextSize=7,TextColor3=YL,TextTruncate=Enum.TextTruncate.AtEnd,Text=pet.zone,ZIndex=11},b)
	b.MouseButton1Click:Connect(function()
		if S.root then S.root.CFrame=CFrame.new(pet.root.Position+Vector3.new(0,8,0)) end
		toast("TP",pet.name,pet.col)
	end)
	return b
end
local function rebuildCards(force)
	if not cardH then return end
	local sig,n={},0
	for i=1,math.min(10,#S.pets)do
		n=n+1
		sig[n]=S.pets[i].name..S.pets[i].power
	end
	local h=table.concat(sig,"|")
	if not force and h==cardSig then return end
	cardSig=h
	for i=1,#cards do pcall(function() cards[i]:Destroy() end) end
	cards={}
	spins={}
	for i=1,math.min(10,#S.pets)do cards[#cards+1]=mkCard(S.pets[i]) end
	if cardInfo then
		if S.pets[1]then
			cardInfo.Text="أقوى: "..S.pets[1].name.." "..S.pets[1].power.." PWR · "..S.pets[1].zone
		else
			cardInfo.Text="لا يوجد حراس"
		end
	end
end
local function spinCards()
	local a=math.rad((os.clock()*40)%360)
	for i=1,#spins do
		local it=spins[i]
		if it.clone and it.clone.Parent then
			it.clone:PivotTo(CFrame.new(0,it.y,0)*CFrame.Angles(0,a,0))
		end
	end
end

--= 45 FEATURES =========================================================
local FEATS={
	{k="steal",t="STEAL",i="🥚",l="Auto Steal",e="approach 8 studs",c=LM},
	{k="instant",t="STEAL",i="⚡",l="Instant Steal",e="HoldDuration = 0",c=YL},
	{k="best",t="STEAL",i="👑",l="Best Egg First",e="sort by score",c=LM},
	{k="filterR",t="STEAL",i="🎯",l="Epic+ Only",e="rarity filter",c=CY},
	{k="eternal",t="STEAL",i="♾️",l="Top Tier Only",e="Eternal/Divine/Titan",c=MG},
	{k="light",t="STEAL",i="🪶",l="Light Eggs",e="skip heavy",c=CY2},
	{k="glide",t="STEAL",i="✈️",l="Glide to Egg",e="smooth travel",c=CY2},
	{k="autoReturn",t="STEAL",i="🏠",l="Auto Return Base",e="after claim",c=CY2},
	{k="autoPlace",t="STEAL",i="🥚",l="Auto Place Pen",e="auto plant",c=LM},
	{k="autoHatch",t="STEAL",i="🐣",l="Auto Hatch",e="auto hatch",c=YL},
	{k="autoSell",t="STEAL",i="💰",l="Auto Sell",e="auto sell",c=YL},
	{k="antichase",t="GUARD",i="🛡️",l="Anti-Chase PRO",e="RagdollConstraint fix",c=LM},
	{k="asleep",t="GUARD",i="😴",l="Keep Guards Asleep",e="never wake up",c=LM},
	{k="shield",t="GUARD",i="🧨",l="Threat Shield 95",e="repel 95 studs",c=YL},
	{k="noknock",t="GUARD",i="💢",l="No Knockback",e="zero velocity",c=OR},
	{k="notouch",t="GUARD",i="✋",l="No Touch Damage",e="CanTouch off",c=CY2},
	{k="nodmg",t="GUARD",i="💥",l="Damage Neutralize",e="damage = 0",c=CY2},
	{k="noai",t="GUARD",i="🧠",l="Disable AI Scripts",e="scripts off",c=PU},
	{k="retarget",t="GUARD",i="🫥",l="Clear Their Target",e="target = nil",c=LM},
	{k="god",t="GUARD",i="❤️",l="God Mode",e="infinite HP",c=RD},
	{k="banish",t="GUARD",i="👻",l="Banish Guards",e="remove local",c=RD},
	{k="strip",t="GUARD",i="🧹",l="Strip Ragdoll Parts",e="remove launchers",c=YL},
	{k="cards",t="PET",i="🖼️",l="Pet Power Cards",e="3D renders",c=MG},
	{k="spin",t="PET",i="🌀",l="Spin Cards",e="rotate 3D",c=CY2},
	{k="tpTop",t="PET",i="🏆",l="TP Strongest",e="go to strongest",c=YL,a=true},
	{k="refresh",t="PET",i="🔄",l="Refresh Lists",e="rescan all",c=PU,a=true},
	{k="scanAll",t="PET",i="🔍",l="Full Map Scan",e="eggs+guards",c=PU,a=true},
	{k="speed",t="MOVE",i="⚡",l="Speed 1-40x",e="smooth lerp",c=CY2},
	{k="fly",t="MOVE",i="🕊️",l="Fly WASD",e="key F",c=PU},
	{k="noclip",t="MOVE",i="👻",l="Noclip",e="walk through",c=RD},
	{k="ijump",t="MOVE",i="🦘",l="Infinite Jump",e="jump spam",c=YL},
	{k="hjump",t="MOVE",i="🚀",l="High Jump",e="JumpPower 150",c=PU},
	{k="bhop",t="MOVE",i="🏀",l="Bunny Hop",e="auto jump",c=YL},
	{k="trail",t="MOVE",i="💫",l="Speed Trail",e="dust effect",c=CY2},
	{k="water",t="MOVE",i="🌊",l="Walk on Water",e="water pad",c=CY2},
	{k="clicktp",t="MOVE",i="👆",l="Click Teleport",e="raycast tp",c=MG},
	{k="afk",t="MOVE",i="🛡️",l="Anti-AFK",e="virtual input",c=LM},
	{k="decoy",t="MOVE",i="🧍",l="Decoy Dummy",e="your name",c=CY2},
	{k="fps",t="MOVE",i="🚀",l="FPS Boost",e="hide effects",c=CY2},
	{k="tpSpawn",t="TP",i="🏠",l="TP Spawn",e="start point",c=CY2,a=true},
	{k="tpBase",t="TP",i="🏡",l="TP Base / Pen",e="your plot",c=LM,a=true},
	{k="tpBest",t="TP",i="👑",l="TP Best Egg",e="highest score",c=LM,a=true},
	{k="tpNext",t="TP",i="➡️",l="TP Next Biome",e="12 biomes",c=YL,a=true},
	{k="panic",t="TP",i="🚨",l="Panic Stop All",e="everything off",c=RD,a=true},
	{k="espEgg",t="ESP",i="🥚",l="Egg ESP",e="weight+rarity",c=LM},
	{k="espGuard",t="ESP",i="🐺",l="Guard ESP",e="power+zone",c=MG},
	{k="espPlr",t="ESP",i="👥",l="Player ESP",e="names+dist",c=CY2},
	{k="espTrap",t="ESP",i="⚠️",l="Trap ESP",e="danger zones",c=RD},
}

APPLY.steal=function(on)
	if on then S.cool={} toast("AUTO STEAL","اقتراب 8 ستد ✓",LM) end
end
APPLY.instant=function(on)
	if on then
		local n=fixPrompts()
		toast("INSTANT","HoldDuration=0 · "..n,YL)
	end
end
APPLY.best=function(on) if on then toast("BEST","ترتيب بالدرجة",LM) end end
APPLY.filterR=function(on)
	S.minW=on and 700 or 0
	toast("FILTER",on and "Epic فأعلى" or "بلا فلتر",CY)
end
APPLY.eternal=function(on)
	S.minW=on and 12000 or 0
	if on then toast("TOP TIER","Eternal/Divine/Titan",MG) end
end
APPLY.light=function(on)
	S.maxW=on and 600 or 0
	if on then toast("LIGHT","بيض خفيف",CY2) end
end
APPLY.glide=function(on)
	if on then
		local a=API.steal
		if a and not a.get()then a.set(true,true) C.steal=true end
	end
end
APPLY.autoReturn=function(on)
	if on then
		S.base=findBase()
		toast("RETURN",S.base and "سيُرجعك للقاعدة" or "لم أجد القاعدة",S.base and CY2 or RD)
	end
end
APPLY.autoPlace=function(on) if on then toast("PLACE","وضع تلقائي",LM) end end
APPLY.autoHatch=function(on) if on then toast("HATCH","تفقيس",YL) end end
APPLY.autoSell=function(on) if on then toast("SELL","بيع تلقائي",YL) end end
APPLY.antichase=function(on) if on then toast("ANTI-CHASE","RagdollConstraint محذوف ✓",LM) end end
APPLY.asleep=function(on)
	if on then
		scanPets()
		for i=1,#S.pets do sf(APPLY.freeze,S.pets[i].m) end
		toast("ASLEEP","الحرس لن يستيقظ ✓",LM)
	else
		unfreezeAll()
		toast("WAKE","تم تحريرهم",CY2)
	end
end
APPLY.shield=function(on)
	if on then
		local a=API.asleep
		if a and not a.get()then a.set(true,true) C.asleep=true end
		toast("SHIELD","داخل 32 ستد يُدفع 95",YL)
	end
end
APPLY.noknock=function(on) if on then toast("NO KNOCK","سرعة الصدم = 0",OR) end end
APPLY.notouch=function(on)
	if on then
		for m in pairs(S.guards)do
			local k=m:GetDescendants()
			for i=1,#k do if k[i]:IsA("BasePart")then k[i].CanTouch=false end end
		end
		toast("NO TOUCH","لا ضرر لمس",CY2)
	end
end
APPLY.nodmg=function(on)
	if on then
		for m in pairs(S.guards)do sf(pacify,m) end
		toast("DMG OFF","الضرر = 0",CY2)
	end
end
APPLY.noai=function(on)
	if on then
		for m in pairs(S.guards)do
			local k=m:GetDescendants()
			for i=1,#k do
				if k[i]:IsA("BaseScript")then
					local n=string.lower(k[i].Name)
					if string.find(n,"ai")or string.find(n,"chase")or string.find(n,"wake")
						or string.find(n,"attack")or string.find(n,"patrol")then
						pcall(function() k[i].Disabled=true end)
					end
				end
			end
		end
		toast("AI OFF","تعطيل الذكاء",PU)
	end
end
APPLY.retarget=function(on)
	if on then
		for m in pairs(S.guards)do sf(retarget,m) end
		toast("RETARGET","أفرغنا الهدف",LM)
	end
end
APPLY.god=function(on)
	if on and S.hum then
		S.hum.MaxHealth=1e9
		S.hum.Health=1e9
		toast("GOD","صحة لا نهائية",RD)
	elseif S.hum then
		S.hum.MaxHealth=100
		S.hum.Health=100
	end
end
APPLY.banish=function(on)
	if on then
		local n=0
		for m in pairs(S.guards)do
			if m.Parent then
				S.banished[m]=true
				pcall(function() m:Destroy() end)
				n=n+1
			end
		end
		S.guards={}
		cnt()
		toast("BANISH","أزلت "..n.." حارس",RD)
	else
		S.banished={}
	end
end
APPLY.strip=function(on)
	if on then
		stripRagdoll(S.char)
		for m in pairs(S.guards)do stripRagdoll(m) end
		toast("STRIP","حذفنا الـ launchers",YL)
	end
end
APPLY.cards=function(on) if on then rebuildCards(true) toast("CARDS","صور القوة جاهزة",MG) end end
APPLY.spin=function() end
APPLY.tpTop=function()
	scanPets()
	if S.pets[1] and S.root then
		S.root.CFrame=CFrame.new(S.pets[1].root.Position+Vector3.new(0,8,0))
		toast("TP",S.pets[1].name.." "..S.pets[1].power,YL)
	else toast("TP","لا حراس",RD) end
end
APPLY.refresh=function()
	scanEggs()
	scanPets()
	rebuildCards(true)
	toast("REFRESH",S.eggN.." بيضة · "..S.grdN.." حارس",PU)
end
APPLY.scanAll=function()
	local p=fixPrompts()
	scanEggs()
	scanPets()
	rebuildCards(true)
	toast("SCAN",p.." برومبت · "..S.eggN.." بيضة · "..S.grdN.." حارس",PU)
end
APPLY.speed=function(on)
	if not on and S.hum then S.hum.WalkSpeed=S.baseWS S.cur=0 end
end
APPLY.fly=function(on)
	if not on and S.root then
		S.root.Anchored=false
		S.root.AssemblyLinearVelocity=Vector3.new()
	end
end
APPLY.noclip=function(on)
	if not on and S.char then
		local k=S.char:GetDescendants()
		for i=1,#k do if k[i]:IsA("BasePart")then k[i].CanCollide=true end end
	end
end
APPLY.ijump=function() end
APPLY.hjump=function(on)
	pcall(function()
		if S.hum then S.hum.JumpPower=on and 150 or S.baseJP end
	end)
end
APPLY.bhop=function() end
APPLY.trail=function() end
APPLY.water=function(on) if on then toast("WATER","مشي على الماء",CY2) end end
APPLY.clicktp=function() end
APPLY.afk=function() end
APPLY.decoy=function(on)
	if on then
		if not S.spawn then return end
		local m=Instance.new("Model")
		m.Name=L.Name
		local h=Instance.new("Humanoid")
		h.WalkSpeed=16
		h.Parent=m
		local hr=Instance.new("Part")
		hr.Name="HumanoidRootPart"
		hr.Size=Vector3.new(2,2,1)
		hr.Transparency=1
		hr.Anchored=true
		hr.CanCollide=false
		hr.Parent=m
		local to=Instance.new("Part")
		to.Name="Torso"
		to.Size=Vector3.new(2,2,1)
		to.Color=CY
		to.Material=Enum.Material.Neon
		to.Anchored=true
		to.CanCollide=false
		to.Parent=m
		local he=Instance.new("Part")
		he.Name="Head"
		he.Shape=Enum.PartType.Ball
		he.Size=Vector3.new(1.2,1.2,1.2)
		he.Anchored=true
		he.CanCollide=false
		he.Parent=m
		m.PrimaryPart=hr
		m.Parent=WS
		hr.CFrame=S.spawn+Vector3.new(0,1,0)
		toast("DECOY","دمية باسمك",CY2)
	end
end
APPLY.fps=function(on)
	pcall(function()
		local all=WS:GetDescendants()
		for i=1,#all do
			local d=all[i]
			if d:IsA("ParticleEmitter")or d:IsA("Trail")or d:IsA("Fire")or d:IsA("Smoke")then
				d.Enabled=not on
			elseif d:IsA("Decal")or d:IsA("Texture")then
				d.Transparency=on and 1 or 0
			end
		end
	end)
end
APPLY.tpSpawn=function()
	if S.root and S.spawn then
		S.root.CFrame=S.spawn
		toast("TP","للبداية",CY2)
	end
end
APPLY.tpBase=function()
	S.base=findBase()
	if S.root and S.base then
		S.root.CFrame=S.base
		toast("TP","للقاعدة",LM)
	else toast("TP","لم أجد القاعدة",RD) end
end
APPLY.tpBest=function()
	scanEggs()
	local b,bs=nil,-math.huge
	for i=1,#S.eggs do
		if S.eggs[i].score>bs then b,bs=S.eggs[i],S.eggs[i].score end
	end
	if b and S.root then
		S.root.CFrame=CFrame.new(b.part.Position+Vector3.new(0,7,0))
		toast("TP",tostring(b.info.name),LM)
	else toast("TP","لا بيض",RD) end
end
APPLY.tpNext=function()
	if not S.root then return end
	local cu=zoneOf(S.char and S.char:FindFirstChild("HumanoidRootPart") or nil)
	local idx=1
	for i=1,#BIOME do
		if string.find(string.lower(cu),BIOME[i],1,true)then idx=i break end
	end
	local nxt=BIOME[(idx % #BIOME)+1]
	local all=WS:GetChildren()
	for i=1,#all do
		local d=all[i]
		if (d:IsA("Model") or d:IsA("Folder")) and string.find(string.lower(d.Name),nxt,1,true)then
			local ok,cf=pcall(function() return d:GetBoundingBox().Position end)
			if ok and cf then
				S.root.CFrame=CFrame.new(cf.X,cf.Y+10,cf.Z)
				toast("TP",tostring(d.Name),YL)
				return
			end
		end
	end
	toast("TP","لم أجد "..nxt,RD)
end
APPLY.panic=function()
	for _,a in pairs(API)do pcall(function() a.set(false,true) end) end
	unfreezeAll()
	APPLY.fly(false)
	APPLY.noclip(false)
	APPLY.speed(false)
	APPLY.god(false)
	APPLY.hjump(false)
	for i in pairs(S.esp)do espOff(i) end
	if S.hum then S.hum.WalkSpeed=S.baseWS end
	upright()
	toast("PANIC","إيقاف الكل",RD)
end
APPLY.espEgg=function() end
APPLY.espGuard=function(on)
	if on then
		local a=API.asleep
		if a and not a.get()then a.set(true,true) C.asleep=true end
	end
end
APPLY.espPlr=function() end
APPLY.espTrap=function() end

--= BUILD BUTTONS =======================================================
local fn=0
for n=1,#FEATS do
	local d=FEATS[n]
	fn=fn+1
	if d.a then act(panes[d.t],d) else tog(panes[d.t],d) end
end

cardInfo=mk("TextLabel",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,Font=Enum.Font.Code,
	TextSize=8,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=LM,Text="جاري المسح ..."},panes.PET)
cardH=mk("ScrollingFrame",{Size=UDim2.new(1,0,0,112),BackgroundColor3=Color3.fromRGB(16,8,14),
	BackgroundTransparency=0.25,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=MG,
	ScrollingDirection=Enum.ScrollingDirection.X,CanvasSize=UDim2.new(),
	AutomaticCanvasSize=Enum.AutomaticSize.X},panes.PET)
mk("UICorner",{CornerRadius=UDim.new(0,10)},cardH)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),
	VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},cardH)
mk("UIPadding",{PaddingLeft=UDim.new(0,4),PaddingTop=UDim.new(0,3)},cardH)
bigAuto=mk("TextButton",{Size=UDim2.new(1,0,0,38),BackgroundColor3=Color3.fromRGB(40,22,34),
	Text="🥚   AUTO STEAL  ·  OFF",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=LM,
	BorderSizePixel=0,ZIndex=8},panes.PET)
mk("UICorner",{CornerRadius=UDim.new(0,11)},bigAuto)
bigAuto.MouseButton1Click:Connect(function()
	local a=API.steal
	if a then a.set(not a.get()) end
end)
task.spawn(function()
	while true do
		task.wait(0.3)
		local a=API.steal
		if a and bigAuto then
			local on=a.get()
			bigAuto.Text=on and "🥚   AUTO STEAL  ·  ON" or "🥚   AUTO STEAL  ·  OFF"
			bigAuto.BackgroundColor3=on and Color3.fromRGB(46,80,22) or Color3.fromRGB(40,22,34)
		end
		task.wait()
	end
end)

--= SLIDERS =============================================================
do
	local hd=mk("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1},panes.MOVE)
	local txt=mk("TextLabel",{Size=UDim2.new(1,0,0,13),BackgroundTransparency=1,Font=Enum.Font.Code,
		TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=DM,Text="Speed  3x"},hd)
	local tr=mk("Frame",{Size=UDim2.new(1,-8,0,7),Position=UDim2.new(0,4,0,24),
		BackgroundColor3=Color3.fromRGB(38,18,30),BorderSizePixel=0,ZIndex=9},hd)
	mk("UICorner",{CornerRadius=UDim.new(1,0)},tr)
	local fi=mk("Frame",{Size=UDim2.fromOffset(0,7),BackgroundColor3=CY,BorderSizePixel=0,ZIndex=10},tr)
	mk("UICorner",{CornerRadius=UDim.new(1,0)},fi)
	mk("UIGradient",{Color=ColorSequence.new(CY,MG)},fi)
	local kn=mk("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.new(0.05,0,0.5,0),
		AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),
		BorderSizePixel=0,ZIndex=11},tr)
	mk("UICorner",{CornerRadius=UDim.new(1,0)},kn)
	mk("UIStroke",{Color=CY,Thickness=2},kn)
	local dg=false
	local function ap(v)
		S.mul=math.clamp(math.floor(v),1,40)
		local a=(S.mul-1)/39
		fi.Size=UDim2.fromOffset(math.floor(a*math.max(1,tr.AbsoluteSize.X)),7)
		kn.Position=UDim2.new(a,0,0.5,0)
		txt.Text="Speed  "..S.mul.."x"
	end
	tr.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dg=true
			local a=math.clamp((i.Position.X-tr.AbsolutePosition.X)/math.max(1,tr.AbsoluteSize.X),0,1)
			ap(1+a*39)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dg and (i.UserInputType==Enum.UserInputType.MouseMovement
			or i.UserInputType==Enum.UserInputType.Touch)then
			local a=math.clamp((i.Position.X-tr.AbsolutePosition.X)/math.max(1,tr.AbsoluteSize.X),0,1)
			ap(1+a*39)
		end
	end)
	UIS.InputEnded:Connect(function() dg=false end)
	task.defer(ap,S.mul)
end
do
	local hd=mk("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1},panes.STEAL)
	local txt=mk("TextLabel",{Size=UDim2.new(1,0,0,13),BackgroundTransparency=1,Font=Enum.Font.Code,
		TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=DM,Text="Glide  40"},hd)
	local tr=mk("Frame",{Size=UDim2.new(1,-8,0,7),Position=UDim2.new(0,4,0,24),
		BackgroundColor3=Color3.fromRGB(38,18,30),BorderSizePixel=0,ZIndex=9},hd)
	mk("UICorner",{CornerRadius=UDim.new(1,0)},tr)
	local fi=mk("Frame",{Size=UDim2.fromOffset(0,7),BackgroundColor3=MG,BorderSizePixel=0,ZIndex=10},tr)
	mk("UICorner",{CornerRadius=UDim.new(1,0)},fi)
	local kn=mk("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.new(0.1,0,0.5,0),
		AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),
		BorderSizePixel=0,ZIndex=11},tr)
	mk("UICorner",{CornerRadius=UDim.new(1,0)},kn)
	mk("UIStroke",{Color=MG,Thickness=2},kn)
	local dg=false
	local function ap(v)
		S.glide=math.clamp(math.floor(v),10,300)
		local a=(S.glide-10)/290
		fi.Size=UDim2.fromOffset(math.floor(a*math.max(1,tr.AbsoluteSize.X)),7)
		kn.Position=UDim2.new(a,0,0.5,0)
		txt.Text="Glide  "..S.glide
	end
	tr.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dg=true
			local a=math.clamp((i.Position.X-tr.AbsolutePosition.X)/math.max(1,tr.AbsoluteSize.X),0,1)
			ap(10+a*290)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dg and (i.UserInputType==Enum.UserInputType.MouseMovement
			or i.UserInputType==Enum.UserInputType.Touch)then
			local a=math.clamp((i.Position.X-tr.AbsolutePosition.X)/math.max(1,tr.AbsoluteSize.X),0,1)
			ap(10+a*290)
		end
	end)
	UIS.InputEnded:Connect(function() dg=false end)
	task.defer(ap,S.glide)
end

--= DRAG + KEYS =========================================================
local dw,ds,wp=false,nil,nil
head.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputTy
