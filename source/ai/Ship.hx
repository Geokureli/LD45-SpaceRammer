package ai;

import openfl.utils.Assets;

import data.PodData;
import sprites.pods.*;
import states.OgmoState;

import haxe.Json;

class Ship
{
    var group:PodGroup;
    var cockpit(get, never):Cockpit;
    inline function get_cockpit() return group.cockpit;
    
    public function new () {}
    
    public function init(group:PodGroup, parent:OgmoEntityLayer)
    {
        this.group = group;
    }
    
    public function update(elapsed:Float):Void {}
}

enum abstract ShipType(String) from String to String
{
    static var data:Dynamic;
    
    var HERO;
    var BROKE;
    var SHOOTER0;
    var NEEDLER0;
    var NEEDLER1;
    var NEEDLER2;
    var WEAKBACK0;
    
    static public function getData(type:ShipType):ShipData
    {
        if (data == null)
            data = Json.parse(Assets.getText("assets/data/Ships.json"));
        
        return Reflect.getProperty(data, type);
    }
    
    static public function getClass(type:ShipType):Ship
    {
        return switch type
        {
            case HERO: return new Hero();
            case BROKE: return new Ship();
            default: return new Enemy();
        }
    }
}