function checkTagName(xmlel::AbstractXMLElement,tagname::String)
	return isequal(xmlel.tag.name,tagname)
end

"""
`getElements!(ret::Vector{XMLElement},xmlel::XMLElement,tagname::String)`

Pushes all `XMLElement`s that match the `tagname` to `ret`. 
"""	
function getElements!(ret::Vector{AbstractXMLElement},xmlel::XMLElement,tagname::String)
	for con in xmlel.content
		if typeof(con)==XMLElement
			if checkTagName(con,tagname)
				push!(ret,con)
			else
				getElements!(ret,con,tagname)
			end
		elseif typeof(con)==XMLEmptyElement
			if checkTagName(con,tagname)
				push!(ret,con)
			end
		end
	end
	return nothing
end

"""
`getElements(xmlel::XMLElement,tagname::String)`

Gets all `XMLElement`s that match the `tagname` and returns a `Vector{XMLElement}`. 
"""	
function getElements(xmlel::XMLElement,tagname::String)
	ret = Vector{AbstractXMLElement}()
	getElements!(ret,xmlel,tagname)
	return ret
end

"""
`getChildrenbyTagName!(ret::Vector{XMLElement},xmlel::XMLElement,tagname::String)`

Pushes all `XMLElement`s that are direct children of `xmlel` and match the `tagname` to `ret`. 
"""	
function getChildrenbyTagName!(ret::Vector{AbstractXMLElement},xmlel::XMLElement,tagname::String)
	for con in xmlel.content
		if typeof(con)<:AbstractXMLElement
			if checkTagName(con,tagname)
				push!(ret,con)
			end
		end
	end
	return nothing
end

"""
`getChildrenbyTagName(xmlel::XMLElement,tagname::String)`

Gets all `XMLElement`s that are direct children of `xmlel` and match the `tagname`.
Return a `Vector{XMLElement}`. 
"""	
function getChildrenbyTagName(xmlel::XMLElement,tagname::String)
	ret = Vector{AbstractXMLElement}()
	getChildrenbyTagName!(ret,xmlel,tagname)
	return ret
end

function copyElementWoContent(el::XMLElement)
	new_el = XMLElement(XMLTag(el.tag.name),Any[])
	foreach(x->push!(new_el.tag.attributes,XMLAttribute(x.key,x.val)),el.tag.attributes)
	return new_el
end



#function getAllPathesbyTag!(ret::Vector{String},xmlel::XMLElement,tagname::String,path="./")
#	for con in xmlel.content
#		if typeof(con)==XMLElement
#			_path = joinpath(path,con.tag.name)
#			for attribute in con.tag.attributes
#				_path = joinpath(_path,"@$(attribute.key)=$(attribute.val)")
#			end
#			if checkTagName(con,tagname)
#				push!(ret,_path)
#			else
#				getAllPathesbyTag!(ret,con,tagname,_path)
#			end
#		end
#	end
#	return nothing
#end
#
#function getAllPathesbyTag(xmlel::XMLElement,tagname::String,path="./")
#	ret = Vector{String}()
#	getAllPathesbyTag!(ret,xmlel,tagname,path)
#	return ret
#end

"""
`hasAttributekey(el::XMLElement,key::String))`

Return true if `el` has a attribute with keyname `key`. Returns false otherwise. 
"""	
function hasAttributekey(el::AbstractXMLElement,key::String)
	for attribute in el.tag.attributes
		if isequal(attribute.key,key)
			return true
		end
	end
	return false
end

"""
`getAttribute(el::XMLElement,key::String)`

Return attribute value if `el` has a attribute with keyname `key`. Returns emptystring otherwise. 
"""	
function getAttribute(el::AbstractXMLElement,key::String)
	for attribute in el.tag.attributes
		if isequal(attribute.key,key)
			return attribute.val
		end
	end
	return ""
end

"""
`setAttribute(el::XMLElement,key::String,val)`

Sets attribute value `val` to XML attribute `key` of `XMLElement` `el`. 
Returns an `error("Attribute not found")` if `key` is not found. Returns `nothing` otherwise.
"""	
function setAttribute(el::AbstractXMLElement,key::String,val)
	for attribute in el.tag.attributes
		if isequal(attribute.key,key)
			attribute.val = string(val)
			return nothing
		end
	end
	return error("Attribute not found")
end

Base.show(io::IO,tag::XMLTag) = print(io,"<"*tag.name*">")
function Base.show(io::IO,tag::XMLTag,depth)
	#foreach(x->print("  "),1:depth)
	print(io,"<"*tag.name*">")
end
function Base.show(io::IO,el::XMLEmptyElement)
	print(io,"<"*el.tag.name*"/>")
end
function Base.show(io::IO,el::XMLElement)
	depth = 0
	show(io,el.tag)
	for elc in el.content
		if typeof(elc) == XMLElement
			show(io,elc,depth+1)
		else
			print(io,elc)
		end
	end
	show(io,el.tag,depth)
end
function Base.show(io::IO,el::XMLElement,depth)
	show(io,el.tag,depth)
	for elc in el.content
		if typeof(elc) == XMLElement
			show(io,elc,depth+1)
		else 
			#foreach(x->print("  "),1:depth)
			print(io,elc)
		end
	end
	show(io,el.tag,depth)
end

function Base.deepcopy(attr::XMLAttribute)
	return XMLAttribute(deepcopy(attr.key),deepcopy(attr.val))
end

function Base.deepcopy(tag::XMLTag)
	return Tag(deepcopy(tag.name), map(deepcopy,tag.attributes))
end


function Base.deepcopy(el::XMLElement)
	return XMLElement(deepcopy(el.tag), map(deepcopy,el.content))
end

function Base.convert(::Type{XMLEmptyElement}, el::XMLElement)
	@assert isempty(el.content)
	return XMLEmptyElement(el.tag)
end

function Base.convert(::Type{XMLElement}, el::XMLEmptyElement)
	return XMLElement(el.tag,Any[])
end