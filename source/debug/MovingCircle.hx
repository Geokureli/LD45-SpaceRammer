package debug;

import openfl.display.Sprite;
import flixel.util.FlxColor;
import flixel.math.FlxVector;


class MovingCircle
{
    public var start(default, null):DragCircle;
    public var line(default, null):Line;
    public var vel(default, null):DragCircle;
    public var end(default, null):Handle;
    
    var velocity = FlxVector.get();
    
    public var x(get, never):Float;
    inline function get_x() return start.x;
    public var y(get, never):Float;
    inline function get_y() return start.y;
    
    public var endX(get, never):Float;
    inline function get_endX() return x + velocity.x;
    public var endY(get, never):Float;
    inline function get_endY() return y + velocity.y;
    
    public var vx(get, never):Float;
    inline function get_vx() return velocity.x;
    public var vy(get, never):Float;
    inline function get_vy() return velocity.y;
    
    var tChanged = false;
    public var t(default, set) = 1.0;
    inline function set_t(value:Float)
    {
        t = value;
        vel.x = tx;
        vel.y = ty;
        return value;
    }
    
    public var tvx(get, never):Float;
    inline function get_tvx() return velocity.x * t;
    public var tvy(get, never):Float;
    inline function get_tvy() return velocity.y * t;
    
    public var tx(get, never):Float;
    inline function get_tx() return x + velocity.x * t;
    public var ty(get, never):Float;
    inline function get_ty() return y + velocity.y * t;
    
    public var radius(get, never):Float;
    inline function get_radius() return start.radius;
    
    public var elasticity(get, set):Float;
    inline function get_elasticity() return start.elasticity;
    inline function set_elasticity(value:Float) return start.elasticity = vel.elasticity = value;
    
    public var density(get, set):Float;
    inline function get_density() return start.density;
    inline function set_density(value:Float) return start.density = vel.density = value;
    
    public var color(get, never):FlxColor;
    inline function get_color() return start.color;
    
    public var lineColor(get, never):FlxColor;
    inline function get_lineColor() return line.color;
    
    public var thickness(get, never):Float;
    inline function get_thickness() return line.thickness;
    
    public var onChange:MovingCircle->Void;
    
    public function new(parent:Sprite, x:Float, y:Float, vx:Float, vy:Float, radius:Float, color:FlxColor)
    {
        vel   = new DragCircle(parent, x + vx * t, y + vy * t, radius, color.getLightened(0.5));
        start = new DragCircle(parent, x, y, radius, color, true);
        parent.addChild(end = new Handle(x + vx, y + vy));
        parent.addChild(line = new Line(x, y, x + vx, y + vy, color.getDarkened(0.5), 2));
        
        velocity.set(vx, vy);
        start.onChange = onCirclesChange;
        end.onChange = onCirclesChange;
    }
    
    function onCirclesChange(target:Dynamic)
    {
        vel.radius = start.radius;
        vel.elasticity = start.elasticity;
        line.x = start.x;
        line.y = start.y;
        line.endX = end.x;
        line.endY = end.y;
        velocity.x = end.x - start.x;
        velocity.y = end.y - start.y;
        vel.x = tx;
        vel.y = ty;
        if (onChange != null)
            onChange(this);
    }
}