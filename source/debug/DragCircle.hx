package debug;

import flixel.math.FlxVector;
import openfl.display.Sprite;
import flixel.util.FlxColor;

class DragCircle
{
    public var main(default, null):CircleShape;
    public var pos(default, null):Handle;
    public var size(default, null):Handle;
    
    public var editable(default, null):Bool;
    
    public var x(get, set):Float;
    function get_x():Float return main.x;
    function set_x(value:Float)
    {
        if (editable)
            size.x += value - main.x;
        main.x = value;
        
        if (onChange != null)
            onChange(this);
        
        return value;
    }
    public var y(get, set):Float;
    function get_y():Float return main.y;
    function set_y(value:Float)
    {
        if (editable)
            size.y += value - main.y;
        main.y = value;
        
        if (onChange != null)
            onChange(this);
        return value;
    }
    
    public var radius(get, set):Float;
    inline function get_radius() return main.radius;
    inline function set_radius(value:Float) return main.radius = value;
    
    public var color(get, set):FlxColor;
    inline function get_color() return main.color;
    inline function set_color(value:FlxColor) return main.color = value;
    
    public var elasticity(get, set):Float;
    inline function get_elasticity() return main.elasticity;
    inline function set_elasticity(value:Float) return main.elasticity = value;
    
    public var density(get, set):Float;
    inline function get_density() return main.density;
    inline function set_density(value:Float) return main.density = value;
    
    public var visible(get, set):Bool;
    inline function get_visible() return main.visible;
    inline function set_visible(value:Bool)
    {
        if (editable)
            pos.visible = size.visible = value;
        return main.visible = value;
    }
    
    public var onChange:DragCircle->Void;
    
    public function new(parent:Sprite, x:Float, y:Float, radius:Float, color:FlxColor, editable = false)
    {
        this.editable = editable;
        parent.addChild(main = new CircleShape(x, y, radius, color));
        if (editable)
        {
            parent.addChild(pos = new Handle(x, y));
            parent.addChild(size = new Handle(x + radius, y));
            pos.onChange = onHandlesChange;
            size.onChange = onHandlesChange;
        }
    }
    
    function onHandlesChange(target:Handle)
    {
        if (target == pos)
        {
            x = pos.x;
            y = pos.y;
        }
        else if (target == size)
            main.radius = Math.sqrt((size.x - pos.x) * (size.x - pos.x) + (size.y - pos.y) * (size.y - pos.y));
        
        if (onChange != null)
            onChange(this);
    }
}

class CircleShape extends openfl.display.Shape
{
    public var color(default, set):FlxColor;
    inline function set_color(value:FlxColor)
    {
        this.color = value;
        redraw();
        return value;
    }
    public var radius(default, set):Float;
    inline function set_radius(value:Float)
    {
        this.radius = value;
        redraw();
        return value;
    }
    public var elasticity(default, set):Float;
    inline function set_elasticity(value:Float)
    {
        this.elasticity = value;
        redraw();
        return value;
    }
    public var density(default, set):Float;
    inline function set_density(value:Float)
    {
        this.density = value;
        redraw();
        return value;
    }
    
    public function new (x:Float, y:Float, radius:Float, color:FlxColor, elasticity = 1.0, density = 1.0)
    {
        super();
        this.x = x;
        this.y = y;
        @:bypassAccessor
        this.color = color;
        @:bypassAccessor
        this.radius = radius;
        @:bypassAccessor
        this.elasticity = elasticity;
        @:bypassAccessor
        this.density = density;
        
        redraw();
    }
    
    function redraw():Void
    {
        graphics.clear();
        if (radius > 0)
        {
            graphics.lineStyle(2, color);
            graphics.beginFill(color, density);
            graphics.drawCircle(0, 0, radius);
            graphics.lineStyle();
            graphics.drawCircle(0, 0, radius * (1 - elasticity));
            graphics.endFill();
        }
    }
}