package sprites.pods;

import data.ExplosionGroup;
import data.PodData;

import flixel.FlxG;
import flixel.math.FlxVector;

@:allow(sprites.pods.PodGroup)
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
    public var hitCooldownTime = 0.25;
    
    public function new (group, x = 0.0, y = 0.0, angle = 0.0)
    {
        super(Cockpit, x, y, angle);
        this.group = group;
        maxSpeed = 150;
    }
    
    public function updateInput(elapsed:Float, ?thrust:FlxVector, ?look:FlxVector, shooting = false, dashing = false):Void
    {
        firing = shooting;
        
        if (thrust != null)
        {
            acceleration.copyFrom(thrust);
            acceleration.scale(maxSpeed / ACCEL_TIME);
        }
        else
            acceleration.set();
        
        if (look != null && !look.isZero())
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
    function checkHealthAndFling(explosions:ExplosionGroup, list:Array<Pod> = null):Array<Pod>
    {
        if (health <= 0)
        {
            if (!exploding)
            {
                var delay = 0.25;
                if (list != null)
                    delay += (list.length + 1) * Pod.FLING_STAGGER;
                
                list = freeChildren(explosions, delay, list);
                delay = 0.25 + (list.length + 1) * Pod.FLING_STAGGER;
                // if (FlxG.random.bool(flingChance * 100))
                // {
                //     list.push(this);
                //     delaFling(explosions, delay);
                // }
                // else
                    die(explosions, delay);
            }
        }
        else
        {
            var i = group.members.length;
            while (i-- > 0)
            {
                var pod = group.members[i];
                if (pod.alive && pod.health <= 0 && pod.canHurt)
                    pod.explode(explosions);
            }
        }
        
        return list;
    }
}