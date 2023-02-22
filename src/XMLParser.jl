module XMLParser

"""
`XMLAttribute`
	
Creates a XML attribute key-value-pair

`XMLAttribute(key::String, val::String)`
"""	
mutable struct XMLAttribute
	key::String
	val::String
end

"""
`XMLTag`

Creates a XML tag

`XMLTag(name::String, attributes::Vector{XMLAttribute})`
"""	
mutable struct XMLTag
	name::String
	attributes::Vector{XMLAttribute}
end
function XMLTag(name::String)
	return XMLTag(name,Vector{XMLAttribute}())
end


abstract type AbstractXMLElement end

"""
`XMLElement <: AbstractXMLElement`

Creates a XML element

`XMLElement(tag::XMLTag, content::Vector{Any})`
"""	
mutable struct XMLElement <: AbstractXMLElement
	tag::XMLTag
	content::Vector{Any}
	XMLElement() = begin; el = new(); el.content = Any[]; return el; end
	XMLElement(tag,content) = new(tag,content)
end

"""
`XMLEmptyElement <: AbstractXMLElement`

Creates a XML element

`XMLElement(tag::XMLTag, content::Vector{Any})`
"""	
mutable struct XMLEmptyElement <: AbstractXMLElement
	tag::XMLTag
	XMLEmptyElement() = begin; el = new(); return el; end
	XMLEmptyElement(tag) = new(tag)
end

include(joinpath(".","XMLParser","io.jl"))
include(joinpath(".","XMLParser","utils.jl"))
include(joinpath(".","XMLParser","julia2xml.jl"))

export XMLAttribute,XMLTag,XMLElement,XMLEmptyElement,IOState,getElements!,getElements,getChildrenbyTagName!,getChildrenbyTagName,copyElementWoContent,hasAttributekey,getAttribute,setAttribute,readXMLElement,writeXMLElement,writeXML,XML2Julia,Julia2XML

end #module XMLParser