package sprites.pods;

import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.math.FlxVector;

import sprites.*;
import data.ExplosionGroup;

@:allow(sprites.PodGroup)
class Pod extends SkidSprite
{
    inline static var SCALE = 1.5;
    inline static public var RADIUS = 9 * SCALE;
    inline static public var RADIUS_SQUARED = RADIUS * RADIUS;
    inline static var BULLET_SCATTER = 2;
    inline static var MIN_SPIN = 90;
    inline static var MAX_SPIN = 720;
    inline static var MIN_FLING = 50;
    inline static var MAX_FLING = 200;
    inline static var FLING_SPEED = 400;
    inline static var HIT_COLOR = 0xFFd95763;
    inline static var HIT_PERIOD = 0.08;
    inline static var HIT_CHEESE_PERIOD = 0.5;
    inline static public var FLING_STAGGER = 0.1;
    
    static var _v1 = FlxVector.get();
    
    public var type     (default, null):PodType;
    public var group    (default, null):Null<PodGroup>;
    public var parentPod(default, null):Null<Pod>;
    public var childPods(default, null):Array<Pod> = [];
    public var linkDis  (default, null) = FlxVector.get();
    public var linkAngle(default, null) = 0.0;
    public var maxHealth(default, null) = 0;
    
    public var dieTimer(default, null) = 0.0;
    
    public var timesFlung(default, null) = 0;
    public var flingTimer(default, null) = 0.0;
    public var flingChance(get, never):Float;
    function get_flingChance():Float return timesFlung == 0 ? 1 : 0.5;
    public var free(get, never):Bool;
    inline function get_free():Bool return group == null;
    
    public var exploding(get, never):Bool;
    inline function get_exploding():Bool return flingTimer > 0 || dieTimer > 0;
    var explosion:Null<Explosion>;
    
    var hitTimer = 0.0;
    public var canHurt(get, never):Bool;
    inline function get_canHurt():Bool return hitTimer == 0;
    
    var _defaultColor = 0xFFffffff;
    public var defaultColor(get, set):Int;
    inline function get_defaultColor():Int return _defaultColor;
    inline function set_defaultColor(value:Int):Int 
    {
        _defaultColor = value;
        if (hitTimer == 0)
            color = value;
        return _defaultColor;
    }
    
    public function new (type:PodType, x = 0.0, y = 0.0, angle = 0.0)
    {
        super();
        init(type, x, y, angle);
        
        scale.set(SCALE, SCALE);
        width = RADIUS * 2;
        height = RADIUS * 2;
    }
    
    public function init(type:PodType, x = 0.0, y = 0.0, angle = 0.0):Void
    {
        this.x = x;
        this.y = y;
        this.type = type;
        this.angle = angle;
        angularVelocity = 0;
        drag.set();
        parentPod = null;
        childPods.resize(0);
        linkDis.set();
        linkAngle = 0;
        hitTimer = 0;
        flingTimer = 0.0;
        timesFlung = 0;
        
        health = maxHealth = Pod.getInitialHealth(type);
        loadGraphic(Pod.getGraphic(type));
        offset.x = -(RADIUS * 2 - graphic.bitmap.width) / 2;
        offset.y = -(RADIUS * 2 - graphic.bitmap.height) / 2;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (hitTimer > 0)
        {
            hitTimer -= elapsed;
            color = ((hitTimer / HIT_PERIOD) % 1 > 0.5) ? HIT_COLOR : _defaultColor;
            if (hitTimer < 0)
                hitTimer = 0;
        }
        
        if (flingTimer > 0)
        {
            flingTimer -= elapsed;
            if (flingTimer <= 0)
            {
                fling();
                flingTimer = 0;
            }
        }
        
        if (dieTimer > 0)
        {
            dieTimer -= elapsed;
            if (dieTimer <= 0)
            {
                dieNow();
                dieTimer = 0;
            }
        }
    }
    
    function orientChildren():Void
    {
        for (pod in childPods)
        {
            _v1.copyFrom(pod.linkDis).rotateByDegrees(angle);
            pod.x = x + _v1.x;
            pod.y = y + _v1.y;
            pod.angle = pod.linkAngle + angle;
            pod.orientChildren();// _v1 will change values from this call
        }
    }
    
    public function fire(parent:FlxTypedGroup<Bullet>):Null<Bullet>
    {
        if (!type.match(Rocket|Laser))
            return null;
        
        var bullet = parent.recycle(Bullet);
        bullet.init(x, y);
        (bullet.velocity:FlxVector)
            .set(bullet.speed, 0)
            .scale(group.bulletSpeedScale)
            .rotateByDegrees(angle + FlxG.random.floatNormal(0, BULLET_SCATTER));
        
        bullet.velocity.addPoint(group.cockpit.velocity);
        
        return bullet;
    }
    
    public function setLinked(group:PodGroup, parent:Pod = null):Void
    {
        if (this.group != null)
            throw "already in group";
        
        if (parent == null)
            parent = group.cockpit;
        
        this.group = group;
        velocity.set();
        angularVelocity = 0;
        parentPod = parent;
        parent.childPods.push(this);
        linkAngle = angle - parent.angle;
        linkDis = FlxVector.get(x - parent.x, y - parent.y);
        linkDis.rotateByDegrees(-parent.angle);
    }
    
    public function setFree(explosions:ExplosionGroup, delay = 0.0):Void
    {
        explosion = explosions.create(RADIUS);
        explosion.visible = false;
        if (delay <= 0)
            fling();
        else
        {
            flingTimer = delay;
            solid = false;
        }
    }
    
    function fling():Void
    {
        explosion.visible = true;
        explosion.start((x + parentPod.x) / 2, (y + parentPod.y) / 2);
        final fling = FlxG.random.float(MIN_FLING, MAX_FLING);
        (velocity.copyFrom(linkDis):FlxVector)
            .rotateByDegrees(parentPod.angle)
            .normalize()
            .scale(FLING_SPEED);
        
        angularVelocity = FlxG.random.float(MIN_SPIN, MAX_SPIN);
        drag.set(1, 1).scale(FLING_SPEED * FLING_SPEED / 2 / fling);
        solid = true;
        color = defaultColor;
        linkDis.normalize().scale(200);
        group.bump(linkDis.x, linkDis.y);
        group = null;
        hitTimer = 0;
        parentPod.childPods.remove(this);
        parentPod = null;
        health = maxHealth;
    }
    
    public function die(explosions:ExplosionGroup, delay = 0.0):Void
    {
        explosion = explosions.create(RADIUS * 2);
        explosion.visible = false;
        if (delay <= 0)
            dieNow();
        else
            dieTimer = delay;
    }
    
    function dieNow()
    {
        explosion.visible = true;
        explosion.start(x, y);
        kill();
    }
    
    public function freeChildren(explosions:ExplosionGroup, startDelay = 0.0, list:Array<Pod> = null):Array<Pod>
    {
        if (list == null)
            list = [];
        
        var i = childPods.length;
        while(i-- > 0)
        {
            var pod = childPods[i];
            if (pod != null && pod.alive)
            {
                list.push(pod);
                var delay = startDelay + FLING_STAGGER * list.length;
                pod.freeChildren(explosions, startDelay, list);
                pod.setFree(explosions, delay);
            }
        }
        
        return list;
    }
    
    public function hit(damage = 1):Void
    {
        if (hitTimer > 0)
            return;
        
        health -= damage;
        hitTimer = 0.5;
    }
    
    public function checkOverlapPod(pod:Pod, checkHurt = true):Bool
    {
        return (!checkHurt || (canHurt && pod.canHurt))
            && _v1.set(pod.x - x, pod.y - y).lengthSquared <= RADIUS_SQUARED;
    }
    
    public function checkOverlapBullet(bullet:Bullet):Bool
    {
        return canHurt && _v1.set(bullet.x - x, bullet.y - y)
            .lengthSquared <= (RADIUS + bullet.radius) * (RADIUS + bullet.radius);
    }
    
    inline static function getGraphic(type:PodType):String
    {
        return switch type
        {
            case Cockpit : "assets/images/cockpit.png";
            case Laser   : "assets/images/laser.png";
            case Rocket  : "assets/images/rocket.png";
            case Thruster: "assets/images/thruster.png";
            case Poker   : "assets/images/poker.png";
            case Shield  : "assets/images/shield.png";
        }
    }
    
    inline static function getInitialHealth(type:PodType)
    {
        return switch type
        {
            default: 3;
            // case Cockpit : 3;
            // case Laser   : 3;
            // case Rocket  : 3;
            // case Thruster: 3;
            // case Poker   : 3;
            // case Shield  : 3;
        }
    }
}

enum PodType
{
    Cockpit;
    Laser;
    Rocket;
    Thruster;
    Poker;
    Shield;
}