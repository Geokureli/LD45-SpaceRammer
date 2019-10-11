package sprites;

import flixel.FlxSprite;
import sprites.pods.Pod;

class Bullet extends FlxSprite
{
    inline static var SCALE = 3;
    public var radius       (default, null) = 4.0 * SCALE;
    public var damage       (default, null) = 0;
    public var speed        (default, null) = 0.0;
    public var lifeTime     (default, null) = 0.0;
    public var lifeRemaining(default, null) = 0.0;
    public var fireForce    (default, null) = 0.0;
    public var impactForce  (default, null) = 0.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
        
    }
    
    public function init(x = 0.0, y = 0.0):Void
    {
        this.x = x;
        this.y = y;
        
        damage = 1;
        lifeTime = 1;
        lifeRemaining = lifeTime;
        speed = 550;
        fireForce = 50;
        impactForce = 100;
        radius = 4.0 * SCALE;
        loadGraphic("assets/images/bullet.png", true);
        animation.add("idle", [0,1], 15);
        animation.play("idle");
        width  = (graphic.width  - 2) * SCALE;
        height = (graphic.height - 2) * SCALE;
        scale.set(SCALE, SCALE);
        centerOffsets();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        lifeRemaining -= elapsed;
        if (lifeRemaining <= 0)
            kill();
    }
    
    public function onHit(pod:Pod):Void
    {
        kill();
    }
}