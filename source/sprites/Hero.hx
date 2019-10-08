package sprites;

import ui.Inputs;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxVector;
import flixel.input.gamepad.FlxGamepad;

class Hero extends PodGroup
{
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
        cockpit.health = 10;
        cockpit.turnSpeed = 180;
        cockpit.defaultColor = 0xFF5fcde4;
        fireRate = 0.5;
        
        FlxG.camera.follow(cockpit, FlxCameraFollowStyle.TOPDOWN);
        
        linkPod(new Pod(Thruster, x, y + Pod.RADIUS * 2));
        linkPod(new Pod(Poker   , x, y - Pod.RADIUS * 2));
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var thrust = FlxVector.get();
        var focus = FlxVector.get();
        
		var pad = FlxG.gamepads.getFirstActiveGamepad();
		if (pad != null)
		{
            thrust.x = pad.analog.value.LEFT_STICK_X;
            thrust.y = pad.analog.value.LEFT_STICK_Y;
            
            focus.x = pad.analog.value.RIGHT_STICK_X;
            focus.y = pad.analog.value.RIGHT_STICK_Y;
		}
        
        if (thrust.isZero())
        {
            var up    = Inputs.pressed.UP;
            var down  = Inputs.pressed.DOWN;
            var left  = Inputs.pressed.LEFT;
            var right = Inputs.pressed.RIGHT;
            
			thrust.x = (right ? 1 : 0) - (left ? 1 : 0);
			thrust.y = (down ? 1 : 0) - (up ? 1 : 0);
        }
        
        if (focus.isZero())
        {
            focus.x = FlxG.mouse.x - cockpit.x;
            focus.y = FlxG.mouse.y - cockpit.y;
        }
        
        cockpit.updateInput(elapsed, thrust, focus, FlxG.mouse.pressed);
    }
}