package sprites.pods;

import flixel.math.FlxAngle;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.math.FlxVector;

import data.Cooldown;
import data.Gun;
import data.ExplosionGroup;
import data.PodData;
import sprites.*;
import sprites.bullets.Bullet;

@:allow(sprites.pods.PodGroup)
class Pod extends Circle
{
    inline static public var SCALE = 1.5;
    inline static public var RADIUS = 9 * SCALE;
    inline static public var DIAMETER_SQUARED = RADIUS * RADIUS * 4;
    
    inline static var FACING_ANGLE_INTERVAL = 60;
    inline static var BULLET_SPEED = 550;
    inline static var MIN_SPIN = 90;
    inline static var MAX_SPIN = 720;
    inline static var MIN_FLING = 50;
    inline static var MAX_FLING = 200;
    inline static var FLING_SPEED = 400;
    inline static var HIT_COLOR = 0xFFd95763;
    inline static var HIT_PERIOD = 0.08;
    inline static var HIT_CHEESE_PERIOD = 0.5;
    inline static public var FLING_STAGGER = 0.2;
    inline static public var FREE_LIFE_TIME = 5.0;
    inline static public var PRE_DIE_FLASH_TIME = 1.0;
    
    static var _v1 = FlxVector.get();
    
    public var type     (default, null):PodType;
    public var group    (default, null):Null<PodGroup>;
    public var parent   (default, null):Null<Pod>;
    public var children (default, null):Array<Pod> = [];
    public var linkDis  (default, null) = FlxVector.get();
    public var linkAngle(default, null) = 0.0;
    public var maxHealth(default, null) = 0;
    
    public var timesFlung(default, null) = 0;
    public var flingCooldown(default, null):Cooldown = 0.0;
    public var flingChance(get, never):Float;
    function get_flingChance():Float return timesFlung == 0 ? 1 : 0.5;
    
    public var free(get, never):Bool;
    inline function get_free():Bool return parent == null && type != Cockpit;
    public var catchable(default, null):Bool = true;
    
    public var exploding(default, null):Bool = false;
    var explosion:Null<Explosion>;
    
    public var dieCooldown(default, null):Cooldown = 0.0;
    var hitCooldown:Cooldown = 0.0;
    public var canHurt(get, never):Bool;
    inline function get_canHurt():Bool return !hitCooldown.cooling;
    
    var hasGun(get, never):Bool;
    inline function get_hasGun() return group.guns.exists(type);
    var gun(get, never):Null<Gun>;
    inline function get_gun() return group.guns[type];
    var fireCooldown:Cooldown = 0;
    
    var flashCooldown:Cooldown = 0.0;
    var _defaultColor = 0xffffff;
    public var defaultColor(get, set):Int;
    inline function get_defaultColor():Int return _defaultColor;
    function set_defaultColor(value:Int):Int 
    {
        if (color == _defaultColor)
            color = value;
        return _defaultColor = value;
    }
    
    public function new (type:PodType, x = 0.0, y = 0.0, angle = 0.0)
    {
        super(RADIUS);
        init(type, x, y, angle);
        
        scale.set(SCALE, SCALE);
        updateHitbox();
    }
    
    public function init(type:PodType, x = 0.0, y = 0.0, angle = 0.0):Void
    {
        this.x = x;
        this.y = y;
        this.type = type;
        this.angle = angle;
        angularVelocity = 0;
        radialDrag = 0;
        parent = null;
        children.resize(0);
        linkDis.set();
        linkAngle = 0;
        hitCooldown.reset();
        flashCooldown.reset();
        dieCooldown.reset();
        fireCooldown.reset();
        flingCooldown.reset();
        timesFlung = 0;
        exploding = false;
        catchable = true;
        elasticity = 1;
        health = maxHealth = 3;
        
        initTypeVars();
    }
    
    inline function initTypeVars()
    {
        loadGraphic(getGraphic(type));
        // offset.x = -(RADIUS * 2 - graphic.bitmap.width) / 2;
        // offset.y = -(RADIUS * 2 - graphic.bitmap.height) / 2;
        
        mass =  1;
        
        switch type
        {
            case Cockpit:
            case Laser:
            case Rocket:
            case Thruster:
            case Poker:
                //mass = 10;
            case Shield:
        }
    }
    
    function createChildrenFromData(data:ShipData):Void
    {
        final groupAngle = group.cockpit.angle;
        for (i in 0...6)
        {
            if (data[i] != null)
            {
                var pod = new Pod
                    ( PodType.createByName(data[i].type)
                    , x + Math.cos(FlxAngle.TO_RAD * (groupAngle + 60 * i)) * RADIUS * 2
                    , y + Math.sin(FlxAngle.TO_RAD * (groupAngle + 60 * i)) * RADIUS * 2
                    , (data[i].angle == null ? 0 : data[i].angle) + groupAngle
                    );
                group.linkPod(pod, this);
                pod.createChildrenFromData(data[i]);
            }
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (free)
            updateFree(elapsed);
        else
            updateLinked(elapsed);
        
        if (dieCooldown.cooling)
        {
            if (dieCooldown.tickAndCheckFire(elapsed))
            {
                dieNow();
                visible = true;
            }
            else if (dieCooldown.value < PRE_DIE_FLASH_TIME)
                visible = (dieCooldown.value / HIT_PERIOD) % 1 > 0.5;
        }
    }
    
    function updateFree(elapsed:Float):Void
    {
        if (!catchable && velocity.isZero())
            catchable = true;
    }
    
    function updateLinked(elapsed:Float):Void
    {
        hitCooldown.tick(elapsed, true);
        
        if (flashCooldown.tick(elapsed).cooling)
            color = ((flashCooldown.value / HIT_PERIOD) % 1 > 0.5) ? HIT_COLOR : _defaultColor;
        
        if (flingCooldown.tickAndCheckFire(elapsed))
            fling();
        
        if (health > 0)
        {
            switch type
            {
                case Rocket|Laser:
                    if (group.cockpit.firing)
                        fireCooldown.tick(elapsed);
                    
                    fireIfReady();
                case Poker:
                    fireCooldown.tick(elapsed);
                    // if (group.cockpit.dashing)
                        // fireIfReady();
                case _:
            }
        }
    }
    
    function orient(elapsed:Float):Void
    {
        _v1.copyFrom(linkDis).rotateByDegrees(parent.angle);
        x = parent.x + _v1.x;
        y = parent.y + _v1.y;
        velocity.set(x - last.x, y - last.y).scale(1 / elapsed);
        angle = linkAngle + parent.angle;
    }
    
    function orientChildren(elapsed:Float):Void
    {
        for (pod in children)
        {
            pod.orient(elapsed);
            pod.orientChildren(elapsed);
        }
    }
    
    public function onPoke(victim:Pod):Void
    {
        victim.hit(2);
        fire(); 
    }
    
    function fireIfReady()
    {
        if (gun.fireRate > 0 && fireCooldown.cooled)
        {
            fireCooldown += gun.fireRate;
            fire();
        }
    }
    
    function fire()
    {
        group.guns[type].fire(group.bullets, this);
    }
    
    public function setLinked(parent:Pod = null):Void
    {
        if (group != null)
            throw "already in group";
        
        if (parent == null)
            parent = group.cockpit;
        
        group = parent.group;
        velocity.set();
        angularVelocity = 0;
        this.parent = parent;
        parent.children.push(this);
        linkAngle = Math.round((angle - parent.angle) / FACING_ANGLE_INTERVAL) * FACING_ANGLE_INTERVAL;
        linkDis = FlxVector.get(x - parent.x, y - parent.y);
        linkDis.length = RADIUS * 2;
        linkDis.degrees = Math.round((linkDis.degrees - parent.angle) / 60) * 60;
        dieCooldown.reset();
        visible = true;
        if (hasGun)
            fireCooldown = FlxG.random.float(0, gun.fireRate);
    }
    
    function delayFling(explosions:ExplosionGroup, delay = 0.0):Void
    {
        if (exploding)
            throw "already free";
        
        explosion = explosions.create(RADIUS);
        explosion.visible = false;
        exploding = true;
        if (delay <= 0)
            fling();
        else
            flingCooldown = delay;
    }
    
    function fling():Void
    {
        exploding = false;
        explosion.visible = true;
        explosion.start((x + parent.x) / 2, (y + parent.y) / 2);
        final fling = FlxG.random.float(MIN_FLING, MAX_FLING);
        velocity.copyFrom(linkDis)
            .rotateByDegrees(parent.angle)
            .normalize()
            .scale(FLING_SPEED);
        
        radialDrag = sqr(FLING_SPEED) / 2 / fling;
        angularVelocity = FlxG.random.float(MIN_SPIN, MAX_SPIN);
        angularDrag = angularVelocity / FREE_LIFE_TIME;
        bumpGroupAtLinkAngle(200);
        setFree();
    }
    
    public function setFree():Void
    {
        color = defaultColor;
        group = null;
        hitCooldown.reset();
        flashCooldown.reset();
        fireCooldown.reset();
        alpha = 1;
        alive = true;
        parent.children.remove(this);
        parent = null;
        health = maxHealth;
        catchable = false;
        dieCooldown = FREE_LIFE_TIME;
    }
    
    public function bumpGroupAtLinkAngle(power:Float):Void
    {
        var v = linkDis.clone().normalize().scale(-power);
        v.rotateByDegrees(group.cockpit.angle);
        group.bump(v.x, v.y);
        v.put();
    }
    
    function explode(explosions:ExplosionGroup):Void
    {
        explosions.create(radius * 2).start(x, y);
        alpha = 0.5;
        alive = false;
        bumpGroupAtLinkAngle(200);
    }
    
    public function die(explosions:ExplosionGroup, delay = 0.0):Void
    {
        explosion = explosions.create(radius * 4);
        explosion.visible = false;
        exploding = true;
        if (delay <= 0)
            dieNow();
        else
            dieCooldown = delay;
    }
    
    function dieNow()
    {
        if (parent != null)
        {
            parent.children.remove(this);
            parent = null;
        }
        exploding = false;
        explosion.visible = true;
        explosion.start(x, y);
        kill();
    }
    
    function freeChildren(explosions:ExplosionGroup, startDelay = 0.0, list:Array<Pod> = null):Array<Pod>
    {
        if (list == null)
            list = [];
        
        var i = children.length;
        while(i-- > 0)
        {
            var pod = children[i];
            if (pod != null && !pod.exploding)
            {
                list.push(pod);
                var delay = startDelay + FLING_STAGGER * list.length;
                pod.freeChildren(explosions, startDelay, list);
                pod.delayFling(explosions, delay);
            }
        }
        
        return list;
    }
    
    public function touchPod(damage = 1.0):Void
    {
        if (damage > 0)
            hit(damage);
        
        if (type == Poker)
            fireIfReady();
        else if (type != Cockpit)
            parent.touchPod(0);
    }
    
    public function hit(damage = 1.0):Void
    {
        if (hitCooldown.cooling)
            return;
        
        health -= damage;
        // hitCooldown = 0.5;
        flashCooldown = 0.5;
    }
    
    
    public function checkOverlapPod(pod:Pod, checkHurt = true):Bool
    {
        return (!checkHurt || (canHurt && pod.canHurt)) && overlapCircle(pod);
    }
    
    public function checkOverlapBullet(bullet:Bullet):Bool
    {
        return canHurt && overlapCircle(bullet);
    }
    
    override function moveFromSeparate(x:Float, y:Float):Void
    {
        if (group == null || type == Cockpit)
            super.moveFromSeparate(x, y);
        else
        {
            group.cockpit.x += x - this.x;
            group.cockpit.y += y - this.y;
            super.moveFromSeparate(x, y);
        }
    }
    
    @:noCompletion
    override function bumpFromSeparate(x:Float, y:Float):Void
    {
        if (group == null || type == Cockpit)
            super.bumpFromSeparate(x, y);
        else
        {
            group.bump(x - velocity.x, y - velocity.y);
            super.bumpFromSeparate(x, y);
        }
    }
    
    override function destroy()
    {
        super.destroy();
        
        group = null;
        parent = null;
        children.resize(0);
    }
    
    inline static public function getGraphic(type:PodType):String
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
    
    inline static public function overlap
        ( objectOrGroup1:FlxBasic
        , objectOrGroup2:FlxBasic
        , ?notifyCallback:Pod->Pod->Void
        , ?processCallback:Pod->Pod->Bool
        ):Bool
    {
        return FlxG.overlap
            ( objectOrGroup1
            , objectOrGroup2
            , notifyCallback
            , processCallback != null ? processCallback : isOverlapping
            );
    }
    
    static public function isOverlapping(a:Pod, b:Pod):Bool
    {
        return a.checkOverlapPod(b);
    }
    
    inline static public function collide
        ( objectOrGroup1:FlxBasic
        , objectOrGroup2:FlxBasic
        , ?notifyCallback:Pod->Pod->Void
        ):Bool
    {
        return overlap(objectOrGroup1, objectOrGroup2, notifyCallback, separate);
    }
    
    static public function separate(a:Pod, b:Pod):Bool
    {
        // avoid checks between pods in the same group
        return (a.group != b.group || a.group == null)
            && a.alive && b.alive
            && Circle.separate(a, b);
    }
    
    inline static function sqr(num:Float) return num * num;
}