package debug.collision;

import openfl.events.MouseEvent;

class Handle extends openfl.display.Sprite
{
    inline static var SIZE = 12;
    inline static var HALF_SIZE = SIZE / 2;
    static var anyDragging = false;
    
    public var onChange:Handle->Void;
    
    public function new(x:Float, y:Float)
    {
        super();
        this.x = x;
        this.y = y;
        
        graphics.lineStyle(2);
        graphics.beginFill(0xFF808080);
        graphics.drawRect(-HALF_SIZE, -HALF_SIZE, SIZE, SIZE);
        graphics.endFill();
        
        addEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }
    
    function onPress(e:MouseEvent):Void
    {
        if (anyDragging)
            return;
        
        anyDragging = true;
        stage.addEventListener(MouseEvent.MOUSE_UP, onRelease);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onDrag);
    }
    
    function onRelease(e:MouseEvent):Void
    {
        stage.removeEventListener(MouseEvent.MOUSE_UP, onRelease);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
        anyDragging = false;
    }
    
    function onDrag(e:MouseEvent):Void
    {
        var changed = x != e.stageX || y != e.stageY;
        x = e.stageX;
        y = e.stageY;
        
        if (onChange != null)
            onChange(this);
    }
}