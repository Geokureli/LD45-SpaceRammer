package;

import openfl.display.Sprite;

import flixel.FlxG;
import flixel.FlxGame;

import states.*;
import ui.Inputs;

class Main extends Sprite
{
    public function new() {
        super();
        
        if (stage == null)
            addEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
        else
            onAddedToStage();
    }
    
    function onAddedToStage(e = null) {
        
        // final zoom = 1;
        // addChild
        // ( new FlxGame
        //     ( Std.int(stage.stageWidth  / zoom)
        //     , Std.int(stage.stageHeight / zoom)
        //     , CollisionState
        //     , Std.int(stage.frameRate)
        //     , Std.int(stage.frameRate)
        //     )
        // );
        
		// FlxG.plugins.add(new Inputs());
        
        addChild(new CollisionTest());
    }
}