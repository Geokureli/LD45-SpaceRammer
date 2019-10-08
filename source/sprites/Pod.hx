package sprites;

import flixel.FlxG;
import flixel.math.FlxVector;

@:allow(sprites.PodGroup)
class Pod extends SkidSprite
{
    static inline public var RADIUS = 9;
    static inline public var RADIUS_SQUARED = RADIUS * RADIUS;
    static inline var MIN_FLING = 200;
    static inline var MAX_FLING = 400;
    static inline var FLING_TIME = 0.5;
    static inline var HIT_COLOR = 0xFFd95763;
    static inline var HIT_PERIOD = 0.08;
    static inline var HIT_CHEESE_PERIOD = 0.5;
    
    static var _v1 = FlxVector.get();
    
    public var type:PodType;
    public var parentPod:Null<Pod>;
    public var childPods:Array<Pod> = [];
    public var linkDis = FlxVector.get();
    public var linkAngle = 0.0;
    public var group:PodGroup;
    
    public var free(get, never):Bool;
    inline function get_free():Bool return group == null;
    
    public var tutorialInvincible = false;
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
        init(type, x, y);
        
        width = RADIUS * 2;
        height = RADIUS * 2;
    }
    
    public function init(type:PodType, x = 0.0, y = 0.0, angle = -90.0):Void
    {
        this.x = x;
        this.y = y;
        this.type = type;
        this.angle = angle;
        drag.set();
        parentPod = null;
        childPods.resize(0);
        linkDis.set();
        linkAngle = 0;
        hitTimer = 0;
        
        health = Pod.getInitialHealth(type);
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
    
    public function fire():Null<Bullet>
    {
        if (!type.match(Rocket|Laser))
            return null;
        
        var bullet = new Bullet(x, y);
        (bullet.velocity:FlxVector)
            .set(bullet.speed, 0)
            .scale(group.bulletSpeedScale)
            .rotateByDegrees(angle)
            .addPoint(group.cockpit.velocity);
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
        parentPod = parent;
        parent.childPods.push(this);
        linkAngle = angle - parent.angle;
        linkDis = FlxVector.get(x - parent.x, y - parent.y);
        linkDis.rotateByDegrees(-parent.angle);
    }
    
    public function setFree():Void
    {
        final flingSpeed = FlxG.random.float(MIN_FLING, MAX_FLING);
        (velocity.copyFrom(linkDis):FlxVector)
            .rotateByDegrees(parentPod.angle)
            .normalize()
            .scale(flingSpeed);
        
        drag.set(1, 1).scale(flingSpeed / FLING_TIME);
        solid = true;
        color = defaultColor;
        group = null;
        hitTimer = 0;
        parentPod.childPods.remove(this);
        parentPod = null;
        tutorialInvincible = false;
    }
    
    public function killAndFreeChildren():Array<Pod>
    {
        var children = freeChildren();
        kill();
        return children;
    }
    
    function freeChildren(list:Array<Pod> = null):Array<Pod>
    {
        if (list == null)
            list = [];
        
        var i = childPods.length;
        while(i-- > 0)
        {
            var pod = childPods.pop();
            list.push(pod);
            pod.freeChildren(list);
            pod.setFree();
        }
        
        return list;
    }
    
    public function hit(damage = 1):Void
    {
        if (hitTimer > 0)
            return;
        
        if (!tutorialInvincible)
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