part of Phaser;

class AnimationManager {
  Sprite sprite;
  Game game;
  Frame currentFrame;
  Animation currentAnim;
  bool updateIfVisible = true;
  bool isLoaded = false;
  final FrameData frameData;

  Map _anims;
  List _outputFrames = [];
  int _frameIndex = 0;

  //int _frame = 0;

  bool __tilePattern;
  bool tilingTexture;

  int get frameTotal => frameData.total;

  bool get paused => currentAnim.isPaused;

  set paused(bool value) {
    currentAnim.isPaused = value;
  }

  int get frame {
    if (this.currentFrame) {
      return this._frameIndex;
    }
    return -1;
  }

  set frame(int value) {
    if (value is num && this.frameData != null && this.frameData.getFrame(value) != null) {
      this.currentFrame = this.frameData.getFrame(value);

      if (this.currentFrame) {
        this._frameIndex = value;
        this.sprite.setTexture(PIXI.TextureCache[this.currentFrame.uuid]);

        if (this.sprite.__tilePattern) {
          this.__tilePattern = false;
          this.tilingTexture = false;
        }
      }
    }
  }

  String get frameName {
    if (this.currentFrame) {
      return this.currentFrame.name;
    }
    else return null;
  }

  set frameName(String value) {
    if (value is String && this.frameData != null && this.frameData.getFrameByName(value) != null) {
      this.currentFrame = this.frameData.getFrameByName(value);
      if (this.currentFrame) {
        this._frameIndex = this.currentFrame.index;
        this.sprite.setTexture(PIXI.TextureCache[this.currentFrame.uuid]);

        if (this.sprite.__tilePattern) {
          this.__tilePattern = false;
          this.tilingTexture = false;
        }
      }
    }
    else {
      window.console.warn('Cannot set frameName: ' + value);
    }
  }

  //FrameData get frameData=>_frameData;

  AnimationManager(this.sprite) {
    game = sprite.game;

  }


  loadFrameData(FrameData frameData) {

    this.frameData = frameData;
    this.frame = 0;
    this.isLoaded = true;

  }

  Animation add(int name, [List frames=[], num frameRate=60, bool loop=false, bool useNumericIndex]) {

    if (this.frameData == null) {
      window.console.warn('No FrameData available for Phaser.Animation ' + name);
      return;
    }

    frameRate = frameRate || 60;


    //  If they didn't set the useNumericIndex then let's at least try and guess it
    if (useNumericIndex == null) {
      if (frames && frames[0] == 'number') {
        useNumericIndex = true;
      }
      else {
        useNumericIndex = false;
      }
    }

    //  Create the signals the AnimationManager will emit
    if (this.sprite.events.onAnimationStart == null) {
      this.sprite.events.onAnimationStart = new Signal();
      this.sprite.events.onAnimationComplete = new Signal();
      this.sprite.events.onAnimationLoop = new Signal();
    }

    this._outputFrames.length = 0;

    this.frameData.getFrameIndexes(frames, useNumericIndex, this._outputFrames);

    this._anims[name] = new Animation(this.game, this.sprite, name, this.frameData, this._outputFrames, frameRate, loop);
    this.currentAnim = this._anims[name];
    this.currentFrame = this.currentAnim.currentFrame;
    this.sprite.setTexture(PIXI.TextureCache[this.currentFrame.uuid]);

    if (this.sprite.__tilePattern) {
      this.__tilePattern = false;
      this.tilingTexture = false;
    }

    return this._anims[name];

  }

  bool validateFrames(List frames, [bool useNumericIndex=true]) {

    for (int i = 0; i < frames.length; i++) {
      if (useNumericIndex == true) {
        if (frames[i] > this.frameData.total) {
          return false;
        }
      }
      else {
        if (this.frameData.checkFrameName(frames[i]) == false) {
          return false;
        }
      }
    }

    return true;

  }

  play(name, num frameRate, bool loop, bool killOnComplete) {

    if (this._anims[name]) {
      if (this.currentAnim == this._anims[name]) {
        if (this.currentAnim.isPlaying == false) {
          this.currentAnim.paused = false;
          return this.currentAnim.play(frameRate, loop, killOnComplete);
        }
      }
      else {
        if (this.currentAnim != null && this.currentAnim.isPlaying) {
          this.currentAnim.stop();
        }

        this.currentAnim = this._anims[name];
        this.currentAnim.paused = false;
        return this.currentAnim.play(frameRate, loop, killOnComplete);
      }
    }

  }

  stop(name, [resetFrame =null]) {
    if (name is String) {
      if (this._anims[name] != null) {
        this.currentAnim = this._anims[name];
        this.currentAnim.stop(resetFrame);
      }
    }
    else {
      if (this.currentAnim) {
        this.currentAnim.stop(resetFrame);
      }
    }
  }

  bool update() {

    if (this.updateIfVisible && !this.sprite.visible) {
      return false;
    }

    if (this.currentAnim && this.currentAnim.update() == true) {
      this.currentFrame = this.currentAnim.currentFrame;
      return true;
    }

    return false;

  }

  Animation getAnimation(name) {
    if (name is String) {
      if (this._anims[name] != null) {
        return this._anims[name];
      }
    }
    return null;
  }

  refreshFrame() {
    this.sprite.setTexture(PIXI.TextureCache[this.currentFrame.uuid]);
    if (this.sprite.__tilePattern) {
      this.__tilePattern = false;
      this.tilingTexture = false;
    }
  }

  destroy() {


    for (Animation anim in this._anims.keys) {
      this._anims[anim].destroy();
    }
    this._anims = {
    };
    this.frameData = null;
    this._frameIndex = 0;
    this.currentAnim = null;
    this.currentFrame = null;
  }


}