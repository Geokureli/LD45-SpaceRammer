package sprites;

import flixel.math.FlxVector;
import flixel.FlxObject;
import flixel.math.FlxMath;

class SkidSprite extends flixel.FlxSprite {
	
	
	function new (x = 0.0, y = 0.0, ?graphic) { super(x, y, graphic); }
	
	// --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
	// Hack to allow drag when acellerating opposite to velocity
	// --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
	
	public var skidDrag = true;
	public var useRadialMotion = true;
	public var radialDrag = 0.0;
	public var radialMaxVelocity = 0.0;
	
	override function updateMotion(elapsed:Float)
	{
		var velocityDelta = 0.5 * 
		( computeVelocity
			(angularVelocity, angularAcceleration, angularDrag, skidDrag, maxAngular, elapsed)
			- angularVelocity
		);
		angularVelocity += velocityDelta; 
		angle += angularVelocity * elapsed;
		angularVelocity += velocityDelta;
		
		if (useRadialMotion)
		{
			var vDelta = computeRadialVelocity
				(velocity, acceleration, radialDrag, skidDrag, radialMaxVelocity, elapsed)
				.subtractPoint(velocity)
				.scale(0.5);
			
			velocity.addPoint(vDelta);
			x += velocity.x * elapsed;
			y += velocity.y * elapsed;
			velocity.addPoint(vDelta);
		}
		else
		{
			velocityDelta = 0.5 *
			( computeVelocity
				(velocity.x, acceleration.x, drag.x, skidDrag, maxVelocity.x, elapsed)
				- velocity.x
			);
			velocity.x += velocityDelta;
			x += velocity.x * elapsed;
			velocity.x += velocityDelta;
			
			velocityDelta = 0.5 *
			( computeVelocity
				(velocity.y, acceleration.y, drag.y, skidDrag, maxVelocity.y, elapsed)
				- velocity.y
			);
			velocity.y += velocityDelta;
			y += velocity.y * elapsed;
			velocity.y += velocityDelta;
		}
	}

	static function computeVelocity
	( velocity    :Float
	, acceleration:Float
	, drag        :Float
	, skidDrag    :Bool
	, max         :Float
	, elapsed     :Float
	):Float
	{
		if (acceleration != 0)
			velocity += acceleration * elapsed;
		
		if (drag != 0 && (acceleration == 0 || (skidDrag && !FlxMath.sameSign(velocity, acceleration))))
		{
			var drag:Float = drag * elapsed;
			if (velocity - drag > 0)
				velocity -= drag;
			else if (velocity + drag < 0)
				velocity += drag;
			else
				velocity = 0;
		}
		
		if ((velocity != 0) && (max != 0))
		{
			if (velocity > max)
				velocity = max;
			else if (velocity < -max)
				velocity = -max;
		}
		return velocity;
	}
	
	static function computeRadialVelocity
	( velocity    :FlxVector
	, acceleration:FlxVector
	, drag        :Float
	, skidDrag    :Bool
	, max         :Float
	, elapsed     :Float
	):FlxVector
	{
		var newVelocity = FlxVector.get()
			.copyFrom(velocity)
			.add(acceleration.x * elapsed, acceleration.y * elapsed);
		
		var length = newVelocity.length;
		if
		( drag > 0
		&&  ( acceleration.isZero()
			|| (skidDrag && newVelocity.dotProduct(acceleration) < 0)
			)
		)
		{
			var drag = drag * elapsed;
			if (length <= drag)
			{
				newVelocity.set();
				length = 0;
			}
			else
			{
				newVelocity.scale((length - drag) / length);
				length -= drag;
			}
		}
		
		if (max > 0 && length > 0 && length > max)
			newVelocity.length = max;
		
		return newVelocity;
	}
}