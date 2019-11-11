package sprites.bullets;


import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxVector;

import data.Cooldown;
import data.Gun;
import sprites.pods.Pod;

using Safety;

abstract BulletGroup(FlxTypedGroup<Bullet>) to FlxTypedGroup<Bullet>
{
    inline public function new(maxSize = 0)
    {
        this = new FlxTypedGroup<Bullet>(maxSize);
    }
    
    inline public function fire()
    {
        return this.recycle(Bullet);
    }
}

class Bullet extends Circle
{
    inline static var SCALE = 3;
    
    public var damage       (default, null) = 0.0;
    public var lifetime     (default, null) = 0.0;
    public var lifeRemaining(default, null):Cooldown = 0;
    public var impactForce  (default, null) = 0.0;
    public var pierce       (default, null) = 0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(4.0 * SCALE, x, y);
    }
    
    override function reset(X:Float, Y:Float)
    {
        super.reset(X, Y);
        
        scale.set(1, 1);
        damage = 0;
        lifetime = 0;
        lifeRemaining = 0;
        impactForce = 0;
        pierce = 0;
    }
    
    public function initFromPodWithGun(pod:Pod, gun:Gun):Bullet
    {
        solid = true;
        gun.graphic.loadGraphic(this);
        scale.set(gun.scale, gun.scale);
        setRadius(gun.radius.or(width / 2 * gun.scale));
        
        var shootAngle = pod.angle + switch(gun.scatter)
        {
            case null: 0;
            case Angle(spread): spread.getRandom();
            default: 0;
        }
        // place on pod perimiter
        velocity.setFromDegrees(shootAngle);
        cX = pod.cX + velocity.x * (radius + pod.radius);
        cY = pod.cY + velocity.y * (radius + pod.radius);
        velocity.scale(gun.speed);
        switch(gun.scatter)
        {
            case null | Angle(_)://handled above
            case Force(value, null, true): applyProjectedForce(value.getRandom(), value.getRandom(), true);
            case Force(value, null, _   ): applyProjectedForce(value.getRandom(), value.getRandom());
            case Force(par  , perp, true): applyProjectedForce(par  .getRandom(), (perp:Distribution).getRandom(), true);
            case Force(par  , perp, _   ): applyProjectedForce(par  .getRandom(), (perp:Distribution).getRandom());
        }
        
        velocity.addPoint(pod.group.cockpit.velocity);
        pod.group.bump
            ( velocity.x * -gun.fireForceRatio
            , velocity.y * -gun.fireForceRatio
            );
        
        lifeRemaining = lifetime = gun.time;
        radialDrag  = gun.drag;
        acceleration.set(gun.accel).degrees = shootAngle;
        damage      = gun.damage;
        impactForce = gun.speed / gun.impactForceRatio;
        // pierce      = gun.pierce;
        return this;
    }
    
    inline public function applyProjectedForce(parallel:Float, perpendicular:Float, rational = false)
    {
        if (!rational)
        {
            var length = velocity.length;
            velocity.add
                ( velocity.x * parallel / length - velocity.y * perpendicular / length
                , velocity.y * parallel / length + velocity.x * perpendicular / length
                );
        }
        else
        {
            velocity.add
                ( velocity.x * parallel - velocity.y * perpendicular
                , velocity.y * parallel + velocity.x * perpendicular
                );
        }
        return this;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (lifetime > 0 && lifeRemaining.tickAndCheckFire(elapsed))
            kill();
    }
    
    public function onHit(pod:Pod):Void
    {
        var forceScaler = impactForce / velocity.length;
        pod.group.bump(velocity.x * forceScaler, velocity.y * forceScaler);
        kill();
    }
}

abstract Exhaust(Bullet) from Bullet to Bullet
{
    public var visible(get, set):Bool;
    inline function get_visible() return this.visible;
    inline function set_visible(value:Bool) return this.visible = value;
    
    public function init(pod:Pod):Void
    {
        this.reset(0, 0);
        this.solid = false;
        this.loadGraphic("assets/images/exhaust.png", true);
        this.animation.add("idle", [0, 1], 15);
        this.animation.play("idle");
        this.setRadius(9);
        followPod(pod);
    }
    
    public function followPod(pod:Pod):Void
    {
        this.cX = pod.cX - Math.cos(pod.angle * FlxAngle.TO_RAD) * (this.radius + pod.radius);
        this.cY = pod.cY - Math.cos(pod.angle * FlxAngle.TO_RAD) * (this.radius + pod.radius);
        this.angle = pod.angle;
    }
}