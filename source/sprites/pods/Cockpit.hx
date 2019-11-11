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
    
    public var dashSpeed:Float;
    public var normalSpeed:Float;
    public var maxSpeed(get, set):Float;
    function get_maxSpeed():Float return radialMaxVelocity;
    function set_maxSpeed(value:Float)
    {
        radialDrag = value / DECEL_TIME;
        return radialMaxVelocity = value;
    }
    public var turnSpeed = 360.0;
    public var hitCooldownTime = 0.25;
    
    public function new (group, x = 0.0, y = 0.0, angle = 0.0)
    {
        super(Cockpit, x, y, angle);
        this.group = group;
        maxSpeed = normalSpeed = 150;
        dashSpeed = 300;
    }
    
    public function updateInput(elapsed:Float, ?thrust:FlxVector, ?look:FlxVector, shooting = false, dashing = false):Void
    {
        if (thrust != null && thrust.isZero())
            thrust = null;
        
        if (look != null && look.isZero())
            look = null;
        
        if (thrust == null)
            dashing = false;
        
        var seekingThruster = dashing;
        for (pod in group.members)
        {
            if (pod != null && pod.health > 0)
            {
                switch(pod.type)
                {
                    case Laser | Rocket:
                        pod.firing = shooting;
                    case Thruster:
                        pod.firing = seekingThruster && pod.checkCanThrust(thrust);
                        if (pod.firing)
                            seekingThruster = false;
                    case _:
                        pod.firing = false;
                }
            }
        }
        // Can't dash if no thruster is avaliable
        dashing = dashing && !seekingThruster;
        
        acceleration.set();
        if (dashing)
        {
            maxSpeed = dashSpeed;
            velocity.copyFrom(thrust);
            velocity.length = maxSpeed;
        }
        else
        {
            maxSpeed = normalSpeed;
            if (thrust != null)
            {
                acceleration.copyFrom(thrust);
                acceleration.scale(maxSpeed / ACCEL_TIME);
            }
            
            // Can't turn while dashing
            if (look != null)
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