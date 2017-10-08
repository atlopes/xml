*
* XMLCanonicalizer
*
* A class to canonicalize an XML document.
*
* Methods:
*	m.VFP = m.XMLCanonicalizer.Canonicalize (Source AS String)
*		Retrieves an XML document (from a string, an URL or a file) and returns its canonicalized version
*		Reference: https://www.w3.org/TR/xml-c14n
*
* Dependencies:
*		XMLSerializer
*
* Load:
*		SET PROCEDURE TO xml-canonicalizer.prg ADDITIVE
*	or
*		DO xml-canonicalizer.prg
*
* Use:
*		m.XMLCanonicalizer = CREATEOBJECT("XMLCanonicalizer")
*

* dependency on XMLSerializer class
DO (LOCFILE("xml-serializer.prg"))

* install itself
IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-serializer-class.h"

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLCanonicalizer AS Custom

	ADD OBJECT Serializer AS XMLSerializer
	
	HIDDEN Trimmer
	Trimmer = .F.
	HIDDEN NMToken
	HIDDEN NMTokens
	NMToken = .NULL.
	NMTokens = .NULL.

	_memberdata = '<VFPData>' + ;
						'<memberdata name="setoption" type="method" display="SetOption"/>' + ;
						'<memberdata name="getoption" type="method" display="GetOption"/>' + ;
						'<memberdata name="canonicalize" type="method" display="Canonicalize"/>' + ;
						'<memberdata name="serializer" type="property" display="Serializer"/>' + ;
						'</VFPData>'

	FUNCTION Init

		This.Serializer.SetOption(XMLSERIAL_WHITESPACE, .T.)
		This.Serializer.SetOption(XMLSERIAL_PROCESSINGINSTRUCTIONS, .T.)
		This.Serializer.SetOption(XMLSERIAL_COMMENTS, .F.)
		This.Serializer.SetOption(XMLSERIAL_DTD, .T.)
		This.Trimmer = .F.

		RETURN .T.

	ENDFUNC

	***************************************************************************************************
	* SetOption
	
	* Sets an option
	***************************************************************************************************
	FUNCTION SetOption (Option AS String)

		SAFETHIS

		DO CASE
		CASE m.Option == "Default"
			This.Init()

		CASE m.Option == "Comment"
			This.Serializer.SetOption(XMLSERIAL_COMMENTS, .T.)

		CASE m.Option == "Trim"
			This.Trimmer = .T.

		ENDCASE
		
	ENDFUNC

	***************************************************************************************************
	* Canonicalize
	
	* Source
	*	- an URL, or file name, or string, with the XML to process
	
	* Returns a canonicalized XML document, or .NULL., if errors during loading of the document
	***************************************************************************************************
	FUNCTION Canonicalize AS String
	LPARAMETERS Source AS StringURLorDOM

		SAFETHIS

		ASSERT TYPE("m.Source") $ "CO" MESSAGE "Source must be a string or an object."

		LOCAL VFPObject AS Empty
		LOCAL Canonicalized AS String

		* try to serialize the source document/object

		m.VFPObject = This.Serializer.XMLtoVFP(m.Source)

		IF !ISNULL(m.VFPObject)

			This.NMToken = CREATEOBJECT("Collection")
			This.NMTokens = CREATEOBJECT("Collection")

			* if succeeded, it may be canonicalized
			m.Canonicalized = This.CanonicalizeVFPTree(m.VFPObject, VFP_DOCUMENT, "", .NULL.)

		ELSE

			* report failure
			* error details in .Serializer.XMLError
			m.Canonicalized = .NULL.

		ENDIF

		This.NMToken = .NULL.
		This.NMTokens = .NULL.

		RETURN m.Canonicalized

	ENDFUNC

	* CanonicalizeVFPTree - process an object / property and its children

	* ObjSource - a point in the VFP object hierarchy
	* ProcessingLevel - what is being processed at this level
	* ParentNamespace - the namespace of the parent element
	* Namespaces - the collection of namespaces referred so far
	HIDDEN FUNCTION CanonicalizeVFPTree AS String
	LPARAMETERS ObjSource AS SerializedVFPObject, ProcessingLevel AS Integer, ParentNamespace AS String, Namespaces AS Collection

		* the canonicalized element
		LOCAL Element AS String
		LOCAL ElementName AS String
		LOCAL Attributes AS Collection
		LOCAL XMLNS AS Collection
		LOCAL KeyIndex AS Integer
		LOCAL ItemReference

		* the properties of the VFP object, at this point of the hierarchy
		LOCAL ARRAY Properties[1]
		LOCAL ObjectName AS String
		LOCAL ObjectContents AS String
		LOCAL Root AS Boolean

		* how a child of this VFP object is referred
		LOCAL ChildReference AS String

		* types: e - element, t - text, c - cdata, p - processing instruction, # - comments (attributes are treated by the AttributeLevel parameter)
		LOCAL ChildType AS String

		* child reference when child is an array
		LOCAL ChildElementReference AS String
		
		* child object
		LOCAL ChildObject AS Object

		* the original positions of the XML elements, keyed by type (e-t-c-p-#) and reference
		LOCAL Positions AS Collection

		* the original positions of XML textual nodes (text and CDATA)
		LOCAL TextPosition AS String

		* loop indexers
		LOCAL Loop AS Integer
		LOCAL ArrayLoop AS Integer
		LOCAL TextLoop AS Integer

		* copy of namespaces collections
		LOCAL MyNamespaces AS Collection

		* create a local instantiation of the namespaces collection
		IF m.ProcessingLevel = VFP_ELEMENT
			m.MyNamespaces = CREATEOBJECT("Collection")
			IF ISNULL(m.Namespaces)
				m.MyNamespaces.Add("", ":")
			ELSE
				FOR m.Loop = 1 TO m.Namespaces.Count
					m.MyNamespaces.Add(m.Namespaces.Item(m.Loop), m.Namespaces.GetKey(m.Loop))
				ENDFOR
			ENDIF

			m.XMLNS = CREATEOBJECT("Collection")
			m.Attributes = CREATEOBJECT("Collection")

			* names of the node
			m.ElementName = NVL(m.ObjSource.xmlqname, m.ObjSource.xmlname)

			This._visibleNS(m.ElementName, m.ObjSource.xmlns, m.MyNamespaces, m.XMLNS)

			IF TYPE("m.ObjSource.xmlattributes") != "U"
				FOR m.Loop = 1 TO AMEMBERS(m.Properties, m.ObjSource.xmlattributes, 0, "U")
					IF !LEFT(m.Properties[m.Loop], 3) == "XML"

						m.ChildReference = "m.ObjSource.xmlattributes." + m.Properties[m.Loop]

						IF TYPE(m.ChildReference, 1) = "A"

							* if it is an array, process the namespace of every element
							FOR m.ArrayLoop = 1 TO ALEN(&ChildReference.)
								m.ChildElementReference = m.ChildReference + "[" + TRANSFORM(m.ArrayLoop) + "]"
								m.ChildObject = EVALUATE(m.ChildElementReference)
								m.ObjectName = NVL(m.ChildObject.xmlqname, m.ChildObject.xmlname)
								This._visibleNS(m.ObjectName, m.ChildObject.xmlns, m.MyNamespaces, m.XMLNS)
								m.ObjectContents = This._canonAttribute(m.ObjSource.xmlname, m.ObjectName, m.ChildObject.xmltext.item(1))
								m.Attributes.Add(m.ObjectContents, PADR(NVL(m.ChildObject.xmlns, ":") + m.ChildObject.xmlname, 200))
							ENDFOR
						ELSE
							* do the same for single objects that are not part of arrays
							m.ChildObject = EVALUATE(m.ChildReference)
							m.ObjectName = NVL(m.ChildObject.xmlqname, m.ChildObject.xmlname)
							This._visibleNS(m.ObjectName, m.ChildObject.xmlns, m.MyNamespaces, m.XMLNS)
							m.ObjectContents = This._canonAttribute(m.ObjSource.xmlname, m.ObjectName, m.ChildObject.xmltext.item(1))
							m.Attributes.Add(m.ObjectContents, PADR(NVL(m.ChildObject.xmlns, ":") + m.ChildObject.xmlname, 200))
						ENDIF
					ENDIF
				ENDFOR
			ENDIF

			m.Element = "<" + m.ElementName
			IF m.XMLNS.Count > 0
				m.XMLNS.KeySort = 2
				FOR EACH m.ItemReference IN m.XMLNS
					m.Element = m.Element + " " + m.ItemReference 
				ENDFOR
			ENDIF
					
			IF m.Attributes.Count > 0
				m.Attributes.KeySort = 2
				FOR EACH m.ItemReference IN m.Attributes
					m.Element = m.Element + " " + m.ItemReference
				ENDFOR
			ENDIF
			m.Element = m.Element + ">"

		ELSE
			m.MyNamespaces = m.Namespaces
			m.Element = ""
		ENDIF

		* collection that will filter and sort all elements back to their original XML order
		m.Positions = CREATEOBJECT("Collection")

		* the children of the current VFP object / property will be processed	
		FOR m.Loop = 1 TO AMEMBERS(m.Properties, m.ObjSource, 0, "U")

			* but disregard the XML* properties and other members which are not value properties
			IF (LEFT(m.Properties[m.Loop], 3) != "XML" OR ;
						m.Properties[m.Loop] == UPPER(XML_PI) OR ;
						m.Properties[m.Loop] == UPPER(XML_COMMENT) OR ;
						m.Properties[m.Loop] == UPPER(XML_DTD) OR ;
						(m.ProcessingLevel = VFP_DOCUMENT AND m.Properties[m.Loop] == UPPER(XML_ORPHANTEXT))) ;
					AND TYPE("m.ObjSource." + m.Properties[m.Loop]) != "U"

				DO CASE
				CASE m.Properties[m.Loop] == UPPER(XML_DTD)
					m.ChildType = XMLT_DTD
				CASE m.Properties[m.Loop] == UPPER(XML_PI)
					m.ChildType = XMLT_PI
				CASE m.Properties[m.Loop] == UPPER(XML_COMMENT)
					m.ChildType = XMLT_COMMENT
				CASE m.Properties[m.Loop] == UPPER(XML_ORPHANTEXT)
					m.ChildType = XMLT_TEXT
				OTHERWISE
					m.ChildType = XMLT_ELEMENT
				ENDCASE

				m.ChildReference = "m.ObjSource." + m.Properties[m.Loop]

				IF TYPE(m.ChildReference, 1) = "A"

					* if it is an array, process every element
					FOR m.ArrayLoop = 1 TO ALEN(&ChildReference.)
						m.ChildElementReference = m.ChildReference + "[" + TRANSFORM(m.ArrayLoop) + "]"
						This._prepareCanonXML(m.ObjSource, m.Positions, m.ChildType, m.ChildElementReference)
					ENDFOR
				ELSE
					* do the same for single objects that are not part of arrays
					This._prepareCanonXML(m.ObjSource, m.Positions, m.ChildType, m.ChildReference)
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

		* sort the positions collection by key, and iterate trough the items
		m.Positions.KeySort = 2

		IF m.ProcessingLevel = VFP_DOCUMENT
			m.Root = .F.
		ELSE
			m.Root = .T.
		ENDIF

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

			CASE m.ChildType == XMLT_ELEMENT
				* go deeper in the element processing
				IF m.ProcessingLevel = VFP_ELEMENT
					m.Element = m.Element + This.CanonicalizeVFPTree(EVALUATE(m.ChildReference), VFP_ELEMENT, m.ObjSource.xmlns, m.MyNamespaces)
				ELSE
					m.Element = m.Element + This.CanonicalizeVFPTree(EVALUATE(m.ChildReference), VFP_ELEMENT, "", .NULL.)
					m.Root = .T.
				ENDIF

			CASE m.ChildType == XMLT_TEXT
				* store a text node
				m.Element = m.Element + This._canonText(NVL(EVALUATE(m.ChildReference),""))

			CASE m.ChildType == XMLT_CDATA
				* store a CDATA node
				m.Element = m.Element + This._canonText(NVL(EVALUATE(m.ChildReference),""))

			CASE m.ChildType == XMLT_PI
				* store a processing instruction node
				m.ObjectName = EVALUATE(m.ChildReference + ".xmlname")
				IF !m.ObjectName == "xml"
					IF m.ProcessingLevel = VFP_DOCUMENT AND m.Root
						m.Element = m.Element + CHR(10)
					ENDIF
					m.Element = m.Element + "<?" + m.ObjectName
					m.ObjectContents = EVALUATE(m.ChildReference + ".xmltext.item(1)")
					IF !EMPTY(m.ObjectContents)
						m.Element = m.Element + " " + m.ObjectContents
					ENDIF
					m.Element = m.Element + "?>"
					IF m.ProcessingLevel = VFP_DOCUMENT AND !m.Root
						m.Element = m.Element + CHR(10)
					ENDIF
				ENDIF

			CASE m.ChildType == XMLT_COMMENT
				* store a comment node
				IF m.ProcessingLevel = VFP_DOCUMENT AND m.Root
					m.Element = m.Element + CHR(10)
				ENDIF
				m.Element = m.Element + "<!--" + EVALUATE(m.ChildReference + ".xmltext.item(1)") + "-->"
				IF m.ProcessingLevel = VFP_DOCUMENT AND !m.Root
					m.Element = m.Element + CHR(10)
				ENDIF

			CASE m.ChildType == XMLT_DTD

				This._setNMTokenAttributes(EVALUATE(m.ChildReference + ".xmltext.item(1)"))

			ENDCASE

		ENDFOR

		IF m.ProcessingLevel = VFP_ELEMENT
			m.Element = m.Element + "</" + m.ElementName + ">"
		ENDIF

		RETURN m.Element

	ENDFUNC

	* _prepareVFPNodeToXML
	* adds a VFP node to the collection of nodes that will be serialized into XML
	HIDDEN FUNCTION _prepareCanonXML (ObjSource AS anyVFPObject, Out AS Collection, TypeOfXMLNode AS Character, NodeReference AS String)
	
		m.Out.Add(m.TypeOfXMLNode + m.NodeReference, TRANSFORM(EVALUATE(m.NodeReference + ".xmlposition"), SORTFORMAT))

	ENDFUNC

	* _visibleNS
	* control the visibility of namespaces in the current node
	HIDDEN FUNCTION _visibleNS (ElementName AS String, Namespace AS String, CurrentNamespaces AS Collection, DeclareNamespaces AS Collection)

		LOCAL KeyIndex AS Integer
		LOCAL Prefix AS String

		IF !(":" $ m.ElementName)

			m.KeyIndex = m.CurrentNamespaces.GetKey(":")

			IF m.KeyIndex = 0
				m.DeclareNamespaces.Add('xmlns="' + m.Namespace + '"', "0")
				m.CurrentNamespaces.Add(m.Namespace, ":")
			ELSE
				IF !(m.CurrentNamespaces.Item(m.KeyIndex) == m.Namespace)
					m.DeclareNamespaces.Add('xmlns="' + m.Namespace + '"', "0")
					m.CurrentNamespaces.Remove(m.KeyIndex)
					m.CurrentNamespaces.Add(m.Namespace, ":")
				ENDIF
			ENDIF

		ELSE

			m.Prefix = LEFT(m.ElementName, AT(":", m.ElementName) - 1)

			m.KeyIndex = m.CurrentNamespaces.GetKey(m.Prefix)

			IF m.KeyIndex = 0
				m.DeclareNamespaces.Add('xmlns:' + m.Prefix + '="' + m.Namespace + '"', "1:" + m.Prefix)
				m.CurrentNamespaces.Add(m.Namespace, m.Prefix)
			ELSE
				IF !(m.CurrentNamespaces.Item(m.KeyIndex) == m.Namespace)
					m.DeclareNamespaces.Add('xmlns:' + m.Prefix + '="' + m.Namespace + '"', "1:" + m.Prefix)
					m.CurrentNamespaces.Remove(m.KeyIndex)
					m.CurrentNamespaces.Add(m.Namespace, m.PrefixPrefix)
				ENDIF
			ENDIF

		ENDIF
	ENDFUNC
	
	* _canonAttribute
	* canonicalize an attribute
	HIDDEN FUNCTION _canonAttribute (ElementName AS String, AttrName AS String, AttrValue AS String)

		LOCAL DTDName AS String
		LOCAL PostAttrValue AS String

		m.DTDName = m.ElementName + ":" + IIF(":" $ m.AttrName, SUBSTR(m.AttrName, AT(":", m.AttrName) + 1), m.AttrName) + ":"
		DO CASE
		CASE This.NMToken.GetKey(m.DTDName) != 0
			m.PostAttrValue = ALLTRIM(m.AttrValue)
		CASE This.NMTokens.GetKey(m.DTDName) != 0
			m.PostAttrValue = ALLTRIM(m.AttrValue)
			DO WHILE "  " $ m.PostAttrValue
				m.PostAttrValue = STRTRAN(m.PostAttrValue, "  ", " ")
			ENDDO
		OTHERWISE
			m.PostAttrValue = m.AttrValue
		ENDCASE

		RETURN m.AttrName + '="' + ;
			This._canonChars(STRTRAN(STRTRAN(STRTRAN(m.PostAttrValue, '&', '&' + 'amp;'), '"', '&' + 'quot;'), '<', '&' + 'lt;'), .T.) + ;
			'"'

	ENDFUNC

	* _canonText
	* canonicalize a text
	HIDDEN FUNCTION _canonText (Source AS String)

		LOCAL Canon AS String
		
		m.Canon =  STRTRAN(STRTRAN(STRTRAN(m.Source, '&', '&' + 'amp;'), '<', '&' + 'lt;'), '>', '&' + 'gt;')
		IF This.Trimmer
			m.Canon = ALLTRIM(m.Canon, 1, " ", CHR(10), CHR(13), CHR(9))
		ENDIF
		
		RETURN m.Canon
	ENDFUNC

	* _canonCDATA
	* canonicalize a CDATA section
	HIDDEN FUNCTION _canonCDATA (Source AS String)
		RETURN m.Source
	ENDFUNC

	* _canonChars
	* canonicalize characters
	HIDDEN FUNCTION _canonChars (Source AS String, LF AS Boolean)

		LOCAL Canon

		m.Canon = STRTRAN(STRTRAN(m.Source, CHR(13), "&" + "#xD;"), CHR(9), "&" + "#x9;")
		IF m.LF
			m.Canon = STRTRAN(m.Canon, CHR(10), "&" + "#xA;")
		ENDIF
		
		RETURN m.Canon
	ENDFUNC

	* _setNMTokenAttributes
	* get NMTOKEN and NMTOKENS attributes from DTD
	HIDDEN FUNCTION _setNMTokenAttributes (DTD AS String)

		LOCAL CleanDTD AS String
		LOCAL Segment AS String
		LOCAL AttIndex AS Integer
		LOCAL ElementName AS String
		LOCAL AttributeName AS String
		LOCAL AttributeType AS String
		LOCAL AttributeValue AS String
		LOCAL Delimiters AS String
		
		m.Delimiters = " " + CHR(9) + CHR(13) + CHR(10)

		* remove comments from DTD
		m.CleanDTD = m.DTD
		DO WHILE "<!--" $ m.CleanDTD
			m.Segment = STREXTRACT(m.CleanDTD, "<!--", "-->", 1, 4)
			m.CleanDTD = STRTRAN(m.CleanDTD, m.Segment, "")
		ENDDO

		DO WHILE "<!ATTLIST" $ m.CleanDTD
			* fetch an attribute list
			m.Segment = STREXTRACT(m.CleanDTD, "<!ATTLIST", ">", 1, 4)
			m.CleanDTD = STRTRAN(m.CleanDTD, m.Segment, "")
			m.Segment = LEFT(m.Segment, LEN(m.Segment) - 1)
			m.AttIndex = 1
			m.ElementName = GETWORDNUM(m.Segment, m.AttIndex + 1, m.Delimiters)
			DO WHILE !EMPTY(m.ElementName)
				m.AttributeName = GETWORDNUM(m.Segment, m.AttIndex + 2, m.Delimiters)
				m.AttributeType = GETWORDNUM(m.Segment, m.AttIndex + 3, m.Delimiters)
				m.AttributeValue = GETWORDNUM(m.Segment, m.AttIndex + 4, m.Delimiters)
				IF m.AttributeValue == "#FIXED"
					m.AttributeValue = m.AttributeValue + " " + GETWORDNUM(m.Segment, m.AttIndex + 5, m.Delimiters)
					m.AttIndex = m.AttIndex + 1
				ENDIF
				
				DO CASE
				CASE m.AttributeType == "NMTOKEN"
					This.NMToken.Add(m.AttributeValue, m.ElementName + ":" + m.AttributeName + ":")
				CASE m.AttributeType == "NMTOKENS"
					This.NMTokens.Add(m.AttributeValue, m.ElementName + ":" + m.AttributeName + ":")
				ENDCASE
				m.AttIndex = m.AttIndex + 4
				m.ElementName = GETWORDNUM(m.Segment, m.AttIndex + 1, m.Delimiters)
			ENDDO
		ENDDO
		
	ENDFUNC

ENDDEFINE
