package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;

import openfl.display.Bitmap;

import data.ExplosionGroup;
import sprites.*;
import sprites.pods.*;
import states.OgmoState;

class GameState extends OgmoState
{
    var stars:FlxTypedGroup<FlxSprite>;
    
    var entities:OgmoEntityLayer;
    var freePods:FlxTypedGroup<Pod>;
    var podGroups:FlxTypedGroup<PodGroup>;
    var enemies:FlxTypedGroup<Enemy>;
    var cockpits:FlxTypedGroup<Cockpit>;
    var badBullets:FlxTypedGroup<FlxTypedGroup<Bullet>>;
    var explosions:ExplosionGroup;
    
    var hero:Hero;
    var geom:FlxTilemap;
    
    override function create()
    {
        super.create();
        // FlxG.debugger.drawDebug = true;
        
        FlxG.cameras.bgColor = FlxG.stage.color;
        add(stars = drawStars());
        
        parseLevel("assets/data/Level.json");
        
        geom = getByName("Geom");
        entities = getByName("Entities");
        hero = entities.getByName("hero");
        
        add(freePods = new FlxTypedGroup());
        
        podGroups = new FlxTypedGroup();
        enemies = new FlxTypedGroup();
        cockpits = new FlxTypedGroup();
        add(explosions = new ExplosionGroup());
        add(badBullets = new FlxTypedGroup());
        add(hero.bullets);
        for (member in entities.members)
        {
            if (Std.is(member, PodGroup))
            {
                var group:PodGroup = cast member;
                podGroups.add(group);
                cockpits.add(group.cockpit);
                if (group != hero)
                {
                    enemies.add(Std.downcast(group, Enemy));
                    badBullets.add(group.bullets);
                }
            }
        }
    }
    
    function drawStars(avgSpacing = 100):FlxTypedGroup<FlxSprite>
    {
        final density = 1 / avgSpacing / avgSpacing;
        final stars = new FlxTypedGroup<FlxSprite>();
        final graphic = new openfl.display.BitmapData(2, 2, false);
        
        var num = Math.floor(camera.width * camera.height * density);
        while(num-- > 0)
        {
            stars.add
                ( new FlxSprite
                    ( FlxG.random.float(camera.x, camera.width)
                    , FlxG.random.float(camera.y, camera.height)
                    , graphic
                    )
                );
        }
        return stars;
    }
    
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        updateStars();
        
        handleCollisions(elapsed);
        
        for (group in podGroups)
        {
            if (group.alive)
                group.checkHealthAndFling(freePods, explosions);
        }
    }
    
    function updateStars():Void
    {
        for (star in stars.members)
        {
            if (star.x + star.width    < camera.scroll.x) star.x += camera.width  + star.width ;
            if (star.x - camera.width  > camera.scroll.x) star.x -= camera.width  + star.width ;
            if (star.y + star.height   < camera.scroll.y) star.y += camera.height + star.height;
            if (star.y - camera.height > camera.scroll.y) star.y -= camera.height + star.height;
        }
    }
    
    function handleCollisions(elapsed:Float):Void
    {
        FlxG.collide(cockpits, geom);
        
        FlxG.collide(freePods, geom);
        
        FlxG.collide(podGroups, geom, 
            function (pod:Pod, _)
            {
                pod.hit();
                pod.group.bounce();
            }
        );
        
        FlxG.overlap(podGroups, freePods,
            function onPodsCollide(used:Pod, free:Pod):Void
            {
                trace(free.free, used.checkOverlapPod(free));
                if (free.free && used.checkOverlapPod(free))
                {
                    freePods.remove(free);
                    used.group.linkPod(free, used);
                }
            }
        );
        
        FlxG.overlap(podGroups, podGroups,
            function onPodsCollide(pod1:Pod, pod2:Pod):Void
            {
                if (pod1.group != pod2.group && pod1.checkOverlapPod(pod2))
                {
                    if (pod1.type == Poker || pod2.type == Poker)
                    {
                        if (pod1.type == Poker && pod2.type != Poker)
                            pod2.group.onPoked(pod1.group, pod2);
                        else if (pod2.type == Poker && pod1.type != Poker)
                            pod1.group.onPoked(pod2.group, pod1);
                    }
                    else
                    {
                        pod1.hit(1);
                        pod2.hit(1);
                        pod1.group.bounce();
                        pod2.group.bounce();
                    }
                }
            }
        );
        
        FlxG.overlap(hero, badBullets, 
            function(pod:Pod, bullet:Bullet)
            {
                if (pod.checkOverlapBullet(bullet))
                {
                    bullet.kill();
                    pod.hit(bullet.damage);
                }
            }
        );
        
        FlxG.overlap(enemies, hero.bullets,
            function(pod:Pod, bullet:Bullet)
            {
                if (pod.checkOverlapBullet(bullet))
                {
                    pod.group.onShot(bullet, pod);
                    bullet.onHit(pod);
                }
            }
        );
    }
}