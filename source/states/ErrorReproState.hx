package states;

class ErrorReproState extends flixel.FlxState
{
    override function create()
    {
        super.create();
        
        createSprite(100, 100, 15);              // shows
        createSprite(200, 100);                  // doesn't show
        createSprite(300, 100);                  // doesn't show
        createSprite(400, 100).color = 0xffff00; // shows
    }
    
    inline function createSprite(x = 0.0, y = 0.0, size = 9):flixel.FlxSprite
    { 
        return cast add(new flixel.FlxSprite(x, y).makeGraphic(size, size));
    }
}