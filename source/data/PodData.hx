package data;

import haxe.Json;
import ui.editor.UiPod;

@:noCompletion
typedef RawShipData =
    { ?child0:RawPodData
    , ?child1:RawPodData
    , ?child2:RawPodData
    , ?child3:RawPodData
    , ?child4:RawPodData
    , ?child5:RawPodData
    }

@:noCompletion
typedef RawPodData = RawShipData & { type:String, ?angle:Int }

abstract ShipData(RawShipData) from RawShipData to RawShipData
{
    public function new (pod:UiPod)
    {
        this = {};
        getChildren(pod);
    }
    
    public function getChildren(pod:UiPod)
    {
        var hasNonZeroChild = false;
        function createAndCheckAngle(child:UiPod):PodData
        {
            final child = new PodData(child);
            hasNonZeroChild = hasNonZeroChild || child.angle != null;
            return child;
        }
        
        if (pod.children[0] != null) this.child0 = createAndCheckAngle(pod.children[0]);
        if (pod.children[1] != null) this.child1 = createAndCheckAngle(pod.children[1]);
        if (pod.children[2] != null) this.child2 = createAndCheckAngle(pod.children[2]);
        if (pod.children[3] != null) this.child3 = createAndCheckAngle(pod.children[3]);
        if (pod.children[4] != null) this.child4 = createAndCheckAngle(pod.children[4]);
        if (pod.children[5] != null) this.child5 = createAndCheckAngle(pod.children[5]);
        
        if (hasNonZeroChild)
        {
            if (this.child0 != null && this.child0.angle == null) this.child0.angle = 0;
            if (this.child1 != null && this.child1.angle == null) this.child1.angle = 0;
            if (this.child2 != null && this.child2.angle == null) this.child2.angle = 0;
            if (this.child3 != null && this.child3.angle == null) this.child3.angle = 0;
            if (this.child4 != null && this.child4.angle == null) this.child4.angle = 0;
            if (this.child5 != null && this.child5.angle == null) this.child5.angle = 0;
        }
    }
    
    inline function exists(child:Int):Bool return getChild(child) != null;
    
    @:arrayAccess inline function getChild(child:Int):Null<PodData>
    {
        return cast switch(child)
        {
            case 0: this.child0;
            case 1: this.child1;
            case 2: this.child2;
            case 3: this.child3;
            case 4: this.child4;
            case 5: this.child5;
            case n: throw 'invalid child number: $n';
        }
    }
    
    public function toJson():String return Json.stringify(this);
}

abstract PodData(RawPodData) from RawPodData to RawPodData to ShipData
{
    public var type (get, never):String;
    inline function get_type () return this.type;
    public var angle(get, never):Null<Int>;
    inline function get_angle() return this.angle;
    
    public function new (pod:UiPod)
    {
        this = { type :pod.type.getName() };
        if (Math.round(pod.angle - pod.cockpit.angle) != 0)
            this.angle = Math.round(pod.angle - pod.cockpit.angle);
        
        (this:ShipData).getChildren(pod);
    }
    
    @:arrayAccess inline function getChild(child:Int):PodData
    {
        return cast switch(child)
        {
            case 0: this.child0;
            case 1: this.child1;
            case 2: this.child2;
            case 3: this.child3;
            case 4: this.child4;
            case 5: this.child5;
            case n: throw 'invalid child number: $n';
        }
    }
}