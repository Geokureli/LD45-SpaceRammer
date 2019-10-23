package states;


import openfl.display.Graphics;
import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.util.FlxColor;
import sprites.Circle;

class CircleTestState extends flixel.FlxState
{
    var circles:FlxTypedGroup<TestCircle>;
    var player:PlayerCircle;
    
    var paused = false;
    
    override function create():Void
    {
        super.create();
        // FlxG.debugger.drawDebug = true;
        
        add(circles = new FlxTypedGroup());
        // add(player = new PlayerCircle());
        
        for (i in 0...10)
        {
            circles.add(new TestCircle()).randomPush();
        }
        
        // var shape = new openfl.display.Shape();
        // FlxG.game.parent.addChild(shape);
        // Circle.debugDrawer = shape.graphics;
    }
    
    override function update(elapsed:Float)
    {
        if (!paused || FlxG.keys.justPressed.RIGHT)
        {
            super.update(elapsed);
            
            #if debug
            if (Circle.debugDrawer != null)
                Circle.debugDrawer.clear();
            #end
            
            // Circle.collide(player, circles);
            Circle.collide(circles, circles);
            
            // for (i in 0...circles.length)
            // {
            //     for (j in i + 1...circles.length)
            //     {
            //         Circle.separate(circles.members[i], circles.members[j]);
            //     }
            // }
        }
        
        if (FlxG.keys.justPressed.SPACE)
            paused = !paused;
    }
}

class PlayerCircle extends TestCircle
{
    var started = false;
    
    public function new (radius = 50, ?x:Float, ?y:Float, color = FlxColor.WHITE)
    {
        super(radius, x != null ? x : FlxG.width / 2, y != null ? y : FlxG.height / 2, color);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (FlxG.mouse.justMoved)
            started = true;
        
        if (started)
        {
            velocity.x = (FlxG.mouse.x - x) * 10;
            velocity.y = (FlxG.mouse.y - y) * 10;
        }
    }
}

class TestCircle extends Circle
{
    var wrap = true;
    
    public function new (?radius:Int, ?x:Float, ?y:Float, ?color:FlxColor, ?mass:Float, ?elasticity:Float)
    {
        if (radius == null)
            radius = FlxG.random.int(15, 50);
        
        super
            ( radius
            , x != null ? x : FlxG.random.int(radius, FlxG.width  - radius)
            , y != null ? y : FlxG.random.int(radius, FlxG.height - radius)
            );
        
        if (mass == null)
            mass = 1;//FlxG.random.float();
        this.mass = mass;
        
        if (elasticity == null)
            elasticity = FlxG.random.float();
        this.elasticity = elasticity;
        
        makeGraphic(radius * 2, radius * 2, 0);
        
        var thickness = (radius - 2) * elasticity;
        flixel.util.FlxSpriteUtil.drawCircle
            ( this
            , -1
            , -1
            , radius - 1 - thickness / 2
            , FlxColor.TRANSPARENT
            , { thickness: thickness + 2, color: 0xFFFFFF | (Std.int(0xFF * mass) << 24) }
            );
        
        if (color == null)
            color = FlxColor.fromHSB(FlxG.random.float(0, 360), 1, .7);
        this.color = color;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (wrap)
        {
            final w = FlxG.width + width;
            final h = FlxG.height + height;
            if (x > FlxG.width ) { x -= w; last.x -= w; }
            if (x < -width     ) { x += w; last.x += w; }
            if (y > FlxG.height) { y -= h; last.y -= h; }
            if (y < -height    ) { y += h; last.y += h; }
        }
    }
    
    public function randomPush():TestCircle
    {
        velocity.x = FlxG.random.float(-1000, 1000);
        velocity.y = FlxG.random.float(-1000, 1000);
        return this;
    }
    
    inline static public function createDefault
    ( x = 0.0
    , y = 0.0
    , radius = 50
    , color = FlxColor.WHITE
    , mass = 1.0
    , elasticity = 1.0
    ):TestCircle
    {
        return new TestCircle(radius, x, y, color, mass, elasticity );
    }
}