package data;

@:using(MotionType.MotionData)
enum MotionType
{
    TimeAndSpeed(time    :Float, speed:Float, ?accel:AccelType);
    DisAndSpeed (distance:Float, speed:Float, ?accel:AccelType);
    DisAndTime  (distance:Float, time :Float, ?accel:AccelType);
}

class MotionData
{
    inline static public function createData(motion:Null<MotionType>):MotionData
    {
        var data = new MotionData();
        // handy dandy
        // vf = vi + a*t
        // D = (vf + vi)*t/2
        // D = vi*t + 0.5*a*t^2
        // vf^2 = vi ^ 2 + 2*a*D
        switch (motion)
        {
            case null:
            case TimeAndSpeed(t, v, accelType):
                data.time = t;
                switch(accelType)
                {
                    //  vf = vi  + a * t      (-vi)
                    //  vf - vi  = a * t      (/t)
                    // (vf - vi) / t = a      
                    case Linear | null:
                        data.speed = v;
                    case ToStop:
                        data.speed = v;
                        data.drag = (v - 0) / t;
                    case FromStop:
                        data.accel = (0 - v) / t;
                    case To(vf):
                        data.speed = v;
                        data.accel = (v - vf) / t;
                    case From(vi):
                        data.speed = vi;
                        data.accel = (vi - v) / t;
                }
            case DisAndSpeed(d, v, accelType):
                switch(accelType)
                {
                    // D = (vf + vi) * t / 2     (*2)
                    // 2 * D = (vf + vi) * t     (/(vf + vi))
                    // 2 * D / (vf + vi) = t
                    case Linear | null:
                        data.speed = v;
                        data.time = d / v;
                    case ToStop:
                        data.speed = v;
                        data.time = 2 * d / (0 + v);
                    case FromStop:
                        data.time = 2 * d / (v + 0);
                    case To(vf):
                        data.speed = v;
                        data.time = 2 * d / (vf + v);
                    case From(vi):
                        data.speed = vi;
                        data.time = 2 * d / (v + vi);
                }
                
            case DisAndTime(d, t, accelType):
                data.time = t;
                switch(accelType)
                {
                    //     d = t * (vf + vi) / 2      (*2)
                    // 2 * d = t * (vf + vi)          (/t)
                    // 2 * d / t = (vf + vi)
                    // vf = vi + a * t && vf = 2 * d / t
                    // a * t + vi = 2 * d / t       (-vi)
                    // a * t = 2 * d / t - vi       (/t)
                    // a = 2 * d / t / t - vi / t   (/t)
                    case Linear | null:
                        data.speed = d / t;
                    case ToStop:
                        data.speed = 2 * d / t - 0;
                        // vf^2 = vi ^ 2 + 2*a*D | where vf = 0
                        data.drag = data.speed * data.speed / 2 / d;
                    case FromStop:
                        trace(2 * d / t / t);
                        data.accel = 2 * d / t / t;// - (0 / t);
                    case To(vf):
                        data.speed = 2 * d / t - vf;
                        // a = vf / t - vi
                        if (vf > data.speed)
                            data.accel = vf / t - data.speed;
                        else
                            data.drag = data.speed - vf / t;
                    case From(vi):
                        data.speed = vi;
                        // a = 2(d - vi * t)
                        if (vi < data.speed)
                            data.accel = 2 * (d - vi * t);
                        else
                            data.drag = 2 * (vi * t - d);
                }
        }
        return data;
    }
    
    public var time (default, null) = 0.0;
    public var speed(default, null) = 0.0;
    public var drag (default, null) = 0.0;
    public var accel(default, null) = 0.0;
    public var max  (default, null) = 0.0;
    
    inline function new() {}
}

enum AccelType
{
    Linear;
    ToStop;
    FromStop;
    To(value:Float);
    From(value:Float);
}