package sprites;

import flixel.FlxObject;
import flixel.math.FlxMath;

class SkidSprite extends flixel.FlxSprite {
	
	
	function new (x = 0.0, y = 0.0, ?graphic) { super(x, y, graphic); }
	
	// --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
	// Hack to allow drag when acellerating opposite to velocity
	// --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
	
	var skidDrag = true;
	
	override function updateMotion(elapsed:Float) { 
		
		if(skidDrag)
			updateMotionSkidDrag(this, elapsed);
		else
			super.updateMotion(elapsed);
	}

	inline static public function updateMotionSkidDrag(obj:FlxObject, elapsed:Float)
	{
		var velocityDelta = 0.5 * 
		( computeVelocity
			( obj.angularVelocity
			, obj.angularAcceleration
			, obj.angularDrag
			, obj.maxAngular
			, elapsed
			) - obj.angularVelocity
		);
		obj.angularVelocity += velocityDelta; 
		obj.angle += obj.angularVelocity * elapsed;
		obj.angularVelocity += velocityDelta;
		
		velocityDelta = 0.5 *
		( computeVelocity
			( obj.velocity.x
			, obj.acceleration.x
			, obj.drag.x
			, obj.maxVelocity.x
			, elapsed
			) - obj.velocity.x
		);
		obj.velocity.x += velocityDelta;
		obj.x += obj.velocity.x * elapsed;
		obj.velocity.x += velocityDelta;
		
		velocityDelta = 0.5 *
		( computeVelocity
			( obj.velocity.y
			, obj.acceleration.y
			, obj.drag.y
			, obj.maxVelocity.y
			, elapsed
			) - obj.velocity.y
		);
		obj.velocity.y += velocityDelta;
		obj.y += obj.velocity.y * elapsed;
		obj.velocity.y += velocityDelta;
	}

	static function computeVelocity(velocity:Float, acceleration:Float, drag:Float, max:Float, elapsed:Float):Float
	{
		if (acceleration != 0)
		{
			velocity += acceleration * elapsed;
		}
		
		if (drag != 0 && (acceleration == 0 || !FlxMath.sameSign(velocity, acceleration)))
		{
			var drag:Float = drag * elapsed;
			if (velocity - drag > 0)
			{
				velocity -= drag;
			}
			else if (velocity + drag < 0)
			{
				velocity += drag;
			}
			else
			{
				velocity = 0;
			}
		}
		
		if ((velocity != 0) && (max != 0))
		{
			if (velocity > max)
			{
				velocity = max;
			}
			else if (velocity < -max)
			{
				velocity = -max;
			}
		}
		return velocity;
	}
}