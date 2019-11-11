package states;

import flixel.math.FlxVector;
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
import sprites.bullets.Bullet;
import states.OgmoState;

class GameState extends OgmoState
{
    var stars:FlxTypedGroup<FlxSprite>;
    
    var entities:OgmoEntityLayer;
    var freePods:FlxTypedGroup<Pod>;
    var podGroups:FlxTypedGroup<PodGroup>;
    var enemies:FlxTypedGroup<PodGroup>;
    var cockpits:FlxTypedGroup<Cockpit>;
    var badBullets:BulletGroup;
    var explosions:ExplosionGroup;
    
    var hero:PodGroup;
    var geom:FlxTilemap;
    
    override function create()
    {
        super.create();
        // FlxG.debugger.drawDebug = true;
        
        FlxG.cameras.bgColor = FlxG.stage.color;
        add(stars = drawStars());
        
        parseLevel("assets/data/ogmo/NeedlerTest.json");
        
        geom = getByName("Geom");
        entities = getByName("Entities");
        hero = entities.getByName("hero");
        
        add(freePods = new FlxTypedGroup());
        
        podGroups = new FlxTypedGroup();
        enemies = new FlxTypedGroup();
        cockpits = new FlxTypedGroup();
        add(explosions = new ExplosionGroup());
        add(hero.bullets = new BulletGroup());
        add(badBullets = new BulletGroup());
        for (member in entities.members)
        {
            if (Std.is(member, PodGroup))
            {
                var group:PodGroup = cast member;
                group.explosions = explosions;
                podGroups.add(group);
                cockpits.add(group.cockpit);
                if (group != hero)
                {
                    enemies.add(group);
                    group.bullets = badBullets;
                }
            }
        }
        
        #if debug
            // if (Circle.debugDrawer == null)
            // {
            //     var shape = new openfl.display.Shape();
            //     FlxG.game.parent.addChild(shape);
            //     Circle.debugDrawerShape = shape;
            // }
        #end
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
        
        if (FlxG.keys.justPressed.ONE  ) freePods.add(new Pod(Laser   , FlxG.mouse.x, FlxG.mouse.y));
        if (FlxG.keys.justPressed.TWO  ) freePods.add(new Pod(Rocket  , FlxG.mouse.x, FlxG.mouse.y));
        if (FlxG.keys.justPressed.THREE) freePods.add(new Pod(Thruster, FlxG.mouse.x, FlxG.mouse.y));
        if (FlxG.keys.justPressed.FOUR ) freePods.add(new Pod(Poker   , FlxG.mouse.x, FlxG.mouse.y));
        if (FlxG.keys.justPressed.FIVE ) freePods.add(new Pod(Shield  , FlxG.mouse.x, FlxG.mouse.y));
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
        #if debug
        if (Circle.debugDrawer != null)
        {
            Circle.debugDrawerShape.x = -FlxG.camera.scroll.x;
            Circle.debugDrawer.clear();
        }
        #end
        
        FlxG.collide(cockpits, geom);
        
        FlxG.collide(freePods, geom);
        
        var p = FlxVector.get();
        var v = FlxVector.get();
        FlxG.overlap(podGroups, geom,
            function (pod:Pod, _)
            {
                pod.hit(1);
                pod.group.cockpit.x + pod.x - p.x;
                pod.group.cockpit.y + pod.y - p.y;
                pod.group.bump(pod.velocity.x - v.x, pod.velocity.y - v.y);
            },
            function (a:Pod, b):Bool
            {
                a.getPosition(p);
                v.copyFrom(a.velocity);
                return FlxObject.separate(a, b);
            }
        );
        v.put();
        
        Pod.overlap(podGroups, freePods,
            function (used:Pod, free:Pod):Void
            {
                freePods.remove(free);
                used.group.linkPod(free, used);
            },
            function (used:Pod, free:Pod):Bool
            {
                return free.free && free.catchable
                    //&& Pod.separate(used, free);
                    ;
            }
        );
        
        Pod.collide(hero, enemies,
            function (pod1:Pod, pod2:Pod):Void
            {
                pod1.touchPod(pod1.type == Poker ? 0 : pod2.type == Poker ? 2 : 1);
                pod2.touchPod(pod2.type == Poker ? 0 : pod1.type == Poker ? 2 : 1);
            }
        );
        
        function processPodBullet(pod:Pod, bullet:Bullet):Bool
        {
            return pod.canHurt && pod.health > 0 && Circle.overlapThisFrame(pod, bullet);
        }
        
        Circle.overlap(hero, badBullets,
            function(pod:Pod, bullet:Bullet)
            {
                pod.hit(bullet.damage);
                bullet.onHit(pod);
                explosions.create(7.5 * bullet.scale.x).start(bullet.x, bullet.y);
            },
            processPodBullet
        );
        
        Circle.overlap(enemies, hero.bullets,
            function(pod:Pod, bullet:Bullet)
            {
                pod.hit(bullet.damage);
                bullet.onHit(pod);
                explosions.create(22.5).start(bullet.x, bullet.y);
            },
            processPodBullet
        );
    }
}