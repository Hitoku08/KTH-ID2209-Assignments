

model StageSimulation

global{
	int stageNumber <- 3;
	int guestNumber <- 5;
	list<Stage> all_stages <- nil;
	list<Guest> all_guests <- nil;
	
	init{
		create Stage number: stageNumber returns: stages;
		create Guest number: guestNumber returns: guests;
		
		all_stages <- stages;
		all_guests <- guests;
		
		loop i from: 0 to: stageNumber - 1 {
			ask stages[i] {
				set lightShow <- rnd(1, 10);
				set speaker <- rnd(1, 10);
				set musicStyle <- rnd(1, 10);
				set location <- point(i * 25 + 35, 20);
			}
		}
		
		loop i from: 0 to: guestNumber - 1 {
			ask guests[i] {
				set lightShow <- rnd(1, 10);
				set speaker <- rnd(1, 10);
				set musicStyle <- rnd(1, 10);
				set location <- point(i * 10 + 25, 50);
			}
		}
	}
}

species Guest skills:[fipa, moving]{
	int lightShow;
	int speaker;
	int musicStyle;
	int utility <- 0;
	Stage stage <- nil;
	
	reflex askForAttributes when: (time = 0){
		write name + ': lightShow: '+ lightShow + '; speaker: '+ speaker+ '; musicStyle:'+ musicStyle;
		if (self = all_guests[guestNumber - 1]) {
				write '-----------------------------------------------------';
		}
		do start_conversation to: list(Stage) protocol:'no-protocol' performative:'inform' contents:['What are your attributes?'];
	}
	reflex receiveInforms when: !empty(informs){
		loop informMsg over: informs{
			//write 'lightShow of stage '+ agent(informMsg.sender).name +' is ' + informMsg.contents[0];
			int temp <- lightShow*int(informMsg.contents[0]) + speaker*int(informMsg.contents[1]) + musicStyle*int(informMsg.contents[2]);
			write name + ': The utility of ' + agent(informMsg.sender).name + ' is ' + temp;
			if(temp > utility){
				utility <- temp;
				stage <- informMsg.sender;
			}
		}
		if (stage != nil){
			do goto target: {stage.location.x + rnd(5), stage.location.y + rnd(5)} speed: 100.0;
			write name + ': I will choose ' + stage + '. The utility is ' + utility;
			write '-----------------------------------------------------';
		}
	}
	
	aspect base {
		draw circle(1) color: #green;
	}
}

species Stage skills:[fipa]{
	int lightShow;
	int speaker;
	int musicStyle;
	
	reflex print when:(time = 0){
		write name + ': lightShow: '+ lightShow + '; speaker: '+ speaker+ '; musicStyle:'+ musicStyle;
		if (self = all_stages[stageNumber - 1]) {
			write '';
		}
	}
	reflex receiveInforms when: !empty(informs){
		loop informMsg over: informs{
			do inform message: informMsg contents: [lightShow,speaker,musicStyle] ;
		}
	}
	
	aspect base {
		draw square(3) color: #blue;
	}
}

experiment stage_experiment {
	output {
		display festival type:2d {
			species Guest aspect:base;
			species Stage aspect:base;
		}
	}
}