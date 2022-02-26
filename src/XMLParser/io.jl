
mutable struct IOState3 #Top Level Hack
	file::String
	f::IOStream
	tokens::Vector{String}
	function IOState3(file)
		return new(file,open(file),String[])
	end
end

function tokenizer(line)
	tagopening = findall("<",line)
	tagclosing = findall(">",line)
	ntag = length(tagopening)
	@assert length(tagopening) == length(tagclosing)
	token = String[]
	if ntag <= 1
		push!(token,line)
		return token
	else 
		push!(token,line[tagopening[1].start:tagclosing[1].start])
		append!(token,tokenizer(line[tagclosing[1].start+1:tagopening[end].start-1]))
		push!(token,line[tagopening[end].start:tagclosing[end].start])
	end
end

function comment_handler(line,state)
	comment_start = findall("<!--",line)
	comment_end = findall("-->",line)
	if length(comment_end) == length(comment_start) == 0
		if !isempty(strip(line))
			append!(state.tokens,tokenizer(line))
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
		append!(state.tokens,tokenizer(line))
		return popfirst!(state.tokens)
	else
		return ""
	end
end

hastokens(state) = !isempty(state.tokens) || !eof(state.f)
istag(token) = !isempty(token) && token[1] == '<' && token[end] == '>' && token[end-1] != '/'
isemptytag(token) = !isempty(token) && token[1] == '<' && token[end] == '>' && token[end-1] == '/'

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
	@assert mod(length(pieces)-1,2)==0
	for i = 2:2:length(pieces)
		key = pieces[i]
		val = pieces[i+1]
		push!(attributes,XMLAttribute(key,val))
	end
	if _empty == false
		return XMLTag(name,attributes)
	else
		return XMLEmptyTag(name,attributes)
	end
end

function readXMLInclude(file)
	state = IOState3(file)
	elements = Vector{XMLElement}()
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
		if istag(token)
			tag = readXMLTag(token)
			if !isdefined(element,:tag)
				element.tag = tag
			elseif element.tag.name == replace(tag.name,"/"=>"")
				return element
			else
				pushfirst!(state.tokens,token)
				push!(element.content,readXMLElement(state))
			end
		elseif isemptytag(token)
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
				push!(element.content,XMLElement(tag,Any[]))
			end
		else
			push!(element.content,token)
		end
	end
	return element
end

function writeAttribute(f,attr)
	key,val = attr.key,attr.val 
	write(f," $key=$val")
end


function writeTag(f,tag::XMLTag,_sec=false)
	if !_sec
		write(f,"<$(tag.name)")
		for attr in tag.attributes
			writeAttribute(f,attr)
		end
		write(f,">\n")
	else
		write(f,"</$(tag.name)>\n")
	end
end

function writeTag(f,tag::XMLEmptyTag,_sec=false)
	if !_sec
		write(f,"<$(tag.name)")
		for attr in tag.attributes
			writeAttribute(f,attr)
		end
		write(f,"/>\n")
	end
end

function writeXMLElement(f,el::XMLElement)
	writeTag(f,el.tag)
	for con in el.content
		if typeof(con) == XMLElement
			writeXMLElement(f,con)
		else
			write(f,con)
			write(f,"\n")
		end
	end
	el.tag.name[1] != '?' ? writeTag(f,el.tag,true) : nothing
end

function Base.read(::Type{XMLElement}, file)
	state = IOState3(file)
	element = readXMLElement(state)
	close(state.f)
	return element
end