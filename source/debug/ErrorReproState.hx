package debug;

class ErrorReproState extends flixel.FlxState
{
    override function create()
    {
        super.create();
        
        add(createSprite(100, 100, 15));              // shows
        add(createSprite(200, 100,  9));              // doesn't show
        add(createSprite(300, 100,  9));              // doesn't show
        add(createSprite(400, 100,  9, 0xffff00)); // shows
    }
    
    inline function createSprite(x = 0.0, y = 0.0, size:Int, color = 0xffffff):flixel.FlxSprite
    {
        var sprite = new flixel.FlxSprite(x, y).makeGraphic(size, size);
        sprite.color = color;
        return sprite;
    }
}