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
*	m.VFP = m.XMLSerializer.GetSimpleCopy(VFPObject AS Object[, Options AS Integer])
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
*			(note that order may become _order, if an array, because order is not allowed as a VFP array property name)
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
IF _VFP.StartMode = 0
	DO LOCFILE("namer.prg")
ELSE
	DO namer.prg
ENDIF

* install itself
IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-serializer-class.h"

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSerializer AS Custom

	ADD OBJECT DomainNamer AS Namer

	_memberdata = '<VFPData>' + ;
						'<memberdata name="xmltovfp" type="method" display="XMLtoVFP"/>' + ;
						'<memberdata name="vfptoxml" type="method" display="VFPtoXML"/>' + ;
						'<memberdata name="gettext" type="method" display="GetText"/>' + ;
						'<memberdata name="getsimplecopy" type="method" display="GetSimpleCopy"/>' + ;
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
	DIMENSION DataTypes[6]
	DataTypes[1] = XMLT_TEXT
	DataTypes[2] = XMLT_CDATA
	DataTypes[3] = XMLT_ELEMENT
	DataTypes[4] = XMLT_PI
	DataTypes[5] = XMLT_COMMENT
	DataTypes[6] = XMLT_DTD
	DIMENSION XMLProperties[9]
	XMLProperties[1] = XMLP_NAME
	XMLProperties[2] = XMLP_TEXT
	XMLProperties[3] = XMLP_NS
	XMLProperties[4] = XMLP_PREFIXES
	XMLProperties[5] = XMLP_POSITION
	XMLProperties[6] = XMLP_COUNT
	XMLProperties[7] = XMLP_ATTRIBUTES
	XMLProperties[8] = XMLP_QNAME
	XMLProperties[9] = XMLP_SOURCE
	
	HIDDEN _Op_WhiteSpace
	HIDDEN _Op_ProcessingInstruction
	HIDDEN _Op_Comment
	HIDDEN _Op_DTD

	_Op_WhiteSpace  =.F.
	_Op_ProcessingInstruction = .F.
	_Op_Comment = .F.
	_Op_DTD = .F.

	FUNCTION Init
	
		SAFETHIS

		* set the name translators for VFP and XML
		This.DomainNamer.AttachProcessor("VFPNamer", LOCFILE("vfp-names.prg"))
		This.DomainNamer.AttachProcessor("XMLNamer", LOCFILE("xml-names.prg"))

		* this is the XML parser (serialized XML DOM objects are created when needed)
		This.Parser = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		This.Parser.Async = .F.

		RETURN .T.

	ENDFUNC

	***************************************************************************************************
	* SetOption
	
	* Sets an option
	***************************************************************************************************
	FUNCTION SetOption (Option AS String, OptionValue AS AnyType)

		SAFETHIS

		DO CASE
		CASE m.Option == XMLSERIAL_WHITESPACE
			This._Op_WhiteSpace = m.OptionValue

		CASE m.Option == XMLSERIAL_PROCESSINGINSTRUCTIONS
			This._Op_ProcessingInstruction = m.OptionValue

		CASE m.Option == XMLSERIAL_COMMENTS
			This._Op_Comment = m.OptionValue

		CASE m.Option == XMLSERIAL_DTD
			This._Op_DTD = m.OptionValue

		ENDCASE

	ENDFUNC

	***************************************************************************************************
	* GetOption
	
	* Returns an option value
	***************************************************************************************************
	FUNCTION GetOption (Option AS String)

		SAFETHIS

		DO CASE
		CASE m.Option == XMLSERIAL_WHITESPACE
			RETURN This._Op_WhiteSpace

		CASE m.Option == XMLSERIAL_PROCESSINGINSTRUCTIONS
			RETURN This._Op_ProcessingInstruction

		CASE m.Option == XMLSERIAL_COMMENTS
			RETURN This._Op_Comment

		CASE m.Option == XMLSERIAL_DTD
			RETURN This._Op_DTD

		ENDCASE

		RETURN .NULL.

	ENDFUNC

	***************************************************************************************************
	* XMLtoVFP
	
	* Source
	*	- a URL, or file name, or string, with the XML to process
	* XPath
	*	- an XPath expression that resolves to a node list
	* Namespaces
	*	- a string or a collection of keyed namespaces to resolve prefix references in XPath
	
	* Returns a VFP Empty-based object, or .NULL., if errors during loading of the document
	***************************************************************************************************
	FUNCTION XMLtoVFP AS Empty
	LPARAMETERS Source AS StringURLorDOM, XPath AS String, Namespaces AS CollectionOrString

		SAFETHIS

		ASSERT VARTYPE(m.Source) $ "CO" MESSAGE "Source must be a string or an object."
		ASSERT PCOUNT() < 2 OR VARTYPE(m.XPath) == "C" MESSAGE "XPath must be a string expression."
		ASSERT PCOUNT() < 3 OR VARTYPE(m.Namespaces) $ "CO" MESSAGE "Namespaces must be a string or an object."

		LOCAL VFPObject AS Empty
		LOCAL SourceObject AS MSXML2.DOMDocument60
		LOCAL SourceTree AS MSXML2.IXMLDOMNodeList
		LOCAL XPathError AS Exception
		LOCAL CurrentNS AS String
		LOCAL SelectionNS AS String
		LOCAL LoopIndex AS Integer

		This.XMLError = ""
		This.XMLLine = 0

		* if an XMLDOM object was passed, use it as the source
		IF VARTYPE(m.Source) == "O"

			m.SourceObject = m.Source

		ELSE

			* follow white space setting
			This.Parser.preserveWhiteSpace = This._Op_WhiteSpace
			* and DTD also
			This.Parser.setProperty("ProhibitDTD", !This._Op_DTD)
			This.Parser.validateOnParse = !This._Op_DTD

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

		IF EMPTY(This.XMLError)

			* if an XPath parameter was passed, use it to set the root of the serialization
			IF !EMPTY(m.XPath)

				TRY
					* the namespaces used in the XPath expression may be set as a string or as a collection 
					IF PCOUNT() = 3
						m.CurrentNS = m.SourceObject.getProperty("SelectionNamespaces")
						IF VARTYPE(m.Namespaces) == "C"
							m.SelectionNS = m.Namespaces
						ELSE
							m.SelectionNS = ""
							FOR m.LoopIndex = 1 TO m.Namespaces.Count
								m.SelectionNS = m.SelectionNS + TEXTMERGE("xmlns:<<m.Namespaces.GetKey(m.LoopIndex)>>='<<m.Namespaces.Item(m.LoopIndex)>>' ")
							ENDFOR
						ENDIF
						m.SourceObject.setProperty("SelectionNamespaces", m.SelectionNS)
					ENDIF

					* get the node list to serialize
					m.SourceTree = m.SourceObject.selectNodes(m.XPath)

					* restore the namespaces in use for selection
					IF PCOUNT() = 3
						m.SourceObject.setProperty("SelectionNamespaces", m.CurrentNS)
					ENDIF

				CATCH TO m.XPathError
					This.XMLError = m.XPathError.Message
					This.XMLLine = -1
				ENDTRY

			ELSE

				* serialize nodes starting at the root, if a DOMDocument
				IF ISNULL(m.SourceObject.ownerDocument)
					m.SourceTree = m.SourceObject.childNodes()
				* otherwise, serialize the XML fragment at the context point of the tree
				ELSE
					m.SourceTree = m.SourceObject.selectNodes(".")
				ENDIF

			ENDIF

		ENDIF


		* if the document was parsed
		IF EMPTY(This.XMLError)

			m.VFPObject = CREATEOBJECT("Empty")
			* read the tree and put it in a VFP object
			This.ReadXMLTree(m.SourceTree, m.VFPObject, .T.)
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

		ASSERT VARTYPE(m.Source) = "O" MESSAGE "Source must be an object."
		ASSERT PCOUNT() = 1 OR VARTYPE(m.Root) = "C" MESSAGE "Root name must be a string."

		LOCAL XMLObject AS MSXML2.DOMDocument60
		LOCAL Namespaces AS Collection
		LOCAL XMLDeclaration AS MSXML2.IXMLDOMProcessingInstruction
		LOCAL NsDeclaration AS MSXML2.IXMLDOMAttribute
		LOCAL LoopIndex AS String

		LOCAL ARRAY Properties[1]
		LOCAL RootProperty AS Integer
		LOCAL PropertyCount AS Integer
		LOCAL PropertiesIndex AS Integer
		LOCAL DTDProperty AS Integer

		LOCAL ExactSetting AS String

		DO CASE

		* source must be an active VFP object
		CASE VARTYPE(m.Source) != "O" OR ISNULL(m.Source)
			RETURN .NULL.
			
		CASE PCOUNT() = 1

			m.ExactSetting = SET("Exact")
			SET EXACT ON

			* there must be a single root at the top of the object property tree
			m.RootProperty = 0
			* no DTD, yet
			m.DTDProperty = 0

			* look for the root (ignoring sibling processing instructions, and comments)
			PropertyCount = AMEMBERS(m.Properties, m.Source, 0, "U")
			FOR m.PropertiesIndex = 1 TO m.PropertyCount
				IF !INLIST(LOWER(m.Properties[m.PropertiesIndex]), XML_DTD, XML_PI, XML_COMMENT, XML_ORPHANTEXT)
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
		m.XMLObject.preserveWhiteSpace = This._Op_WhiteSpace

		m.XMLDeclaration = m.XMLObject.createProcessingInstruction("xml", 'version="1.0" encoding="utf-8"')
		m.XMLObject.appendChild(m.XMLDeclaration)

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

		ASSERT VARTYPE(m.Element) == "O" MESSAGE "Element must be an object."

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

		ASSERT VARTYPE(m.Element) == "O" MESSAGE "Element must be an object."

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

		ASSERT VARTYPE(m.Element) == "O" MESSAGE "Element must be an object."
		ASSERT VARTYPE(m.Options) $ "LN" MESSAGE "Options must be logical or a number."

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
		IF VARTYPE(m.Options) == "L"
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
					ADDPROPERTY(m.SimpleCopy, m.Property + "[" + LTRIM(STR(m.ArrayLength)) + "]")
					IF m.Options = 0
						* and a sibling <name>_value_[], to hold values if needed
						ADDPROPERTY(m.SimpleCopy, m.Property + XML_SIMPLETEXT + "[" + LTRIM(STR(m.ArrayLength)) + "]")
						* for now, there are no values assigned to this new array
						m.ArrayNoValues = .T.
					ENDIF

					* go through each member of the array
					FOR m.LoopArrayIndex = 1 TO m.ArrayLength
					
						* create a reference to it
						m.ArrayProperty = m.Property + "[" + LTRIM(STR(m.LoopArrayIndex)) + "]"
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
							m.ArrayProperty = m.Property + XML_SIMPLETEXT +"[" + LTRIM(STR(m.LoopArrayIndex)) + "]"
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
	LPARAMETERS XMLNodes AS MSXML2.IXMLDOMNodeList, VFPObject AS Object, IsDocument AS Boolean

		SAFETHIS

		* to traverse the XML document tree
		LOCAL Node AS MSXML2.IXMLDOMNode
		LOCAL NodeIndex AS Integer
		LOCAL NameSpace AS String
		LOCAL Prefix AS String
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
		LOCAL Source AS Collection

		* name, value and xml representation of a point in the tree
		LOCAL NewName AS String
		LOCAL NewValue AS Empty
		LOCAL NewNode AS Boolean
		
		* to manipulate arrays of elements
		LOCAL CheckArray AS String
		LOCAL NewArrayName AS String
		LOCAL ToArray AS Boolean
		LOCAL TempValue AS Empty

		* read DTD?
		LOCAL ReadDTDs AS Boolean
		LOCAL DTDs AS Integer
		* read processing instructions?
		LOCAL ReadProcessingInstructions AS Boolean
		LOCAL ProcessingInstructions AS Integer
		* read comments?
		LOCAL ReadComments AS Boolean
		LOCAL Comments AS Integer
		* read orphan texts?
		LOCAL ReadOrphanTexts AS Boolean
		LOCAL OrphanTexts AS Integer

		m.NodeIndex = 0

		m.ReadDTDs = m.IsDocument AND This._Op_DTD
		m.ReadOrphanTexts = m.IsDocument AND This._Op_WhiteSpace
		m.ReadProcessingInstructions = This._Op_ProcessingInstruction
		m.ReadComments = This._Op_Comment

		STORE 0 TO m.ProcessingInstructions, m.Comments, m.OrphanTexts, m.DTDs

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

							* prepare the collection of prefixes, if not done already
							IF ISNULL(m.Prefixes)
								m.Prefixes = CREATEOBJECT("Collection")
							ENDIF

							* if not prefixed, use a default prefix key for the entry
							IF m.NameSpaceDeclaration.baseName == m.NameSpaceDeclaration.nodeName
								m.Prefix = ":"
							ELSE
								m.Prefix = m.NameSpaceDeclaration.baseName
							ENDIF

							* add the (prefixed?) namespace to the collection
							m.Prefixes.Add(m.NameSpaceDeclaration.text, m.Prefix)
						ENDIF
					ENDFOR

					* check if there are any attributes that are not namespaces
					m.Attributes = .selectNodes("@*[namespace-uri(.) != 'http://www.w3.org/2000/xmlns/']")
					m.HasAttributes = m.Attributes.length > 0

					m.TextNodeIndex = 0
					m.Texts = .NULL.
					m.Source = .NULL.

					* traverse all children, looking for text nodes
					FOR EACH m.TextNode IN .childNodes

						m.TextNodeIndex = m.TextNodeIndex + 1

						* if a text or CDATA child was found
						IF INLIST(m.TextNode.nodeType, NODE_TEXT, NODE_CDATA)

							* insert it in the texts collection, with its position marked
							IF ISNULL(m.Texts)
								m.Texts = CREATEOBJECT("Collection")
								m.Source = CREATEOBJECT("Collection")
							ENDIF
							m.Texts.Add(m.TextNode.text, IIF(m.TextNode.nodeType = NODE_TEXT, XML_ISTEXT, XML_ISCDATA) + LTRIM(STR(m.TextNodeIndex)))
							m.Source.Add(m.TextNode.xml, IIF(m.TextNode.nodeType = NODE_TEXT, XML_ISTEXT, XML_ISCDATA) + LTRIM(STR(m.TextNodeIndex)))

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
					m.Source = CREATEOBJECT("Collection")
					m.Source.Add(.xml, XML_ISTEXT + "1")

					* attributes may have a namespace
					m.NameSpace = EVL(.namespaceURI, .NULL.)

				CASE .nodeType = NODE_DTD AND m.ReadDTDs
					m.DTDs = This._newDTD(m.VFPObject, .parentNode.doctype.xml, m.DTDs, m.NodeIndex)
					LOOP

				CASE .nodeType = NODE_PROCINSTRUCTION AND m.ReadProcessingInstructions
					m.ProcessingInstructions = This._newProcessingInstruction(m.VFPObject, .nodeName, .nodeValue, m.ProcessingInstructions, m.NodeIndex)
					LOOP

				CASE .nodeType = NODE_COMMENT AND m.ReadComments
					m.Comments = This._newComment(m.VFPObject, .nodeValue, m.Comments, m.NodeIndex)
					LOOP

				* orphan text nodes are located at the document level
				CASE .nodeType = NODE_TEXT AND m.ReadOrphanTexts
					m.OrphanTexts = This._newOrphanText(m.VFPObject, .nodeValue, .xml, m.OrphanTexts, m.NodeIndex)
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
				*		- the original names
				*		- the text section(s) of the node
				*		- the namespace
				*		- the prefixes
				* 		- and its position, in the tree
				m.NewValue = This._newVFPNode(.nodeName, m.Texts, m.Source, m.NameSpace, m.Prefixes, m.NodeIndex)
				
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
					IF .specified AND .selectNodes(m.CheckArray).length <= 1
					
						* add a regular property to this level of the current object
						ADDPROPERTY(m.VFPObject, m.NewName, m.NewValue)
						* that will be used as a root for further processing
						m.NodeVFPRoot = EVALUATE("m.VFPObject." + m.NewName)
					
					ELSE
					
						* get a name, again, now safe for array names
						This.DomainNamer.SetProperty("VFPNamer", "SafeArrayName", .T.)
						This.DomainNamer.SetProperty("VFPNamer", "AllowReserved", .F.)
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
						This.DomainNamer.SetProperty("VFPNamer", "AllowReserved", .F.)
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
					m.NewName = m.NewName + "[" + LTRIM(STR(ALEN(m.VFPObject.&NewName.) + 1)) + "]"
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
					This.ReadXMLTree(m.Attributes, m.AttributesVFPRoot, .F.)
				
				ENDIF
				
				* if there are children to process
				IF .childNodes.length > 0
				
					* use the current node as the root of the XML tree
					This.ReadXMLTree(.childNodes, m.NodeVFPRoot, .F.)
				
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
		LOCAL WriteDTDs AS Boolean

		m.WriteProcessingInstructions = This._Op_ProcessingInstruction
		m.WriteComments = This._Op_Comment
		m.WriteDTDs = This._Op_DTD			&& not used

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
						m.Prefix = "ns" + LTRIM(STR(m.Namespaces.Count + 1))
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
		IF VARTYPE(m.ObjSource) == "O" AND !ISNULL(m.ObjSource) AND AMEMBERS(m.Properties, m.ObjSource, 0, "U") != 0

			* will be processed	
			FOR m.Loop = 1 TO ALEN(m.Properties)

				* but disregard the XML* properties and other members which are not value properties
				IF (LEFT(m.Properties[m.Loop], 3) != "XML" OR ;
							m.Properties[m.Loop] == UPPER(XML_PI) OR ;
							m.Properties[m.Loop] == UPPER(XML_COMMENT) OR ;
							(m.ProcessingLevel = VFP_DOCUMENT AND m.Properties[m.Loop] == UPPER(XML_ORPHANTEXT))) ;
						AND TYPE("m.ObjSource." + m.Properties[m.Loop]) != "U"

					DO CASE
					CASE m.Properties[m.Loop] == UPPER(XML_PI)
						m.ChildType = XML_ISPI
					CASE m.Properties[m.Loop] == UPPER(XML_COMMENT)
						m.ChildType = XML_ISCOMMENT
					CASE m.Properties[m.Loop] == UPPER(XML_ORPHANTEXT)
						m.ChildType = XML_ISTEXT
					OTHERWISE
						m.ChildType = XML_ISELEMENT
					ENDCASE

					m.ChildReference = "m.ObjSource." + m.Properties[m.Loop]

					IF TYPE(m.ChildReference, 1) = "A"

						* if it is an array, process every element
						FOR m.ArrayLoop = 1 TO ALEN(&ChildReference.)
							m.ChildElementReference = m.ChildReference + "[" + LTRIM(STR(m.ArrayLoop)) + "]"
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

					m.ChildReference = "m.ObjSource.xmltext.Item(" + LTRIM(STR(m.TextLoop)) + ")"
					m.TextPosition = EVALUATE("m.ObjSource.xmltext.GetKey(" + LTRIM(STR(m.TextLoop)) + ")")
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
	HIDDEN FUNCTION _newVFPNode (Name AS String, Texts AS Collection, Source AS Collection, Namespace AS String, Prefixes AS Collection, Position AS Integer) AS Empty

		LOCAL NewVFPNode AS Empty
		
		m.NewVFPNode = CREATEOBJECT("Empty")
		ADDPROPERTY(m.NewVFPNode, XML_NAME, IIF(!ISNULL(m.Name) AND ":" $ m.Name, SUBSTR(m.Name, AT(":", m.Name) + 1), m.Name))
		ADDPROPERTY(m.NewVFPNode, XML_TEXT, m.Texts)
		ADDPROPERTY(m.NewVFPNode, XML_NAMESPACE, m.NameSpace)
		ADDPROPERTY(m.NewVFPNode, XML_PREFIXES, m.Prefixes)
		ADDPROPERTY(m.NewVFPNode, XML_POSITION, m.Position)
		ADDPROPERTY(m.NewVFPNode, XML_QNAME, IIF(!ISNULL(m.Name) AND ":" $ m.Name, m.Name, .NULL.))
		ADDPROPERTY(m.NewVFPNode, XML_SOURCE, m.Source)

		RETURN m.NewVFPNode

	ENDFUNC

	* _newIndependentNode
	* stores a new independent node
	HIDDEN FUNCTION _newIndependentNode (VFPObject AS Object, NodeType AS String, Name AS String, Text AS String, Source AS String, Count AS Integer, Position AS Integer) AS Integer

		LOCAL NewNode AS Empty
		LOCAL NewCount AS Integer
		LOCAL Texts AS Collection
		LOCAL XML AS Collection
		LOCAL Nodes AS String

		* get the text node
		m.Texts = CREATEOBJECT("Collection")
		m.Texts.Add(m.Text, XML_ISTEXT + "1")
		IF !ISNULL(m.Source)
			m.XML = CREATEOBJECT("Collection")
			m.XML.Add(m.Source, XML_ISTEXT + "1")
		ELSE
			m.XML = .NULL.
		ENDIF

		m.NewNode = This._newVFPNode(m.Name, m.Texts, m.XML, .NULL., .NULL., m.Position)

		m.NewCount = m.Count + 1
		m.Nodes = m.NodeType + "[" + LTRIM(STR(m.NewCount)) + "]"

		IF m.NewCount = 1
			* no nodes yet?
			ADDPROPERTY(m.VFPObject, m.Nodes)
		ELSE
			* add to the already existing array of nodes, if this was not the first
			DIMENSION m.VFPObject.&Nodes.
		ENDIF

		m.VFPObject.&Nodes. = m.NewNode

		RETURN m.NewCount

	ENDFUNC

	* _newProcessingInstruction
	* stores a new processing instruction in the VFP object
	HIDDEN FUNCTION _newProcessingInstruction (VFPObject AS Object, Name AS String, Text AS String, PICount AS Integer, Position AS Integer) AS Integer

		RETURN This._newIndependentNode(m.VFPObject, XML_PI, m.Name, m.Text, .NULL., m.PICount, m.Position)

	ENDFUNC

	* _newDTD
	* stores a new DTD in the VFP object
	HIDDEN FUNCTION _newDTD (VFPObject AS Object, Text AS String, DTDCount AS Integer, Position AS Integer) AS Integer

		RETURN This._newIndependentNode(m.VFPObject, XML_DTD, .NULL., m.Text, .NULL., m.DTDCount, m.Position)

	ENDFUNC

	* _newComment
	* stores a new comment in the VFP object
	HIDDEN FUNCTION _newComment (VFPObject AS Object, Text AS String, CommentCount AS Integer, Position AS Integer) AS Integer

		RETURN This._newIndependentNode(m.VFPObject, XML_COMMENT, .NULL., m.Text, .NULL., m.CommentCount, m.Position)

	ENDFUNC

	* _newOrphanText
	* stores a new orphan text in the VFP object
	HIDDEN FUNCTION _newOrphanText (VFPObject AS Object, Text AS String, Source AS String, OrphanTextCount AS Integer, Position AS Integer) AS Integer

		RETURN This._newIndependentNode(m.VFPObject, XML_ORPHANTEXT, .NULL., m.Text, m.Source, m.OrphanTextCount, m.Position)

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
