package sprites;

import flixel.FlxSprite;

class Bullet extends FlxSprite
{
    public var radius = 4.0;
    public var damage = 1;
    public var speed = 200.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
        
        loadGraphic("assets/images/bullet.png", true);
        animation.add("idle", [0,1], 15);
    }
}