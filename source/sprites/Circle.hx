package sprites;

import openfl.display.Shape;
import openfl.display.Graphics;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.math.FlxVector;

class Circle extends SkidSprite
{
    #if debug
    static public var debugDrawerShape:Shape;
    static public var debugDrawer(get, never):Graphics;
    inline static function get_debugDrawer():Graphics
        return debugDrawerShape == null ? null : debugDrawerShape.graphics;
    inline static var A_COLOR = 0xFFFF0000;
    inline static var B_COLOR = 0xFF0000FF;
    #end
    
    public var cX(get, set):Float;
    inline function get_cX() return x + radius;
    inline function set_cX(value:Float) return x = value - radius;
    public var cY(get, set):Float;
    inline function get_cY() return y + radius;
    inline function set_cY(value:Float) return y = value - radius;
    
    public var radius:Float;
    /**
     * sets the radius and updates the hitbox.
     * @param value 
     */
    public function setRadius(value:Float)
    {
        radius = value;
        updateHitbox();
    }
    
    public function new(radius:Float, x = 0.0, y = 0.0, ?graphic)
    {
        super(x, y, graphic);
        
        setRadius(radius);
    }
    
    inline static function sqr(num:Float) return num * num;
    
    override function updateHitbox()
    {
        width = radius * 2;
        height = radius * 2;
        offset.set(-0.5 * (width - frameWidth), -0.5 * (height - frameHeight));
    }
    
    function overlapCircle(circle:Circle):Bool
    {
        return sqr(circle.x - x) + sqr(circle.y - y) <= sqr(circle.radius + radius);
    }
    
    inline static public function overlap
        ( objectOrGroup1:FlxBasic
        , objectOrGroup2:FlxBasic
        , ?notifyCallback:Dynamic->Dynamic->Void
        , ?processCallback:Dynamic->Dynamic->Bool
        ):Bool
    {
        if (processCallback == null)
            processCallback = isOverlapping;
        
        return FlxG.overlap(objectOrGroup1, objectOrGroup2, notifyCallback, processCallback);
    }
    
    static public function isOverlapping(a:Circle, b:Circle):Bool
    {
        return a.overlapCircle(b);
    }
    
    inline static public function collide
        ( objectOrGroup1:FlxBasic
        , objectOrGroup2:FlxBasic
        , ?notifyCallback:Dynamic->Dynamic->Void
        ):Bool
    {
        return overlap(objectOrGroup1, objectOrGroup2, notifyCallback, separate);
    }
    
    @:noCompletion
    function moveFromSeparate(x:Float, y:Float):Void
    {
        this.x = x;
        this.y = y;
    }
    
    @:noCompletion
    function bumpFromSeparate(x:Float, y:Float):Void
    {
        velocity.set(x, y);
    }
    
    /**
     * Determines whether 2 circles overlap at any point during this frame
     * @param a     A circle
     * @param b     A circle
     * @return true if they overlap
     */
    static public function overlapThisFrame(a:Circle, b:Circle):Bool
    {
        if (a.immovable && b.immovable)
            return false;
        
        var radSum = a.radius + b.radius;
        if (sqr(a.x - b.x) + sqr(a.y - b.y) <= sqr(radSum)
        ||  sqr(a.last.x - b.last.x) + sqr(a.last.y - b.last.y) <= sqr(radSum))
            return true;
        
        #if debug
        drawDebugMovingCircle(a, A_COLOR);
        drawDebugMovingCircle(b, B_COLOR);
        #end
        
        var dis = FlxVector.get().copyFrom(b.last).subtractPoint(a.last);
        var aFrameVel = FlxVector.get(a.x - a.last.x, a.y - a.last.y);
        var bFrameVel = FlxVector.get(b.x - b.last.x, b.y - b.last.y);
        var vDif = aFrameVel.subtractNew(bFrameVel);
        aFrameVel.put();
        bFrameVel.put();
        var par = dis.projectTo(vDif);
        var perp = dis.projectTo(vDif.rightNormal(FlxVector.weak()));
        dis.put();
        
        #if debug
        drawDebugLine(a.last.x, a.last.y, a.last.x + vDif.x, a.last.y + vDif.y, 0xFFFFFF, 4);
        drawDebugLine(a.last.x, a.last.y, a.last.x + par.x, a.last.y + par.y, 0xFF00);
        drawDebugLine(a.last.x + par.x, a.last.y + par.y, a.last.x + par.x + perp.x, a.last.y + par.y + perp.y, 0xFF00);
        #end
        
        var isOverlapping = false;
        if (perp.lengthSquared < sqr(radSum) && par.dotProduct(vDif) > 0)
        {
            var tLength = par.length - Math.sqrt((radSum * radSum) - perp.lengthSquared);
            isOverlapping = sqr(tLength) < vDif.lengthSquared;
        }
        
        vDif.put();
        par.put();
        perp.put();
        
        return isOverlapping;
    }
    
    static public function separate(a:Circle, b:Circle):Bool
    {
        if (a.immovable && b.immovable)
            return false;
        
        var radSum = a.radius + b.radius;
        // if (sqr(a.x - b.x) + sqr(a.y - b.y) > sqr(radSum)
        // &&  sqr(a.last.x - b.last.x) + sqr(a.last.y - b.last.y) > sqr(radSum))
        //     return false;
        
        #if debug
        drawDebugMovingCircle(a, A_COLOR);
        drawDebugMovingCircle(b, B_COLOR);
        #end
        
        var dis = FlxVector.get().copyFrom(b.last).subtractPoint(a.last);
        var aFrameVel = FlxVector.get(a.x - a.last.x, a.y - a.last.y);
        var bFrameVel = FlxVector.get(b.x - b.last.x, b.y - b.last.y);
        
        if (dis.lengthSquared < sqr(radSum))
        {
            //overlapping at start of frame
            var length = dis.length;
            if (a.immovable)
            {
                b.x += dis.x * (radSum - length) / length;
                b.y += dis.y * (radSum - length) / length;
            }
            else if (b.immovable)
            {
                a.x -= dis.x * (radSum - length) / length;
                a.y -= dis.y * (radSum - length) / length;
            }
            else
            {
                a.x -= dis.x * (radSum - length) / length / 2;
                a.y -= dis.y * (radSum - length) / length / 2;
                b.x += dis.x * (radSum - length) / length / 2;
                b.y += dis.y * (radSum - length) / length / 2;
            }
        }
        
        var vDif = aFrameVel.subtractNew(bFrameVel);
        var par = dis.projectTo(vDif);
        var perp = dis.projectTo(vDif.rightNormal(FlxVector.weak()));
        dis.put();
        
        #if debug
        drawDebugLine(a.last.x, a.last.y, a.last.x + vDif.x, a.last.y + vDif.y, 0xFFFFFF, 4);
        drawDebugLine(a.last.x, a.last.y, a.last.x + par.x, a.last.y + par.y, 0xFF00);
        drawDebugLine(a.last.x + par.x, a.last.y + par.y, a.last.x + par.x + perp.x, a.last.y + par.y + perp.y, 0xFF00);
        #end
        
        var overlapping = false;
        if (perp.lengthSquared < sqr(radSum) && par.dotProduct(vDif) > 0)
        {
            var tLength = par.length - Math.sqrt((radSum * radSum) - perp.lengthSquared);
            if (tLength * tLength < vDif.lengthSquared)// && tLength >= 0)
            {
                var aPerp = FlxVector.get();
                var bPerp = FlxVector.get();
                var average = FlxVector.get();
                var aImpactPos = FlxVector.get();
                var bImpactPos = FlxVector.get();
                var wallNorm = FlxVector.get();
                var aVel = FlxVector.get();
                var bVel = FlxVector.get();
                
                var parLength = par.length;
                var t = tLength / vDif.length;
                
                aImpactPos.copyFrom(aFrameVel).scale(t).addPoint(a.last);
                bImpactPos.copyFrom(aFrameVel).scale(t).addPoint(b.last);
                wallNorm.copyFrom(bImpactPos).subtractPoint(aImpactPos);
                
                #if debug
                var wall = wallNorm.leftNormal();
                var intersection = FlxVector.get().copyFrom(wallNorm)
                    .scale(a.radius / radSum)
                    .addPoint(aImpactPos);
                drawDebugLine
                    ( intersection.x + wall.x, intersection.y + wall.y
                    , intersection.x - wall.x, intersection.y - wall.y
                    , 0xFFFFFF, 4
                    );
                intersection.put();
                wall.put();
                #end
                
                // calculate end position
                // trace(aFrameVel.toString(), bFrameVel.toString());
                aPerp = aFrameVel.scale(1 - t).projectTo(wallNorm, aPerp);
                bPerp = bFrameVel.scale(1 - t).projectTo(wallNorm, bPerp);
                average.copyFrom(aPerp).addPoint(bPerp).scale(0.5);
                aFrameVel.subtractPoint(aPerp);
                bFrameVel.subtractPoint(bPerp);
                aPerp.scale(a.mass / b.mass);
                bPerp.scale(b.mass / a.mass);
                aPerp.subtractPoint(average).scale(b.elasticity).addPoint(average);
                bPerp.subtractPoint(average).scale(a.elasticity).addPoint(average);
                aFrameVel.addPoint(bPerp);
                bFrameVel.addPoint(aPerp);
                // trace(aPerp.toString(), bPerp.toString());
                a.moveFromSeparate(aImpactPos.x + aFrameVel.x, aImpactPos.y + aFrameVel.y);
                b.moveFromSeparate(bImpactPos.x + bFrameVel.x, bImpactPos.y + bFrameVel.y);
                
                //change actual velocity
                // trace(a.velocity.toString(), b.velocity.toString());
                aPerp = (a.velocity:FlxVector).projectTo(wallNorm, aPerp);
                bPerp = (b.velocity:FlxVector).projectTo(wallNorm, bPerp);
                average.copyFrom(aPerp).addPoint(bPerp).scale(0.5);
                aVel.copyFrom(a.velocity);
                bVel.copyFrom(b.velocity);
                aVel.subtractPoint(aPerp);
                bVel.subtractPoint(bPerp);
                aPerp.scale(a.mass / b.mass);
                bPerp.scale(b.mass / a.mass);
                aPerp.subtractPoint(average).scale(b.elasticity).addPoint(average);
                bPerp.subtractPoint(average).scale(a.elasticity).addPoint(average);
                aVel.addPoint(aPerp);
                bVel.addPoint(bPerp);
                // trace(aPerp.toString(), bPerp.toString());
                a.bumpFromSeparate(bVel.x, bVel.y);
                b.bumpFromSeparate(aVel.x, aVel.y);
                
                aImpactPos.put();
                bImpactPos.put();
                wallNorm.put();
                aPerp.put();
                bPerp.put();
                average.put();
                
                overlapping = true;
            }
        }
        
        aFrameVel.put();
        bFrameVel.put();
        vDif.put();
        par.put();
        perp.put();
        
        return overlapping;
    }
    
    #if debug
    inline static function drawDebugLine
    ( x1:Float, y1:Float
    , x2:Float, y2:Float
    , color = 0xFFFFFF
    , thickness = 2
    )
    {
        if (debugDrawer != null)
        {
            if (color != 0xFFFFFF)
                drawDebugLine(x1, y1, x2, y2, 0xFFFFFF, thickness * 2);
            
            debugDrawer.lineStyle(thickness, color);
            debugDrawer.moveTo(x1, y1);
            debugDrawer.lineTo(x2, y2);
        }
    }
    inline static function drawDebugMovingCircle(circle:Circle, color = 0xFFFFFF, thickness = 2)
    {
        if (debugDrawer != null)
        {
            if (color != 0xFFFFFF)
                drawDebugMovingCircle(circle, 0xFFFFFF, thickness * 2);
            
            debugDrawer.lineStyle(thickness, color);
            debugDrawer.drawCircle(circle.last.x, circle.last.y, circle.radius);
        }
    }
    #end
}