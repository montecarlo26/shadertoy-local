
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <stdio.h>

#include "user_input.h"
#include "shader.h"

#include "global_variables.h"
extern global_variables the_global_variables;




void GLAPIENTRY MessageCallback(GLenum source,
	GLenum type,
	GLuint id,
	GLenum severity,
	GLsizei length,
	const GLchar* message,
	const void* userParam)
{

	if (severity != 0x826b) {
		fprintf(stderr, "\n\nGL CALLBACK: %s type = 0x%x, severity = 0x%x, message = %s\n",
			(type == GL_DEBUG_TYPE_ERROR ? "** GL ERROR **" : ""),
			type, severity, message);
	}

}



void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods);

static void cursor_position_callback(GLFWwindow* window, double mouse_velocity, double ypos);




void main() {




	float current_glfw_time = 0;
	float last_glfw_time = 0;
	float glfw_change_in_time = 0;
	int frames = 0;
	int seconds = 0;



	//load a shader based on user input
	shader quad_shader;
	printf("choose the desired fragment shader to run:\n");
	printf("0: clouds\n");
	printf("1: kaleidoscope\n");
	printf("2: universe\n");
	
	int selection;
	scanf_s("%d", &selection);


	






	//create the window
	glfwInit();
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	GLFWwindow* window = glfwCreateWindow(the_global_variables.window_width, the_global_variables.window_height, __FILE__, NULL, NULL);
	//GLFWwindow* window = glfwCreateWindow(the_global_variables.window_width, the_global_variables.window_height, __FILE__, glfwGetPrimaryMonitor(), NULL);
	glfwMakeContextCurrent(window);

	glfwSetKeyCallback(window, key_callback);
	glfwSetInputMode(window, GLFW_STICKY_KEYS, 1);
	glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
	glfwSetCursorPosCallback(window, cursor_position_callback);
	glfwSetCursorPos(window, 0, 0);

	gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);
	//glClearColor(sky_color[0], sky_color[1], sky_color[2], 0);
	printf("window width and height: %d, %d. Values set in global_variables.h\n\n", the_global_variables.window_width, the_global_variables.window_height);
	glViewport(0, 0, the_global_variables.window_width, the_global_variables.window_height);

	//glEnable(GL_DEPTH_TEST);	
	glFrontFace(GL_CW);
	//glEnable(GL_BLEND);//for font to render. disable to show the quads
	//glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	//glPixelStorei(GL_UNPACK_ALIGNMENT, 1);


	glEnable(GL_DEBUG_OUTPUT);
	glDebugMessageCallback(MessageCallback, 0);

	




	//create the quad
	float a_fullscreen_quad[4][2];//pp
	a_fullscreen_quad[0][0] = -1;//top left
	a_fullscreen_quad[0][1] = 1;
	a_fullscreen_quad[1][0] = 1;//top right
	a_fullscreen_quad[1][1] = 1;
	a_fullscreen_quad[2][0] = -1;//bottom left
	a_fullscreen_quad[2][1] = -1;
	a_fullscreen_quad[3][0] = 1;//bottom right
	a_fullscreen_quad[3][1] = -1;



	GLuint quad_vao;
	GLuint quad_vbo;
	GLuint quad_indices;

	glGenVertexArrays(1, &quad_vao);
	glGenBuffers(1, &quad_vbo);
	glGenBuffers(1, &quad_indices);

	glBindVertexArray(quad_vao);
	glBindBuffer(GL_ARRAY_BUFFER, quad_vbo);
	glBufferData(GL_ARRAY_BUFFER, 4 * 2 * sizeof(float), &a_fullscreen_quad[0][0], GL_STATIC_DRAW);

	// Position attribute 
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);



	

	//shaders can only be loaded after GLAD and GLFW window init
	if (selection == 0) {
		quad_shader.load("shaders/quad_v.glsl", "shaders/clouds_f.glsl", NULL);
	}
	else if (selection == 1) {
		quad_shader.load("shaders/quad_v.glsl", "shaders/kaleidoscope_f.glsl", NULL);
	}
	else if (selection == 2) {
		quad_shader.load("shaders/quad_v.glsl", "shaders/universe_f.glsl", NULL);
	}
	else {
		printf("bad input you dum dum\n");
	}

	//only 1 shader and buffer, can be called once outside the render loop
	glUseProgram(quad_shader.final_shader);//gui shader
	glBindBuffer(GL_ARRAY_BUFFER, quad_vbo);
	glBindVertexArray(quad_vao);





	//user input
	user_input the_user_input;


	glfwSwapInterval(1);

	//render loop
	while (!glfwWindowShouldClose(window)) {


		//get inputs
		glfwPollEvents();
		the_user_input.get_inputs(window);	

		if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
			glfwSetWindowShouldClose(window, GL_TRUE);
		}


		//time
		last_glfw_time = current_glfw_time;
		current_glfw_time = glfwGetTime();
		glfw_change_in_time = current_glfw_time - last_glfw_time;

		the_global_variables.current_time = current_glfw_time;
		the_global_variables.change_in_time = glfw_change_in_time;
		
		//framerate
		frames = frames + 1;
		if (the_global_variables.current_time > seconds + 1) {
			printf("fps: %d\n", frames);
			seconds = seconds + 1;
			frames = 0;
		}




		//send some variables
		glUniform1f(glGetUniformLocation(quad_shader.final_shader, "current_time"), the_global_variables.current_time);

		

		
		//render
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);//4 = # of vertices
		glfwSwapBuffers(window);

	}//end main loop


	
	glfwTerminate();
	printf("clean exit...\n");

}//end main












void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {

}

static void cursor_position_callback(GLFWwindow* window, double mouse_velocity, double ypos) {

}