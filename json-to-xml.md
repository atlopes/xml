# JsonToXML
A simple JSON to XML converter.

Part of [VFP XML library set](README.md "VFP XML library set").

## Usage

```foxpro
m.jx = createobject("JsonToXML")
m.xml = m.jx.convert(m.jsonString, "root")
if isnull(m.xml)
  ? m.jx.ParseError, '@', m.jx.ParsePosition
else
  ? m.xml.xml
endif
```

## Status

- In development.

## Dependencies

- [Namer / Name Syntax Checker](https://github.com/atlopes/names "Namer") 
