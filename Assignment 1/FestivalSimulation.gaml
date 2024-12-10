/**
* Name: FestivalSimulation
* Author: Juke Liu, Bitte Chu
*/


model FestivalSimulation


global{
	int numCenter <- 1;
	int numGuest <- 10;
	int numStore <- 4;
	float wanderPace <- 5.0;
	point infoCenterLoc <- point(50,50);
	float storeDistance <- 30.0;
	
	int initHunger <- 100;
	int initThirst <- 100;
	
	init{
		create Store number: numStore returns: shops;
		
		ask [shops[0], shops[1]] {
			set trait <- "food";
		}
		
		ask [shops[2], shops[3]] {
			set trait <- "water";
		}
		
		ask shops {
			int angle <- rnd(360);
            float x_offset <- storeDistance * cos(angle);
            float y_offset <- storeDistance * sin(angle);
            location <- point(infoCenterLoc.x + x_offset + rnd(10), infoCenterLoc.y + y_offset + rnd(10));
		}

		create SecurityGuard number: 1 returns: guards;
		create InfoCenter number: numCenter returns: info;
		ask info {
			set stores <- shops;
			set guard <- guards[0];
		}
		
		create Guest number: numGuest returns: guests;
		
		ask guests {
			set infoCenter <- info[0];
		}
		
		ask last(guests) {
			set evil <- true;
		}
		
		ask [guests[0], guests[1], guests[2]] {
			set hasBrain <- true;
		}
	}
	
}

species InfoCenter{
	point location <- infoCenterLoc;
	list<Store> stores;
	SecurityGuard guard;

	aspect base{
		draw square(10) color: #pink;
        draw "InfoCenter" at: location color: #black;
	}
}

species Store{
	string trait <- nil;
    aspect base {
    	if (trait = "water") {
	        draw triangle(6) color: #blue;
	        draw "WaterStore" at: location color: #black;
    	} else {
	        draw triangle(6) color: #brown;
	        draw "FoodStore" at: location color: #black;
    	}
    }	
}

species Guest skills:[moving]{
	int hunger <- initHunger min:0;
	int thirst<- initThirst min:0;
	bool isHungry <- hunger<=0 update: hunger<=0;
	bool isThirsty <- thirst<=0 update: thirst<=0;
	int infoCenterRange <- 10;
	int storeRange <- 3;
	string toward <- nil;
	InfoCenter infoCenter;
	Store targetStore;
	bool evil <- false;
	bool hasBrain <- false;
	Store memory <- nil;
	float distanceTraveled <- 0.0;
	point prevLocation <- location;
	
	reflex idle when: toward = nil{
		if((isHungry or isThirsty) and toward != "store"){
			if (memory != nil) {
				if ((memory.trait = "water" and isThirsty) 
					or (memory.trait = "food" and isHungry)
				) {
					targetStore <- memory;
					toward <- "store";
//					write "use memory from: " + self;
					return;
				}
			}
			toward <- "center";
		} else {
			hunger <- hunger - rnd(20);
			thirst <- thirst - rnd(20);
			do wander speed: wanderPace;
		}
	}

	reflex gotoTarget when: toward!=nil{
		if (toward = "center") {
			do goto target: infoCenter.location speed: 7.0;
		} else if (toward = "store") {
			do goto target: targetStore.location speed: 7.0;
		}
	}
	
	reflex countDist {
		distanceTraveled <- distanceTraveled + (prevLocation distance_to location);
		prevLocation <- location;
		write "total distance traveled reported from: " + self + " value: " + distanceTraveled;
	}
	
	reflex centerInRange when: toward = "center" and ((location distance_to infoCenter.location) < infoCenterRange) {
		ask infoCenter {
			if (myself.evil) {
				Guest badGuy <- myself;
				// call the security guard and kill the bad guy
				ask self.guard {
					do kill(badGuy);
				}
				return;
			}
			
			string needTrait;
			if (myself.isHungry and myself.isThirsty) {
				if (rnd(1) = 1) {
					needTrait <- "food";
				} else {
					needTrait <- "water";
				}
			} else if (myself.isThirsty) {
				needTrait <- "water";
			} else if (myself.isHungry) {
				needTrait <- "food";
			}
			myself.targetStore <- (self.stores where (each.trait = needTrait)) closest_to myself;
			myself.toward <- "store";
		}
	}
	
	reflex storeInRange when: toward = "store" and ((location distance_to targetStore.location) < storeRange) {
		ask targetStore {
			if (self.trait = "water") {
				myself.thirst <- initThirst;
			} else {
				myself.hunger <- initHunger;
			}
		}
		if (hasBrain and rnd(100) < 70 and memory = nil) {
			memory <- targetStore;
		}
		toward <- nil;
		targetStore <- nil;
	}
	
	reflex forget when: memory != nil {
		if (rnd(100) < 5) {
			memory <- nil;
//			write "forget memory from " + self;
		}
	}
	
	aspect base{
		rgb peopleColor <- #green;
		string state <- "healthy";
		if (evil) {
			peopleColor <- #purple;
			state <- "evil";
		} else {
			if(isHungry and isThirsty){
				peopleColor <- #red;
				state <- "bad";
			}
			else if(isHungry){
				peopleColor <- #yellow;
				state <- "hungry";
			}
			else if(isThirsty){
				peopleColor <- #blue;
				state <- "thirsty";
			}
		}
		
		draw circle(3) at: location color:peopleColor;
		draw state at: location color: #black;
	}

}

species SecurityGuard skills: [moving] {
	Guest badToKill <- nil;
	int killRange <- 1;
	point location <- point(20,20);
	
	action kill(Guest badApple) {
		badToKill <- badApple;
	}
	
	reflex chase when: badToKill != nil {
		if (location distance_to(badToKill.location) > killRange) {
			write "Guard: I'm chasing the bad guy!";
			do goto target: badToKill.location speed: 7.0;
		} else {
			ask badToKill {
				do die;
			}
			write "the bad guy has been killed! farewell!";
			badToKill <- nil;
		}
	}
	
	reflex idle when: badToKill = nil {
		do wander speed: 7.0;
	}
	
	aspect base{
		draw circle(2) at: location color: #azure;
		draw "guard" at: location color: #black;
	}
}

experiment myExperiment type:gui {
	output {
		display myDisplay {
			species InfoCenter aspect:base;
			species Guest aspect:base;
			species Store aspect:base;
			species SecurityGuard aspect:base;
		}
	}
}