using Gtk4
using ModernGL

# mostly copied from ModernGL.jl: see https://github.com/JuliaGL/ModernGL.jl/blob/master/test/runtests.jl

function glGenOne(glGenFn)
	id = GLuint[0]
	glGenFn(1, id)
	glCheckError("generating a buffer, array, or texture")
	id[]
end
glGenBuffer() = glGenOne(glGenBuffers)
glGenVertexArray() = glGenOne(glGenVertexArrays)
glGenTexture() = glGenOne(glGenTextures)
function getInfoLog(obj::GLuint)
	# Return the info log for obj, whether it be a shader or a program.
	isShader = glIsShader(obj)
	getiv = isShader == GL_TRUE ? glGetShaderiv : glGetProgramiv
	getInfo = isShader == GL_TRUE ? glGetShaderInfoLog : glGetProgramInfoLog
	# Get the maximum possible length for the descriptive error message
	len = GLint[0]
	getiv(obj, GL_INFO_LOG_LENGTH, len)
	maxlength = len[]
	# TODO: Create a macro that turns the following into the above:
	# maxlength = @glPointer getiv(obj, GL_INFO_LOG_LENGTH, GLint)
	# Return the text of the message if there is any
	if maxlength > 0
		buffer = zeros(GLchar, maxlength)
		sizei = GLsizei[0]
		getInfo(obj, maxlength, sizei, buffer)
		len = sizei[]
		unsafe_string(pointer(buffer), len)
	else
		""
	end
end
function validateShader(shader)
	success = GLint[0]
	glGetShaderiv(shader, GL_COMPILE_STATUS, success)
	success[] == GL_TRUE
end
function glErrorMessage()
# Return a string representing the current OpenGL error flag, or the empty string if there's no error.
	err = glGetError()
	err == GL_NO_ERROR ? "" :
	err == GL_INVALID_ENUM ? "GL_INVALID_ENUM: An unacceptable value is specified for an enumerated argument. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_INVALID_VALUE ? "GL_INVALID_VALUE: A numeric argument is out of range. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_INVALID_OPERATION ? "GL_INVALID_OPERATION: The specified operation is not allowed in the current state. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_INVALID_FRAMEBUFFER_OPERATION ? "GL_INVALID_FRAMEBUFFER_OPERATION: The framebuffer object is not complete. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_OUT_OF_MEMORY ? "GL_OUT_OF_MEMORY: There is not enough memory left to execute the command. The state of the GL is undefined, except for the state of the error flags, after this error is recorded." : "Unknown OpenGL error with error code $err."
end
function glCheckError(actionName="")
	message = glErrorMessage()
	if length(message) > 0
		if length(actionName) > 0
		error("Error ", actionName, ": ", message)
		else
		error("Error: ", message)
		end
	end
end
function createShader(source, typ)
# Create the shader
	shader = glCreateShader(typ)::GLuint
	if shader == 0
		error("Error creating shader: ", glErrorMessage())
	end
	# Compile the shader
	glShaderSource(shader, 1, convert(Ptr{UInt8}, pointer([convert(Ptr{GLchar}, pointer(source))])), C_NULL)
	glCompileShader(shader)
	# Check for errors
	!validateShader(shader) && error("Shader creation error: ", getInfoLog(shader))
	shader
end
function createShaderProgram(f, vertexShader, fragmentShader)
	# Create, link then return a shader program for the given shaders.
	# Create the shader program
	prog = glCreateProgram()
	if prog == 0
		error("Error creating shader program: ", glErrorMessage())
	end
	# Attach the vertex shader
	glAttachShader(prog, vertexShader)
	glCheckError("attaching vertex shader")
	# Attach the fragment shader
	glAttachShader(prog, fragmentShader)
	glCheckError("attaching fragment shader")
	f(prog)
	# Finally, link the program and check for errors.
	glLinkProgram(prog)
	status = GLint[0]
	glGetProgramiv(prog, GL_LINK_STATUS, status)
	if status[] == GL_FALSE then
		glDeleteProgram(prog)
		error("Error linking shader: ", glGetInfoLog(prog))
	end
	prog
end
createShaderProgram(vertexShader, fragmentShader) = createShaderProgram(prog->0, vertexShader, fragmentShader)
global GLSL_VERSION = ""
function createcontextinfo()
	global GLSL_VERSION
	verstring=glGetString(GL_SHADING_LANGUAGE_VERSION)
	verstring == C_NULL && error("Can't set up GL context")
	glsl = split(unsafe_string(verstring), ['.', ' '])
	if length(glsl) >= 2
		glsl = VersionNumber(parse(Int, glsl[1]), parse(Int, glsl[2]))
		GLSL_VERSION = string(glsl.major) * rpad(string(glsl.minor),2,"0")
	else
		error("Unexpected version number string. Please report this bug! GLSL version string: $(glsl)")
	end

	glv = split(unsafe_string(glGetString(GL_VERSION)), ['.', ' '])
	if length(glv) >= 2
		glv = VersionNumber(parse(Int, glv[1]), parse(Int, glv[2]))
	else
		error("Unexpected version number string. Please report this bug! OpenGL version string: $(glv)")
	end
	dict = Dict{Symbol,Any}(
	    :glsl_version   => glsl,
	    :gl_version     => glv,
	    :gl_vendor	    => unsafe_string(glGetString(GL_VENDOR)),
	    :gl_renderer	=> unsafe_string(glGetString(GL_RENDERER)),
	    #:gl_extensions => split(unsafe_string(glGetString(GL_EXTENSIONS))),
	)
end
function get_glsl_version_string()
	if isempty(GLSL_VERSION)
		error("couldn't get GLSL version, GLUTils not initialized, or context not created?")
	end
	return "#version $(GLSL_VERSION)\n"
end

# The data for our triangle
const data = GLfloat[
	0.0, 0.5,
	0.5, -0.5,
	-0.5,-0.5
]

mutable struct State
	i::Int64
	program
end

state = State(0,nothing)

function on_realized(a)
	Gtk4.G_.make_current(a)
	createcontextinfo()
	e = Gtk4.G_.get_error(a)
	if e != C_NULL
		@async println("Error!")
		return
	end

	# Generate a vertex array and array buffer for our data
	vao = glGenVertexArray()
	glBindVertexArray(vao)
	vbo = glGenBuffer()
	glBindBuffer(GL_ARRAY_BUFFER, vbo)
	glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW)

	# Create and initialize shaders
	vsh = """
	$(get_glsl_version_string())
	in vec2 position;
	void main() {
	    gl_Position = vec4(position, 0.0, 1.0);
	}
	"""
	fsh = """
	$(get_glsl_version_string())
	out vec4 outColor;
	void main() {
	    outColor = vec4(1.0, 1.0, 1.0, 1.0);
	}
	"""
	vertexShader = createShader(vsh, GL_VERTEX_SHADER)
	fragmentShader = createShader(fsh, GL_FRAGMENT_SHADER)
	state.program = createShaderProgram(vertexShader, fragmentShader)
	@async println(state.program)
end

function on_render(a, c, user_data)
	glUseProgram(state.program)
	positionAttribute = glGetAttribLocation(state.program, "position");
	glEnableVertexAttribArray(positionAttribute)
	glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, false, 0, C_NULL)

	# Pulse the background blue
	glClearColor(0.0, 0.0, 0.5 * (1 + sin(state.i * 0.02)), 1.0)
	glClear(GL_COLOR_BUFFER_BIT)
	# Draw our triangle
	glDrawArrays(GL_TRIANGLES, 0, 3)

	return Cint(0)
end

wh = 600
w = GtkWindow("GL example", wh, wh)
glarea = GtkGLArea()

signal_connect(on_realized, glarea, "realize")
signal_connect(on_render, glarea, "render", Cint, (Ptr{Gtk4.Gdk4.GdkGLContext},))

w[]=glarea

for i=1:500
	state.i=i
	queue_render(glarea)
	sleep(0.01)
end
