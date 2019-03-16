# FastFollow
FFXI Windower addon that allows multiboxers to follow more easily and keep their characters more tightly grouped. ONLY WORKS WITH MULTIBOXERS.
Note that this is NOT the same as `/follow`. You must use `//ffo <name>` or `//ffo me` to start following.

## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called FastFollow, rather than FastFollow-master or FastFollow-v1.whatever. Your file structure should look like this:

    addons/FastFollow/FastFollow.lua
    addons/FastFollow/spell_cast_times.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to add a line to your scripts/init.txt:

    lua load FastFollow

## Commands

You can use `//fastfollow` or `//ffo`.

    //ffo <character_name> -- Will cause the current character to follow the specified character.  
    //ffo me -- Cause all other characters to follow this one.  
    //ffo stop -- Make this character stop following.  
    //ffo stopall -- Stop following on all characters.  
    //ffo pauseon <spells|items|dismount> -- Use auto-pausing to temporarily stop following to cast spells, etc.  
    //ffo pausedelay <delay> -- Choose how long to wait for following to correctly stop before doing the action.  
    //ffo min <distance> -- Set how closely to follow, between 0.2 and 10 yalms.  
    //ffo zone <duration> -- Set how long to attempt to follow into the next zone.  
    //ffo info [on|off] -- Display a box containing client-to-client distances, to detect when an alt gets orphaned.  
