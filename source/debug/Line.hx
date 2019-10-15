package debug;

import flixel.math.FlxVector;
import flixel.util.FlxColor;

class Line extends openfl.display.Shape
{
    var v(default, null) = FlxVector.get();
    public var endX(get, set):Float;
    inline function get_endX():Float return x + v.x;
    inline function set_endX(value:Float):Float
    {
        v.x = value - x;
        redraw();
        return value;
    }
    
    public var endY(get, set):Float;
    inline function get_endY():Float return y + v.y;
    inline function set_endY(value:Float):Float
    {
        v.y = value - y;
        redraw();
        return value;
    }
    
    override function set_x(value:Float):Float
    {
        v.x = x + v.x - value;
        super.set_x(value);
        redraw();
        return value;
    }
    
    override function set_y(value:Float):Float
    {
        v.y = y + v.y - value;
        super.set_y(value);
        redraw();
        return value;
    }
    
    public var vx(get, set):Float;
    inline function get_vx() return v.x;
    inline function set_vx(value:Float)
    {
        v.x = value;
        redraw();
        return value;
    }
    public var vy(get, set):Float;
    inline function get_vy() return v.y;
    inline function set_vy(value:Float)
    {
        v.y = value;
        redraw();
        return value;
    }
    
    public var thickness(default, null):Float;
    public var color(default, null):FlxColor;
    
    public function new (x:Float, y:Float, endX:Float, endY:Float, color = FlxColor.BLACK, thickness = 1.0)
    {
        super();
        this.x = x;
        this.y = y;
        v.set(endX - x, endY - y);
        
        this.color = color;
        this.thickness = thickness;
        
        redraw();
    }
    
    function redraw():Void
    {
        graphics.clear();
        if (!v.isZero())
        {
            graphics.lineStyle(thickness, color);
            graphics.moveTo(0, 0);
            graphics.lineTo(v.x, v.y);
        }
    }
    
    inline public function setStart(x:Float, y:Float):Void { this.x = x; this.y = y; }
    inline public function setEnd  (x:Float, y:Float):Void { endX   = x; endY   = y; }
    inline public function setVel  (x:Float, y:Float):Void { vx     = x; vy     = y; }
    
    
    inline public function setZero():Void
    {
        vx = vy = 0;
    }
    
    inline static public function vector(x:Float, y:Float, vx:Float, vy:Float, color:FlxColor, thickness = 1.0):Line
    {
        return new Line(x, y, x + vx, y + vy, color, thickness);
    }
    
    inline static public function zero(color:FlxColor, thickness = 1.0):Line
    {
        return new Line(0, 0, 0, 0, color, thickness);
    }
}