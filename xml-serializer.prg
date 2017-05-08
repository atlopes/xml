*
* XMLSerializer
*
* A class to serialize an XML document into a VFP object, back and forth. It may also be used to serialize
*	an arbitrary VFP object (or an object fragment) into an XML document.
*
* Methods:
*	m.VFP = m.XMLSerializer.XMLtoVFP (Source AS String)
*		Retrieves an XML document (from a string, an URL or a file) and returns a VFP object matching the tree of the Source.
*		xml* members of the returned object control different aspects of the XML nodes (name, namespaces, ...).
*		Nodes that repeat their names (either because they occur more than once, in the source document, either because
*			their VFP name is repeated) are treated as arrays.
*		*************************************************************************************************************
*		Important note:
*		Based on the original code and ideas of Marco Plaza, and on his nfxmlread program (see nfXML poject in VFPX).
*		*************************************************************************************************************
*		Example of a serialization
*
*		<?xml version="1.0"?>
*		<doc>
*			<child order="a">Some value</child>
*			<child order="b">Other value</child>
*		</doc>
*
*		results in
*
*		doc
*		-	child[1]
*			-	xmlattributes
*					-	order
*						-	xmlname
*						-	xmlns
*						-	xmlposition
*						-	xmltext
*			-	xmlname
*			-	xmlns
*			-	xmlcount
*			-	xmlposition
*			-	xmltext
*		-	child[2]
*			-	...
*		-	xmlname
*		-	xmlns
*		-	xmlposition
*
*	m.VFP = m.XMLSerializer.GeSimpleCopy(VFPObject AS Object[, Options AS Integer])
*		Produces a simplified copy of the serialized object, from which the xml* information is stripped.
*		The copy may be configured to produce added _value_ properties for mixed elements (with text and subtree), to
*			hold text values in simplified xmltext properties, or to follow nfxml serializations.
*		For instance, as for the above ezample:
*
*		simplified result (Options = 1)
*
*		doc
*		-	child[1]
*			-	xmlattributes
*					-	order
*			-	xmltext
*		-	child[2]
*			-	...
*
*	m.XML = m.XMLSerializer.VFPtoXML (VFPObject AS Object[, Root AS String])
*		Creates an XML DOM object from a VFP object (either serialized from an XML document, or originally a VFP object).
*		If xml* members are present in the VFP object, they are used to (re)construct the XML DOM.
*		The name of a root may be passed, to encapsulate a rootless VFP object (or to add a new layer to another).
*
*	m.Text = m.XMLSerializer.GetText (VFPObject.property)
*		Retrieves the text associated to a serialized property.
*		For instance, as for the above example,
*				? m.Serializer.GetText(m.VFP.doc.child[1])
*			would return
*				Some value
*			or
*				? m.Serializer.GetText(m.VFP.doc.child[2].xmlattributes.order)
*			would return
*				b
*			(note that order may become _order, if an array, because order is not allowed as a VFP property name)
*
*	m.Count = m.XMLSerializer.GetArrayLength (VFPObject.property)
*		Retrieves the number of elements in a serialized array, or 0 if the property does not hold an array.
*		For instance, as for the the above example
*				? m.Serializer.GetArrayLength(m.VFP.doc.child)
*			would return
*				2
*
*
* Dependencies:
*		VFP9
*		MSXML6
*		NAMER.PRG procedure file
*
* Load:
*		SET PROCEDURE TO xml-serializer.prg ADDITIVE
*	or
*		DO xml-serializer.prg
*
* Use:
*		m.XMLSerializer = CREATEOBJECT("XMLSerializer")
*

* dependency on Namer class
DO (LOCFILE("NAMER.PRG"))

* install itself
IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "XML-Serializer.h"

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

* processed XML nodes as VFP nodes, other than elements (always arrayed)
#DEFINE XML_PI				"xmlprocessinginstruction"
#DEFINE XML_COMMENT		"xmlcomment"
#DEFINE XML_ORPHANTEXT	"xmltext"

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

* VFP node names, or part names, for encoding or exporting
#DEFINE XML_SIMPLEATTR	UPPER(XML_ATTRIBUTE)
#DEFINE XML_SIMPLETEXT	"_value_"
#DEFINE XML_NFATTR		"_attr_"
#DEFINE XML_NFTEXT		"_nodetext_"

* DOM node types
#DEFINE NODE_ELEMENT				1
#DEFINE NODE_ATTRIBUTE			2
#DEFINE NODE_TEXT					3
#DEFINE NODE_CDATA				4
#DEFINE NODE_PROCINSTRUCTION	7
#DEFINE NODE_COMMENT				8

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSerializer AS Custom

	ADD OBJECT DomainNamer AS Namer
	ADD OBJECT Options AS Collection

	_memberdata = '<VFPData>' + ;
						'<memberdata name="xmltovfp" type="method" display="XMLtoVFP"/>' + ;
						'<memberdata name="vfptoxml" type="method" display="VFPtoXML"/>' + ;
						'<memberdata name="gettext" type="method" display="GetText"/>' + ;
						'<memberdata name="getsimplecopy" type="method" display="GeSimpleCopy"/>' + ;
						'<memberdata name="getarraylength" type="method" display="GetArrayLength"/>' + ;
						'<memberdata name="setoption" type="method" display="SetOption"/>' + ;
						'<memberdata name="getoption" type="method" display="GetOption"/>' + ;
						'<memberdata name="domainnamer" type="property" display="DomainNamer"/>' + ;
						'<memberdata name="options" type="property" display="Options"/>' + ;
						'<memberdata name="xmlerror" type="property" display="XMLError"/>' + ;
						'<memberdata name="xmlline" type="property" display="XMLLine"/>' + ;
						'</VFPData>'

	XMLError = ""
	XMLLine = 0
	
	Parser = .NULL.
	DIMENSION DataTypes[5]
	DataTypes[1] = "t"
	DataTypes[2] = "c"
	DataTypes[3] = "e"
	DataTypes[4] = "p"
	DataTypes[5] = "*"
	DIMENSION XMLProperties[7]
	XMLProperties[1] = "xmlname"
	XMLProperties[2] = "xmltext"
	XMLProperties[3] = "xmlns"
	XMLProperties[4] = "xmlprefixes"
	XMLProperties[5] = "xmlposition"
	XMLProperties[6] = "xmlcount"
	XMLProperties[7] = "xmlattributes"
	
	FUNCTION Init
	
		SAFETHIS

		* load now the namer library, if not already loaded
		DO (LOCFILE("NAMER.PRG"))

		* set the name translators for VFP and XML
		This.DomainNamer.AttachProcessor("VFPNamer", LOCFILE("vfp-names.prg"))
		This.DomainNamer.AttachProcessor("XMLNamer", LOCFILE("xml-names.prg"))

		* this is the XML parser (serialized XML DOM objects are created when needed)
		This.Parser = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		This.Parser.Async = .F.

		This.SetOption(XMLSERIAL_WHITESPACE, .F.)
		This.SetOption(XMLSERIAL_PROCESSINGINSTRUCTIONS, .F.)
		This.SetOption(XMLSERIAL_COMMENTS, .F.)

		RETURN .T.

	ENDFUNC

	***************************************************************************************************
	* SetOption
	
	* Sets an option
	***************************************************************************************************
	FUNCTION SetOption (Option AS String, OptionValue AS AnyType)

		SAFETHIS

		LOCAL OptionKey AS String

		IF m.Option == XMLSERIAL_WHITESPACE OR ;
				m.Option == XMLSERIAL_PROCESSINGINSTRUCTIONS OR ;
				m.Option == XMLSERIAL_COMMENTS

			m.OptionKey = UPPER(m.Option)

			IF !EMPTY(This.Options.GetKey(m.OptionKey))
				This.Options.Remove(m.OptionKey)
			ENDIF

			This.Options.Add(m.OptionValue, m.OptionKey)

		ENDIF

		RETURN m.OptionValue

	ENDFUNC

	***************************************************************************************************
	* GetOption
	
	* Returns an option value
	***************************************************************************************************
	FUNCTION GetOption (Option AS String)

		SAFETHIS

		IF m.Option == XMLSERIAL_WHITESPACE OR ;
				m.Option == XMLSERIAL_PROCESSINGINSTRUCTIONS OR ;
				m.Option == XMLSERIAL_COMMENTS

			RETURN This.Options.Item(UPPER(m.Option))
		ENDIF

		RETURN .NULL.

	ENDFUNC

	***************************************************************************************************
	* XMLtoVFP
	
	* Source
	*	- an URL, or file name, or string, with the XML to process
	
	* Returns a VFP Empty-based object, or .NULL., if errors during loading of the document
	***************************************************************************************************
	FUNCTION XMLtoVFP AS Empty
	LPARAMETERS Source AS StringURLorDOM

		SAFETHIS

		ASSERT TYPE("m.Source") $ "CO" MESSAGE "Source must be a string or an object."

		LOCAL VFPObject AS Empty
		LOCAL SourceObject AS MSXML2.IXMLDOMNode

		This.XMLError = ""
		This.XMLLine = 0

		* if an XMLDOM object was passed, use it as the source
		IF TYPE("m.Source") == "O"

			m.SourceObject = m.Source

		ELSE

			* follow white space setting
			This.Parser.preserveWhiteSpace = This.GetOption(XMLSERIAL_WHITESPACE)

			* otherwise, a source document has to be loaded
			* try to load as an URL / file
			IF !This.Parser.Load(m.Source)
				* if not, as a string
				This.Parser.LoadXML(m.Source)
			ENDIF

			This.XMLError = This.Parser.parseError.reason
			This.XMLLine = This.Parser.parseError.line

			m.SourceObject = This.Parser

		ENDIF
		
		* if the document was parsed
		IF EMPTY(This.XMLError)
			m.VFPObject = CREATEOBJECT("Empty")
			* read the tree and put it in a VFP object
			This.ReadXMLTree(m.SourceObject.childNodes(), m.VFPObject)
		ELSE
			* report failure
			m.VFPObject = .NULL.
		ENDIF
		
		RETURN m.VFPObject

	ENDFUNC

	***************************************************************************************************
	* VFPtoXML
	
	* Source
	*		- a VFP object reference 
	* Root
	*		- [optional] the name of the root element
	
	* Returns an XML DOM Document
	***************************************************************************************************
	FUNCTION VFPtoXML AS MSXML2.DOMDocument60
	LPARAMETERS Source AS anyVFPObject, Root AS String

		SAFETHIS

		ASSERT TYPE("m.Source") = "O" MESSAGE "Source must be an object."
		ASSERT PCOUNT() = 1 OR TYPE("m.Root") = "C" MESSAGE "Root name must be a string."

		LOCAL XMLObject AS MSXML2.DOMDocument60
		LOCAL Namespaces AS Collection
		LOCAL XMLDeclaration AS MSXML2.IXMLDOMProcessingInstruction
		LOCAL NsDeclaration AS MSXML2.IXMLDOMAttribute
		LOCAL LoopIndex AS String

		LOCAL ARRAY Properties[1]
		LOCAL RootProperty AS Integer
		LOCAL PropertyCount AS Integer
		LOCAL PropertiesIndex AS Integer

		LOCAL ExactSetting AS String

		DO CASE

		* source must be an active VFP object
		CASE TYPE("m.Source") != "O" OR ISNULL(m.Source)
			RETURN .NULL.
			
		CASE PCOUNT() = 1

			m.ExactSetting = SET("Exact")
			SET EXACT ON

			* there must be a single root at the top of the object property tree
			m.RootProperty = 0

			* look for the root (ignoring sibling processing instructions, and comments)
			PropertyCount = AMEMBERS(m.Properties, m.Source, 0, "U")
			FOR m.PropertiesIndex = 1 TO m.PropertyCount
				IF !INLIST(LOWER(m.Properties[m.PropertiesIndex]) , XML_PI, XML_COMMENT, XML_ORPHANTEXT)
					* give up if there is more than one
					IF m.RootProperty != 0
						m.RootProperty = 0
						EXIT
					ENDIF
					m.RootProperty = m.PropertiesIndex
				ENDIF
			ENDFOR

			IF m.ExactSetting == "OFF"
				SET EXACT OFF
			ENDIF

			* give up if a root was not found, or it is an array, or it is undefined
			IF m.RootProperty = 0 ;
					OR TYPE("m.Source." + m.Properties[m.RootProperty], 1) == "A" ;
					OR TYPE("m.Source." + m.Properties[m.RootProperty]) == "U"
				RETURN .NULL.
			ENDIF

		OTHERWISE
			m.PropertyCount = 1

		ENDCASE

		* the object that will be built and then returned
		m.XMLObject = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		m.XMLDeclaration = m.XMLObject.createProcessingInstruction("xml", 'version="1.0" encoding="UTF-8"')
		m.XMLObject.appendChild(m.XMLDeclaration)

		m.XMLObject.preserveWhiteSpace = This.GetOption(XMLSERIAL_WHITESPACE)

		* the collection of the namespaces in use
		m.Namespaces = CREATEOBJECT("Collection")

		* process the VFP object tree, starting from top property or from the object itself
		DO CASE
		CASE PCOUNT() = 1 AND m.PropertyCount = 1
			* a simple case where there is a single property at the top
			This.ReadVFPTree(m.Properties[1], EVALUATE("m.Source." + m.Properties[1]), m.XMLObject, m.XMLObject, VFP_ELEMENT, "", m.Namespaces)

		CASE m.PropertyCount > 1
			* when there are several properties, with one identified root, process from the document level
			This.ReadVFPTree("", m.Source, m.XMLObject, m.XMLObject, VFP_DOCUMENT, "", m.Namespaces)

		OTHERWISE
			* the root is named, and identified, process from there
			This.ReadVFPTree(m.Root, m.Source, m.XMLObject, m.XMLObject, VFP_ELEMENT, "", m.Namespaces)

		ENDCASE

		* after the XML object is built, move the namespaces declarations to the root element to reduce verbosity
		FOR m.LoopIndex = 1 TO m.Namespaces.Count

			m.NsDeclaration = m.XMLObject.createAttribute("xmlns:" + m.Namespaces.Item(m.LoopIndex))
			m.NsDeclaration.text = m.Namespaces.GetKey(m.LoopIndex)
			m.XMLObject.documentElement.attributes.setNamedItem(m.NsDeclaration)

		ENDFOR

		* done
		RETURN m.XMLObject

	ENDFUNC

	***************************************************************************************************
	* GetText
	
	* Element
	*		- a point in a serialized VFP object
	
	* Returns the textual value of the element, or .NULL. if the element does not exist
	***************************************************************************************************
	FUNCTION GetText
	LPARAMETERS Element

		ASSERT TYPE("m.Element") = "O" MESSAGE "Element must be an object."

		LOCAL ElementText AS String
		LOCAL LoopIndex AS Integer

		IF TYPE("m.Element.xmltext") == "O"

			m.ElementText = ""
			IF !ISNULL(m.Element.xmltext)
				FOR m.LoopIndex = 1 TO m.Element.xmltext.Count
					m.ElementText = m.ElementText + NVL(m.Element.xmltext(m.LoopIndex), "")
				ENDFOR
			ENDIF

		ELSE

			m.ElementText = .NULL.

		ENDIF

		RETURN m.ElementText

	ENDFUNC

	***************************************************************************************************
	* GetArrayLength
	
	* Element
	*		- a point in a serialized VFP object
	
	* Returns the numbers of elements of an array, 0 for a regular element, or .NULL. if it is .NULL.
	***************************************************************************************************
	FUNCTION GetArrayLength
	LPARAMETERS Element

		ASSERT TYPE("m.Element") = "O" MESSAGE "Element must be an object."

		LOCAL ArrayLength AS Integer

		DO CASE
		CASE TYPE("m.Element.xmlcount") == "N"

			m.ArrayLength = m.Element.xmlcount

		CASE !ISNULL(m.Element)
		
			m.ArrayLength = 0
		
		OTHERWISE

			m.ArrayLength = .NULL.

		ENDCASE

		RETURN m.ArrayLength

	ENDFUNC

	***************************************************************************************************
	* GetSimpleCopy
	
	* Element
	*		- a point in a serialized VFP object
	* Options
	*		- 0 (or .F., default) produce added _value_ properties for mixed elements (with text and subtree)
	*		- 1 (or .T.) text from mixed elements is simplified as an xmltext character property
	*		- 2 create nfXML compatible structure
	
	* Returns a simplified copy of the serialized VFP object, from which xml* data is removed
	***************************************************************************************************
	FUNCTION GetSimpleCopy
	LPARAMETERS Element, Options AS Integer

		SAFETHIS

		ASSERT TYPE("m.Element") = "O" MESSAGE "Element must be an object."
		ASSERT TYPE("m.Options") $ "LN" MESSAGE "Options must be logical or a number."

		* the segment of the simple copy created at this level
		LOCAL SimpleCopy AS Empty
		* and what follows downtree
		LOCAL DownTree AS	Empty
		* properties found at this level, and immediately downtree
		LOCAL ARRAY Properties[1], DownProperties[1]
		* to control a property that is being processed (regular or array)
		LOCAL Property AS String
		LOCAL ArrayProperty AS String
		LOCAL ArrayLength AS Integer
		LOCAL ArrayNoValues AS Boolean
		LOCAL TextValue AS String
		* loop indexers
		LOCAL LoopIndex AS Integer
		LOCAL LoopArrayIndex AS Integer
		
		* make sure that Options is 0, 1 or 2
		IF TYPE("m.Options") == "L"
			m.Options = IIF(m.Options, 1, 0)
		ELSE
			IF !INLIST(VAL(TRANSFORM(m.Options)), 1, 2)
				m.Options = 0
			ENDIF
		ENDIF

		* create the segment that will be returned		
		m.SimpleCopy = CREATEOBJECT("Empty")

		* go through all properties at this level (from root downtree)
		FOR m.LoopIndex = 1 TO AMEMBERS(m.Properties, m.Element, 0)
		
			m.Property = UPPER(m.Properties[m.LoopIndex])
			
			* ignore all xml* properties, except attributes
			IF LEFT(m.Property, 3) != "XML" OR m.Property == XML_SIMPLEATTR
			
				m.ArrayLength = This.GetArrayLength(m.Element.&Property.)
		
				* cases where properties were arrayed	
				IF m.ArrayLength != 0

					* create the full array (we have the number of elements, beforehand)
					ADDPROPERTY(m.SimpleCopy, m.Property + "[" + TRANSFORM(m.ArrayLength) + "]")
					IF m.Options = 0
						* and a sibling <name>_value_[], to hold values if needed
						ADDPROPERTY(m.SimpleCopy, m.Property + XML_SIMPLETEXT + "[" + TRANSFORM(m.ArrayLength) + "]")
						* for now, there are no values assigned to this new array
						m.ArrayNoValues = .T.
					ENDIF

					* go through each member of the array
					FOR m.LoopArrayIndex = 1 TO m.ArrayLength
					
						* create a reference to it
						m.ArrayProperty = m.Property + "[" + TRANSFORM(m.LoopArrayIndex) + "]"
						* fetch the simplified text value
						m.TextValue = EVL(This.GetText(m.Element.&ArrayProperty.), "")
						* and create the simplified version of the tree under it (if there is one)
						m.DownTree = This.GetSimpleCopy(m.Element.&ArrayProperty., m.Options)
						
						DO CASE
						* if there is no tree
						CASE AMEMBERS(m.DownProperties, m.DownTree) = 0
							* just use the text value
							m.SimpleCopy.&ArrayProperty. = NVL(m.TextValue, "")

						* is there text, and we are using _value_ properties?
						CASE m.Options = 0 AND !EMPTY(NVL(m.TextValue, ""))
							* store the downtree in the property
							m.SimpleCopy.&ArrayProperty. = m.DownTree
							* and the text value in the sibling array
							m.ArrayProperty = m.Property + XML_SIMPLETEXT +"[" + TRANSFORM(m.LoopArrayIndex) + "]"
							m.SimpleCopy.&ArrayProperty. = m.TextValue
							* signal that we used the sibling array
							m.ArrayNoValues = .F.

						* is there text, and we are running in nf compatible mode?
						CASE m.Options = 2 AND !EMPTY(NVL(m.TextValue, ""))
							* store the downtree in the property
							m.SimpleCopy.&ArrayProperty. = m.DownTree
							* and add a special property for the text
							ADDPROPERTY(m.SimpleCopy.&ArrayProperty., XML_NFTEXT, m.TextValue)

						OTHERWISE
							* in other cases, store the downtree in the property
							m.SimpleCopy.&ArrayProperty. = m.DownTree
							* and add the text value to a character property, if set by option
							IF m.Options = 1 AND !EMPTY(NVL(m.TextValue, ""))
								ADDPROPERTY(m.SimpleCopy.&ArrayProperty., XML_TEXT, NVL(m.TextValue, ""))
							ENDIF
						ENDCASE
					
					ENDFOR

					* if the sibling array was not needed, it may be removed, now
					IF m.Options = 0 AND m.ArrayNoValues
						REMOVEPROPERTY(m.SimpleCopy, m.Property + XML_SIMPLETEXT)
					ENDIF

				* cases where property is not arrayed
				ELSE
				
					* get its simplified text
					m.TextValue = This.GetText(m.Element.&Property.)
					* and its downtree
					m.DownTree = This.GetSimpleCopy(m.Element.&Property., m.Options)
					
					DO CASE

					* if there is no tree
					CASE AMEMBERS(m.DownProperties, m.DownTree) = 0
						* just use the text value
						ADDPROPERTY(m.SimpleCopy, m.Property, NVL(m.TextValue, ""))

					* is there text, and we are using _value_ properties?
					CASE m.Options = 0 AND !EMPTY(NVL(m.TextValue, ""))
						* store the downtree in the property
						ADDPROPERTY(m.SimpleCopy, m.Property, m.DownTree)
						* and the text value in the sibling property
						ADDPROPERTY(m.SimpleCopy, m.Property + XML_SIMPLETEXT, m.TextValue)

					* is there text, and we are running in nf compatible mode?
					CASE m.Options = 2 AND !EMPTY(NVL(m.TextValue, ""))
						* store the downtree in the property
						ADDPROPERTY(m.SimpleCopy, m.Property, m.DownTree)
						* and add a special property for the text
						ADDPROPERTY(m.SimpleCopy.&Property., XML_NFTEXT, m.TextValue)

					* there is no text, we are running in nf compatible mode and building the attributes structure?
					CASE m.Options = 2 AND m.Property == XML_SIMPLEATTR
						* store the attribute downtree in the property, with the nf name
						ADDPROPERTY(m.SimpleCopy, XML_NFATTR, m.DownTree)

					OTHERWISE
						* in other cases, store the downtree in the property
						ADDPROPERTY(m.SimpleCopy, m.Property, m.DownTree)
						* and add the text value to a character property, if set by option
						IF m.Options = 1 AND !EMPTY(NVL(m.TextValue, ""))
							ADDPROPERTY(m.SimpleCopy.&Property., XML_TEXT, NVL(m.TextValue, ""))
						ENDIF
					ENDCASE
					
				ENDIF

			ENDIF

		ENDFOR

		* return the tree segment produced at this level
		RETURN m.SimpleCopy

	ENDFUNC

	* ReadXMLTree - process an XML object / property and its children

	* XMLNodes - the XML point in the tree
	* VFPObject - the VFP object that is being built
	HIDDEN FUNCTION ReadXMLTree
	LPARAMETERS XMLNodes AS MSXML2.IXMLDOMNodeList, VFPObject AS Object

		SAFETHIS

		* to traverse the XML document tree
		LOCAL Node AS MSXML2.IXMLDOMNode
		LOCAL NodeIndex AS Integer
		LOCAL NameSpace AS String
		LOCAL Prefixes AS Collection
		LOCAL NodeVFPRoot AS Empty

		* to identify and traverse the attributes of an element
		LOCAL Attributes AS MSXML2.IXMLDOMNodeList
		LOCAL HasAttributes AS Boolean
		LOCAL AttributesVFPRoot AS Empty

		* to store the text (regular and CDATA) of an element/attribute
		LOCAL TextNode AS MSXML2.IXMLDOMNode
		LOCAL TextNodeIndex AS Integer
		LOCAL Texts AS Collection

		* name, value and xml representation of a point in the tree
		LOCAL NewName AS String
		LOCAL NewValue AS Empty
		LOCAL NewNode AS Boolean
		
		* to manipulate arrays of elements
		LOCAL CheckArray AS String
		LOCAL NewArrayName AS String
		LOCAL ToArray AS Boolean
		LOCAL TempValue AS Empty

		* read processing instructions?
		LOCAL ReadProcessingInstructions AS Boolean
		LOCAL ProcessingInstructions AS Integer
		* read comments?
		LOCAL ReadComments AS Boolean
		LOCAL Comments AS Integer

		m.NodeIndex = 0

		m.ReadProcessingInstructions = This.GetOption(XMLSERIAL_PROCESSINGINSTRUCTIONS)
		m.ReadComments = This.GetOption(XMLSERIAL_COMMENTS)

		STORE 0 TO m.ProcessingInstructions, m.Comments

		* traverse every node in the list
		FOR EACH m.Node IN m.XMLNodes

			* mark its relative position		
			m.NodeIndex = m.NodeIndex + 1

			WITH m.Node
			
				* process a node
				DO CASE

				CASE .nodeType = NODE_ELEMENT				&& found an element
				
					* fetch all namespace prefixes
					m.Prefixes = .NULL.

					FOR EACH m.NameSpaceDeclaration IN m.Node.Attributes

						* found a namespace declaration
						IF m.NameSpaceDeclaration.namespaceURI == "http://www.w3.org/2000/xmlns/"
						
							* check if it is qualified
							IF !(m.NameSpaceDeclaration.baseName == m.NameSpaceDeclaration.nodeName)
							
								* prepare the collection of prefixes, if not done already
								IF ISNULL(m.Prefixes)
									m.Prefixes = CREATEOBJECT("Collection")
								ENDIF
								
								* add the prefixed namespace to the collection
								m.Prefixes.Add(m.NameSpaceDeclaration.text, m.NameSpaceDeclaration.baseName)
							ENDIF
						ENDIF
					ENDFOR

					* check if there are any attributes that are not namespaces
					m.Attributes = .selectNodes("@*[namespace-uri(.) != 'http://www.w3.org/2000/xmlns/']")
					m.HasAttributes = m.Attributes.length > 0
					
					m.TextNodeIndex = 0
					m.Texts = .NULL.
					
					* traverse all children, looking for text nodes
					FOR EACH m.TextNode IN .childNodes
					
						m.TextNodeIndex = m.TextNodeIndex + 1

						* if a text or CDATA child was found
						IF INLIST(m.TextNode.nodeType, NODE_TEXT, NODE_CDATA)
						
							* insert it in the texts collection, with its position marked
							IF ISNULL(m.Texts)
								m.Texts = CREATEOBJECT("Collection")
							ENDIF
							m.Texts.Add(m.TextNode.text, IIF(m.TextNode.nodeType = NODE_TEXT, XML_ISTEXT, XML_ISCDATA) + TRANSFORM(m.TextNodeIndex))

						ENDIF
					ENDFOR
					
					* fetch the namespace for the current node
					m.NameSpace = .namespaceURI
				
				CASE .nodeType = NODE_ATTRIBUTE		&& found an attribute
				
					* attributes do not have attributes
					m.HasAttributes = .F.

					* just text, that is added to its collection
					m.Texts = CREATEOBJECT("Collection")
					m.Texts.Add(.text, XML_ISTEXT + "1")

					* attributes may have a namespace
					m.NameSpace = EVL(.namespaceURI, .NULL.)


				CASE .nodeType = NODE_PROCINSTRUCTION AND m.ReadProcessingInstructions
					m.ProcessingInstructions = This._newProcessingInstruction(m.VFPObject, .nodeName, .nodeValue, m.ProcessingInstructions, m.NodeIndex)
					LOOP

				CASE .nodeType = NODE_COMMENT AND m.ReadComments
					m.Comments = This._newComment(m.VFPObject, .nodeValue, m.Comments, m.NodeIndex)
					LOOP

				OTHERWISE			&& for all other cases ignore the XML source

					LOOP

				ENDCASE

				* try to treat the node as a single property
				m.ToArray = .F.

				* get an allowed VFP name, corresponding to the XML name
				This.DomainNamer.SetOriginalName(.baseName)
				This.DomainNamer.SetProperty("VFPNamer", "SafeArrayName", .F.)
				m.NewName = This.DomainNamer.GetName("VFPNamer")
				
				* is it a new node?
				m.NewNode = TYPE("m.VFPObject." + m.NewName) == "U"
				
				* this is the information related to a single node:
				*		- the original name
				*		- the text section(s) of the node
				*		- the namespace
				*		- the prefixes
				* 		- and its position, in the tree
				m.NewValue = This._newVFPNode(.baseName, m.Texts, m.NameSpace, m.Prefixes, m.NodeIndex)
				
				* an element or attribute with this name did not exist
				IF m.NewNode
					
					* check if there are siblings (elements or attributes) with the same normalized name,
					* which will generate an array
					m.CheckArray = "../" + IIF(.nodeType = 2,"@", "") + "*" + ;
								"[translate(local-name(), " + ;
									"'-abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿžšœ'," + ;
									"'_ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞŸŽŠŒ') = '" + ;
									UPPER(m.NewName) + "']"

					* if there are none,
					IF .selectNodes(m.CheckArray).length <= 1
					
						* add a regular property to this level of the current object
						ADDPROPERTY(m.VFPObject, m.NewName, m.NewValue)
						* that will be used as a root for further processing
						m.NodeVFPRoot = EVALUATE("m.VFPObject." + m.NewName)
					
					ELSE
					
						* get a name, again, now safe for array names
						This.DomainNamer.SetProperty("VFPNamer", "SafeArrayName", .T.)
						m.NewName = This.DomainNamer.GetName("VFPNamer")
						
						* if the name was not already in use, use it now for the property
						IF TYPE("m.VFPObject." + m.NewName) == "U"
							ADDPROPERTY(m.VFPObject, m.NewName + "[1]")
							* set a counter
							ADDPROPERTY(m.NewValue, XML_COUNT, 1)
							* and the value
							m.VFPObject.&NewName.[1] = m.NewValue
							* use it as a root for further processing
							m.NodeVFPRoot = EVALUATE("m.VFPObject." + m.NewName + "[1]")
						ELSE
							* similar node names were found at the same level, so the property will be an array already set
							m.ToArray = .T.
						ENDIF
					
					ENDIF
				
				ELSE
				
					* if a property already exists, then it must be assigned to an array
					m.ToArray = .T.

					* a few cases must require a change from a regular property to an array property,
					* when the translated VFP name can not be trapped by the selectNodes query
					* (for instance, when the XML name clashes with a VFP reserved word)
					IF TYPE("m.VFPObject." + m.NewName, 1) != "A"

						* get a name, again, now safe for array names
						This.DomainNamer.SetProperty("VFPNamer", "SafeArrayName", .T.)
						m.NewArrayName = This.DomainNamer.GetName("VFPNamer")

						* if an array has not already been set with this adjusted name 
						IF TYPE("m.VFPObject." + m.NewArrayName, 1) != "A"

							* hold the value of the regular property
							m.TempValue = EVALUATE("m.VFPObject." + m.NewName)
							* remove it
							REMOVEPROPERTY(m.VFPObject, m.NewName)
							* set the name to the array name (they may be different)
							m.NewName = m.NewArrayName
							* insert it back again as an array
							ADDPROPERTY(m.VFPObject, m.NewName + "[1]")
							* set a counter
							ADDPROPERTY(m.TempValue, XML_COUNT, 1)
							* and restore the value
							m.VFPObject.&NewName.[1] = m.TempValue
						ENDIF
					ENDIF
				ENDIF
				
				* the property is an array element
				IF m.ToArray
					
					* set the counter for the array
					m.VFPObject.&NewName.[1].xmlcount = m.VFPObject.&NewName.[1].xmlcount + 1
					* create a new element at the end of the array
					m.NewName = m.NewName + "[" + TRANSFORM(ALEN(m.VFPObject.&NewName.) + 1) + "]"
					DIMENSION m.VFPObject.&NewName.
					* set its value
					m.VFPObject.&NewName. = m.NewValue
					* and proceed, later on, to its subtree
					m.NodeVFPRoot = EVALUATE("m.VFPObject." + m.NewName)
					
				ENDIF
				
				* if the current node has attributes
				IF m.HasAttributes
				
					* add to the VFP object
					ADDPROPERTY(m.NodeVFPRoot, XML_ATTRIBUTE, CREATEOBJECT("Empty"))
					* and set its/their values
					m.AttributesVFPRoot = EVALUATE("m.NodeVFPRoot." + XML_ATTRIBUTE)
					* by traversing the attribute list
					This.ReadXMLTree(m.Attributes, m.AttributesVFPRoot)
				
				ENDIF
				
				* if there are children to process
				IF .childNodes.length > 0
				
					* use the current node as the root of the XML tree
					This.ReadXMLTree(.childNodes, m.NodeVFPRoot)
				
				ENDIF

			ENDWITH
		
		ENDFOR
		
	ENDFUNC

	* ReadVFPTree - process an object / property and its children

	* ObjSourceName - the VFP name
	* ObjSource - a point in the VFP object hierarchy
	* ObjNode - the parent of the element, in the XML tree
	* ObjDocument - the general XML document that is being built
	* ProcessingLevel - what is being processed at this level
	* ParentNamespace - the namespace of the parent element
	* Namespaces - the collection of namespaces referred so far
	FUNCTION ReadVFPTree
	LPARAMETERS ObjSourceName AS String, ObjSource AS anyVFPObject, ;
		ObjNode AS MSXML2.IXMLDOMNode, ObjDocument AS MSXML2.DOMDocument60, ;
		ProcessingLevel AS Integer, ParentNamespace AS String, Namespaces AS Collection

		SAFETHIS

		* the XML element that matches the VFP property
		LOCAL Element AS MSXML2.IXMLDOMElement

		* text, CDATA, PI and comment nodes
		LOCAL TextNode AS MSXML2.IXMLDOMText
		LOCAL CDATANode AS MSXML2.IXMLDOMCDATASection
		LOCAL ProcessingInstructionNode AS MSXML2.IXMLDOMProcessingInstruction
		LOCAL CommentNode AS MSXML2.IXMLDOMComment

		* the XML object name and namespace (empty, if from an original VFP object)
		LOCAL ObjectName AS String
		LOCAL ObjectNamespace AS String

		* the properties of the VFP object, at this point of the hierarchy
		LOCAL ARRAY Properties[1]

		* control of the namespace collection and its impact on the current element
		LOCAL NamespaceEntry AS Integer
		LOCAL NamespaceAttribute AS MSXML2.IXMLDOMAttribute
		LOCAL QualifyName AS Boolean
		LOCAL Prefix AS String

		* how a child of this VFP object is referred
		LOCAL ChildReference AS String

		* types: e - element, t - text, c - cdata, p - processing instruction, # - comments (attributes are treated by the AttributeLevel parameter)
		LOCAL ChildType AS String

		* child reference when child is an array
		LOCAL ChildElementReference AS String

		* the original positions of the XML elements, keyed by type (e-t-c-p-#) and reference
		LOCAL Positions AS Collection

		* the original positions of XML textual nodes (text and CDATA)
		LOCAL TextPosition AS String

		* loop indexers
		LOCAL Loop AS Integer
		LOCAL ArrayLoop AS Integer
		LOCAL TextLoop AS Integer

		* options settings
		LOCAL WriteProcessingInstructions AS Boolean
		LOCAL WriteComments AS Boolean

		m.WriteProcessingInstructions = This.GetOption(XMLSERIAL_PROCESSINGINSTRUCTIONS)
		m.WriteComments = This.GetOption(XMLSERIAL_COMMENTS)

		* no namespace in use
		m.ObjectNamespace = ""
		m.QualifyName = .F.

		* if processing a single element or attribute, prepare a DOM object to match
		IF INLIST(m.ProcessingLevel, VFP_ELEMENT, VFP_SINGLEATTRIBUTE)

			* if there is a namespace associated with a VFP property
			IF TYPE("m.ObjSource.xmlns") == "C"

				* get it
				m.ObjectNamespace = NVL(m.ObjSource.xmlns, m.ParentNamespace)
				
				* and insert it in the namespace collection, if it wasn't there yet,
				* setting a general prefix for it, at the same time
				IF !EMPTY(m.ObjectNamespace)
					* look for the namespace in the namespaces collection
					m.NamespaceEntry = m.Namespaces.GetKey(m.ObjectNamespace)
					IF m.NamespaceEntry = 0
						* new entry, if it wasn't defined, yet
						m.Prefix = "ns" + TRANSFORM(m.Namespaces.Count + 1)
						m.Namespaces.Add(m.Prefix, m.ObjectNamespace)
					ELSE
						* or just key the prefix, otherwise
						m.Prefix = m.Namespaces.Item(m.NamespaceEntry)
					ENDIF
				ENDIF
			ENDIF

			* get a name for the element, either from an XML original or from the VFP property name
			IF TYPE("m.ObjSource.xmlname") = "C"
				m.ObjectName = m.ObjSource.xmlname
				IF !EMPTY(m.ObjectNamespace) AND !(m.ObjectNamespace == m.ParentNamespace)
					m.ObjectName = m.Prefix + ":" + m.ObjectName
					m.QualifyName = .T.
				ENDIF
			ELSE
				This.DomainNamer.SetOriginalName(m.ObjSourceName)
				m.ObjectName = This.DomainNamer.GetName("XMLNamer")
			ENDIF

			* create an XML node in the DOM to hold all information
			DO CASE
			CASE m.ProcessingLevel = VFP_ELEMENT
				* a regular element
				m.Element = m.ObjDocument.createNode(NODE_ELEMENT, m.ObjectName, IIF(m.QualifyName, m.ObjectNamespace, ""))
			CASE m.ProcessingLevel = VFP_SINGLEATTRIBUTE
				* or an attribute
				m.Element = m.ObjDocument.createNode(NODE_ATTRIBUTE, m.ObjectName, IIF(m.QualifyName, m.ObjectNamespace, ""))
			ENDCASE
		ENDIF
		
		* collection that will filter and sort all elements back to their original XML order or to the natural VFP order
		m.Positions = CREATEOBJECT("Collection")

		* the children of the current VFP object / property
		IF TYPE("m.ObjSource") == "O" AND !ISNULL(m.ObjSource) AND AMEMBERS(m.Properties, m.ObjSource, 0, "U") != 0

			* will be processed	
			FOR m.Loop = 1 TO ALEN(m.Properties)

				* but disregard the XML* properties and other members which are not value properties
				IF (LEFT(m.Properties[m.Loop], 3) != "XML" OR ;
							m.Properties[m.Loop] == UPPER(XML_PI) OR ;
							m.Properties[m.Loop] == UPPER(XML_COMMENT)) ;
						AND TYPE("m.ObjSource." + m.Properties[m.Loop]) != "U"

					DO CASE
					CASE m.Properties[m.Loop] == UPPER(XML_PI)
						m.ChildType = XML_ISPI
					CASE m.Properties[m.Loop] == UPPER(XML_COMMENT)
						m.ChildType = XML_ISCOMMENT
					OTHERWISE
						m.ChildType = XML_ISELEMENT
					ENDCASE

					m.ChildReference = "m.ObjSource." + m.Properties[m.Loop]

					IF TYPE(m.ChildReference, 1) = "A"

						* if it is an array, process every element
						FOR m.ArrayLoop = 1 TO ALEN(&ChildReference.)
							m.ChildElementReference = m.ChildReference + "[" + TRANSFORM(m.ArrayLoop) + "]"
							This._prepareVFPNodeToXML(m.ObjSource, m.Positions, m.ChildType, m.ChildElementReference, SORTNOTSET + TRANSFORM(m.Loop, SORTFORMAT) + TRANSFORM(m.ArrayLoop, SORTFORMAT))
						ENDFOR
					ELSE
						* do the same for single objects that are not part of arrays
						This._prepareVFPNodeToXML(m.ObjSource, m.Positions, m.ChildType, m.ChildReference, SORTNOTSET + TRANSFORM(m.Loop, SORTFORMAT) + SUBSORTNOTSET)
					ENDIF
				ENDIF
			ENDFOR

			* if there is text associated with the element / attribute, put it in the position collection
			IF TYPE("m.ObjSource.xmltext") = "O" AND !ISNULL(m.ObjSource.xmltext)
			
				FOR m.TextLoop = 1 TO m.ObjSource.xmltext.Count

					m.ChildReference = "m.ObjSource.xmltext.Item(" + TRANSFORM(m.TextLoop) + ")"
					m.TextPosition = EVALUATE("m.ObjSource.xmltext.GetKey(" + TRANSFORM(m.TextLoop) + ")")
					m.Positions.Add(LEFT(m.TextPosition, 1) + m.ChildReference, TRANSFORM(VAL(SUBSTR(m.TextPosition, 2)), SORTFORMAT))

				ENDFOR
			
			ENDIF

			* process the attributes for the element, if any
			IF m.ProcessingLevel = VFP_ELEMENT AND TYPE("m.ObjSource.xmlattributes") = "O" AND !ISNULL(m.ObjSource.xmlattributes)

				This.ReadVFPTree("", m.ObjSource.xmlattributes, m.Element, m.ObjDocument, VFP_ATTRIBUTES, m.ObjectNamespace, m.Namespaces)

			ENDIF

		* if not an object with children, that is, already a string or other scalar type, store the value as CDATA
		ELSE
		
			m.Positions.Add(XML_ISCDATA + "m.ObjSource", SORTNOTSET)

		ENDIF

		* sort the positions collection by key, and iterate trough the items
		m.Positions.KeySort = 2

		FOR EACH m.ChildReference IN m.Positions

			* the type is in the left char of the reference
			m.ChildType = LEFT(m.ChildReference, 1)

			m.ChildReference = SUBSTR(m.ChildReference,2)
			m.ObjectName = m.ChildReference
			IF "[" $ m.ObjectName
				m.ObjectName = LEFT(m.ObjectName, AT("[", m.ObjectName) - 1)
			ENDIF
			m.ObjectName = SUBSTR(m.ObjectName, RAT(".", m.ObjectName) + 1)
			
			DO CASE
			CASE m.ProcessingLevel = VFP_ATTRIBUTES
				* if processing a collection of .xmlattributes, process the VFP hierarchy
				This.ReadVFPTree("", EVALUATE(m.ChildReference), m.ObjNode, m.ObjDocument, VFP_SINGLEATTRIBUTE, m.ObjectNamespace, m.Namespaces)
			
			CASE m.ProcessingLevel = VFP_SINGLEATTRIBUTE
				* if processing a single attribute, prepare its value to be inserted
				m.Element.text = TRANSFORM(NVL(EVALUATE(m.ChildReference),""))

			CASE m.ChildType == XML_ISELEMENT
				* go deeper in the element processing
				IF m.ProcessingLevel = VFP_DOCUMENT
					This.ReadVFPTree(m.ObjectName, EVALUATE(m.ChildReference), m.ObjDocument, m.ObjDocument, VFP_ELEMENT, m.ObjectNamespace, m.Namespaces)
				ELSE
					This.ReadVFPTree(m.ObjectName, EVALUATE(m.ChildReference), m.Element, m.ObjDocument, VFP_ELEMENT, m.ObjectNamespace, m.Namespaces)
				ENDIF

			CASE m.ChildType == XML_ISTEXT
				* store a text node
				m.TextNode = m.ObjDocument.createNode(NODE_TEXT, "", "")
				m.TextNode.text = TRANSFORM(NVL(EVALUATE(m.ChildReference),""))
				IF m.ProcessingLevel = VFP_DOCUMENT
					m.ObjDocument.appendChild(m.TextNode)
				ELSE
					m.Element.appendChild(m.TextNode)
				ENDIF

			CASE m.ChildType == XML_ISCDATA
				* store a CDATA node
				m.CDATANode = m.ObjDocument.createNode(NODE_CDATA, "", "")
				m.CDATANode.text = TRANSFORM(NVL(EVALUATE(m.ChildReference),""))
				m.Element.appendChild(m.CDATANode)

			CASE m.ChildType == XML_ISPI AND m.WriteProcessingInstructions
				* store a processing instruction node
				m.ObjectName = EVALUATE(m.ChildReference + ".xmlname")
				IF !m.ObjectName == "xml"
					m.ProcessingInstructionNode = m.ObjDocument.createProcessingInstruction(m.ObjectName, EVALUATE(m.ChildReference + ".xmltext.item(1)"))
					IF m.ProcessingLevel = VFP_DOCUMENT
						m.ObjDocument.appendChild(m.ProcessingInstructionNode)
					ELSE
						m.Element.appendChild(m.ProcessingInstructionNode)
					ENDIF
				ENDIF

			CASE m.ChildType == XML_ISCOMMENT AND m.WriteComments
				* store a comment node
				m.CommentNode = m.ObjDocument.createComment(EVALUATE(m.ChildReference + ".xmltext.item(1)"))
				IF m.ProcessingLevel = VFP_DOCUMENT
					m.ObjDocument.appendChild(m.CommentNode)
				ELSE
					m.Element.appendChild(m.CommentNode)
				ENDIF

			ENDCASE

		ENDFOR
		
		* the built node can now be appended (as an element or as an attribute) to the current node of the document tree
		DO CASE
		CASE m.ProcessingLevel = VFP_ELEMENT

			m.ObjNode.appendChild(m.Element)

		CASE m.ProcessingLevel = VFP_SINGLEATTRIBUTE

			m.ObjNode.attributes.setNamedItem(m.Element)

		ENDCASE

	ENDFUNC

	* _newVFPNode()
	* creates a new VFP Node
	HIDDEN FUNCTION _newVFPNode (Name AS String, Texts AS Collection, Namespace AS String, Prefixes AS Collection, Position AS Integer) AS Empty

		LOCAL NewVFPNode AS Empty
		
		m.NewVFPNode = CREATEOBJECT("Empty")
		ADDPROPERTY(m.NewVFPNode, XML_NAME, m.Name)
		ADDPROPERTY(m.NewVFPNode, XML_TEXT, m.Texts)
		ADDPROPERTY(m.NewVFPNode, XML_NAMESPACE, m.NameSpace)
		ADDPROPERTY(m.NewVFPNode, XML_PREFIXES, m.Prefixes)
		ADDPROPERTY(m.NewVFPNode, XML_POSITION, m.Position)

		RETURN m.NewVFPNode

	ENDFUNC

	* _newProcessingInstruction
	* stores a new processing instruction in the VFP object
	HIDDEN FUNCTION _newProcessingInstruction (VFPObject AS Object, Name AS String, Text AS String, PICount AS Integer, Position AS Integer) AS Integer

		LOCAL NewPI AS Empty
		LOCAL NewPICount AS Integer
		LOCAL Texts AS Collection
		LOCAL ProcessingInstructions AS String

		m.Texts = CREATEOBJECT("Collection")
		m.Texts.Add(m.Text, XML_ISTEXT + "1")

		m.NewPI = This._newVFPNode(m.Name, m.Texts, .NULL., .NULL., m.Position)

		m.NewPICount = m.PICount + 1
		m.ProcessingInstructions = XML_PI + "[" + TRANSFORM(m.NewPICount) + "]"

		IF m.NewPICount = 1
			* no processing instructions yet?
			ADDPROPERTY(m.VFPObject, m.ProcessingInstructions)
		ELSE
			* add to the already existing array, if this was not the first
			DIMENSION m.VFPObject.&ProcessingInstructions.
		ENDIF

		m.VFPObject.&ProcessingInstructions. = m.NewPI

		RETURN m.NewPICount

	ENDFUNC

	* _newComment
	* stores a new comment in the VFP object
	HIDDEN FUNCTION _newComment (VFPObject AS Object, Text AS String, CommentCount AS Integer, Position AS Integer) AS Integer

		LOCAL NewComment AS Empty
		LOCAL NewCommentCount AS Integer
		LOCAL Texts AS Collection
		LOCAL Comments AS String

		m.Texts = CREATEOBJECT("Collection")
		m.Texts.Add(m.Text, XML_ISTEXT + "1")

		m.NewComment = This._newVFPNode(.NULL., m.Texts, .NULL., .NULL., m.Position)

		m.NewCommentCount = m.CommentCount + 1
		m.Comments = XML_COMMENT + "[" + TRANSFORM(m.NewCommentCount) + "]"

		IF m.NewCommentCount = 1
			* no comments yet?
			ADDPROPERTY(m.VFPObject, m.Comments)
		ELSE
			* add to the already existing array, if this was not the first
			DIMENSION m.VFPObject.&Comments.
		ENDIF

		m.VFPObject.&Comments. = m.NewComment

		RETURN m.NewCommentCount

	ENDFUNC

	* _prepareVFPNodeToXML
	* adds a VFP node to the collection of nodes that will be serialized into XML
	HIDDEN FUNCTION _prepareVFPNodeToXML (ObjSource AS anyVFPObject, Out AS Collection, TypeOfXMLNode AS Character, NodeReference AS String, NoPosition AS String)
	
		IF TYPE(m.NodeReference + ".xmlposition") == "N"
			m.Out.Add(m.TypeOfXMLNode + m.NodeReference, TRANSFORM(EVALUATE(m.NodeReference + ".xmlposition"), SORTFORMAT))
		ELSE
			m.Out.Add(m.TypeOfXMLNode + m.NodeReference, m.NoPosition)
		ENDIF

	ENDFUNC

ENDDEFINE
