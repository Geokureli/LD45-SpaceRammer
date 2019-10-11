package sprites;

import flixel.FlxG;
import flixel.math.FlxVector;
import flixel.group.FlxGroup;

import states.OgmoState;
import sprites.pods.*;

class PodGroup
extends FlxTypedGroup<Pod>
implements IOgmoEntity
{
    public var BOUNCE_TIME = 0.5;
    var fireRate = 1.0;
    public var bulletSpeedScale(default, null) = 1.0;
    
    public var x(get, never):Float;
    public var y(get, never):Float;
    public var angle(get, never):Float;
    
    public var cockpit(default, null):Cockpit;
    public var bullets(default, null):FlxTypedGroup<Bullet> = new FlxTypedGroup();
    
    var stunTime = 0.0;
    
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
        cockpit.orientChildren();
        
        super.update(elapsed);
        
        if (cockpit.health <= 0)
        {
            if (!cockpit.alive)
                kill();
            return;
        }
        
        if (stunTime == 0)
            updateControls(elapsed);
        
        var firing = fireCooldown == 0 && cockpit.firing;
        if (firing)
        {
            var fireForce = FlxVector.get();
            fireCooldown += fireRate;
            
            for (pod in members)
            {
                if (pod != null && pod.alive)
                {
                    var bullet = pod.fire(bullets);
                    if (bullet != null)
                    {
                        fireForce.add
                            ( bullet.velocity.x * -bullet.fireForce / bullet.speed
                            , bullet.velocity.y * -bullet.fireForce / bullet.speed
                            );
                    }
                }
            }
            bump(fireForce.x, fireForce.y);
        }
        else if (fireCooldown > 0)
        {
            fireCooldown -= elapsed;
            if (fireCooldown <= 0)
                fireCooldown = 0;
        }
        
        if (stunTime > 0)
        {
            stunTime -= elapsed;
            if (stunTime < 0)
                stunTime = 0;
        }
    }
    
    function updateControls(elapsed:Float):Void { }
    
    public function checkHealthAndFling(parent:FlxTypedGroup<Pod>, explosions:FlxTypedGroup<Explosion>):Void
    {
        var i = 0;
        while(i < members.length)
        {
            var pod = members[i];
            if (pod != null && pod.alive && pod.health <= 0 && !pod.exploding)
            {
                var delay = .25;
                final freedPods = pod.freeChildren(explosions, delay);
                delay += (freedPods.length + 1) * Pod.FLING_STAGGER;
                if (FlxG.random.bool(pod.flingChance * 100))
                {
                    freedPods.push(pod);
                    pod.setFree(explosions, delay);
                }
                else
                    pod.die(explosions, delay);
                
                while (freedPods.length > 0)
                    parent.add(remove(freedPods.pop()));
            }
            i++;
        }
    }
    
    public function bump(x:Float, y:Float, stunTime = 0.0):Void
    {
        cockpit.velocity.add(x, y);
        
        if (stunTime > 0)
            stun(stunTime);
    }
    
    public function bounce():Void
    {
        cockpit.velocity.scale(-1);
        
        if (stunTime > 0)
            stun(0.5);
    }
    
    inline function stun(time:Float):Void
    {
        cockpit.acceleration.set();
        
        stunTime = time;
    }
    
    public function onPoked(attacker:PodGroup, victim:Pod):Void
    {
        victim.hit(2);
        cockpit.velocity.copyFrom(attacker.cockpit.velocity).scale(2);
        attacker.bounce();
    }
    
    public function onShot(bullet:Bullet, victim:Pod):Void
    {
        victim.hit(bullet.damage);
        bump
            ( bullet.velocity.x * bullet.impactForce / bullet.speed
            , bullet.velocity.y * bullet.impactForce / bullet.speed
            );
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