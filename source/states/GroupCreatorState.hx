package states;

import data.PodData;
import flixel.math.FlxAngle;
import flixel.math.FlxVector;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

import sprites.Circle;
import sprites.pods.Cockpit;
import sprites.pods.Pod;
import sprites.pods.PodType;
import ui.editor.UiPod;

class GroupCreatorState extends flixel.FlxState
{
    inline static var GRID_X = Pod.RADIUS * 2 * 0.866025403784439;//sin(60);
    inline static var GRID_Y = Pod.RADIUS * 2;
    inline static var OFFSET_Y = -Pod.RADIUS;
    
    var pods:FlxTypedGroup<UiPod>;
    var links:FlxTypedGroup<UiLink>;
    var placePod:UiPod;
    var cockpit:UiCockpit;
    var socket:Socket;
    
    var columns = Math.ceil(FlxG.width / GRID_X / 2) * 2;// must be even so all offset indices are even
    var rows = Math.ceil(FlxG.height / GRID_Y);
    var takenSpots:Map<Int, UiPod>;
    var activeTool:ToolType = Mouse;
    
    override function create()
    {
        super.create();
        // FlxG.debugger.drawDebug = true;
        
        add(socket = new Socket()).visible = false;
        add(pods = new FlxTypedGroup());
        add(links = new FlxTypedGroup());
        var pos = getNearestHexCoord(FlxG.width / 2, FlxG.height / 2);
        pods.add(cockpit = new UiCockpit(pos.x, pos.y));
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
            links.remove(placePod.link);
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
            links.add(placePod.link);
            placePod.angle = cockpit.angle;
        }
        else
        {
            placePod.exists = true;
            placePod.init(type, 0, 0, cockpit.angle);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if      (FlxG.keys.justPressed.M    ) onButtonClick(Mouse);
        else if (FlxG.keys.justPressed.ONE  ) onButtonClick(PlacePod(PodType.createByIndex(1)));
        else if (FlxG.keys.justPressed.TWO  ) onButtonClick(PlacePod(PodType.createByIndex(2)));
        else if (FlxG.keys.justPressed.THREE) onButtonClick(PlacePod(PodType.createByIndex(3)));
        else if (FlxG.keys.justPressed.FOUR ) onButtonClick(PlacePod(PodType.createByIndex(4)));
        else if (FlxG.keys.justPressed.FIVE ) onButtonClick(PlacePod(PodType.createByIndex(5)));
        
        var tool = activeTool;
        if (FlxG.keys.pressed.ALT)//Todo: Control on win Command on Mac
            tool = Mouse;
        
        switch (tool)
        {
            case Mouse      : updateMouse(elapsed);
            case PlacePod(_): updatePlacePod(elapsed);
        }
        
        if (FlxG.keys.justPressed.SPACE)
            trace(cockpit.createJson());
    }
    
    function updateMouse(elapsed:Float)
    {
        if (placePod == null)
        {
            if (FlxG.mouse.justPressed)
            {
                var mouseIndex = getNearestHexIndex(FlxG.mouse.x, FlxG.mouse.y);
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
        if (placePod == null)
        {
            switch(activeTool)
            {
                case PlacePod(type): setPlacePod(type);
                case _: throw "unhandled case";
            }
        }
        if (placePod.free)
        {
            if (FlxG.mouse.justMoved)
                movePodToMouse(placePod);
            
            if (FlxG.mouse.justPressed)
            {
                if (attachPod(placePod))
                {
                    socket.visible = true;
                    socket.setPos(placePod.x, placePod.y);
                }
            }
        }
        
        //separate if/else in case justPressed and justReleased are handled in the same frame
        if (!placePod.free)
        {
            if (FlxG.mouse.justReleased)
            {
                var type = placePod.type;
                placePod = null;
                setPlacePod(type);
                socket.visible = false;
            }
            else if (FlxG.mouse.pressed && FlxG.mouse.justMoved && !FlxG.mouse.justPressed)
                rotatePodToMouse(placePod, socket);
        }
    }
    
    function movePodToMouse(pod:UiPod)
    {
        var gridMouse = getNearestHexCoord(FlxG.mouse.x, FlxG.mouse.y);
        // check if moved tiles, update color to convey valid placement
        // if (pod.x != gridMouse.x || pod.y != gridMouse.y)
        // {
            var tileIndex = getNearestHexIndex(gridMouse.x, gridMouse.y);
            pod.x = gridMouse.x;
            pod.y = gridMouse.y;
            
            var touchingPod:UiPod = null;
            if (!takenSpots.exists(tileIndex))
                touchingPod = getIntendedNeighbor(tileIndex);
            pod.setNeighbor(touchingPod);
        // }
        
        gridMouse.put();
    }
    
    function rotatePodToMouse(pod:UiPod, socket:Socket)
    {
        var mouse = FlxVector.get(FlxG.mouse.x, FlxG.mouse.y);
        if (!FlxG.keys.pressed.SHIFT)
            mouse = roundToNearestHexCoord(mouse);
        
        socket.setPos(mouse.x, mouse.y);
        if (mouse.x != pod.x || mouse.y != pod.y)
        {
            var v = FlxVector.get(mouse.x - pod.x, mouse.y - pod.y);
            pod.angle = Math.round(v.degrees);
            v.put();
        }
        mouse.put();
    }
    
    function attachPod(pod:UiPod):Bool
    {
        if (pod.neighbor != null)
        {
            pod.linkToNeighbor();
            takenSpots[getNearestHexIndex(pod.x, pod.y)] = pod;
            return true;
        }
        return false;
    }
    
    inline function getIntendedNeighbor(index:Int):Null<UiPod>
    {
        var nearestDis = Pod.DIAMETER_SQUARED * 4;
        var nearest:UiPod = null;
        
        final mouse = FlxG.mouse;
        for (pod in getAllNeighbors(index))
        {
            var dis = sqr(mouse.x - pod.x) + sqr(mouse.y - pod.y);
            if (dis < nearestDis)
            {
                nearestDis = dis;
                nearest = pod;
            }
        }
        return nearest;
    }
    
    inline function getAllNeighbors(index:Int):Array<UiPod>
    {
        return getAllNeighborsOf(index, cockpit, []);
    }
    
    @:noCompletion
    function getAllNeighborsOf(index:Int, pod:UiPod, list:Array<UiPod>):Array<UiPod>
    {
        if (isAdjacent(getPodHexIndex(pod), index))
            list.push(pod);
        
        for (i in pod.children.keys())
            getAllNeighborsOf(index, pod.children[i], list);
        
        return list;
    }
    
    inline function getFirstNeighbor(index:Int):Null<UiPod>
    {
        return getFirstNeighborOf(index, cockpit);
    }
    
    @:noCompletion
    function getFirstNeighborOf(index:Int, pod:UiPod = null):Null<UiPod>
    {
        if (isAdjacent(getPodHexIndex(pod), index))
            return pod;
        
        for (i in pod.children.keys())
        {
            var child = getFirstNeighborOf(index, pod.children[i]);
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

@:forward
abstract Socket(FlxSprite) to FlxSprite
{
    inline public function new ()
    {
        this = new FlxSprite("assets/images/podSocket.png");
        
        this.scale.scale(Pod.SCALE);
        this.updateHitbox();
        this.offset.copyFrom(this.origin);
    }
    
    inline public function setPos(x:Float, y:Float):Void
    {
        this.x = x;
        this.y = y;
    }
}

enum ToolType
{
    PlacePod(type:PodType);
    Mouse;
}