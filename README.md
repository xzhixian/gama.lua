# Gama.lua

A lua module for using Gama assets directly in Cocos2d-x game engine.

[gama.lua](https://github.com/GamaLabs/gama.lua) 是一个 gama 针对 [Cocos2d-x](http://www.cocos2d-x.org/) 引擎的开源插件，通过这个插件，Cocos2d-x的开发者可以直接在程序中使用各种 gama 素材


## API 文档

```
▼ GamaAnimation : Class
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

▼ GamaFigure : Class
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

▼ GamaIconPack : Class
    __tostring : function
    drawOnSprite : function
    new : function
    release : function
    retain : function

▼ GamaTilemap : Class
    __tostring : function
    addOrnament : function
    bindToSprite : function
    getContainerPoisition : function
    moveBy : function
    new : function
    setCenterPosition : function
    uiCordToVertexCord : function
    updateContainerPosition : function

▼ gama.animation : object
    getByCSX : function
    getById : function

▼ gama.figure : object
    getByCSX : function
    getByCharacterId : function
    getById : function

▼ gama.iconpack* : object
    getByCSX : function
    getById : function

▼ gama.scene : object
  ▼ getByCSX : function
      isMaskedAt : function
      isMaskedAtBrick : function
      isWalkableAt : function
      isWalkableAtBrick : function
    jobProcessor : function
    loadById : function

▼ gama.tilemap* : object
    getByCSX : function
    getById : function


▼ gama.texture2D* : object
    getById : function
    getFromJSON : function
    makeSpriteFrames : function

▼ window* : object
    DUMMY_CALLBACK : function
    cleanup : function
    fromhex : function
    getTypeById : function
    loadById : function
    playSoundFx : function
    readJSON : function
    readJSONAsync : function
    soundFX2Action : function

```






