#pragma once



struct global_variables {

	
	//constants
	float rad_to_deg = 180.0 / 3.14159265;
	float deg_to_rad = 3.14159265 / 180.0;


	//user input settings
	float analog_sensitivity[6] = { 0.2, 0.2, 0.2, 0.2, 0, 0.2 };//don't take in analog input unless above these thresholds (stick drift fix)
	//shared user input
	bool is_using_controller = 0;


	//gamepad user inputs
	//0 = a, 1 = b, 2 = x, 3 = y, 4 = lb, 5 = rb, 6 = select, 7 = start
	//8 = click left stick, 9 = click right stick, 10 = dpad up
	//11 = dpad right, 12 = dpad down, 13 = dpad left
	bool gamepad_inputs[14];
	int gamepad_press_states[14];//gamepad change in state from frame to frame 0, 1, -1
	//0 = x left stick, 1 = y left stick, 2 = x right stick, 3 = y right stick
	//4 = left trigger, 5 = right trigger
	float analog_inputs[6];//analog inputs after thresholds
	int analog_press_states[6] = { 0 };//analog input transition from 0 to nonzero or maybe release?

	//mouse and keyboard input
	double mouse_velocity[2];
	bool keyboard_inputs[5];//w, a, s, d, f
	int keyboard_press_states[5];//w, a, s, d, f


	//time
	float change_in_time = 0;
	float time_of_day = 12;//12 = noon (sun directly overhead), 6 = morning (sunrise in the East)
	float current_time = 0;



	//window stuff
	//int window_width = 1920;
	//int window_height = 1080;
	//int window_width = 900;
	//int window_height = 900;
	//int window_width = 853;
	//int window_height = 400;
	int window_width = 1600;
	int window_height = 900;

};//end global_variables struct









