# VFP XML classes

A set of VFP classes for XML processing.

## List of developed classes

**[XMLSerializer](xml-serializer.md "XMLSerializer")**
Reads an XML document to create a corresponding VFP object, or writes a serialized VFP object back to XML, or an original VFP object to XML.

The reader concept was based on the original work by Marco Plaza, and on his great [nfXMLread()](https://github.com/VFPX/nfXML "nfXMLread()") function.

Status: complete.

**[XMLCanonicalizer](xml-canonicalizer.md "XMLCanonicalizer")**
Canonicalizes an XML document. Only the first W3C test cases are covered, for now.

Status: usable.

**[XMLSampler](xml-sampler.md "XMLSampler")**
Reads an XML Schema, and produces a sample XML document out of it.

Status: usable.

## In alpha-development

**XMLSecurity** set of classes to sign, encrypt, and secure XML documents.

## Ideas for the future

- SOAP client
- XML Schema to VFP Class
- ...

## License and other stuff

- The use of all classes is governed by an [UNLICENSE](UNLICENSE.md "UNLICENSE").
- There are a few dependencies on other classes that may be, or not, externally documented. Check the specific XML class documentation, for details.
- atlopes may be found at [LevelExtreme](https://www.levelextreme.com/ "LevelExtreme"), [Foxite](https://www.foxite.com "Foxite"), or [Tek-Tips](http://www.tek-tips.com/threadminder.cfm?pid=184 "Tek-Tips") VFP forum.
