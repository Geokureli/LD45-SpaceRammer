package sprites;

import flixel.math.FlxVector;

import states.OgmoState;
import sprites.pods.*;

class Enemy extends PodGroup
{
    var hero:Hero;
    var difficulty = 0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
        cockpit.defaultColor = 0xFFfbf236;
        fireRate = 1;
    }
    
    override function ogmoInit(data:OgmoEntityData, parent:OgmoEntityLayer):Void
    {
        cockpit.x = data.x;
        cockpit.y = data.y;
        
        hero = parent.getByName("hero");
        
        if (hero == null)
            throw "invalid hero";
        
        final rad2 = Pod.RADIUS * 2;
        difficulty = Std.parseInt(data.values.difficulty);
        switch(difficulty)
        {
            case 0:
                cockpit.defaultColor = 0xFF847e87;
                linkPod(new Pod(Thruster, x - rad2, y));
                linkPod(new Pod(Laser   , x + rad2, y));
            case 1:
                var pod = linkPod(new Pod(Laser, x + rad2, y));
                linkPod(new Pod(Laser   , x + rad2, y - rad2, -45), pod);
                linkPod(new Pod(Laser   , x + rad2, y + rad2,  45), pod);
                linkPod(new Pod(Thruster, x - rad2, y));
        }
        
        cockpit.angle = data.rotation;
        cockpit.maxSpeed = data.values.maxSpeed;
        cockpit.turnSpeed = data.values.turnSpeed;
        fireRate = data.values.fireRate;
    }
    
    override function updateControls(elapsed:Float)
    {
        super.updateControls(elapsed);
        
        if (difficulty == 0)
            return;
        
        var thrust = FlxVector.get();
        var focus = FlxVector.get();
        
        var distance = FlxVector.get(hero.x - x, hero.y - y);
        var length = distance.length;
        if (length < 500 && length > 100)
            thrust.copyFrom(distance).scale(1 / length);
        
        focus.copyFrom(distance);
        
        cockpit.updateInput(elapsed, thrust, focus, length < 200);
    }
}