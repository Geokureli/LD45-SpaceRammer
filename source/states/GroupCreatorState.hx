package states;

import flixel.math.FlxAngle;
import flixel.math.FlxVector;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

import sprites.Circle;
import sprites.pods.Cockpit;
import sprites.pods.Pod;
import sprites.pods.PodType;

class GroupCreatorState extends flixel.FlxState
{
    inline static var GRID_X = Pod.RADIUS * 2 * 0.866025403784439;//sin(60);
    inline static var GRID_Y = Pod.RADIUS * 2;
    inline static var OFFSET_Y = -Pod.RADIUS;
    
    var pods:FlxTypedGroup<UiPod>;
    var placePod:UiPod;
    var cockpit:UiPod;
    
    var columns = Math.ceil(FlxG.width / GRID_X / 2) * 2;// must be even so all offset indices are even
    var rows = Math.ceil(FlxG.height / GRID_Y);
    var takenSpots:Map<Int, UiPod>;
    var activeTool:ToolType = Mouse;
    
    override function create()
    {
        super.create();
        add(pods = new FlxTypedGroup());
        var pos = getNearestHexCoord(FlxG.width / 2, FlxG.height / 2);
        pods.add(cockpit = new UiPod(Cockpit, pos.x, pos.y, -90));
        pos.put();
        takenSpots = [getNearestHexIndex(cockpit.x, cockpit.y) => cockpit];
        
        for (i in 0...6)
        {
            var type = i == 0 ? Mouse : PlacePod(PodType.createByIndex(i));
            final button = new Button(type, 10, 10, onButtonClick);
            button.y += (10 + button.height) * i;
            if (i > 0)
                button.angle = cockpit.angle;
            add(button);
        }
    }
    
    function onButtonClick(type:ToolType):Void
    {
        activeTool = type;
        
        switch(type)
        {
            case PlacePod(type):
                setPlacePod(type);
            case Mouse:
                killPlacePod();
        }
    }
    
    inline function killPlacePod():Void
    {
        if (placePod != null)
        {
            pods.remove(placePod);
            placePod.kill();
            placePod = null;
        }
    }
    
    function setPlacePod(type:PodType, forceNew = false)
    {
        if (forceNew)
            killPlacePod();
        
        if (placePod == null)
        {
            pods.add(placePod = new UiPod(type, -100));
            placePod.angle = cockpit.angle;
        }
        else
        {
            placePod.exists = true;
            placePod.init(type);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        switch (activeTool)
        {
            case Mouse      : updateMouse(elapsed);
            case PlacePod(_): updatePlacePod(elapsed);
        }
    }
    
    function updateMouse(elapsed:Float)
    {
        if (placePod == null)
        {
            if (FlxG.mouse.justPressed)
            {
                var mouseIndex = getNearestHexIndex(FlxG.mouse.x - Pod.RADIUS, FlxG.mouse.y - Pod.RADIUS);
                if (takenSpots.exists(mouseIndex) && takenSpots[mouseIndex] != cockpit)
                {
                    placePod = takenSpots[mouseIndex];
                    placePod.setFree();
                    takenSpots.remove(mouseIndex);
                }
            }
        }
        else
            updateMouseMovePod(elapsed);
    }
    
    /** Update handler for ToolType.Mouse when a pod is clicked and dragged */
    function updateMouseMovePod(elapsed:Float)
    {
        if (!FlxG.mouse.pressed)
        {
            var attached = attachPod(placePod);
            if (!attached)
                killPlacePod();
            else
                placePod = null;
        }
        else if (FlxG.mouse.justMoved)
            movePodToMouse(placePod);
    }
    
    /** Update handler for ToolType.PlacePod */
    function updatePlacePod(elapsed:Float)
    {
        if (placePod.free)
        {
            if (FlxG.mouse.justMoved)
                movePodToMouse(placePod);
            
            if (FlxG.mouse.justPressed)
                attachPod(placePod);
        }
        
        //separate if/else in case justPressed and justReleased are handled in the same frame
        if (!placePod.free)
        {
            if (FlxG.mouse.justReleased)
            {
                var type = placePod.type;
                placePod = null;
                setPlacePod(type);
            }
            else if (FlxG.mouse.pressed && FlxG.mouse.justMoved && !FlxG.mouse.justPressed)
                rotatePodToMouse(placePod);
        }
    }
    
    function movePodToMouse(pod:UiPod)
    {
        var gridMouse = getNearestHexCoord(FlxG.mouse.x - pod.radius, FlxG.mouse.y - pod.radius);
        // check if moved tiles, update color to convey valid placement
        if (pod.x != gridMouse.x || pod.y != gridMouse.y)
        {
            var tileIndex = getNearestHexIndex(gridMouse.x, gridMouse.y);
            pod.alpha = 0.5;
            if (!takenSpots.exists(tileIndex) && getTouchingPod(tileIndex, cockpit) != null)
                pod.alpha = 1;
            
            pod.x = gridMouse.x;
            pod.y = gridMouse.y;
        }
        
        gridMouse.put();
    }
    
    function rotatePodToMouse(pod:UiPod)
    {
        var mouse = FlxVector.get(FlxG.mouse.x, FlxG.mouse.y);
        if (FlxG.keys.pressed.SHIFT)
            mouse = roundToNearestHexCoord(mouse);
        
        if (mouse.x != pod.x && mouse.y != pod.y)
        {
            var v = FlxVector.get(mouse.x - pod.x, mouse.y - pod.y);
            pod.angle = v.degrees + cockpit.angle;
            v.put();
        }
        mouse.put();
    }
    
    function attachPod(pod:UiPod):Bool
    {
        var index = getNearestHexIndex(pod.x, pod.y);
        if (!takenSpots.exists(index))
        {
            var parent = getTouchingPod(index, cockpit);
            if (parent != null)
            {
                pod.setLinked(parent);
                takenSpots[index] = pod;
                return true;
            }
        }
        return false;
    }
    
    function getTouchingPod(index:Int, pod:UiPod):UiPod
    {
        if (isAdjacent(getPodHexIndex(pod), index))
            return pod;
        
        for (i in pod.childPods.keys())
        {
            var child = getTouchingPod(index, pod.childPods[i]);
            if (child != null)
                return child;
        }
        
        return null;
    }
    
    inline function sqr(num:Float):Float return num * num;
    inline function isOffsetColumn(index:Int):Bool return index % 2 == 1;
    inline function getColumnOffset(index:Int):Float return (index % 2) * OFFSET_Y;
    inline function getHexIndex(column:Int, row:Int):Int return row * columns + column;
    inline function getColumn(index:Int):Int return index % columns;
    inline function getRow(index:Int):Int return Math.floor(index / columns);
    
    inline function roundToNearestHexCoord(v:FlxVector):FlxVector
    {
        return getNearestHexCoord(v.x, v.y, v);
    }
    
    function getNearestHexCoord(x:Float, y:Float, ?newVector:FlxVector):FlxVector
    {
        if (newVector == null)
            newVector = FlxVector.get();
        
        var index = getNearestHexIndex(x, y);
        newVector.x = getColumn(index) * GRID_X;
        newVector.y = getColumnOffset(index) + getRow(index) * GRID_Y;
        return newVector;
    }
    
    function getNearestHexIndexPair(x:Float, y:Float, ?newVector:FlxVector):FlxVector
    {
        if (newVector == null)
            newVector = FlxVector.get();
        
        final xIndex = Math.round(x / GRID_X);
        newVector.y = Math.round((y - getColumnOffset(xIndex)) / GRID_Y);
        newVector.x = xIndex;
        return newVector;
    }
    
    function getNearestHexIndex(x:Float, y:Float):Int
    {
        final v = getNearestHexIndexPair(x, y);
        final index = getHexIndex(Std.int(v.x), Std.int(v.y));
        v.put();
        return index;
    }
    
    inline function getPodHexIndex(pod:UiPod):Int
    {
        return getNearestHexIndex(pod.x, pod.y);
    }
    
    function getAdjactentSpots(index:Int):Array<Int>
    {
        return
            if (isOffsetColumn(index))
                [ index - columns - 1 // x-1, y-1: upleft
                , index - columns     // x  , y-1: up
                , index - columns + 1 // x+1, y-1: upright
                , index           - 1 // x-1, y  : downleft
                , index           + 1 // x+1, y  : downright
                , index + columns     // x  , y+1: down
                ];
            else
                [ index - columns     // x  , y-1: up
                , index           - 1 // x-1, y  : upleft
                , index           + 1 // x+1, y  : upright
                , index + columns - 1 // x-1, y+1: downleft
                , index + columns     // x  , y+1: downright
                , index + columns + 1 // x+1, y+1: down
                ];
    }
    
    function isAdjacent(indexA:Int, indexB:Int):Bool
    {
        var diff = indexB - indexA;
        if (isOffsetColumn(indexA))
            return diff == -columns - 1 // x-1, y-1: upleft
                || diff == -columns     // x  , y-1: up
                || diff == -columns + 1 // x+1, y-1: upright
                || diff ==  0       - 1 // x-1, y  : downleft
                || diff ==  0       + 1 // x+1, y  : downright
                || diff ==  columns     // x  , y+1: down
                ;
        else
            return diff == -columns     // x  , y-1: up
                || diff ==  0       - 1 // x-1, y  : upleft
                || diff ==  0       + 1 // x+1, y  : upright
                || diff ==  columns - 1 // x-1, y+1: downleft
                || diff ==  columns     // x  , y+1: downright
                || diff ==  columns + 1 // x+1, y+1: down
                ;
    }
}

class Button extends flixel.ui.FlxButton
{
    public function new(type:ToolType, x:Float, y:Float, onClick:ToolType->Void)
    {
        super(x, y, ()->onClick(type));
        switch(type)
        {
            case PlacePod(podType):
                loadGraphic(Pod.getGraphic(podType));
            case Mouse:
                loadGraphic("assets/images/mouse.png");
        }
        scale.scale(1.5);
        updateHitbox();
    }
}

class UiPod extends Circle
{
    public var type     (default, null):PodType;
    public var parentPod(default, null):Null<UiPod>;
    public var childPods(default, null):Map<Int, UiPod> = new Map();
    public var cockpit  (default, null):Null<UiPod>;
    public var free(get, never):Bool;
    inline function get_free():Bool return parentPod == null && type != Cockpit;
    
    public function new (type:PodType, x = 0.0, y = 0.0, angle = 0.0)
    {
        super(Pod.RADIUS);
        init(type, x, y, angle);
        
        scale.scale(Pod.SCALE);
        updateHitbox();
        
        if (type == Cockpit)
            cockpit = this;
    }
    
    public function init(type:PodType, x = 0.0, y = 0.0, angle = 0.0):Void
    {
        this.x = x;
        this.y = y;
        this.type = type;
        this.angle = angle;
        parentPod = null;
        cockpit = null;
        childPods.clear();
        
        loadGraphic(Pod.getGraphic(type));
    }
    
    public function setFree():Void
    {
        if (parentPod != null)
        {
            // var index = parentPod.childPods.c(this);
            // parentPod.childPods[index] = null;
        }
        parentPod = null;
        cockpit = null;
    }
    
    public function setLinked(parent:UiPod):Void
    {
        cockpit = parent.cockpit;
        // 6 spots to connect, 12o'clock is 0, increasing clockwise
        final index = Math.round((Math.atan2(y - parent.y, x - parent.x) * FlxAngle.TO_DEG - cockpit.angle) / 60) + 1;
        parent.childPods[index] = this;
        parentPod = parent;
    }
}

enum ToolType
{
    PlacePod(type:PodType);
    Mouse;
}