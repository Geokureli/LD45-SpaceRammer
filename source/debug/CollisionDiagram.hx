package debug;

import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.events.KeyboardEvent;
import openfl.events.Event;

import flixel.math.FlxVector;
import flixel.util.FlxColor;

import openfl.events.MouseEvent;
import openfl.display.Shape;
import openfl.display.Sprite;

class CollisionDiagram extends Sprite
{
    var a:MovingCircle;
    var b:MovingCircle;
    var dis:Line;
    var vDif:Line;
    var subB:Line;
    var par:Line;
    var perp:Line;
    var impact:Line;
    
    var relativeImpact:DragCircle;
    // rebound
    var wall:Line;
    var wallNorm:Line;
    var aBounce:Line;
    var bBounce:Line;
    var aEnd:DragCircle;
    var bEnd:DragCircle;
    
    var extraWork:Sprite;
    
    var t = 0.0;
    var animating = false;
    
    public function new ()
    {
        super();
        a = new MovingCircle(this, 200, 200, 500, 200, 50, FlxColor.RED);
        b = new MovingCircle(this, 200, 400, 400, -200, 50, FlxColor.BLUE);
        addChild(extraWork = new Sprite()).visible = false;
        extraWork.addChild(dis = new Line(a.x, a.y, b.x, b.y, FlxColor.GREEN, 2));
        extraWork.addChild(vDif = Line.vector(a.x, a.y, a.vx - b.vx, a.vx - b.vy, FlxColor.BLACK, 2));
        extraWork.addChild(subB = Line.zero(b.lineColor, b.thickness));
        extraWork.addChild(par = Line.zero(FlxColor.GREEN, 2));
        extraWork.addChild(perp = Line.zero(FlxColor.GREEN, 2));
        extraWork.addChild(impact = Line.zero(FlxColor.YELLOW, 2));
        relativeImpact = new DragCircle(extraWork, 0, 0, a.radius, FlxColor.GREEN);
        //rebound
        addChild(wall = Line.zero(FlxColor.BLACK, 4));
        extraWork.addChild(wallNorm = Line.zero(FlxColor.BLACK, 2));
        addChild(aBounce = Line.zero(a.lineColor, a.thickness));
        addChild(bBounce = Line.zero(b.lineColor, a.thickness));
        aEnd = new DragCircle(this, a.x, a.y, a.radius, a.color);
        bEnd = new DragCircle(this, b.x, b.y, b.radius, b.color);
        setChildIndex(aEnd.main, getChildIndex(a.start.main));
        setChildIndex(bEnd.main, getChildIndex(b.start.main));
        
        a.onChange = onChange;
        b.onChange = onChange;
        
        onChange();
        
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }
    
    function onAddedToStage(e:Event):Void
    {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        
        stage.addEventListener(KeyboardEvent.KEY_DOWN,
            (e)->
            {
                if (e.keyCode == 32)
                    extraWork.visible = !extraWork.visible;
            }
        );
        
        var text = new TextField();
        addChild(text);
        text.autoSize = LEFT;
        text.text = "Drag handles to change the situation, SPACE to show/hide the work.";
        text.defaultTextFormat = new TextFormat("Arial", 16);
        text.y = stage.stageHeight - text.height;
        text.x = (stage.stageWidth - text.width) / 2;
        
        new Slider(this,  10, 10, a.elasticity, 0.00, "Elasticity", a.color, (value)->{ a.elasticity = value; onChange(); });
        new Slider(this,  10, 30, a.density   , 0.03, "Density"   , a.color, (value)->{ a.density    = value; onChange(); });
        new Slider(this, 310, 10, b.elasticity, 0.00, "Elasticity", b.color, (value)->{ b.elasticity = value; onChange(); });
        new Slider(this, 310, 30, b.density   , 0.03, "Density"   , b.color, (value)->{ b.density    = value; onChange(); });
    }
    
    function onChange(target:MovingCircle = null)
    {
        // dis
        dis.setStart(a.x, a.y);
        dis.setEnd(b.x, b.y);
        
        // v
        vDif.setStart(a.x, a.y);
        vDif.setVel(a.vx - b.vx, a.vy - b.vy);
        
        //subB
        subB.setStart(a.endX, a.endY);
        subB.setEnd(vDif.endX, vDif.endY);
        
        var _dis = FlxVector.get(dis.endX - dis.x, dis.endY - dis.y);
        var _vDif = FlxVector.get(vDif.vx, vDif.vy);
        //par
        var _par = _dis.projectTo(_vDif);
        par.setStart(a.x, a.y);
        par.setVel(_par.x, _par.y);
        
        var _vNorm = _vDif.rightNormal();
        //perp
        var _perp = _dis.projectTo(_vNorm);
        perp.setStart(par.endX, par.endY);
        perp.setVel(_perp.x, _perp.y);
        
        impact.setZero();
        wall.setZero();
        wallNorm.setZero();
        aBounce.setZero();
        bBounce.setZero();
        a.t = b.t = 1;
        relativeImpact.visible = false;
        aEnd.visible = false;
        bEnd.visible = false;
        var radSum = a.radius + b.radius;
        if (_perp.lengthSquared < radSum * radSum)// && _par.dotProduct(_vDif) > 0)
        {
            var tLength = _par.length - Math.sqrt((radSum * radSum) - _perp.lengthSquared);
            if (tLength * tLength < _vDif.lengthSquared)// && tLength >= 0)
            {
                impact.setStart(b.x, b.y);
                var parLength = _par.length;
                impact.setEnd(a.x + _par.x / parLength * tLength, a.y + _par.y / parLength * tLength);
                
                relativeImpact.visible = true;
                relativeImpact.radius = a.radius;
                relativeImpact.x = impact.endX;
                relativeImpact.y = impact.endY;
                
                t = a.t = b.t = tLength / _vDif.length;
                
                
                var _wallNorm = FlxVector.get(b.tx - a.tx, b.ty - a.ty);
                var _wall = _wallNorm.leftNormal();
                var intersection = FlxVector.get().copyFrom(_wallNorm)
                    .scale(a.radius / radSum)
                    .add(a.tx, a.ty);
                wall.setStart(intersection.x + _wall.x, intersection.y + _wall.y);
                wall.setEnd(intersection.x - _wall.x, intersection.y - _wall.y);
                
                wallNorm.setStart(a.tx, a.ty);
                wallNorm.setEnd(b.tx, b.ty);
                
                var _aVel = FlxVector.get(a.vx, a.vy);
                var _bVel = FlxVector.get(b.vx, b.vy);
                var _aPerp = _aVel.projectTo(_wallNorm);
                var _bPerp = _bVel.projectTo(_wallNorm);
                var average = _aPerp.addNew(_bPerp).scale(0.5);
                _aVel.subtractPoint(_aPerp);
                _bVel.subtractPoint(_bPerp);
                _aPerp.scale(a.density / b.density);
                _bPerp.scale(b.density / a.density);
                _aPerp.subtractPoint(average).scale(b.elasticity).addPoint(average);
                _bPerp.subtractPoint(average).scale(a.elasticity).addPoint(average);
                _aVel.addPoint(_bPerp);
                _bVel.addPoint(_aPerp);
                _aVel.scale(1 - t);
                _bVel.scale(1 - t);
                
                aBounce.setStart(a.tx, a.ty);
                aBounce.setVel(_aVel.x, _aVel.y);
                aEnd.radius = a.radius;
                aEnd.elasticity = a.elasticity;
                aEnd.density = a.density;
                aEnd.x = a.tx + _aVel.x;
                aEnd.y = a.ty + _aVel.y;
                aEnd.visible = true;
                
                bBounce.setStart(b.tx, b.ty);
                bBounce.setVel(_bVel.x, _bVel.y);
                bEnd.radius = b.radius;
                bEnd.elasticity = b.elasticity;
                bEnd.density = b.density;
                bEnd.x = b.tx + _bVel.x;
                bEnd.y = b.ty + _bVel.y;
                bEnd.visible = true;
            }
        }
    }
}