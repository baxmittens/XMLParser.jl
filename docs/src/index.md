# XMLParser.jl

A lightweight XML parser which is purely written in Julia.

For extensive use of XML features, consider using one of the following XML-libraries: [LightXML.jl](https://github.com/JuliaIO/LightXML.jl), [EzXML.jl](https://github.com/JuliaIO/EzXML.jl).

```@docs
XMLAttribute(key::String,val::String)
XMLTag(name::String,attributes::Vector{XMLAttribute})
XMLEmptyTag(name::String,attributes::Vector{XMLAttribute})
XMLElement(tag::AbstractXMLTag,content::Vector{Any})
```