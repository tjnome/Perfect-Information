//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_MCMScreenListener
//	Author: tjnome
//	
//-----------------------------------------------------------

class XCom_Perfect_Information_MCMScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen) {
    local XCom_Perfect_Information_MCMListener MCMListener;

    if (MCM_API(Screen) != none) {
        MCMListener = new class'XCom_Perfect_Information_MCMListener';
        MCMListener.OnInit(Screen);
    }
}

defaultproperties
{
    // The class you're listening for doesn't exist in this project, so you can't listen for it directly.
    ScreenClass = none;
}