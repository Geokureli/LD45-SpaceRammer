package debug;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.text.TextFormat;
import flixel.util.FlxColor;

import openfl.text.TextField;

class Slider
{
    inline static var TRACK_WIDTH = 200;
    inline static var LABEL_WIDTH = 60;
    
    var label:TextField;
    var handle:Handle;
    var track:Shape;
    var min:Float;
    
    public var onChange:Float->Void;
    public var value(default, null):Float;
    
    public function new
        ( parent:Sprite
        , x:Float
        , y:Float
        , value:Float
        , min = 0.0
        , label:String
        , color:FlxColor
        , onChange:Float->Void
        )
    {
        this.min = min;
        this.value = value;
        
        parent.addChild(this.label = new TextField());
        this.label.x = x;
        this.label.y = y;
        this.label.text = label;
        this.label.defaultTextFormat = new openfl.text.TextFormat("Arial", 12);
        this.label.textColor = color;
        
        parent.addChild(track = new Shape());
        track.x = this.label.x + LABEL_WIDTH;
        track.y = this.label.y + this.label.textHeight * 0.5 + 1;
        track.graphics.lineStyle(1);
        track.graphics.moveTo(0, 0);
        track.graphics.lineTo(TRACK_WIDTH, 0);
        
        parent.addChild(handle = new Handle(track.x + value * track.width, track.y));
        handle.onChange = onHandleChange;
        this.onChange = onChange;
    }
    
    function onHandleChange(handle:Handle):Void
    {
        handle.y = track.y;
        
        if (handle.x < track.x)
            handle.x = track.x;
        
        if (handle.x > track.x + track.width)
            handle.x = track.x + track.width;
        
        value = (handle.x - track.x) / track.width;
        if (value < min)
            value = min;
        trace(value);
        onChange(value);
    }
}