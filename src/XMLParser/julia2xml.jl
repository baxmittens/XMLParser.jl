
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
	return attr.key == "julia:tp"
end

function istpname(attr::XMLAttribute)
	return attr.key == "julia:tpn"
end

function Julia2XML(obj::T,tpn::Union{Nothing,String}=nothing) where T
	content = Any[]
	tag = XMLTag(gettypestring(T))
	typeparams = gettypeparams(T)
	if typeparams != nothing
		push!(tag.attributes, XMLAttribute("julia:tp",typeparams))
	end
	if tpn != nothing
		push!(tag.attributes, XMLAttribute("julia:tpn",tpn))
	end
	for (fieldvar,fieldtp) in zip(fieldnames(T),fieldtypes(T))
		if isprimitivetype(fieldtp)
			push!(tag.attributes, XMLAttribute(string(fieldvar),string(getfield(obj,fieldvar))))
		else
			push!(content, Julia2XML(getfield(obj,fieldvar), string(fieldvar)))
		end
	end
	el = XMLElement(tag,content)
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
		fieldvar = parse(fieldtp, replace(attr.val,"\""=>""))
		_dict[fieldnm] = fieldvar
	end
	for con in el.content
		tpn = filter(istpname, con.tag.attributes)
		@assert length(tpn) == 1
		s = Symbol(replace(tpn[1].val,"\""=>""))
		_dict[s] = XML2Julia(con)
	end
	return dict2obj(_type,_dict)
end
