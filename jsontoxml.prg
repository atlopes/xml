*
* JsonToXML
* 
* A simple Json to XML converter
*
* m.jx = CREATEOBJECT("JsonToXML")
* m.xml = m.jx.Convert(m.JSonSource, "Root") && returns MSXML2.DOMDocument60
* if isnull(m.xml)
*   ? m.jx.ParseError, '@', m.jx.ParsePosition
* else
*   ? m.xml.xml
* endif

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

#DEFINE	JX_IN_OBJECT	1
#DEFINE	JX_IS_ARRAY		2
#DEFINE	JX_MUST_FOLLOW	4	

DEFINE CLASS JsonToXML AS Custom

	XML = .NULL.
	Anonymous = ""
	ParseError = ""
	ParsePosition = ""

	HIDDEN RegExp, XMLName
	RegExp = .NULL.
	XMLName = .NULL.

	_memberdata = '<VFPData>' + ;
						'<memberdata name="convert" type="method" display="Convert"/>' + ;
						'<memberdata name="xml" type="property" display="XML"/>' + ;
						'<memberdata name="anonymous" type="property" display="Anonymous"/>' + ;
						'<memberdata name="parseerror" type="property" display="ParseError"/>' + ;
						'<memberdata name="parseposition" type="property" display="ParsePosition"/>' + ;
						'</VFPData>'

	FUNCTION Init

		LOCAL Done AS Logical

		TRY
			This.XML = CREATEOBJECT("MSXML2.DOMDocument.6.0")
			This.XML.Async = .F.
			This.RegExp = CREATEOBJECT("VBScript.RegExp")
			This.XMLName = CREATEOBJECT("Namer")
			This.XMLName.AttachProcessor("XMLNamer", "xml-names.prg")
			m.Done = .T.
		CATCH
			m.Done = .F.
		ENDTRY

		RETURN m.Done

	ENDFUNC

	FUNCTION Convert (JsonSource AS String, RootName AS String) AS MSXML2.DOMDocument60

		LOCAL _JSon AS String
		LOCAL Catcher AS Exception
		LOCAL Converted AS MSXML2.DOMDocument60

		This.XMLName.SetOriginalName(EVL(m.RootName, "JSON"))
		m._JSon = ALLTRIM(m.JsonSource, 0, " ", CHR(13), CHR(10), CHR(9), CHR(26)) 
		This.XML.LoadXML("<" + This.XMLName.GetName() + "/>")

		STORE "" TO This.ParseError, This.ParsePosition

		TRY
			DO CASE

			CASE LEFT(m._JSon, 1) == "{" AND RIGHT(m._JSon, 1) == "}"
				This.ConvertObject(SUBSTR(m._JSon, 2, LEN(m._JSon) - 2), "", This.XML.DocumentElement, JX_IN_OBJECT)

			CASE LEFT(m._JSon, 1) == "[" AND RIGHT(m._JSon, 1) == "]"
				This.ConvertObject(SUBSTR(m._JSon, 2, LEN(m._JSon) - 2), "array", This.XML.DocumentElement, JX_IS_ARRAY)

			OTHERWISE
				This.ConvertObject(m._JSon, "", This.XML.DocumentElement, JX_MUST_FOLLOW)

			ENDCASE

			m.Converted = This.XML

		CATCH TO m.Catcher

			This.ParseError = m.Catcher.UserValue

			m.Converted = .NULL.

		ENDTRY

		RETURN m.Converted

	ENDFUNC

	HIDDEN FUNCTION ConvertObject (JsonObject AS String, ElementName AS String, XMLRoot AS MSXML2.IXMLDOMElement, Flags AS Integer) AS String

		LOCAL _JSon AS String
		LOCAL JSValue AS String
		LOCAL ObjectName AS String
		LOCAL Named AS Logical
		LOCAL MustFollow AS Logical
		LOCAL XMLElement AS MSXML2.IXMLDOMElement

		m.MustFollow = BITAND(m.Flags, JX_MUST_FOLLOW) != 0

		m._JSon = ALLTRIM(m.JsonObject, 0, " ", CHR(13), CHR(10), CHR(9))

		IF BITAND(m.Flags, JX_IS_ARRAY) != 0

			DO WHILE !(LEFT(m._JSon, 1) $ "}]") AND !EMPTY(m._JSon)
				m.XMLElement = m.XMLRoot.ownerDocument.createElement(m.ElementName)
				m._JSon = This.ConvertObject(m._JSon, "", m.XMLElement, JX_IN_OBJECT)
				m.XMLRoot.appendChild(m.XMLElement)
			ENDDO

			RETURN ALLTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9))

		ENDIF

		IF LEFT(m._JSon, 1) == ","

			IF m.MustFollow
				This.ParsePosition = m._JSon
				THROW "Expected element or value not found"
			ENDIF

			m._JSon = ALLTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9))
			m.MustFollow = .T.

		ENDIF

		IF LEFT(m._JSon, 1) == "{"
			m._JSon = ALLTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9))
		ENDIF

		m.JSValue = .NULL.
		This.ParsePosition = m._JSon
		IF LEFT(m._JSon, 1) == '"'
			m.ObjectName = This.GetValue(m._JSon)
			IF !ISNULL(m.ObjectName)
				m._JSon = ALLTRIM(SUBSTR(m._JSon, LEN(m.ObjectName) + 1), 0, " ", CHR(13), CHR(10), CHR(9))
				m.ObjectName = This.UnencodeValue(m.ObjectName)
				IF LEFT(m._JSon, 1) == ":"
					m.Named = .T.
				ELSE
					m.Named = .F.
					m.JSValue = m.ObjectName
					m.ObjectName = This.Anonymous
				ENDIF
			ENDIF
		ELSE
			m.ObjectName = This.Anonymous
			m.Named = .F.
		ENDIF
		IF ISNULL(m.ObjectName)
			THROW "Invalid object name"
		ENDIF

		This.XMLName.SetOriginalName(m.ObjectName)
		m.ObjectName = This.XMLName.GetName()

		IF m.Named
			m._JSon = ALLTRIM(SUBSTR(m._JSon, AT(":", m._JSon) + 1), 0, " ", CHR(13), CHR(10), CHR(9))
		ENDIF

		IF LEFT(m._JSon, 1) == "["

			m._JSon = This.ConvertObject(SUBSTR(m._JSon, 2), m.ObjectName, m.XMLRoot, JX_IS_ARRAY)

		ELSE 

			IF LEFT(m._JSon, 1) == "{"

				m.XMLElement = m.XMLRoot.ownerDocument.createElement(m.ObjectName)
				m._JSon = This.ConvertObject(SUBSTR(m._JSon, 2), "", m.XMLElement, JX_IN_OBJECT + JX_MUST_FOLLOW)
				m.XMLRoot.appendChild(m.XMLElement)

			ELSE

				IF !LEFT(m._JSon, 1) $ "]}"

					This.ParsePosition = m._JSon

					IF ISNULL(m.JSValue)

						m.JSValue = This.GetValue(m._JSon)
						IF ISNULL(m.JSValue)
							THROW "Unexpected value format"
						ENDIF

						m._JSon = ALLTRIM(SUBSTR(m._JSon, LEN(m.JSValue) + 1), 0, " ", CHR(13), CHR(10), CHR(9))

						m.JSValue = This.UnencodeValue(m.JSValue)
						IF ISNULL(m.JSValue)
							THROW "Invalid value encoding"
						ENDIF
					ENDIF

					m.XMLElement = m.XMLRoot.ownerDocument.createElement(m.ObjectName)
					m.XMLElement.text = m.JSValue
					m.XMLRoot.appendChild(m.XMLElement)

				ELSE

					IF m.MustFollow
						THROW "Expected element or value not found"
					ENDIF

				ENDIF

			ENDIF

			This.ParsePosition = m._JSon

			DO CASE
			CASE LEFT(m._JSon, 1) == ","

				IF BITAND(m.Flags, JX_IN_OBJECT + JX_IS_ARRAY) = 0
					THROW "Elements not allowed"
				ENDIF

				 m._JSon = This.ConvertObject(ALLTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9)), "", m.XMLRoot, JX_IN_OBJECT + JX_MUST_FOLLOW)

			CASE LEFT(m._JSon, 1) == "]" AND !EMPTY(m.ElementName)
				* signal end of array

			CASE LEFT(m._JSon, 1) == "}" AND EMPTY(m.ElementName)

				m._JSon = SUBSTR(m._JSon, 2)

			CASE !EMPTY(m._JSon)

				THROW "Unexpected character"

			ENDCASE

		ENDIF

		RETURN ALLTRIM(m._JSon, 0,  " ", CHR(13), CHR(10), CHR(9))

	ENDFUNC

	HIDDEN FUNCTION GetValue (JSon AS String) AS String

		LOCAL Reg
		LOCAL ChAt AS Character
		LOCAL EndPos AS Integer

		IF LEFT(m.JSon, 1) == '"'

			m.ChAt = SUBSTR(m.JSon, 2, 1)
			m.EndPos = 2
			DO WHILE m.EndPos <= LEN(m.JSon) AND !m.ChAt == '"'
				IF m.ChAt == "\"
					m.ChAt = SUBSTR(m.JSon, m.EndPos + 1, 1)
					IF m.ChAt $ '"\/bfnrtu'
						m.EndPos = m.EndPos + 2
					ELSE
						RETURN .NULL.
					ENDIF
				ELSE
					m.EndPos = m.EndPos + 1
				ENDIF
				m.ChAt = SUBSTR(m.JSon, m.EndPos, 1)
			ENDDO
	
			IF m.EndPos > LEN(m.JSon)
				RETURN .NULL.
			ENDIF

			RETURN LEFT(m.JSon, m.EndPos)

		ELSE

			This.RegExp.Pattern = '^((-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?)|(true)|(false)|(null))'
			m.Reg = This.RegExp.Execute(m.JSon)
			IF m.Reg.Count = 1
				RETURN m.Reg.Item(0).Value
			ELSE
				RETURN .NULL.
			ENDIF

		ENDIF
	
	ENDFUNC

	HIDDEN FUNCTION UnencodeValue (Original AS String) AS String

		LOCAL Unencoded AS String
		LOCAL Esc AS Integer
		LOCAL Occ AS Integer
		LOCAL EscapedQuotes AS Integer
		LOCAL EscChar AS Character

		DO CASE
		CASE LEFT(m.Original, 1) == '"'

			m.Unencoded = SUBSTR(m.Original, 2, LEN(m.Original) - 2)
			m.EscapedQuotes = OCCURS('\"', m.Unencoded)

			m.Occ = 1
			m.Esc = AT("\", m.Unencoded, 1)
			DO WHILE m.Esc != 0 AND !ISNULL(m.Unencoded)
				IF m.Esc = LEN(m.Unencoded)
					m.Unencoded = .NULL.
				ELSE 
					m.EscChar = SUBSTR(m.Unencoded, m.Esc + 1, 1)
					DO CASE
					CASE m.EscChar $ '"/\'
						m.Unencoded = STUFF(m.Unencoded, m.Esc, 1, "")
						IF m.EscChar == "\"
							m.Occ = m.Occ + 1
						ENDIF
					CASE m.EscChar $ "bfnrt"
						m.Unencoded = STUFF(m.Unencoded, m.Esc, 2, CHRTRAN(m.EscChar, "bfnrt", 0h070c0a0d09))
					CASE m.EscChar == "u" AND m.Esc + 6 <= LEN(m.Unencoded)
						m.Unencoded = STUFF(m.Unencoded, m.Esc, 6, STRCONV(BINTOC(VAL("0x" + SUBSTR(m.Unencoded, m.Esc + 2, 4)), "2RS"), 6))
					OTHERWISE
						m.Unencoded = .NULL.
					ENDCASE
				ENDIF
				m.Esc = AT("\", NVL(m.Unencoded, ""), m.Occ)
			ENDDO			

			IF !ISNULL(m.Unencoded) AND m.EscapedQuotes != OCCURS('"', m.Unencoded)
				m.Unencoded = .NULL.
			ENDIF

		OTHERWISE

			m.Unencoded = m.Original

		ENDCASE

		RETURN m.Unencoded

	ENDFUNC

ENDDEFINE
