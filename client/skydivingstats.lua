class 'SkydivingStats'

function SkydivingStats:__init()
	self.enabled = true
	self.stats_printout = false
    self.unit = 1 -- 0: m/s 1: km/h 2: mph

	self.flight_timer = Timer()
	self.last_state = 0

	self.average_speed = nil
	self.average_angle = nil
	self.average_distance = nil

	self.text_size = TextSize.Gigantic
	self.x_offset = 2

	self:CreateSettings()

	Events:Subscribe( "Render", self, self.Render )	
	Events:Subscribe( "PostTick", self, self.PostTick )
	
    Events:Subscribe( "LocalPlayerChat", self, self.LocalPlayerChat )
    Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )

    Events:Subscribe( "ModuleLoad", self, self.ModuleLoad )
    Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )
end

function SkydivingStats:CreateSettings()
    self.window_open = false

    self.window = Window.Create()
    self.window:SetSize( Vector2( 300, 100 ) )
    self.window:SetPosition( (Render.Size - self.window:GetSize())/2 )

    self.window:SetTitle( "Skydiving Stats Settings" )
    self.window:SetVisible( self.window_open )
    self.window:Subscribe( "WindowClosed",
    	function() self:SetWindowOpen( false ) end )

    self.widgets = {}

    local enabled_checkbox = LabeledCheckBox.Create( self.window )
    enabled_checkbox:SetSize( Vector2( 300, 20 ) )
    enabled_checkbox:SetDock( GwenPosition.Top )
    enabled_checkbox:GetLabel():SetText( "Enabled" )
    enabled_checkbox:GetCheckBox():SetChecked( self.enabled )
    enabled_checkbox:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.enabled = enabled_checkbox:GetCheckBox():GetChecked() end )

    local stats_printout = LabeledCheckBox.Create( self.window )
    stats_printout:SetSize( Vector2( 300, 20 ) )
    stats_printout:SetDock( GwenPosition.Top )
    stats_printout:GetLabel():SetText( "Stats Printout" )
    stats_printout:GetCheckBox():SetChecked( self.stats_printout )
    stats_printout:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.stats_printout = stats_printout:GetCheckBox():GetChecked() end )

    local rbc = RadioButtonController.Create( self.window )
    rbc:SetSize( Vector2( 300, 20 ) )
    rbc:SetDock( GwenPosition.Top )

    local units = { "m/s", "km/h", "mph" }
    for i, v in ipairs( units ) do
        local option = rbc:AddOption( v )
        option:SetSize( Vector2( 100, 20 ) )
        option:SetDock( GwenPosition.Left )

        if i-1 == self.unit then
            option:Select()
        end

        option:GetRadioButton():Subscribe( "Checked",
            function()
                self.unit = i-1
            end )
    end
end

function SkydivingStats:GetWindowOpen()
    return self.window_open
end

function SkydivingStats:SetWindowOpen( state )
    self.window_open = state
    self.window:SetVisible( self.window_open )
    Mouse:SetVisible( self.window_open )
end

function SkydivingStats:GetMultiplier()
    if self.unit == 0 then
        return 1
    elseif self.unit == 1 then
        return 3.6
    elseif self.unit == 2 then
        return 2.237
    end
end

function SkydivingStats:GetUnitString()
    if self.unit == 0 then
        return "m/s"
    elseif self.unit == 1 then
        return "km/h"
    elseif self.unit == 2 then
        return "mph"
    end
end

function SkydivingStats:DrawText( text, col )
	Render:DrawText( Vector3( 1, 1, 0 ), text, 
		Color( 0, 0, 0, 100 ), self.text_size )
	Render:DrawText( Vector3( 0, 0, 0 ), text, 
		col, self.text_size )
end

function SkydivingStats:DrawSpeedometer( t )
	local speed = LocalPlayer:GetLinearVelocity():Length()

	if self.average_speed == nil then
		self.average_speed = speed
	else
		self.average_speed = (self.average_speed + speed)/2
	end

	local text = string.format( "%.02f %s", 
		speed * self:GetMultiplier(), self:GetUnitString() )
	local text_vsize = Render:GetTextSize( text, self.text_size )
	local text_vsize_3d = Vector3( text_vsize.x, text_vsize.y, 0 )
	local ang = Camera:GetAngle()

	local left = Copy( t )
	left:Translate( Vector3( -self.x_offset, 0, -5 ) )
	left:Rotate( Angle( math.pi + math.rad(30), 0, math.pi ) )
	left:Scale( 0.002 )
	left:Translate( -text_vsize_3d/2 )

	Render:SetTransform( left )

	local col = Color( 254,67,101 )

	self:DrawText( text, col )
end

function SkydivingStats:DrawAngle( t )
	local angle = math.deg(LocalPlayer:GetAngle().pitch)

	if self.average_angle == nil then
		self.average_angle = angle
	else
		self.average_angle = (self.average_angle + angle)/2
	end

	local text = string.format( "%.02f\176", angle )
	local text_vsize = Render:GetTextSize( text, self.text_size )
	local text_vsize_3d = Vector3( text_vsize.x, text_vsize.y, 0 )
	local ang = Camera:GetAngle()

	local right = Copy( t )
	right:Translate( Vector3( self.x_offset, 0, -5 ) )
	right:Rotate( Angle( math.pi - math.rad(30), 0, math.pi ) )
	right:Scale( 0.002 )
	right:Translate( -text_vsize_3d/2 )

	Render:SetTransform( right )

	local col = Color( 67,254,101 )

	self:DrawText( text, col )
end

function SkydivingStats:DrawDistance( t )
	local pos = LocalPlayer:GetBonePosition( "ragdoll_Spine" )
	local dir = LocalPlayer:GetAngle() * Vector3( 0, -1, 1 )

	local result = Physics:Raycast( pos, dir, 0, 100 )
	local distance = result.distance

	if distance >= 100 then return end

	if self.average_distance == nil then
		self.average_distance = distance
	else
		self.average_distance = (self.average_distance + distance)/2
	end

	local text = string.format( "%.02f m", distance )
	local text_vsize = Render:GetTextSize( text, self.text_size )
	local text_vsize_3d = Vector3( text_vsize.x, text_vsize.y, 0 )
	local ang = Camera:GetAngle()

	local left = Copy( t )
	left:Translate( Vector3( -self.x_offset, -0.5, -5 ) )
	left:Rotate( Angle( math.pi + math.rad(30), 0, math.pi ) )
	left:Scale( 0.002 )
	left:Translate( -text_vsize_3d/2 )

	Render:SetTransform( left )

	local col = Color( 0, 170, 255 )

	self:DrawText( text, col )
end

function SkydivingStats:DrawTimer( t )
	local text = string.format( "%.02f seconds", self.flight_timer:GetSeconds() )
	local text_vsize = Render:GetTextSize( text, self.text_size )
	local text_vsize_3d = Vector3( text_vsize.x, text_vsize.y, 0 )
	local ang = Camera:GetAngle()

	local right = Copy( t )
	right:Translate( Vector3( self.x_offset, -0.5, -5 ) )
	right:Rotate( Angle( math.pi - math.rad(30), 0, math.pi ) )
	right:Scale( 0.002 )
	right:Translate( -text_vsize_3d/2 )

	Render:SetTransform( right )

	local col = Color( 255, 255, 255 )

	self:DrawText( text, col )
end

function SkydivingStats:Render()
	if not self.enabled then return end
	if Game:GetState() ~= GUIState.Game then return end
	if LocalPlayer:GetBaseState() ~= AnimationState.SSkydive then return end

	local position = LocalPlayer:GetBonePosition( "ragdoll_Head" )

	local t = Transform3()
	t:Translate( Camera:GetPosition() )	
	t:Rotate( Camera:GetAngle() )

	self:DrawSpeedometer( t )
	self:DrawAngle( t )
	self:DrawDistance( t )
	self:DrawTimer( t )
end

function SkydivingStats:FlightEnd()
	if self.stats_printout and (self.average_speed ~= nil) then 
		Chat:Print( "Flight ended!", Color( 0, 255, 0 ) )
		Chat:Print(
			string.format( "\tTime: %.02f seconds", self.flight_timer:GetSeconds() ),
			Color( 255, 255, 255 ) )
		Chat:Print(
			string.format( "\tAverage speed: %.02f %s", 
			self.average_speed * self:GetMultiplier(),
			self:GetUnitString() ),
			Color( 254,67,101 ) )
		Chat:Print(
			string.format( "\tAverage angle: %.02f\176", self.average_angle ),
			Color( 67,254,101 ) )	

		if self.average_distance ~= nil then
			Chat:Print(
				string.format( "\tAverage distance: %.02f m", self.average_distance ),
				Color( 0, 170, 255 ) )
		end
	end

	self.average_speed = nil
	self.average_angle = nil
	self.average_distance = nil
end

function SkydivingStats:PostTick()
	if not self.enabled then return end
	if LocalPlayer:GetBaseState() == last_state then return end

	if last_state == AnimationState.SSkydive then
		self:FlightEnd()
	end
	
	self.flight_timer:Restart()
	last_state = LocalPlayer:GetBaseState()
end

function SkydivingStats:LocalPlayerChat( args )
    local msg = args.text

    if msg == "/skydivestats" or msg == "/skydivingstats" then
        self:SetWindowOpen( not self:GetWindowOpen() )
    end
end

function SkydivingStats:LocalPlayerInput( args )
    if self:GetWindowOpen() and Game:GetState() == GUIState.Game then
        return false
    end
end

function SkydivingStats:ModuleLoad()
	Events:FireRegisteredEvent( "HelpAddItem",
        {
            name = "Skydiving Stats",
            text = 
                "The skydiving stats script shows you information about " ..
                "your current skydive; when you land or open your parachute, " ..
                "it will show statistics for your last flight.\n\n" ..
                "To configure it, type /skydivestats or /skydivingstats in chat."
        } )
end

function SkydivingStats:ModuleUnload()
    Events:FireRegisteredEvent( "HelpRemoveItem",
        {
            name = "Skydiving Stats"
        } )
end

fps = SkydivingStats()