//Autosplitter for the .exe flash version of Vex 3, (currently limited to) Any%

state("vex-3")
{
	//This variable starts to return 1 when a transition starts and
	//returns 0 again as soon as the transition's diamonds are fading
	//away. 
	//It's a variable of the main script. 
	int transitionIn : 0x007E8A80, 0x10, 0x8, 0x24, 0x6C, 0x8, 0x0, 0xCC;
	
	//This variable returns 1 while the player is being sucked into the
	//finish portal. I'm not quite sure if the igt stops as soon as this
	//variable is 1 or a single frame later, haven't really looked into 
	//the update order yet. 
	//It's a variable of the current player instance. 
	int finishedLevel : 0x00804070, 0x4, 0x314, 0x88, 0x9C, 0x2C, 0x19C, 0xD0;
	
	//This variable changes to the current level (0 = Hub, 1 = Act 1, 
	//10 = Vexation) and it looks like it changes the current color 
	//palette. The important aspect is that this is 10 while playing 
	//Vexation, which has to be split using the finishedLevel variable
	//instead of the transitionIn variable. 
	//It's a variable of the main script. 
	int level : 0x007E8A80, 0x10, 0x8, 0x24, 0x6C, 0x8, 0x0, 0x74;
	
	//This variable is a frame counter. It seems to start counting when
	//the program is started. 
	//I have no clue where this variable is defined ...
	int frameCount : 0x00804070, 0x4, 0xC, 0xC, 0x114;
}



startup
{
	//This seems to allow us to play around with the timer functions,
	//we need this to reset when you exit the game.
	vars.TimerModel = new TimerModel { CurrentState = timer };
	
	//This variable stores the state of the frame counter when the run
	//is started.
	vars.frameCountOnStart = 0;
	
	//Settings ...
	settings.Add("traditionalSplits", false, "Traditional splits");
	settings.SetToolTip("traditionalSplits", 
		"Split whenever a finish portal is reached, instead of splitting whenever a transition starts or ends (+Vex portal).");
}



start
{
	//When you press "Play game", you start a transition, so we check
	//for a rising edge of the transitionIn variable.
	if((current.transitionIn == 1) && (old.transitionIn == 0)){
		//Remember the current frame count
		vars.frameCountOnStart = current.frameCount;
		return true;
	}
	return false;
}

split
{
	bool transitionChange = (current.transitionIn != old.transitionIn);
	bool anyFinishPortalEntered = (current.finishedLevel == 1) && (old.finishedLevel == 0);
	int vexationLevelId = 10;
	bool finalFinishPortalEntered = (anyFinishPortalEntered && (current.level == vexationLevelId));
	
	if(settings["traditionalSplits"]){
		
		//  Traditional splits:
		//Split when a finish portal is reached.
		return anyFinishPortalEntered;
		
	}
	else{
		
		//  Non-traditional splits:
		//Split whenever the transition state changes, when a transition
		//starts and when it ends. 
		//In addition to that, split when the player enters the final
		//finish portal of the Vexation act.
		return transitionChange || finalFinishPortalEntered;
		
	}
	
}

gameTime
{
	int frames = current.frameCount - vars.frameCountOnStart;
	int fps = 30;
	int millis = (frames * 1000) / fps;
	return TimeSpan.FromMilliseconds(millis);
}



reset{return false;}//just to make the reset setting show up

exit
{
	//If the reset setting is enabled and the run isn't finished ...
	if(settings.ResetEnabled && !(timer.CurrentPhase == TimerPhase.Ended)){
	
		//We need to undo the last split because the split condition
		//"transitionChange" is briefly met when you exit the game while
		//old.transitionIn is 1 (aka during a transition). This means 
		//that your best transition segment won't be saved if you exit
		//during the following split. It's not too elegant but it works
		//well enough imho. 
		vars.TimerModel.UndoSplit();
		vars.TimerModel.Reset();
	}
}