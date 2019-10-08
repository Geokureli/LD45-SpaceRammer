package sprites;

import states.OgmoState;
import flixel.math.FlxVector;

class Enemy extends PodGroup
{
    var hero:Hero;
    var difficulty = 0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
        cockpit.defaultColor = 0xFFfbf236;
        fireRate = 3;
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
                linkPod(new Pod(Thruster, x       , y + rad2));
                linkPod(new Pod(Laser   , x       , y - rad2)).tutorialInvincible = true;
            case 1:
                var pod = linkPod(new Pod(Laser, x, y - rad2));
                linkPod(new Pod(Laser   , x + rad2, y - rad2), pod);
                linkPod(new Pod(Laser   , x - rad2, y - rad2), pod);
                linkPod(new Pod(Thruster, x       , y + rad2));
        }
        
        cockpit.angle = data.rotation;
        cockpit.maxSpeed = data.values.maxSpeed;
        cockpit.turnSpeed = data.values.turnSpeed;
        fireRate = data.values.fireRate;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (difficulty == 0)
            return;
        
        var thrust = FlxVector.get();
        var focus = FlxVector.get();
        
        var distance = FlxVector.get(hero.x - x, hero.y - y);
        var length = distance.length;
        if (length < 500 && length > 100)
            thrust.copyFrom(distance).scale(distance.length);
        
        focus.copyFrom(distance);
        
        cockpit.updateInput(elapsed, thrust, focus, length < 200);
    }
}