package sprites;

import flixel.system.FlxAssets;

class Explosion extends flixel.FlxSprite
{
    public function new(x = 0.0, y = 0.0, graphicPath:String = "assets/images/explosion.png")
    {
        super(x, y);
        
        loadGraphic(graphicPath, true);
        animation.add("explode", [0, 1, 1], 30, false);
        animation.play("explode", true);
    }
    
    public function init(radius = 7.5):Explosion
    {
        scale.set(1, 1).scale(2 * radius / graphic.height);
        centerOffsets();
        
        return this;
    }
    
    public function start(x:Float, y:Float):Void
    {
        reset(x, y);
        animation.play("explode", true);
        animation.finishCallback = (anim)->kill();
    }
}