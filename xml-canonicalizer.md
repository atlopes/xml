# XMLCanonicalizer
A VFP class to canonicalize an XML document, according to W3C specifications (although not fully).

The class stands on the ``XMLSerializer`` class, which is required to prepare a VFP version of the document that will be canonicalized.

The main purpose of canonical XML it to provide a basis for the creation and validation of signed documents.

Part of [VFP XML library set](README.md "VFP XML library set").

## Usage
```foxpro
*!* install the library
DO LOCFILE("xml-canonicalizer.prg")
*!* instantiate an object
m.XMLCanon = CREATEOBJECT("XMLCanonicalizer")
*!* call methods...
```

## Components

- [xml-canonicalizer.prg](xml-canonicalizer.prg "xml-canonicalizer.prg")

## Dependencies

- [XMLSerializer](xml-serializer.md "XMLSerializer")

## Methods

### Canonicalize()
```foxpro
m.XML = m.XMLCanon.Canonicalize (m.Source)
```
Reads an XML document from a string, a URL, a file, or a DOM node, and returns its canonicalized form, as a text.

Example (from W3C test cases):
```xml
<!DOCTYPE doc [<!ATTLIST e9 attr CDATA "default">]>
<doc>
   <e1   />
   <e2   ></e2>
   <e3   name = "elem3"   id="elem3"   />
   <e4   name="elem4"   id="elem4"   ></e4>
   <e5 a:attr="out" b:attr="sorted" attr2="all" attr="I'm"
      xmlns:b="http://www.ietf.org"
      xmlns:a="http://www.w3.org"
      xmlns="http://example.org"/>
   <e6 xmlns="" xmlns:a="http://www.w3.org">
      <e7 xmlns="http://www.ietf.org">
         <e8 xmlns="" xmlns:a="http://www.w3.org">
            <e9 xmlns="" xmlns:a="http://www.ietf.org"/>
         </e8>
      </e7>
   </e6>
</doc> 

```
results in a canonicalized XML document (EXC-C14N)
```xml
<doc>
   <e1></e1>
   <e2></e2>
   <e3 id="elem3" name="elem3"></e3>
   <e4 id="elem4" name="elem4"></e4>
   <e5 xmlns="http://example.org" xmlns:a="http://www.w3.org" xmlns:b="http://www.ietf.org" attr="I'm" attr2="all" b:attr="sorted" a:attr="out"></e5>
   <e6>
      <e7 xmlns="http://www.ietf.org">
         <e8 xmlns="">
            <e9 attr="default"></e9>
         </e8>
      </e7>
   </e6>
</doc>
```

### SetMethod()
```foxpro
m.XMLCanon.SetMethod(m.MethodURI)
```
Sets the canonicalization method, according to its algorithm URI.

### SetInclusiveNamespaces()
```foxpro
m.XMLCanon.SetInclusiveNamespaces(m.PrefixList)
```
Sets the list of namespaces that will be canonicalized inclusively during an exclusive canonicalization.

### SetOption()
```foxpro
m.XMLCanon.SetOption(m.Option)
```
Sets (by activating) canonicalization options.

Options
- "Default" (reset all options)
- "Exclusive" (defaults to true)
- "Inclusive" (defaults do false)
- "Comments" (defaults to false)
- "No-Comments" (defaults to true)
- "Trim" (defaults to false)
