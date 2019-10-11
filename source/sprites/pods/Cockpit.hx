package sprites.pods;

import flixel.math.FlxVector;

@:allow(sprites.PodGroup)
class Cockpit extends Pod
{
    inline static var ACCEL_TIME = 0.25;
    inline static var DECEL_TIME = 0.50;
    
    override function get_flingChance():Float return 0;
    
    public var maxSpeed(default, set):Float = 0;
    function set_maxSpeed(value:Float)
    {
        drag.set(value / DECEL_TIME, value / DECEL_TIME);
        maxVelocity.set(value, value);
        return maxSpeed = value;
    }
    public var turnSpeed = 90.0;
    public var firing = false;
    
    public function new (group, x = 0.0, y = 0.0, angle = 0.0)
    {
        super(Cockpit, x, y, angle);
        this.group = group;
        maxSpeed = 150;
    }
    
    function updateInput(elapsed:Float, thrust:FlxVector, look:FlxVector, shooting:Bool):Void
    {
        firing = shooting;
		acceleration.copyFrom(thrust);
        acceleration.scale(maxSpeed / ACCEL_TIME);
        
        if (!look.isZero())
        {
            var lookAngle = look.degrees;
            if (angle >  180) angle -= 360;
            if (angle < -180) angle += 360;
            if (lookAngle - angle >  180) lookAngle -= 360;
            if (lookAngle - angle < -180) lookAngle += 360;
            var speed = turnSpeed * elapsed;
            
            if (Math.abs(lookAngle - angle) < speed)
                angle = lookAngle; 
            else
            {
                if (lookAngle - angle < 0)
                    angle -= speed;
                else
                    angle += speed;
            }
        }
    }
}