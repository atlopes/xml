*!* Header for XML-Serializer class.

*!" public header (for object consumption)

#INCLUDE "xml-serializer.h"

*!* class header

* sorter formats and strings, to rearrange nodes positions in a re-serialized XML document
#DEFINE SORTFORMAT		"@L 9999999999"
#DEFINE SORTNOTSET		"UNSET"
#DEFINE SUBSORTNOTSET	REPLICATE("0",10)

* XML properties of an XML to VFP node
#DEFINE XML_NAME			This.XMLProperties[1]
#DEFINE XML_TEXT			This.XMLProperties[2]
#DEFINE XML_NAMESPACE	This.XMLProperties[3]
#DEFINE XML_PREFIXES		This.XMLProperties[4]
#DEFINE XML_POSITION		This.XMLProperties[5]
#DEFINE XML_COUNT			This.XMLProperties[6]
#DEFINE XML_ATTRIBUTE	This.XMLProperties[7]
#DEFINE XML_QNAME			This.XMLProperties[8]
#DEFINE XML_SOURCE		This.XMLProperties[9]

* processing level when serializing from VFP to XML
#DEFINE VFP_DOCUMENT				-1
#DEFINE VFP_ELEMENT				0
#DEFINE VFP_SINGLEATTRIBUTE	1
#DEFINE VFP_ATTRIBUTES			2

* type of node identifier
#DEFINE XML_ISTEXT		This.DataTypes[1]
#DEFINE XML_ISCDATA		This.DataTypes[2]
#DEFINE XML_ISELEMENT	This.DataTypes[3]
#DEFINE XML_ISPI			This.DataTypes[4]
#DEFINE XML_ISCOMMENT	This.DataTypes[5]
#DEFINE XML_ISDTD			This.DataTypes[6]

* type of node codes in serialized VFP object
#DEFINE XMLT_TEXT			"t"
#DEFINE XMLT_CDATA		"c"
#DEFINE XMLT_ELEMENT		"e"
#DEFINE XMLT_PI			"p"
#DEFINE XMLT_COMMENT		"*"
#DEFINE XMLT_DTD			"d"

* DOM node types
#DEFINE NODE_ELEMENT				1
#DEFINE NODE_ATTRIBUTE			2
#DEFINE NODE_TEXT					3
#DEFINE NODE_CDATA				4
#DEFINE NODE_PROCINSTRUCTION	7
#DEFINE NODE_COMMENT				8
#DEFINE NODE_DTD					10
