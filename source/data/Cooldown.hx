package data;

@:forward
abstract Cooldown(Float) to Float from Float from Int
{
    public var cooling(get, never):Bool;
    inline function get_cooling() return this > 0;
    public var value(get, never):Float;
    inline function get_value() return this;
    
    
    inline public function check(elapsed:Float):Bool
    {
        var fired = false;
        if (cooling)
        {
            this -= elapsed;
            if (this < 0)
            {
                this = 0;
                fired = true;
            }
        }
        return fired;
    }
    
    inline public function reset(value = 0.0):Void
    {
        this = value;
    }
}