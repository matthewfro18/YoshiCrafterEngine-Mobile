import sys.thread.Thread;
import sys.io.File;
import sys.FileSystem;
import lime.system.System;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

typedef LoadingShit = {
    var name:String;
    var func:Void->Void; 
}

class LoadingScreen extends FlxState {
    var loadSections:Array<LoadingShit> = [
    ];
    var step:Int = 0;
    var loadingText:FlxText;
    var switchin:Bool = false;
    var bg:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();
    
    var w = 775;
    var h = 550;

    public override function create() {
        super.create();
        // var loadingBG = new FlxSprite(0,0).loadGraphic(Paths.image("loading/bg", "preload"));
        // add(loadingBG);

        

        var loadingThingy = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK, true);
        loadingThingy.pixels.lock();
        var color1 = FlxColor.fromRGB(0, 66, 119);
        var color2 = FlxColor.fromRGB(86, 0, 151);
        for(x in 0...loadingThingy.pixels.width) {
            for(y in 0...loadingThingy.pixels.height) {
                loadingThingy.pixels.setPixel32(x, y, FlxColor.fromRGB(
                    Std.int(FlxMath.remapToRange(((y / loadingThingy.pixels.height) * 1), 0, 1, color1.red, color2.red)),
                    Std.int(FlxMath.remapToRange(((y / loadingThingy.pixels.height) * 1), 0, 1, color1.green, color2.green)),
                    Std.int(FlxMath.remapToRange(((y / loadingThingy.pixels.height) * 1), 0, 1, color1.blue, color2.blue))
                ));
            }
        }
        loadingThingy.pixels.unlock();
        add(loadingThingy);

        

        for(x in 0...Math.ceil(FlxG.width / w)+1) {
            for(y in 0...(Math.ceil(FlxG.height / h)+1)) {
                // bg pattern
                var pattern = new FlxSprite(x * w, y * h);
                pattern.loadGraphic(Paths.image("loading/bgpattern", "preload"));
                pattern.antialiasing = true;
                bg.add(pattern);
            }
        }
        add(bg);

        var loading = new FlxSprite().loadGraphic(Paths.image("loading/loading"));
        loading.scale.set(0.85, 0.85);
        loading.updateHitbox();
        loading.y = FlxG.height - (loading.height * 0.85);
        loading.screenCenter(X);
        loading.antialiasing = true;
        add(loading);

        loadingText = new FlxText(0, 0, FlxG.width, "Loading...", 32);
        loadingText.setFormat(Paths.font("vcr.ttf"), Std.int(32), FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        loadingText.y = FlxG.height - (loadingText.height * 1.5);
        loadingText.screenCenter(X);
        loadingText.antialiasing = true;
        add(loadingText);

        var logoBl = new FlxSprite(-150, -25);
        logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
        logoBl.antialiasing = true;
        logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
        logoBl.animation.play('bump');
        logoBl.updateHitbox();
        logoBl.screenCenter(X);
        add(logoBl);

        loadSections.push({
                "name" : "Save Data",
                "func" : saveData
            });
        #if android
        loadSections.push({
                "name" : "Base Game Installation",
                "func" : installBaseGame
            });
        #end
        loadSections.push({
                "name" : "Mod Config",
                "func" : modConfig
            });
        // loadSections.push({
        //         "name" : "Freeplay Songs",
        //         "func" : freeplayShit
        //     });

        FlxG.autoPause = false;

        #if sys
        Thread.create(function() {
            for(k=>s in loadSections) {
                loadingText.text = 'Loading ${s.name}... (${Std.string(Math.floor((k / loadSections.length) * 100))}%)';
                trace(loadingText.text);
                s.func();
            }
            switchin = true;
            // FlxG.autoPause = false;
    
            var e = new #if ycebeta BetaWarningState #else TitleState #end();
            FlxG.switchState(e);
        });
        #end
    }
    var aborted = false;

    public override function update(elapsed:Float) {
        bg.x -= w * elapsed / 4;
        bg.x %= w;
        bg.y -= h * elapsed / 4;
        bg.y %= h;
        super.update(elapsed);

        #if !sys
        if (switchin || aborted) return;

        
        if (step < 0) {
            loadingText.text = "Loading " + loadSections[0].name + "... (0%)";
            step = 0;
            return;
        }
        if (step >= loadSections.length) {
                switchin = true;
                FlxG.autoPause = true;
                var e = new TitleState();
                trace(e);
                FlxG.switchState(e);
        } else {
            loadSections[step].func();
            step++;
            if (aborted) return;
            if (step >= loadSections.length) {
                loadingText.text = "Loading Complete ! (100%)";
            } else {
                loadingText.text = "Loading " + loadSections[step].name + "... (" + Std.string(Math.round((step / loadSections.length) * 100)) + "%)";
            }
            loadingText.screenCenter(X);
        }
        #end

    }

    public function modConfig() {
        ModSupport.reloadModsConfig();
    }
    // public function storyModeShit() {
    //     StoryMenuState.loadWeeks();
    // }
    // public function freeplayShit() {
    //     FreeplayState.loadFreeplaySongs();
    // }
    public function saveData() {
		// ╔═══════════════════════════════════════════════════╗
		// ║ /!\ WARNING !                                     ║
		// ╟───────────────────────────────────────────────────╢
		// ║ I bet you guys have enough of having to redo your ║
		// ║ keybinds everytime you load a new mod. The line   ║
		// ║ below assure synchronisation between EVERY mods   ║
		// ║ that uses YoshiCrafter Engine. For god's sake, DO NOT    ║
		// ║ edit the function, or remove this line. People    ║
		// ║ have enough of having to do their keybinds        ║
		// ║ everytime they download a new mod. If you wanna   ║
		// ║ set your own bind path, uses the fields :         ║
		// ║   - Settings.save_bind_name                       ║
		// ║   - Settings.save_bind_path                       ║
		// ║ In the EngineSettings.hx file.                      ║
		// ╚═══════════════════════════════════════════════════╝
		   FlxG.save.bind(Settings.save_bind_name, Settings.save_bind_path); // Binds to your mod data
		   Settings.loadDefault();  // Binds another instance of FlxSave to the engine's settings, allowing synchronisation between mods
		// -------------------------------------------

        
        var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
        diamond.persist = true;
        diamond.destroyOnNoUse = false;
        FlxG.bitmap.spareFromCache.push(diamond);

        trace("transitions");
        FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.5, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
            new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
        trace(FlxTransitionableState.defaultTransIn);

        FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.35, new FlxPoint(0, 1),
            {asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
        trace(FlxTransitionableState.defaultTransOut);
        // transIn = FlxTransitionableState.defaultTransIn;
        // transOut = FlxTransitionableState.defaultTransOut;

    }
    #if android
    public function installBaseGame() {
        trace("Installing base game...");
        Settings.engineSettings.data.developerMode = true;
        if (!FileSystem.exists(Paths.modsPath)) {
            // trace("no mods folder, creating one");;
            loadingText.text = "Mods folder not detected. Please follow the instructions in the zip file.";
            loadingText.y = FlxG.height - (loadingText.height * 1.5);
            aborted = true;
        }
        if (!FileSystem.exists(Paths.getSkinsPath())) {
            // trace("no skins folder, creating one");
            // FileSystem.createDirectory(Paths.getSkinsPath());
            trace("copying yoshiCrafter engine skins");
            loadingText.text = "Skins folder not detected. Please follow the instructions in the zip file.";
            loadingText.y = FlxG.height - (loadingText.height * 1.5);
            aborted = true;
        }
    }
    #end
}