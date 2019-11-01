package ai;

import input.Inputs;
import states.OgmoState;
import sprites.pods.*;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxVector;
import flixel.input.gamepad.FlxGamepad;

class Hero extends Ship
{
    var lastMouseScreenPos = FlxVector.get();
    var mouseMode = true;
    
    override function init(group:PodGroup, parent:OgmoEntityLayer)
    {
        super.init(group, parent);
        
        group.cockpit.hitCooldownTime = 0;
        
        FlxG.camera.follow(group.cockpit, FlxCameraFollowStyle.TOPDOWN);
        lastMouseScreenPos.set(FlxG.mouse.screenX, FlxG.mouse.screenY);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var thrust = FlxVector.get();
        var focus = FlxVector.get();
        
        var pad = FlxG.gamepads.getFirstActiveGamepad();
        if (pad != null && checkPadChange(pad))
        {
            mouseMode = false;
            
            thrust.x = pad.analog.value.LEFT_STICK_X;
            thrust.y = pad.analog.value.LEFT_STICK_Y;
            
            focus.x = pad.analog.value.RIGHT_STICK_X;
            focus.y = pad.analog.value.RIGHT_STICK_Y;
        }
        else if (mouseMode || checkKeyMouseChange())
        {
            mouseMode = true;
            
            focus.x = FlxG.mouse.x - cockpit.x;
            focus.y = FlxG.mouse.y - cockpit.y;
            
            var up    = Inputs.pressed.UP;
            var down  = Inputs.pressed.DOWN;
            var left  = Inputs.pressed.LEFT;
            var right = Inputs.pressed.RIGHT;
            
            thrust.x = (right ? 1 : 0) - (left ? 1 : 0);
            thrust.y = (down ? 1 : 0) - (up ? 1 : 0);
        }
        lastMouseScreenPos.set(FlxG.mouse.screenX, FlxG.mouse.screenY);
        
        cockpit.updateInput
            ( elapsed
            , thrust
            , focus
            , Inputs.pressed.SHOOT || FlxG.mouse.pressed     //TODO: check mouse in Inputs
            , Inputs.pressed.DASH  || FlxG.mouse.pressedRight//TODO: check mouse in Inputs
            );
    }
    
    inline function checkPadChange(pad:FlxGamepad):Bool
    {
        return pad.analog.justMoved.LEFT_STICK
            || pad.analog.justMoved.RIGHT_STICK
            || pad.pressed.ANY
            || pad.justReleased.ANY
            ;
    }
    
    inline function checkKeyMouseChange():Bool
    {
        // return FlxG.mouse.justMoved// tracks world pos, we need screen pos
        return lastMouseScreenPos.x != FlxG.mouse.screenX
            || lastMouseScreenPos.y != FlxG.mouse.screenY
            || FlxG.keys.pressed.ANY
            || FlxG.keys.justReleased.ANY
            ;
    }
}