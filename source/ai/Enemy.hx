package ai;

import flixel.math.FlxVector;

import states.OgmoState;
import sprites.pods.*;

class Enemy extends Ship
{
    var hero:PodGroup;
    
    override function init(group:PodGroup, parent:OgmoEntityLayer):Void
    {
        super.init(group, parent);
        hero = parent.getByName("hero");
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var thrust = FlxVector.get();
        var focus = FlxVector.get();
        
        var distance = FlxVector.get(hero.x - cockpit.x, hero.y - cockpit.y);
        var length = distance.length;
        if (length < 500 && length > 100)
            thrust.copyFrom(distance).scale(1 / length);
        
        focus.copyFrom(distance);
        
        cockpit.updateInput(elapsed, thrust, focus, length < 350);
    }
}