/**
* Name: Queens
* Based on the internal empty template. 
* Author: Juke Liu, Bite Chu
* Tags: 
*/
model Queens

global {
	int N <- 8;
	matrix board_mat <- matrix(chess_board_cell);
	int cur_to_be_posed <- 0;
	init {
		create queen number: N returns: queens;
		loop i from: 0 to: N - 1 {
			ask queens at i {
				set my_row <- i;
				set location <- board_mat[0, i].location;
				if (i > 0) {
					set pred <- queens[i - 1];
				}
				if (i < N - 1) {
					set succ <- queens[i + 1];
				}
			}
		}
	}
}

species queen skills:[fipa] {
	int my_row;
	int my_col;
	queen pred <- nil;
	queen succ <- nil;
	
	bool wait_pos <- false;
	bool positioned <- false;
	
	int next_tried_col <- 0;
	
	list<point> banned_pos <- [];
	list<int> tried_col <- [];
	
		
	reflex pos_me {
		if (cur_to_be_posed = my_row and !wait_pos and !positioned) {
			if (my_row = 0) {
				if (next_tried_col = N) {
					write "dead end! bro";
				}
				my_col <- next_tried_col;
				location <- board_mat[my_col, my_row].location;
				next_tried_col <- next_tried_col + 1;
				positioned <- true;
				cur_to_be_posed <- my_row + 1;
				banned_pos <- [];
				
				// calc my banned pos
				loop r from: 0 to: N - 1 {
					loop c from: 0 to: N - 1 {
						if (r = my_row) {
							banned_pos << {r,c};
						} else if (c = my_col) {
							banned_pos << {r,c};
						} else if (r - c = my_row - my_col) {
							banned_pos << {r,c};
						} else if (r + c = my_row + my_col) {
							banned_pos << {r,c};
						}
					}
				}
				
				write 'queen ' + my_row + ": " + "my banned_pos: " + banned_pos; 
				
				return;
			}
			
			write 'queen ' + my_row + ": " + " I asked"; 
			
			do start_conversation to: list(pred) protocol: 'no-protocol' performative: 'inform' contents: ["ask_pos", tried_col];
			wait_pos <- true;
		}
	}
	
	reflex handle_msg when: !empty(informs) {
		loop msg over: informs {
			string msg_type <- msg.contents[0];
			
			if (msg_type = "ask_pos") {
				list<int> succ_tried_cols <- msg.contents[1];
				// calc pos for succ
				int succ_col <- -1;
				write 'queen ' + my_row + ": " + " I got asked and my banned_pos " + banned_pos;
				loop c from: 0 to: N - 1 {
					if (!(succ_tried_cols contains c)) {
						if (!(banned_pos contains {my_row + 1, c})) {
							write "c: " + c;
							succ_col <- c;
							break;
						}
					}
				}
				
				if (succ_col = -1) {
					do start_conversation to: list(succ) protocol: 'no-protocol' performative: 'inform' contents: ["no_pos"];
					cur_to_be_posed <- my_row;
					positioned <- false;
					write 'queen ' + my_row + ": " + " I reply no pos";
				} else {
					do start_conversation to: list(succ) protocol: 'no-protocol' performative: 'inform' contents: ["reply_pos", succ_col, banned_pos];
					write 'queen ' + my_row + ": " + " I reply col " + succ_col + " and banned_pos " + banned_pos;
				}
			}
			
			if (msg_type = "reply_pos" and wait_pos) {
				// [1] col
				my_col <- int(msg.contents[1]);
				// [2] banned of pred
				list<point> banned_of_pred <- msg.contents[2];
				// re-calc my banned according to my pos
				banned_pos <- [];
				banned_pos <<+ banned_of_pred;
				list<point> my_banned_pos <- [];
				loop r from: 0 to: N - 1 {
					loop c from: 0 to: N - 1 {
						if (r = my_row) {
							my_banned_pos << {r,c};
						} else if (c = my_col) {
							my_banned_pos << {r,c};
						} else if (r - c = my_row - my_col) {
							my_banned_pos << {r,c};
						} else if (r + c = my_row + my_col) {
							my_banned_pos << {r,c};
						}
					}
				}
				banned_pos <<+ my_banned_pos;
				// pos I tried
				tried_col << my_col;
				// change my pos
				location <- board_mat[my_col, my_row].location;
				positioned <- true;
				wait_pos <- false;
				cur_to_be_posed <- my_row + 1;
			
				write 'queen ' + my_row + ": " + " I got my col " + my_col + " and my banned pos " + banned_pos;
				if (my_row = N - 1) {
					write 'Congrats! You solved this ' + N + "-Queen Problem!";
				}
			}
			
			if (msg_type = "no_pos" and wait_pos) {
				// reset
				write 'queen ' + my_row + ": " + " I got no pos";
				wait_pos <- false;
				// my pred must move
				tried_col <- [];
			}
		}
		
	}
	
	aspect base {
		draw circle(1) color: #pink;
	}
}

grid chess_board_cell width:N height:N {
	
}

experiment n_queens_simulation {
	output {
		display chess_board type:2d {
			grid chess_board_cell border:#black;
			species queen aspect: base;
		}
	}
	
}