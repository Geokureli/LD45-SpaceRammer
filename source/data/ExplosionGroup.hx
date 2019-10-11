package data;

import sprites.Explosion;

import flixel.group.FlxGroup.FlxTypedGroup;

abstract ExplosionGroup(FlxTypedGroup<Explosion>)
from FlxTypedGroup<Explosion>
to   FlxTypedGroup<Explosion>
{
    inline public function new (maxSize = 0)
    {
        this = new FlxTypedGroup<Explosion>(maxSize);
    }
    
    inline public function create(radius = 7.5):Explosion
    {
        return this.recycle(Explosion).init(radius);
    }
}