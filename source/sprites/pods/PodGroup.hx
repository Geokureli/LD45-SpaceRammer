package sprites.pods;

import data.ExplosionGroup;
import flixel.FlxG;
import flixel.math.FlxVector;
import flixel.group.FlxGroup;

import ai.Ship;
import data.Gun;
import data.PodData;
import states.OgmoState;
import sprites.bullets.Bullet;

typedef OgmoPod = 
{ type     :ShipType
, id       :String
, maxSpeed :OgmoInt
, dashSpeed:OgmoInt
, turnSpeed:OgmoInt
, color    :OgmoColor
, health   :OgmoInt
}

class PodGroup
extends FlxTypedGroup<Pod>
implements IOgmoEntity<OgmoPod>
{
    public var BOUNCE_TIME = 0.5;
    
    public var x(get, never):Float;
    public var y(get, never):Float;
    public var angle(get, never):Float;
    
    public var cockpit(default, null):Cockpit;
    public var bullets:BulletGroup;
    public var explosions:ExplosionGroup;
    
    public var guns(default, null):Map<PodType, Gun> =
        [ Laser  => new Gun(DisAndTime(400, 0.66, FromStop), Angle(Even(5)))
        , Rocket => new Gun()
        , Poker  => new Gun(4, DisAndTime(200, 0.25, ToStop), 0.25, Force(Normal(0.25), true))
        ];
    
    var controller:Ship;
    var stunTime = 0.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(0);
        
        add(cockpit = new Cockpit(this, x, y));
    }
    
    public function ogmoInit(data:OgmoEntityData<OgmoPod>, parent:OgmoEntityLayer):Void
    {
        cockpit.x = data.x;
        cockpit.y = data.y;
        if (Reflect.hasField(data, "rotation"))
            cockpit.angle = data.rotation;
        
        final rad2 = Pod.RADIUS * 2;
        
        cockpit.angle = data.rotation;
        if (!data.values.maxSpeed.isEmpty)
            cockpit.maxSpeed = cockpit.normalSpeed = data.values.maxSpeed.sure;
        if (!data.values.dashSpeed.isEmpty)
            cockpit.dashSpeed = data.values.dashSpeed.sure;
        if (!data.values.turnSpeed.isEmpty)
            cockpit.turnSpeed = data.values.turnSpeed.sure;
        cockpit.defaultColor = data.values.color.sure;
        
        cockpit.createChildrenFromData(ShipType.getData(data.values.type));
        controller = ShipType.getClass(data.values.type);
        controller.init(this, parent);
    }
    
    public function linkPod(pod:Pod, parent:Pod = null):Pod
    {
        if (members.indexOf(pod) != -1)
            return pod;
        
        if (parent == null)
            parent = cockpit;
        
        pod.setLinked(parent);
        return add(pod);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        cockpit.orientChildren(elapsed);
        
        if (cockpit.health <= 0)
        {
            if (!cockpit.alive)
                kill();
            return;
        }
        
        if (stunTime == 0)
            updateControls(elapsed);
        
        // if (cockpit.firing)
        // {
        //     for (pod in members)
        //         if (pod != null && pod.alive && pod.health > 0)
        //             pod.fireIfReady(elapsed);
        // }
        
        if (stunTime > 0)
        {
            stunTime -= elapsed;
            if (stunTime < 0)
                stunTime = 0;
        }
    }
    
    function updateControls(elapsed:Float):Void
    {
        controller.update(elapsed);
    }
    
    public function getFirstCanThrust(dir:FlxVector):Null<Pod>
    {
        for (member in members)
        {
            if (member != null
            && member.type == Thruster
            && member.health > 0
            && member.checkCanThrust(dir))
                return member;
        }
        return null;
    }
    
    public function canThrust(dir:FlxVector):Bool
    {
        return getFirstCanThrust(dir) != null;
    }
    
    public function checkHealthAndFling(parent:FlxTypedGroup<Pod>, explosions:FlxTypedGroup<Explosion>):Void
    {
        final freedPods = cockpit.checkHealthAndFling(explosions);
        if (freedPods != null)
        {
            while (freedPods.length > 0)
            {
                var pod = freedPods.pop();
                if (members.indexOf(pod) == -1)
                    throw "null wtf!";
                
                remove(pod);
                parent.add(pod);
            }
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
    
    inline public function forEachHealthy(f:(Pod)->Void):Void
    {
        for (member in members)
        {
            if (member != null && member.health > 0)
                f(member);
        }
    }    
    
    inline public function forEachPodType(type:PodType, f:(Pod)->Void, healthy = true):Void
    {
        for (member in members)
        {
            if (member != null && member.type == type && (!healthy || member.health > 0))
                f(member);
        }
    }    
    
    inline function get_x():Float { return cockpit.x; }
    inline function get_y():Float { return cockpit.y; }
    inline function get_angle():Float { return cockpit.angle; }
}