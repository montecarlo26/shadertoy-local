
#include <math.h>//fabs

#include "user_input.h"



//is a value + or -?
template <class T>
inline int
sgn(T v) {
	return (v > T(0)) - (v < T(0));
}


void user_input::get_inputs(GLFWwindow* window) {

	//get mouse input
	glfwGetCursorPos(window, &the_global_variables.mouse_velocity[0], &the_global_variables.mouse_velocity[1]);
	glfwSetCursorPos(window, 0, 0);


	//don't try getting controller inputs if a controller isn't connected
	if (glfwJoystickPresent(GLFW_JOYSTICK_1)) {



		//get gamepad inputs
		int gamepad_analog_count;//x axis left stick, y axis left stick, triggers,...
		const float* gamepad_axes = glfwGetJoystickAxes(GLFW_JOYSTICK_1, &gamepad_analog_count);
		//0 = x left stick, 1 = y left stick, 2 = x right stick, 3 = y right stick
		//4 = left trigger, 5 = right trigger
		//printf("%f\n", gamepad_axes[0]);
		float input_total = 0;
		for (int i = 0; i < 4; i++) {
			input_total = input_total + fabs(gamepad_axes[i]);
		}

		int gamepad_button_count;
		const unsigned char* gamepad_buttons = glfwGetJoystickButtons(GLFW_JOYSTICK_1, &gamepad_button_count);
		//0 = a, 1 = b, 2 = x, 3 = y, 4 = lb, 5 = rb, 6 = select, 7 = start
		//8 = click left stick, 9 = click right stick, 10 = dpad up
		//11 = dpad right, 12 = dpad down, 13 = dpad left
		//printf("%d\n", gamepad_buttons[0]);
		for (int i = 0; i < 14; i++) {
			input_total = input_total + gamepad_buttons[i];
			the_global_variables.gamepad_inputs[i] = gamepad_buttons[i];
			the_global_variables.gamepad_press_states[i] = gamepad_buttons[i] - gamepad_previous_press_states[i];
			gamepad_previous_press_states[i] = gamepad_buttons[i];
		}

	


		//if the total number of controller inputs is greater than 0.5,
		//then the user is probably trying to use the controller
		if (input_total > 0.5) {
			the_global_variables.is_using_controller = 1;

		}
		else if (the_global_variables.mouse_velocity[0] != 0 || the_global_variables.mouse_velocity[1] != 0) {
			the_global_variables.is_using_controller = 0;
		}

	
	






		//adjust the analog inputs with the thresholds
		if (the_global_variables.is_using_controller == 1) {

			if (fabs(gamepad_axes[0]) < the_global_variables.analog_sensitivity[0]) {//left stick sensitivity
				the_global_variables.analog_inputs[0] = 0;
			}
			else {
				the_global_variables.analog_inputs[0] = (gamepad_axes[0] - sgn(gamepad_axes[0]) * the_global_variables.analog_sensitivity[0]) / (1 - the_global_variables.analog_sensitivity[0]);

			}

			if (fabs(gamepad_axes[1]) < the_global_variables.analog_sensitivity[1]) {
				the_global_variables.analog_inputs[1] = 0;
			}
			else {
				the_global_variables.analog_inputs[1] = (gamepad_axes[1] - sgn(gamepad_axes[1]) * the_global_variables.analog_sensitivity[1]) / (1 - the_global_variables.analog_sensitivity[1]);
			}

			if (fabs(gamepad_axes[2]) < the_global_variables.analog_sensitivity[2]) {//right stick sensitivity
				the_global_variables.analog_inputs[2] = 0;
			}
			else {
				the_global_variables.analog_inputs[2] = (gamepad_axes[2] - sgn(gamepad_axes[2]) * the_global_variables.analog_sensitivity[2]) / (1 - the_global_variables.analog_sensitivity[2]);
			}

			if (fabs(gamepad_axes[3]) < the_global_variables.analog_sensitivity[3]) {
				the_global_variables.analog_inputs[3] = 0;
			}
			else {
				the_global_variables.analog_inputs[3] = (gamepad_axes[3] - sgn(gamepad_axes[3]) * the_global_variables.analog_sensitivity[3]) / (1 - the_global_variables.analog_sensitivity[3]);
			}

			//left trigger -1 to 1, change to  0 to 1, assume no threshold
			the_global_variables.analog_inputs[4] = 0.5 * gamepad_axes[4] + 0.5;
			/*
			if (gamepad_axes[4] > -1 + the_global_variables.analog_sensitivity[4]) {
				the_global_variables.analog_inputs[4] = gamepad_axes[4] + (1 - the_global_variables.analog_sensitivity[4]) / (2 + (1 - the_global_variables.analog_sensitivity[4]));
			}
			else {
				the_global_variables.analog_inputs[4] = 0;
			}
			*/

			//right trigger -1 to 1, change to  0 to 1, assume no threshold
			the_global_variables.analog_inputs[5] = 0.5 * gamepad_axes[5] + 0.5;
			/*
			if (gamepad_axes[5] > -1 + the_global_variables.analog_sensitivity[5]) {
				the_global_variables.analog_inputs[5] = gamepad_axes[5] + (1 - the_global_variables.analog_sensitivity[5]) / (2 + (1 - the_global_variables.analog_sensitivity[5]));
			}
			else {
				the_global_variables.analog_inputs[5] = 0;
			}
			*/


			//was an analog direction just pressed?
			//negative means
			for (int i = 0; i < 6; i++) {

				if (the_global_variables.analog_inputs[i] != 0 && analog_previous_press_states[i] == 0) {
					the_global_variables.analog_press_states[i] = 1;
				}
				else {
					the_global_variables.analog_press_states[i] = 0;
				}

				analog_previous_press_states[i] = the_global_variables.analog_inputs[i];

			}








		}//end if using controller for analog



	}//end if controller is connected


	if (the_global_variables.is_using_controller == 0) {
		
		the_global_variables.keyboard_inputs[0] = glfwGetKey(window, GLFW_KEY_W);
		the_global_variables.keyboard_inputs[1] = glfwGetKey(window, GLFW_KEY_A);
		the_global_variables.keyboard_inputs[2] = glfwGetKey(window, GLFW_KEY_S);
		the_global_variables.keyboard_inputs[3] = glfwGetKey(window, GLFW_KEY_D);

		the_global_variables.keyboard_inputs[4] = glfwGetKey(window, GLFW_KEY_F);


		for (int i = 0; i < 5; i++) {

			the_global_variables.keyboard_press_states[i] = the_global_variables.keyboard_inputs[i] - keyboard_previous_press_states[i];

			keyboard_previous_press_states[i] = the_global_variables.keyboard_inputs[i];
		}

	}//end if using keyboard





}//end get input




