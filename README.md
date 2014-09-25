# Gama.lua

A lua module for using Gama assets directly in Cocos2d-x game engine.

[gama.lua](https://github.com/GamaLabs/gama.lua) 是一个 gama 针对 [Cocos2d-x](http://www.cocos2d-x.org/) 引擎的开源插件，通过这个插件，Cocos2d-x的开发者可以直接在程序中使用各种 gama 素材


## API 文档

```lua
▼ GamaAnimation : Class                           -- 由 gama.lua 生成的类，用于表达一个 动画 对象
    __tostring : function
    drawSingleFrame : function
    getDuration : function
    new : function
    playOnSprite : function
    playOnSpriteWithInterval : function
    playOnceInContainer : function
    playOnceOnSprite : function
    release : function
    retain : function

▼ GamaFigure : Class                              -- 由 gama.lua 生成的类，用于表达一个 动作造型 对象
    __tostring : function
    findAnimation : function
    getId : function
    getMotions : function
    getSoundFX : function
    isFlipped : function
    new : function
    playOnSprite : function
    playOnceOnSprite : function
    setDefaultDirection : function
    setDefaultMotion : function

▼ GamaIconPack : Class                            -- 由 gama.lua 生成的类，用于表达一个 图片集合 对象
    __tostring : function
    drawOnSprite : function
    new : function
    release : function
    retain : function

▼ GamaTilemap : Class                             -- 由 gama.lua 生成的类，用于表达一个 瓦片地图 对象
    __tostring : function
    addOrnament : function
    bindToSprite : function
    getContainerPoisition : function
    moveBy : function
    new : function
    setCenterPosition : function
    uiCordToVertexCord : function
    updateContainerPosition : function

▼ gama.animation : object                         -- 载入 gama 动画素材的方法集合
    getByCSX : function
    getById : function

▼ gama.figure : object                            -- 载入 gama 动作造型 素材的方法集合
    getByCSX : function
    getByCharacterId : function
    getById : function

▼ gama.iconpack : object                          -- 载入 gama 图片集合 素材的方法集合
    getByCSX : function
    getById : function

▼ gama.scene : object                             -- 载入 gama 场景 素材的方法集合
  ▼ getByCSX : function
      isMaskedAt : function
      isMaskedAtBrick : function
      isWalkableAt : function
      isWalkableAtBrick : function
    loadById : function

▼ gama.tilemap : object                           -- 载入 gama 瓦片地图 素材的方法集合
    getByCSX : function
    getById : function

▼ gama.texture2D : object                         -- [内部模块] 用于异步加载纹理素材和将纹理素材转换为 Cocos2d-x 的动作帧
    getById : function
    getFromJSON : function
    makeSpriteFrames : function

```






