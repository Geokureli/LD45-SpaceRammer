package sprites.bullets;


import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxVector;

import data.Cooldown;
import data.Gun;
import sprites.pods.Pod;

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
    
    public var damage       (default, null) = 0;
    public var lifetime     (default, null) = 0.0;
    public var lifeRemaining(default, null):Cooldown = 0;
    public var impactForce  (default, null) = 0.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(4.0 * SCALE, x, y);
    }
    
    public function init(pod:Pod, gun:Gun):Bullet
    {
        this.x = pod.x;
        this.y = pod.y;
        
        var shootAngle = pod.angle + switch(gun.scatter)
        {
            case null: 0;
            case Angle(spread): spread.getRandom();
            default: 0;
        }
        setPolarVelocity(gun.speed, shootAngle);
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
        (acceleration:FlxVector).set(gun.accel).degrees = shootAngle;
        damage      = gun.damage;
        impactForce = gun.speed / gun.impactForceRatio;
        
        gun.graphic.loadGraphic(this);
        
        var newRadius = gun.radius;
        if (newRadius == null)
            newRadius = Math.min(graphic.width, graphic.height);
        
        radius = newRadius * gun.scale;
        
        scale.set(gun.scale, gun.scale);
        width  = (graphic.width  - 2) * gun.scale;
        height = (graphic.height - 2) * gun.scale;
        centerOffsets();
        return this;
    }
    
    inline public function setPolarVelocity(speed:Float, angle:Float):Bullet
    {
        (velocity:FlxVector).set(speed, 0).rotateByDegrees(angle);
        
        return this;
    }
    
    inline public function applyProjectedForce(parallel:Float, perpendicular:Float, rational = false)
    {
        if (!rational)
        {
            var length = (velocity:FlxVector).length;
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
        
        if (lifeRemaining.tickAndCheckFire(elapsed))
            kill();
    }
    
    public function onHit(pod:Pod):Void
    {
        kill();
    }
}