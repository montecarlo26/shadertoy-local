#pragma once

#include <GLFW/glfw3.h>
#include <stdio.h>//printf

#include "global_variables.h"
extern struct  global_variables the_global_variables;


struct user_input {


	int gamepad_previous_press_states[14] = { 0 };
	float analog_previous_press_states[5] = { 0 };

	int keyboard_previous_press_states[14] = { 0 };

	void get_inputs(GLFWwindow* window);





};//end user input struct

