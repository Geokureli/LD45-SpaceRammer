package data;

import flixel.math.FlxVector;
import flixel.FlxG;
import flixel.system.FlxAssets;

import sprites.bullets.Bullet;
import sprites.pods.Pod;

@:structInit
class Gun
{
    static var defaultGraphic:BulletGraphicType
        = Animated("assets/images/bullet.png");
    
    public var shotsPerFire    (default, null) = 1;
    public var graphic         (default, null) = defaultGraphic;
    public var speed           (default, null) = 550.0;
    public var lifetime        (default, null) = 1.0;
    public var fireForceRatio  (default, null) = 0.1;
    public var impactForceRatio(default, null) = 0.2;
    public var damage          (default, null) = 1;
    public var scale           (default, null) = 3.0;
    public var drag            (default, null) = 0.0;
    public var scatter         (default, null):Null<ScatterType> = Angle(Even(5));
    public var radius          (default, null):Float = null;
    
    public function new
    ( shotsPerFire = 1
    , ?graphic    :BulletGraphicType
    , speed        = 550.0
    , lifetime     = 1.0
    , damage       = 1
    , ?scatter    :ScatterType
    , drag         = 0.0
    )
    {
        this.shotsPerFire = shotsPerFire;
        this.speed = speed;
        this.lifetime = lifetime;
        this.damage = damage;
        this.drag = drag;
        
        if (scatter != null)
            this.scatter = scatter;
        
        if (graphic != null)
            this.graphic = graphic;
    }
    
    public function fire(bullets:BulletGroup, pod:Pod)
    {
        var i = shotsPerFire;
        while (i-- > 0)
            bullets.fire().init(pod, this);
    }
}

enum ScatterType
{
    /** An angle spread in either direction. */
    Angle(spread:Distribution);
    /** Adds a random force to the fire vectors component along the axis of the gun barrel. */
    Force(parallel:Distribution, ?perpendicular:Distribution, ?rational:Bool);
}

@:using(Gun.DistributionTools)
enum Distribution
{
    Even(max:Float);
    Normal(deviation:Float);
}

@:noCompletion
class DistributionTools
{
    inline static public function getRandom(distribution:Distribution):Float
    {
        return switch (distribution)
        {
            case Even(max): FlxG.random.float(-max, max);
            case Normal(deviation): FlxG.random.floatNormal(0, deviation);
        }
    }
}

enum BulletGraphicType
{
    Static(asset:FlxGraphicAsset);
    Animated(asset:FlxGraphicAsset, ?width:Int, ?height:Int);
}