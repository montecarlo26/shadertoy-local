
#include <fstream>
#include <string>
#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include "shader.h"



void shader::load(const char* v_shader, const char* f_shader,
	const char* g_shader) {

	const char* the_v_shader_ref;//pointless pointer
	std::string the_v_shader;

	const char* the_f_shader_ref;//pointless pointer
	std::string the_f_shader;

	const char* the_g_shader_ref;//pointless pointer
	std::string the_g_shader;

	std::ifstream a_string(v_shader);
	the_v_shader = std::string(
		std::istreambuf_iterator<char>(a_string),
		std::istreambuf_iterator<char>()
	);
	the_v_shader_ref = the_v_shader.c_str();

	std::ifstream another_string(f_shader);//redundant
	the_f_shader = std::string(
		std::istreambuf_iterator<char>(another_string),
		std::istreambuf_iterator<char>()
	);
	the_f_shader_ref = the_f_shader.c_str();

	if (g_shader != NULL) {
		std::ifstream more_string(g_shader);//redundant
		the_g_shader = std::string(
			std::istreambuf_iterator<char>(more_string),
			std::istreambuf_iterator<char>()
		);
		the_g_shader_ref = the_g_shader.c_str();
	}
	

	GLint more_v_shader = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(more_v_shader, 1, &the_v_shader_ref, NULL);
	glCompileShader(more_v_shader);

	//fragment shader
	GLint more_f_shader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(more_f_shader, 1, &the_f_shader_ref, NULL);
	glCompileShader(more_f_shader);

	//geometry shader
	GLint more_g_shader = glCreateShader(GL_GEOMETRY_SHADER);
	if (g_shader != NULL) {

		glShaderSource(more_g_shader, 1, &the_g_shader_ref, NULL);
		glCompileShader(more_g_shader);
	}


	final_shader = glCreateProgram();
	glAttachShader(final_shader, more_v_shader);
	glAttachShader(final_shader, more_f_shader);

	if (g_shader != NULL) {
		glAttachShader(final_shader, more_g_shader);
	}

	glLinkProgram(final_shader);

	glDeleteShader(more_v_shader);
	glDeleteShader(more_f_shader);
	glDeleteShader(more_g_shader);





}//end load