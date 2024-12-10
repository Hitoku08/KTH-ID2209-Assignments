/**
* Name: AuctionSimulationBasic
* Based on the internal empty template. 
* Author: Bite Chu, Juke Liu
* Tags: 
*/


model AuctionSimulation

/* Insert your model definition here */
global{
	int reduce_interval <- 10;
	
	int num_auctioneer <- 4;
	int num_bidder <- 5;
	
	init{
		create Auctioneer number:num_auctioneer returns: aucs;
		ask aucs[0] {
			set auction_type <- 'dutch';
			set genre <- 'clothes';
		}
		ask aucs[1] {
			set auction_type <- 'dutch';
			set genre <- 'cd';
		}
		ask aucs[2] {
			set auction_type <- 'sealed';
			set genre <- 'clothes';
		}
		ask aucs[3] {
			set auction_type <- 'vicrey';
			set genre <- 'cd';
		}
		
		create Bidder number:num_bidder returns: clothes_bidders;
		ask clothes_bidders {
			set interest <- "clothes";
		}
		create Bidder number:num_bidder returns: cd_bidders;
		ask cd_bidders {
			set interest <- "cd";
		}
	}
}

species Auctioneer skills:[fipa]{
	int current_price <-rnd(210,230);
	string state <- 'init';
	string genre;
	string auction_type;
	string winner <- nil;
	
	reflex init_auction when: state = 'init' {
		if(auction_type = 'dutch'){
			state <- 'in_progress';
			write '(Time ' + time + ', ' + auction_type + ', ' + genre +') OK! Auction starts at price '+ current_price +' dollars! Anyone who want to buy?';
			write '-----------------------------------------------------';
			do start_conversation to: list(Bidder) protocol: 'fipa-contract-net' performative: 'cfp' contents:[genre,auction_type,current_price];
		}
		if(auction_type = 'sealed'){
			state <- 'in_progress';
			write '(Time ' + time + ', ' + auction_type + ', ' + genre +') OK! Auction starts! Anyone who want to buy?';
			write '-----------------------------------------------------';
			do start_conversation to: list(Bidder) protocol: 'fipa-contract-net' performative: 'cfp' contents:[genre,auction_type];
		}
		if(auction_type = 'vicrey'){
			state <- 'in_progress';
			write '(Time ' + time + ', ' + auction_type + ', ' + genre +') OK! Auction starts! Anyone who want to buy?';
			write '-----------------------------------------------------';
			do start_conversation to: list(Bidder) protocol: 'fipa-contract-net' performative: 'cfp' contents:[genre,auction_type];
		}
	}
	
	//Reduce price when there is no one that would like to buy
	reflex reduce_price when:empty(proposes) and time > 0 and state = 'in_progress'{
		if(auction_type = 'dutch'){
			loop refuse_msg over: refuses{
				string dummy <- refuse_msg.contents;
			}
			current_price <- current_price - reduce_interval;
			write '(Time ' + time + ', ' + auction_type + ', ' + genre +') The price is reduced to '+ current_price +' dollars! Anyone?';
			write '-----------------------------------------------------';
			do start_conversation to: list(Bidder) protocol: 'fipa-contract-net' performative: 'cfp' contents:[genre,auction_type,current_price];
		}
	}
	
	//If there is a bidder who proposes to buy, end the auction
	reflex receive_bids when:!empty(proposes){
		if(auction_type = 'dutch'){
			loop propose_msg over: proposes{
				if (winner = nil){
					winner <- agent(propose_msg.sender).name;
					write '(Time ' + time + ', ' + auction_type + ', ' + genre +') Fine! The winner is ' + winner + '! The final price is ' + current_price + ' dollars!';
					write '-----------------------------------------------------';
					state <- 'end';
					string dummy <- propose_msg.contents;
				}
			}
		}
		if(auction_type = 'sealed') {
			int largest_bid <- 0;
			string cur_winner <- nil;
			loop propose_msg over: proposes{
				int cur_bid <- int(propose_msg.contents[0]);
				if (cur_bid > largest_bid) {
					largest_bid <- cur_bid;
					cur_winner <- agent(propose_msg.sender).name;
				}
			}
			winner <- cur_winner;
			write '(Time ' + time + ', ' + auction_type + ', ' + genre +') Fine! The winner is ' + winner + '! The final price is ' + largest_bid + ' dollars!';
			write '-----------------------------------------------------';
			state <- 'end';
		}
		if(auction_type = 'vicrey') {
			int largest_bid <- 0;
			int second_largest_bid <- 0;
			string cur_winner <- nil;
			loop propose_msg over: proposes{
				int cur_bid <- int(propose_msg.contents[0]);
				if (cur_bid > largest_bid) {
					second_largest_bid <- largest_bid;
					largest_bid <- cur_bid;
					cur_winner <- agent(propose_msg.sender).name;
				} else if (cur_bid < largest_bid and cur_bid > second_largest_bid) {
					second_largest_bid <- cur_bid;
				}
			}
			winner <- cur_winner;
			write '(Time ' + time + ', ' + auction_type + ', ' + genre +') Fine! The winner is ' + winner + '! The final price (second largest) is ' + second_largest_bid + ' dollars!';
			write '-----------------------------------------------------';
			state <- 'end';
		}
	}
}

species Bidder skills:[fipa]{
	int expected_price <- rnd(80,180);
	string interest;
	
	reflex receive_price when:!empty(cfps){
		loop cfp_msg over: cfps{
			string genre <- cfp_msg.contents[0];
			string type <- cfp_msg.contents[1];
			
			if (genre != interest) {
				write name + ': ' + '(' + genre + ", " + type + ') ' + 'I am not interested, so I will not particiapate in this auction';
			} else {
				if (type = 'dutch'){
					int current_price <- int(cfp_msg.contents[2]);
					if(current_price <= expected_price){
						do propose message: cfp_msg contents:["Proposal from " + name];
						write name + ': ' + '(' + genre + ", " + type + ') ' + 'I will buy it!';
					}else{
						do refuse message: cfp_msg contents:["Too expensive " + name];
						write name + ': ' + '(' + genre + ", " + type + ') ' + 'I do not buy.';
					}
				}
				if (type = 'sealed' or type = 'vicrey') {
					do propose message: cfp_msg contents:[expected_price];
					write name + ': ' + '(' + genre + ", " + type + ') ' + 'I will buy it with ' + expected_price + ' dollars';
				}
			}
			string dummy <- cfp_msg.contents;
		}
		write '';
	}
}

experiment my_experiment{}