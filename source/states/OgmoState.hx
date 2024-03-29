package states;

import haxe.Json;

import openfl.Assets;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.tile.FlxTilemap;
import flixel.group.FlxGroup;

import sprites.pods.PodGroup;

class OgmoState extends FlxState
{
    var byName:Map<String, FlxBasic> = new Map();
    
    function parseLevel(levelPath:String)
    {
        var data:OgmoLevelData = Json.parse(Assets.getText(levelPath));
        
        var bounds = FlxG.worldBounds.set(data.offsetX, data.offsetY, data.width, data.height);
        FlxG.camera.setScrollBounds(bounds.left, bounds.right, bounds.top, bounds.bottom);
        
        for (layerData in data.layers)
        {
            var layer = createLayer(layerData);
            add(layer);
            byName[layerData.name] = layer;
        }
    }
    
    function createLayer(data:OgmoLayerData):FlxBasic
    {
        if (Reflect.hasField(data, "tileset"))
            return new OgmoTilemap(cast data);
        
        if (Reflect.hasField(data, "entities"))
            return new OgmoEntityLayer(cast data);
        
        throw 'unhandled layer: ${data.name}';
    }
    
    public function getByName<T:FlxBasic>(name:String):Null<T>
    {
        return cast byName[name];
    }
}

class OgmoTilemap extends FlxTilemap
{
    public var name:String;
    public function new (data:OgmoTileLayerData)
    {
        super();
        
        name = data.name;
        x = data.offsetX;
        y = data.offsetY;
        loadMapFromArray
            ( data.data.map(i->i+1)
            , data.gridCellsX
            , data.gridCellsY
            , "assets/images/tiles.png"
            , data.gridCellWidth
            , data.gridCellHeight
            , AUTO
            , 0
            , 0
            , 0
            );
    }
}


class OgmoEntityLayer extends FlxGroup
{
    public var name:String;
    
    var byName:Map<String, FlxBasic> = new Map();
    
    public function new (data:OgmoEntityLayerData)
    {
        super();
        
        for (entityData in data.entities)
        {
            var entity = add(create(entityData));
            if (entityData.values.id != "" && entityData.values.id != null)
                byName[entityData.values.id] = entity;
        }
        
        for (i in 0...data.entities.length)
        {
            (cast members[i]:IOgmoEntity<Dynamic>).ogmoInit(data.entities[i], this);
        }
    }
    
    function create(data:OgmoEntityData<Dynamic>):FlxBasic
    {
        var entity = switch(data.name)
        {
            case "Ship": new PodGroup();
            case name: throw 'unhandled entity name: $name';
        }
        
        return entity;
    }
    
    public function getByName<T:FlxBasic>(name:String):Null<T>
    {
        return cast byName[name];
    }
}

typedef OgmoLevelData =
{
    width     :Int,
    height    :Int,
    offsetX   :Int,
    offsetY   :Int,
    layers    :Array<OgmoLayerData>,
    exportMode:Int,
    arrayMode :Int
}

typedef OgmoLayerData = 
{
    name          :String,
    offsetX       :Int,
    offsetY       :Int,
    gridCellWidth :Int,
    gridCellHeight:Int,
    gridCellsX    :Int,
    gridCellsY    :Int
}

typedef OgmoTileLayerData
= OgmoLayerData
& {
    tileset:String,
    data   :Array<Int>
}

typedef OgmoEntityLayerData
= OgmoLayerData
& {
    entities:Array<OgmoEntityData<Dynamic>>
}

typedef OgmoEntityData<T>
= {
    name    :String,
    id      :Int,
    x       :Int,
    y       :Int,
    rotation:Float,
    originX :Int,
    originY :Int,
    values  :T
}

interface IOgmoEntity<T>
{
    function ogmoInit(data:OgmoEntityData<T>, parent:OgmoEntityLayer):Void;
}