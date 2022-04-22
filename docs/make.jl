push!(LOAD_PATH,"../src/")
using Documenter, XMLParser
makedocs(sitename="My Documentation")
deploydocs(
    repo = "github.com/baxmittens/XMLParser.jl.git",
)