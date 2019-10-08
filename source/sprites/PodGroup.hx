package sprites;

import states.OgmoState;
import flixel.math.FlxVector;
import flixel.group.FlxGroup;

class PodGroup
extends FlxTypedGroup<Pod>
implements IOgmoEntity
{
    var fireRate = 1.0;
    public var bulletSpeedScale(default, null) = 1.0;
    
    public var x(get, never):Float;
    public var y(get, never):Float;
    public var angle(get, never):Float;
    
    public var cockpit(default, null):Cockpit;
    public var bullets(default, null):FlxTypedGroup<Bullet> = new FlxTypedGroup();
    
    var hitTimer = 0.0;
    
    var fireCooldown = 0.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(0);
        
        add(cockpit = new Cockpit(this, x, y));
    }
    
    public function ogmoInit(data:OgmoEntityData, parent:OgmoEntityLayer):Void
    {
        cockpit.x = data.x;
        cockpit.y = data.y;
        if (Reflect.hasField(data, "rotation"))
            cockpit.angle = data.rotation;
    }
    
    public function linkPod(pod:Pod, parent:Pod = null):Pod
    {
        if (members.indexOf(pod) != -1)
            return pod;
        
        pod.setLinked(this, parent);
        return add(pod);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        cockpit.orientChildren();
        
        var firing = fireCooldown == 0 && cockpit.firing;
        if (firing)
        {
            fireCooldown += fireRate;
            
            for (pod in members)
            {
                if (pod != null && pod.alive)
                {
                    var bullet = pod.fire();
                    if (bullet != null)
                        bullets.add(bullet);
                }
            }
        }
        else if (fireCooldown > 0)
        {
            fireCooldown -= elapsed;
            if (fireCooldown <= 0)
                fireCooldown = 0;
        }
        
        if (hitTimer > 0)
        {
            hitTimer -= elapsed;
            if (hitTimer < 0)
            {
                hitTimer = 0;
                setSolid(true);
            }
        }
    }
    
    public function checkHealthAndFling(parent:FlxTypedGroup<Pod>):Void
    {
        var dead = cockpit.health <= 0;
        
        var i = 0;
        while(i < members.length)
        {
            var pod = members[i];
            if (pod != null && pod.alive && pod.health <= 0)
            {
                final freedPods = pod.killAndFreeChildren();
                while (freedPods.length > 0)
                    parent.add(remove(freedPods.pop()));
            }
            i++;
        }
        
        if (dead)
            kill();
    }
    
    public function bounce(setInvincible = false):Void
    {
        cockpit.velocity.scale(-1);
        if (setInvincible)
            startInvinciblePeriod();
    }
    
    public function startInvinciblePeriod():Void
    {
        setSolid(false);
        
        hitTimer = 0.5;
    }
    
    public function onPoked(attacker:PodGroup, victim:Pod):Void
    {
        victim.hit(2);
        cockpit.velocity.copyFrom(attacker.cockpit.velocity).scale(2);
        attacker.cockpit.velocity.set();
    }
    
    function setSolid(value:Bool):Bool
    {
        for (pod in members)
        {
            if (pod != null)
                pod.solid = value;
        }
        return value;
    }
    
    inline function get_x():Float { return cockpit.x; }
    inline function get_y():Float { return cockpit.y; }
    inline function get_angle():Float { return cockpit.angle; }
}