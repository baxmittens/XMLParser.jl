# XMLParser.jl
A lightweight XML parser which is purely written in Julia.

For extensive use of XML features, consider using one of the following XML-libraries: [LightXML.jl](https://github.com/JuliaIO/LightXML.jl), [EzXML.jl](https://github.com/JuliaIO/EzXML.jl).

```julia
import Pkg
Pkg.add("XMLParser")
```

### Unsupported features

* It is not allowed to use one of the following characters in XML content: `<`,`>`

There are probably many more XML features that are not supported at the moment.