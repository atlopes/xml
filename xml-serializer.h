*!* XML-Serializer

*!* Definitions for .SetOption() and .GetOption() methods

#DEFINE	XMLSERIAL_WHITESPACE						"WhiteSpace"
#DEFINE	XMLSERIAL_PROCESSINGINSTRUCTIONS		"ProcessingInstructions"
#DEFINE	XMLSERIAL_COMMENTS						"Comments"
#DEFINE	XMLSERIAL_DTD								"DTD"

*!* VFP node names, or part names, for encoding or exporting

#DEFINE XML_SIMPLEATTR	UPPER(XML_ATTRIBUTE)
#DEFINE XML_SIMPLETEXT	"_value_"
#DEFINE XML_NFATTR		"_attr_"
#DEFINE XML_NFTEXT		"_nodetext_"

*!* processed XML nodes as VFP nodes, other than elements (always arrayed)

#DEFINE XML_PI				"xmlprocessinginstruction"
#DEFINE XML_COMMENT		"xmlcomment"
#DEFINE XML_DTD			"xmldtd"
#DEFINE XML_ORPHANTEXT	"xmlorphantext"

*!* name of serialized VFP properties

#DEFINE XMLP_NAME			"xmlname"
#DEFINE XMLP_TEXT			"xmltext"
#DEFINE XMLP_NS			"xmlns"
#DEFINE XMLP_PREFIXES	"xmlprefixes"
#DEFINE XMLP_POSITION	"xmlposition"
#DEFINE XMLP_COUNT		"xmlcount"
#DEFINE XMLP_ATTRIBUTES	"xmlattributes"
#DEFINE XMLP_QNAME		"xmlqname"
#DEFINE XMLP_SOURCE		"xmlsource"
