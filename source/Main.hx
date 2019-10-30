package;

import openfl.display.Sprite;

import flixel.FlxG;
import flixel.FlxGame;

import input.Inputs;

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
        
        #if run_collision_test
        addChild(new debug.collision.CollisionDiagram());
        #else
        final zoom = 1;
        addChild
        ( new FlxGame
            ( Std.int(stage.stageWidth  / zoom)
            , Std.int(stage.stageHeight / zoom)
            , states.GameState
            // , debug.collision.CircleTestState
            // , states.GroupCreatorState
            // , debug.ErrorReproState
            , Std.int(stage.frameRate)
            , Std.int(stage.frameRate)
            )
        );
        
        FlxG.plugins.add(new Inputs());
        #end
        
        #if js
        stage.showDefaultContextMenu = false;
        #end
    }
}