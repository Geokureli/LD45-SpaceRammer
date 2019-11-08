package data;

@:forward
abstract Cooldown(Float) to Float from Float from Int
{
    public var cooling(get, never):Bool;
    inline function get_cooling() return this > 0;
    public var cooled(get, never):Bool;
    inline function get_cooled() return this <= 0;
    public var value(get, never):Float;
    inline function get_value() return this;
    
    
    inline public function tick(elapsed:Float, resetIfCooled = false):Cooldown
    {
        if (cooling)
        {
            this -= elapsed;
            if (resetIfCooled && cooled)
                reset();
        }
        return this;
    }
    
    inline public function tickAndCheckFire(elapsed:Float, resetOnFire = true):Bool
    {
        var fire = false;
        if (cooling)
        {
            this -= elapsed;
            fire = cooled;
            if (fire && resetOnFire)
                reset();
        }
        return fire;
    }
    
    inline public function reset(value = 0.0):Void
    {
        this = value;
    }
}