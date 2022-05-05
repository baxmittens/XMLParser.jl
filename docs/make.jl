import Pkg; Pkg.add("Documenter")
push!(LOAD_PATH,"../src/")
using Documenter, XMLParser
makedocs(
	sitename = "XMLParser.jl",
	modules = [XMLParser],
	pages = [
		"Home" => "index.md"
	]
	)
deploydocs(
    repo = "github.com/baxmittens/XMLParser.jl.git"
)