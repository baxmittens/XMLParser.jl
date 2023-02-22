using Test
using XMLParser

struct tmp{A,B}
	a::A
	b::B
end

struct tmp2
	a::Int
	b::Int
end

struct ntmp{A,B}
	a::A
	b::B
	c::tmp{A,B}
	d::tmp
	e::tmp2
end

@testset "XMLParser.jl" begin

filename = "./testxml.xml"
#filename = "./testxml.xml"
xmlfile = read(XMLElement, filename)

@test typeof(xmlfile) == XMLElement

filename2 = "./tmp.xml"
#filename2 = "./tmp.xml"
writeXML(xmlfile, filename2)
a = read(XMLElement, filename2)

@test typeof(a) == XMLElement

obj = tmp(1.0,1)
obj2 = ntmp(1.0,1,tmp(2.0,1),tmp(1,1.0),tmp2(3,3))

el = convert(XMLElement, obj)
println(el)
println(el.tag.attributes)

el2 = convert(XMLElement, obj2)
println(el2)
println(el2.tag.attributes)

filename = "./tst.xml"
f = open(filename,"w")
writeXMLElement(f,el2)
close(f)

el3 = read(XMLElement, filename)

@test typeof(el3) == XMLElement

b = XML2Julia(el3)

@test typeof(b) == ntmp

end