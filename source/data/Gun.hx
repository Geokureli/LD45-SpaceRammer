package data;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxVector;
import flixel.system.FlxAssets;

import data.MotionType;
import sprites.bullets.Bullet;
import sprites.pods.Pod;

using Safety;

@:structInit
class Gun
{
    static var defaultGraphic:BulletGraphicType
        = Animated("assets/images/bullet.png");
    
    public var shotsPerFire    (default, null) = 1;
    public var fireRate        (default, null) = 0.25;
    public var graphic         (default, null) = defaultGraphic;
    public var fireForceRatio  (default, null) = 0.1;
    public var impactForceRatio(default, null) = 0.2;
    public var damage          (default, null) = 1.0;
    public var scale           (default, null) = 3.0;
    public var scatter         (default, null):Null<ScatterType> = Angle(Even(5));
    public var radius          (default, null):Null<Float> = null;
    
    var motionData:MotionData;
    public var time (get, never):Float; inline function get_time () return motionData.time;
    public var speed(get, never):Float; inline function get_speed() return motionData.speed;
    public var drag (get, never):Float; inline function get_drag () return motionData.drag;
    public var accel(get, never):Float; inline function get_accel() return motionData.accel;
    public var max  (get, never):Float; inline function get_max  () return motionData.max;
    
    public function new
    ( shotsPerFire = 1
    , fireRate     = 0.25
    , ?graphic    :BulletGraphicType
    , ?motion     :MotionType
    , damage       = 1.0
    , ?scatter    :ScatterType
    )
    {
        this.shotsPerFire = shotsPerFire;
        this.damage = damage;
        this.motionData = motion.or(DisAndTime(400, 0.50)).createData();
        
        if (scatter != null)
            this.scatter = scatter;
        
        if (graphic != null)
            this.graphic = graphic;
    }
    
    public function fire(bullets:BulletGroup, pod:Pod)
    {
        var i = shotsPerFire;
        while (i-- > 0)
            bullets.fire().initFromPodWithGun(pod, this);
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

typedef BulletAttack =
{
    damage:Float,
    impactForce:Float,
    ?pierce:Int
}

@:using(Gun.GraphicTools)
enum BulletGraphicType
{
    Static(asset:FlxGraphicAsset);
    Animated(asset:FlxGraphicAsset, ?width:Int, ?height:Int);
}

@:noCompletion
class GraphicTools
{
    inline static public function loadGraphic(type:BulletGraphicType, sprite:FlxSprite)
    {
        switch (type)
        {
            case Static(asset):
                sprite.loadGraphic(asset);
            case Animated(asset, width, height):
                sprite.loadGraphic
                    ( asset
                    , true
                    , width  == null ? 0 : width
                    , height == null ? 0 : height
                    );
                sprite.animation.add("idle", [for (i in 0...sprite.animation.frames) i], 15);
                sprite.animation.play("idle");
        }
    }
}