package sprites.bullets;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxVector;

import sprites.pods.Pod;

abstract BulletGroup(FlxTypedGroup<Bullet>) to FlxTypedGroup<Bullet>
{
    inline public function new(maxSize = 0)
    {
        this = new FlxTypedGroup<Bullet>(maxSize);
    }
    
    inline public function fire(x = 0.0, y = 0.0)
    {
        return this.recycle(Bullet).init(x, y);
    }
    
    inline public function fireFrom(pod:Pod, speed:Float, scatterAngle:Float)
    {
        var bullet = fire(pod.x, pod.y).setPolarVelocity(speed, pod.angle, scatterAngle);
        bullet.velocity.addPoint(pod.velocity);
        return bullet;
    }
}

class Bullet extends Circle
{
    inline static var SCALE = 3;
    public var damage       (default, null) = 0;
    public var lifeTime     (default, null) = 0.0;
    public var lifeRemaining(default, null) = 0.0;
    public var fireForce    (default, null) = 0.0;
    public var impactForce  (default, null) = 0.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(4.0 * SCALE, x, y);
    }
    
    public function init(x = 0.0, y = 0.0):Bullet
    {
        this.x = x;
        this.y = y;
        
        // elasticity = 1;
        damage = 1;
        lifeTime = 1;
        lifeRemaining = lifeTime;
        fireForce = 50;
        impactForce = 100;
        setRadius(4.0 * SCALE);
        loadGraphic("assets/images/bullet.png", true);
        animation.add("idle", [0,1], 15);
        animation.play("idle");
        width  = (graphic.width  - 2) * SCALE;
        height = (graphic.height - 2) * SCALE;
        scale.set(SCALE, SCALE);
        centerOffsets();
        
        return this;
    }
    
    inline public function setPolarVelocity(speed:Float, angle:Float, scatterAngle:Float):Bullet
    {
        (velocity:FlxVector)
            .set(speed, 0)
            .rotateByDegrees(angle + FlxG.random.floatNormal(0, scatterAngle));
        
        return this;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        lifeRemaining -= elapsed;
        if (lifeRemaining <= 0)
            kill();
    }
    
    public function onHit(pod:Pod):Void
    {
        kill();
    }
}