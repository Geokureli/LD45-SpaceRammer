package ui.editor;

import flixel.FlxSprite;
import flixel.math.FlxVector;
import flixel.math.FlxAngle;

import data.PodData;
import sprites.pods.Pod;
import sprites.pods.PodType;

class UiPod extends sprites.Circle
{
    public var type    (default, null):PodType;
    public var parent  (default, null):Null<UiPod>;
    public var children(default, null):Map<Int, UiPod> = new Map();
    public var cockpit (default, null):Null<UiPod>;
    public var link    (default, null):Null<UiLink>;
    public var free(get, never):Bool;
    inline function get_free():Bool return parent == null && type != Cockpit;
    
    public var neighbor(default, null):Null<UiPod>;
    inline public function setNeighbor(pod:Null<UiPod>):Null<UiPod>
    {
        if (pod == null)
            link.hide();
        else
            link.clipTo(pod, this);
        
        return neighbor = pod;
    }
    
    public function new (type:PodType, x = 0.0, y = 0.0, angle = 0.0)
    {
        super(Pod.RADIUS);
        link = new UiLink();
        init(type, x, y, angle);
        
        scale.scale(Pod.SCALE);
        updateHitbox();
        offset.copyFrom(origin);
        
        if (type == Cockpit)
            cockpit = this;
    }
    
    public function init(type:PodType, x = 0.0, y = 0.0, angle = 0.0):Void
    {
        this.x = x;
        this.y = y;
        this.type = type;
        this.angle = angle;
        parent = null;
        cockpit = null;
        children.clear();
        
        loadGraphic(Pod.getGraphic(type));
    }
    
    public function setFree():Void
    {
        if (parent != null)
        {
            for (i in parent.children.keys())
            {
                if(parent.children[i] == this)
                    parent.children.remove(i);
            }
        }
        parent = null;
        cockpit = null;
        link.hide();
    }
    
    inline public function linkToNeighbor():Void setLinked(neighbor);
    
    public function setLinked(parent:UiPod):Void
    {
        neighbor = null;
        this.parent = parent;
        cockpit = parent.cockpit;
        // 6 spots to connect, 12o'clock is 0, increasing clockwise
        final angle = Math.atan2(y - parent.y, x - parent.x) * FlxAngle.TO_DEG - cockpit.angle;
        final index = (Math.round(angle / 60) + 6) % 6;
        parent.children[index] = this;
        link.clipTo(parent, this);
    }
    
    static public function fromData(data:PodData, x:Float, y:Float):UiPod
    {
        var pod = new UiPod(PodType.createByName(data.type), x, y, data.angle);
        pod.setChildrenFromData(data);
        return pod;
    }
    
    inline function setChildrenFromData(data:ShipData)
    {
        children.clear();
        var v = FlxVector.get(0, -Pod.RADIUS * 2);
        for (i in 0...6)
        {
            if (data[i] != null)
                fromData(data[i], x + v.x, y + v.y).setLinked(this);
            v.degrees -= 60;
        }
    }
}

@:forward
abstract UiCockpit(UiPod) to UiPod
{
    public function new(x = 0.0, y = 0.0, angle = -90.0)
    {
        this = new UiPod(Cockpit, x, y, angle);
    }
    
    inline public function fromData(data:ShipData, cockpit:UiPod)
    {
        this.angle = 0;
        @:privateAccess
        this.setChildrenFromData(data);
    }
    
    inline public function createJson():String
    {
        return new ShipData(this).toJson();
    }
}

@:allow(ui.editor.UiPod)
abstract UiLink(FlxSprite) to FlxSprite
{
    inline function new()
    {
        this = new FlxSprite("assets/images/link.png");
        this.offset.copyFrom(this.origin);
    }
    function hide():Void this.exists = false;
    function clipTo(parent:UiPod, child:UiPod):Void
    {
        this.exists = true;
        var dis = FlxVector.get(child.x - parent.x, child.y - parent.y);
        this.x = parent.x + dis.x / 2;
        this.y = parent.y + dis.y / 2;
        this.angle = dis.degrees;
        dis.put();
    }
}