# FastFollow
FFXI Windower addon that allows multiboxers to follow more easily and keep their characters more tightly grouped. ONLY WORKS WITH MULTIBOXERS.

## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called FastFollow, rather than -master or -v1.whatever. Your file structure should look like this:

    addons/FastFollow/FastFollow.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to add a line to your scripts/init.txt:

    lua load FastFollow

To get pause-on-spellcasting working perfectly, you will also need an update for Windower's `res/spells.lua` for the Era cast times. Some spells had their cast times reduced in retail.

## Commands

You can use `//fastfollow` or `//ffo`.

    //ffo <character_name> -- Will cause the current character to follow the specified character.  
    //ffo me -- Cause all other characters to follow this one.  
    //ffo pauseon <spells|items|dismount> -- Use auto-pausing to temporarily stop following to cast spells, etc.  
    //ffo pausedelay <delay> -- Choose how long to wait for following to correctly stop before doing the action.
