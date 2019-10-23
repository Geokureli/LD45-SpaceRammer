package states;

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
    
    var buttons:Map<PodType, PodButton>;
    var pods:FlxTypedGroup<Pod>;
    var dragPod:Pod;
    var cockpit:Pod;
    
    var columns = Math.ceil(FlxG.width / GRID_X / 2) * 2;// must be even so all offset indices are even
    var rows = Math.ceil(FlxG.height / GRID_Y);
    var takenSpots:Array<Int>;
    
    override function create()
    {
        super.create();
        buttons = new Map();
        add(pods = new FlxTypedGroup());
        var pos = getNearestHexCoord(FlxG.width / 2, FlxG.height / 2);
        pods.add(cockpit = new Pod(Cockpit, pos.x, pos.y, -90));
        pos.put();
        final cockpitIndex = getNearestHexIndex(cockpit.x, cockpit.y);
        takenSpots = [cockpitIndex];
        
        for (i in 0...5)
        {
            final type = PodType.createByIndex(i + 1);
            final button = new PodButton(type, 10, 10, onButtonClick);
            button.y += (10 + button.height) * i;
            button.angle = cockpit.angle;
            buttons[type] = button;
            add(button);
        }
    }
    
    function onButtonClick(type:PodType):Void
    {
        if (dragPod == null)
        {
            pods.add(dragPod = new Pod(type, -100));
            dragPod.angle = cockpit.angle;
        }
        else
            dragPod.init(type);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (dragPod != null)
            updateDragPod(elapsed);
    }
    
    function updateDragPod(elapsed:Float)
    {
        if (dragPod.free)
        {
            var tileIndex = getNearestHexIndex(dragPod.x, dragPod.y);
            if (FlxG.mouse.justMoved)
            {
                var gridMouse = getNearestHexCoord(FlxG.mouse.x - dragPod.radius, FlxG.mouse.y - dragPod.radius);
                // check if moved tiles, update color to convey valid placement
                if (dragPod.x != gridMouse.x || dragPod.y != gridMouse.y)
                {
                    tileIndex = getNearestHexIndex(gridMouse.x, gridMouse.y);
                    dragPod.alpha = 0.5;
                    if (takenSpots.indexOf(tileIndex) == -1 && getTouchingPod(tileIndex, cockpit) != null)
                        dragPod.alpha = 1;
                    
                    dragPod.x = gridMouse.x;
                    dragPod.y = gridMouse.y;
                }
                
                gridMouse.put();
            }
            
            if (FlxG.mouse.justPressed)
            {
                if (takenSpots.indexOf(tileIndex) == -1)
                {
                    var parent = getTouchingPod(tileIndex, cockpit);
                    if (parent != null)
                    {
                        dragPod.setLinked(parent);
                        takenSpots.push(tileIndex);
                    }
                }
            }
        }
        else
        {
            if (FlxG.mouse.justReleased)
            {
                var type = dragPod.type;
                dragPod = null;
                onButtonClick(type);
            }
            else if (FlxG.mouse.pressed && FlxG.mouse.justMoved)
            {
                var mouse = FlxVector.get(FlxG.mouse.x, FlxG.mouse.y);
                if (FlxG.keys.pressed.SHIFT)
                    mouse = roundToNearestHexCoord(mouse);
                
                var v = FlxVector.get(mouse.x - dragPod.x, mouse.y - dragPod.y);
                if (!v.isZero())
                    dragPod.angle = v.degrees + cockpit.angle;
                v.put();
            }
        }
    }
    
    function getTouchingPod(index:Int, pod:Pod):Pod
    {
        if (isAdjacent(getPodHexIndex(pod), index))
            return pod;
        
        for (i in 0...pod.childPods.length)
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
    
    inline function getPodHexIndex(pod:Pod):Int
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

class PodButton extends flixel.ui.FlxButton
{
    public function new(type:PodType, x:Float, y:Float, onClick:PodType->Void)
    {
        super(x, y, ()->onClick(type));
        loadGraphic(Pod.getGraphic(type));
    }
}

@:forward
abstract Socket(Circle) to Circle
{
    inline public  function new(x:Float, y:Float)
    {
        this = new Circle(9 * 1.5, x, y, "assets/images/podSocket.png");
        this.scale.scale(1.5);
    }
}