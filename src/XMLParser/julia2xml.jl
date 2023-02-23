
function gettypestring(_type::Type{T}) where {T}
	return string(_type.name.name)
end

function gettypeparams(_type::Type{T}) where T
	if isempty(_type.parameters)
		return nothing
	else
		return foldl((x,y)->string(x)*","*string(y),_type.parameters)
	end
end

function istypeparam(attr::XMLAttribute)
	return attr.key == "julia:type"
end

function istpname(attr::XMLAttribute)
	return attr.key == "julia:fieldname"
end

function Julia2XMLinit(obj::T,tpn::Union{Nothing,String}=nothing) where T
	content = Any[]
	tag = XMLTag(gettypestring(T))
	typeparams = gettypeparams(T)
	if typeparams != nothing
		push!(tag.attributes, XMLAttribute("julia:type",typeparams))
	end
	if tpn != nothing
		push!(tag.attributes, XMLAttribute("julia:fieldname",tpn))
	end
	return content,tag
end

function Julia2XML(obj::Vector{T},tpn::Union{Nothing,String}=nothing) where T
	content,tag = Julia2XMLinit(obj,tpn)
	for (i,o) in enumerate(obj)
		otp = typeof(o)
		if isprimitivetype(otp) || otp == DataType  || otp == String 
			push!(content, string(o))
		else
			push!(content, Julia2XML(fieldvar, string(fieldvarname)))
		end
	end
	return XMLElement(tag,content)
end

function Julia2XML(obj::T,tpn::Union{Nothing,String}=nothing) where T
	content,tag = Julia2XMLinit(obj,tpn)
	for fieldvarname in fieldnames(T)
		fieldvar = getfield(obj,fieldvarname)
		fieldtp = typeof(fieldvar)
		if isprimitivetype(fieldtp) || fieldtp == DataType  || fieldtp == String 
			push!(tag.attributes, XMLAttribute(string(fieldvarname),string(fieldvar)))
		else
			push!(content, Julia2XML(fieldvar, string(fieldvarname)))
		end
	end
	if isempty(content)
		el = XMLEmptyElement(tag)
	else
		el = XMLElement(tag,content)
	end
	return el
end

function gettype(el::XMLElement)
	_type =  el.tag.name
	tp = filter(istypeparam, el.tag.attributes)
	ltp = length(tp)
	@assert ltp <= 1
	if ltp == 1
		_type *= "{"*replace(tp[1].val,"\""=>"")*"}"
	end
	return eval(Meta.parse("Main."*_type))
end

function dict2obj(_type::Type{T}, _dict::Dict{Symbol,Any}) where {T}
	return T((_dict[x] for x in fieldnames(T))...)
end

function XML2Julia(el::XMLElement)
	_type = gettype(el)
	_dict = Dict{Symbol,Any}()
	attrs = filter(x->!istypeparam(x) && !istpname(x) ,el.tag.attributes)
	for attr in attrs
		fieldnm = Symbol(attr.key)
		fieldtp = fieldtype(_type, fieldnm)
		if fieldtp == DataType
			fieldvar = eval(Meta.parse("Main."*attr.val))
		elseif fieldtp == String
			fieldvar = attr.val
		else
			fieldvar = parse(fieldtp, attr.val)
		end
		_dict[fieldnm] = fieldvar
	end
	for con in el.content
		tpn = filter(istpname, con.tag.attributes)
		@assert length(tpn) == 1
		s = Symbol(tpn[1].val)
		_dict[s] = XML2Julia(con)
	end
	return dict2obj(_type,_dict)
end
