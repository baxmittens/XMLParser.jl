module XMLParser

mutable struct XMLAttribute
	key::String
	val::String
end

abstract type AbstractXMLTag end
mutable struct XMLTag <: AbstractXMLTag
	name::String
	attributes::Vector{XMLAttribute}
end
function XMLTag(name::String)
	return XMLTag(name,Vector{XMLAttribute}())
end
"""
    XMLEmptyTag(name,attributes)
"""	
mutable struct XMLEmptyTag <: AbstractXMLTag
	name::String
	attributes::Vector{XMLAttribute}
end

"""
    XMLElement(tag,content)
"""	
mutable struct XMLElement
	tag::AbstractXMLTag
	content::Vector{Any}
	XMLElement() = begin; el = new(); el.content = Any[]; return el; end
	XMLElement(tag,content) = new(tag,content)
end

include(joinpath(".","XMLParser","io.jl"))
include(joinpath(".","XMLParser","utils.jl"))

export XMLAttribute,XMLTag,XMLEmptyTag,XMLElement,IOState,getElements!,getElements,getChildrenbyTagName!,getChildrenbyTagName,copyElementWoContent,hasAttributekey,getAttribute,setAttribute,readXMLElement,writeXMLElement

end #module XMLParser