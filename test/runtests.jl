using Test
using XMLParser

#filename = "./test/testxml.xml"
filename = "./testxml.xml"
xmlfile = read(XMLElement, filename)

#filename2 = "./test/tmp.xml"
filename2 = "./tmp.xml"
writeXML(xmlfile, filename2)
read(XMLElement, filename2)
