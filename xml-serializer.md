# XMLSerializer
A VFP class to serialize an XML document into a VFP object, back and forth. It may also be used to serialize an arbitrary VFP object (or an object fragment) into an XML document.

A serialized VFP object is based in the Empty class. Besides being filled with the original XML source data, a group of XML metadata properties is addedto the VFP object . These properties will allow to re-serialize the data into XML without loss.

Data elements can be accessed like a regular VFP object, by following its hierarchy, and the stored values are always of type Character.

Part of [VFP XML library set](README.md "VFP XML library set").

## Usage
```foxpro
*!* install the library
DO LOCFILE("xml-serializer.prg")
*!* include header file
#INCLUDE "xml-serializer.h"
*!* instantiate an object
m.XMLSerializer = CREATEOBJECT("XMLSerializer")
*!* call methods...
```

## Components

- [xml-serializer.prg](xml-serializer.prg "xml-serializer.prg")
- [xml-serializer.h](xml-serializer.h "xml-serializer.h")
- [xml-serializer-class.h](xml-serializer-class.h "xml-serializer-class.h")


## Dependencies
`XMLSerializer` depends on [Namer](https://bitbucket.org/atlopes/names "Namer"), a VFP class to translate names of a particular domain to another (in this case, from XML's domain to VFP's, and vice-versa).

## Methods

### XMLtoVFP()
```foxpro
m.VFP = m.XMLSerializer.XMLtoVFP (m.Source)
```
Retrieves an XML document from a string, a URL, a file, or a DOM node, and returns a VFP Empty-based object matching the XML tree.

`xml*` members of the returned object control different properties of the XML nodes: the original name, the attributes, the namespace, the original position, and others.

Nodes and attributes that repeat their names - either because they occur more than once under the same node in the source data, either because their equivalent VFP name is repeated, are treated  as arrays.

Note:

------------
This method started as a rewriting of Marco Plaza's [nfxmlread()](https://github.com/VFPX/nfXML "nfxmlread()"). The main intention for the rewrite was to target for round-tripability (that is, to be able to functionally recreate an XML document from a serialized VFP object). Although during the process many other features were included, the basic architecture of the method still inherits from Marco's original concept.

------------

Example of the serialization of an XML document:
```xml
<?xml version="1.0"?>
<doc>
  <child order="a">Some value</child>
  <child order="b">Other value</child>
</doc>
```
results in a VFP object with the following hierarchy
```
doc   && <doc>
--child[1]   && first <doc/child>
----xmlattributes   && attributes of <doc/child>
------order  && <doc/child/@order>
--------xmlname   && xml properties of <doc/child/@order>
--------xmltext
--------xmlns
--------xmlprefixes
--------xmlposition
--------xmlcount
--------xmlqname
--------xmlsource
----xmlname   && xml properties of <doc/child>
----xmltext
----xmlns
----xmlprefixes
----xmlposition
----xmlcount
----xmlqname
----xmlsource
--child[2]   && second <doc/child>
```
The object hierarchy can be navigated like a regular VFP object (for instance, `? m.VFP.doc.child[1].xmlname`).

### VFPtoXML()
```foxpro
m.XML = m.XMLSerializer.VFPtoXML (m.VFPObject[, m.Root])
```
Creates an XML DOM object from a VFP object (either serialized from an XML document, or originally a VFP object).

If `xml* ` members are present in the VFP object, they are used to (re)construct the XML DOM.

The name of a root may be optionally passed as the second argument, to encapsulate a rootless VFP object, or to add a new level to other root.

### SetOption() and GetOption()
```foxpro
m.XMLSerializer.SetOption(m.Option, m.Setting)
m.Setting = m.XMLSerializer.GetOption(m.Option)
```
Sets or gets serialization options (to and from XML).

Available options (all of Logical type):
- `XMLSERIAL_WHITESPACE`:
-- preserve whitespace
- `XMLSERIAL_PROCESSINGINSTRUCTIONS`:
-- process processing instructions (`<?pi ?>`)
- `XMLSERIAL_COMMENTS`:
-- process comments (`<!-- -->`)
- `XMLSERIAL_DTD`:
-- process Document Type Definitions (`<!DOCTYPE >`) 

### GetSimpleCopy()
```foxpro
m.VFP = m.XMLSerializer.GetSimpleCopy(m.VFPObject[, m.Options])
```

Produces a simplified copy of the serialized object, from which most of the `xml*` information is stripped out.

The copy may be configured to produce added `_value_` properties for mixed elements (that is, elements that contains text and a subtree of elements at the same time), to hold text values in simplified `xmltext` properties, or to follow the schema of nfxml serializations.

For instance, as for the above serialization example:

a) simplified result (Options = 1)
```
doc
--child[1]
----xmlattributes
------order  && contains "a"
----xmltext   && contains "Some value"
--child[2] ...
```

### GetText()
```foxpro
m.Text = m.XMLSerializer.GetText (m.VFPObject.property)
```
Retrieves the text associated with a serialized property. The `xmltext` property is a collection that hold all text segments that an XML segment may have, keyed by their type (simple text or CDATA) and position. This method provide a simple way to retrieve the textual contents of an element.

For instance, as for the above serialization example:

```foxpro
? m.XMLSerializer.GetText(m.VFP.doc.child[1])
* prints "Some value"
? m.XMLSerializer.GetText(m.VFP.doc.child[2].xmlattributes.order)
* prints "b"
```

### GetArrayLength()
```foxpro
m.Count = m.XMLSerializer.GetArrayLength (m.VFPObject.property)
```
Retrieves the number of elements in a serialized array, or 0 if the property does not hold an array.

For instance, as for the the above serialization example:
```foxpro
? m.XMLSerializer.GetArrayLength(m.VFP.doc.child)
* prints 2
? m.XMLSerializer.GetArrayLength(m.VFP.doc.child[1].xmlattributes.order)
* prints 0
? m.XMLSerializer.GetArrayLength(m.VFP.doc.grandchild)
* prints .NULL.
```