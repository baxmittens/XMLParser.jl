
mutable struct IOState
	file::String
	f::IOStream
	tokens::Vector{String}
	function IOState(file)
		return new(file,open(file),String[])
	end
end

function tokenizer(line,state)
	tagopening = findall("<",line)
	tagclosing = findall(">",line)
	ntag = length(tagopening)
	if length(tagopening) == length(tagclosing)
		token = String[]
		if ntag <= 1
			push!(token,line)
			return token
		else 
			push!(token,line[tagopening[1].start:tagclosing[1].start])
			append!(token,tokenizer(line[tagclosing[1].start+1:tagopening[end].start-1],state))
			push!(token,line[tagopening[end].start:tagclosing[end].start])
		end
	else
		line *= " "*strip(readline(state.f))
		if contains(line,"<!--")
			return comment_handler(line,state)
		else
			return tokenizer(line,state)
		end
	end
end

function comment_handler(line,state)
	comment_start = findall("<!--",line)
	comment_end = findall("-->",line)
	if length(comment_end) == length(comment_start) == 0
		if !isempty(strip(line))
			append!(state.tokens,tokenizer(line,state))
		end
		return nexttoken(state)
	elseif isempty(comment_end)
		line = line *" " * strip(readline(state.f))
		return comment_handler(line,state)
	elseif length(comment_end) != length(comment_start) 
		error("Nested comments not allowed.")
	else
		tmp = line[1:comment_start[1].start-1]
		for i = 2:length(comment_start)
			tmp *= line[comment_end[i-1].stop+1:comment_start[i].start-1] 
		end
		line = tmp * line[comment_end[end].stop+1:end]
		return comment_handler(line,state)
	end
end

function nexttoken(state)
	if !isempty(state.tokens)
		return popfirst!(state.tokens)
	elseif !eof(state.f)
		line = strip(readline(state.f))
		if isempty(line)
			return nexttoken(state)
		end
		if contains(line,"<!--")
			return comment_handler(line,state)
		end
		append!(state.tokens,tokenizer(line,state))
		return popfirst!(state.tokens)
	else
		return ""
	end
end

hastokens(state) = !isempty(state.tokens) || !eof(state.f)
iselement(token) = !isempty(token) && token[1] == '<' && token[end] == '>' && token[end-1] != '/'
isemptyelement(token) = !isempty(token) && token[1] == '<' && token[end] == '>' && token[end-1] == '/'

function readXMLTag(token,_empty=false)
	token = replace(token,"<"=>"")
	token = replace(token,">"=>"")
	if _empty
		if token[end] == '/'
			token = token[1:end-1]
		else
			error()
		end
	end
	token = replace(token, "="=>" ")
	pieces = split(token," ")
	filter!(!isempty,pieces)
	name = pieces[1]
	attributes = XMLAttribute[]
	@assert mod(length(pieces)-1,2)==0 "$pieces"
	for i = 2:2:length(pieces)
		key = pieces[i]
		val = replace(pieces[i+1], "\""=>"")
		push!(attributes,XMLAttribute(key,val))
	end
	#if _empty == false
	return XMLTag(name,attributes)
	#else
	#	return XMLEmptyTag(name,attributes)
	#end
end

function readXMLInclude(file)
	state = IOState(file)
	elements = Vector{AbstractXMLElement}()
	while hastokens(state)
		element = readXMLElement(state)
		if isdefined(element,:tag)
			push!(elements,element)
		end
	end
	close(state.f)
	return elements
end

function readXMLElement(state)
	element = XMLElement()
	while hastokens(state)
		token = nexttoken(state)
		#println(token)
		if iselement(token)
			tag = readXMLTag(token)
			if !isdefined(element,:tag)
				element.tag = tag
			elseif tag.name[1]=='/' && element.tag.name == replace(tag.name,"/"=>"")
				return element
			else
				pushfirst!(state.tokens,token)
				if tag.name == "include" && tag.attributes[1].key == "file"
					file = replace(tag.attributes[1].val,"\""=>"")
					elements = readXMLInclude(joinpath(split(state.file,"/")[1:end-1]...,file)) #only linux
					append!(element.content,elements)
				else
					push!(element.content,readXMLElement(state))
				end
			end
		elseif isemptyelement(token)
			@assert isdefined(element,:tag) "Empty-tag cannot be root"
			tag = readXMLTag(token,true)
			if tag.name == "include"
				@assert length(tag.attributes) == 1 "<include> does not support multiple attributes"
				if tag.attributes[1].key == "file"
					file = replace(tag.attributes[1].val,"\""=>"")
					elements = readXMLInclude(joinpath(split(state.file,"/")[1:end-1]...,file)) #only linux
					append!(element.content,elements)
				else
					error("Undefined attribute key $(tag.attributes)")
				end
			else
				push!(element.content,XMLEmptyElement(tag))
			end
		else
			push!(element.content,token)
		end
	end
	return element
end

function writeAttribute(f::IOStream,attr,tab::Int=0)
	key,val = attr.key,attr.val 
	write(f,repeat("\t",tab))
	write(f," $key=\"$val\"\n")
end


function writeTag(f::IOStream,tag::XMLTag,tab::Int=0,_sec=false)
	write(f,repeat("\t",tab))
	if !_sec
		write(f,"<$(tag.name)")
		if !isempty(tag.attributes)
			write(f,"\n")
		end
		for attr in tag.attributes
			writeAttribute(f,attr,tab+1)
		end
		write(f,repeat("\t",tab))
		write(f,">\n")
	else
		write(f,"</$(tag.name)>\n")
	end
end

function writeEmptyTag(f::IOStream,tag::XMLTag,tab::Int=0,_sec=false)
	if !_sec
		write(f,repeat("\t",tab))
		write(f,"<$(tag.name)")
		if !isempty(tag.attributes)
			write(f,"\n")
		end
		for attr in tag.attributes
			writeAttribute(f,attr,tab+1)
		end
		write(f,repeat("\t",tab))
		write(f,"/>\n")
	end
end

"""
`writeXMLElement(f::IOStream, el::XMLElement)`

Writes a `XMLElement` to an `IOStream`.
"""
function writeXMLElement(f::IOStream, el::XMLElement,tab::Int=0)
	writeTag(f,el.tag,tab)
	for con in el.content
		if typeof(con) == XMLElement || typeof(con) == XMLEmptyElement
			writeXMLElement(f,con,tab+1)
		else
			write(f,repeat("\t",tab+1))
			write(f,con)
			write(f,"\n")
		end
	end
	el.tag.name[1] != '?' ? writeTag(f,el.tag,tab,true) : nothing
end

function writeXMLHeader(f::IOStream, el::XMLHeader)
	write(f,el.header+"\n")
end

"""
`writeXMLElement(f::IOStream, el::XMLElement)`

Writes a `XMLElement` to an `IOStream`.
"""
function writeXMLElement(f::IOStream, el::XMLEmptyElement,tab::Int=0)
	writeEmptyTag(f,el.tag,tab)
end

function Base.write(filename::String, xmlfile::XMLFile)
	f = open(filename,"w")
	writeXMLHeader(f,xmlfile.header)
	writeXMLElement(f,xmlfile.element)
	close(f)
end


function Base.read(::Type{XMLHeader}, state::IOState)
	tok = nexttoken(state)
	ophead = findall("<?",tok)
	clhead = findall("?>",tok)
	@assert length(ophead) == length(clhead) == 1 && ophead[1].start == 1 && clhead[1].stop == length(tok) "no header found"
	return XMLHeader(tok)
end

"""
`Base.read(::Type{XMLElement}, file::String)`

Reads a XML file in location `file`.
Returns a `XMLElement`.
"""
function Base.read(::Type{XMLElement}, file::String)
	state = IOState(file)
	element = readXMLElement(state)
	close(state.f)
	return element
end

"""
`Base.read(::Type{XMLElement}, state::IOState)`

Reads a XML file in location `file`.
Returns a `XMLElement`.
"""
function Base.read(::Type{XMLElement}, state::IOState)
	try
		element = readXMLElement(state)
		return element
	catch
		return nothing
	end
end

"""
`Base.read(::Type{XMLFile}, file::String)`

Reads a XML file in location `file`.
Returns a `XMLFile`.
"""
function Base.read(::Type{XMLFile}, file::String)
	state = IOState(file)
	header = read(XMLHeader,state)
	element = read(XMLElement,state)
	close(state.f)
	return XMLFile(header,element)
end

function writeXML(el::AbstractXMLElement, filename::String)
	f = open(filename,"w")
	writeXMLElement(f,el)
	close(f)
end

function Base.string(attr::XMLAttribute)
	key,val = attr.key,attr.val 
	return "$key=$val"
end

#function Base.string(tag::XMLEmptyTag, tab::Int=0)
#	str = repeat("\t",tab)*"<$(tag.name)"
#	for i in 1:length(tag.attributes)-1
#		str *= " "*string(tag.attributes[i])*","
#	end
#	str *= " "*string(tag.attributes[end])*"/>"
#	return str
#end

function Base.string(tag::XMLTag,tab::Int=0,_empty=false)
	str = repeat("\t",tab)*"<$(tag.name)"
	if length(tag.attributes) > 0
		for i in 1:length(tag.attributes)-1
			str *= " "*string(tag.attributes[i])*","
		end
		str *= " "*string(tag.attributes[end])
	end
	if _empty
		str *= "/>"
	else
		str *= ">"
	end
	return str
end

function Base.string(el::XMLElement, tab::Int=0)
	str = string(el.tag,tab)
	for con in el.content
		if typeof(con) == XMLElement || typeof(con) == XMLEmptyElement
			str *= "\n"*string(con,tab+1)
		else
			str *= "\n"*repeat("\t",tab+1)*string(con)
		end
	end
	str *= el.tag.name[1] != '?' ? "\n"*string(el.tag,tab) : ""
	return str
end

function Base.string(el::XMLEmptyElement, tab::Int=0)
	str = string(el.tag,tab,true)
	return str
end