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
#DEFINE	JX_IN_ARRAY		2
#DEFINE	JX_MUST_FOLLOW	4
#DEFINE	JX_IS_ARRAY		8

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
				This.ConvertObject(SUBSTR(m._JSon, 2, LEN(m._JSon) - 2), "", This.XML.DocumentElement, JX_IN_ARRAY + JX_IS_ARRAY)

			OTHERWISE
				This.ConvertObject(m._JSon, "", This.XML.DocumentElement, 0)

			ENDCASE

			m.Converted = This.XML

		CATCH TO m.Catcher

			IF m.Catcher.ErrorNo = 2071
				This.ParseError = m.Catcher.UserValue
			ELSE
				This.ParseError = "Converter Error: " + m.Catcher.Message
				This.ParsePosition = m.Catcher.LineContents
			ENDIF

			m.Converted = .NULL.

		ENDTRY

		RETURN m.Converted

	ENDFUNC

	HIDDEN FUNCTION ConvertObject (JsonObject AS String, ElementName AS String, XMLRoot AS MSXML2.IXMLDOMElement, Flags AS Integer) AS String

		LOCAL _JSon AS String
		LOCAL Next_JSon AS Character
		LOCAL Next_TokenLength AS Integer
		LOCAL JSValue AS String
		LOCAL ObjectName AS String
		LOCAL Named AS Logical
		LOCAL XMLElement AS MSXML2.IXMLDOMElement

		m._JSon = LTRIM(m.JsonObject, 0, " ", CHR(13), CHR(10), CHR(9))

		IF EMPTY(m._JSon) AND BITAND(m.Flags, JX_MUST_FOLLOW) = 0
			RETURN ""
		ENDIF

		IF BITAND(m.Flags, JX_IS_ARRAY) != 0

			DO WHILE !LEFT(m._JSon, 1) == "]" AND !EMPTY(m._JSon)
				m.XMLElement = m.XMLRoot.ownerDocument.createElement(EVL(m.ElementName, "array"))
				m._JSon = This.ConvertObject(m._JSon, "", m.XMLElement, JX_IN_ARRAY)
				m.XMLRoot.appendChild(m.XMLElement)
			ENDDO

			IF EMPTY(m._Json) AND !EMPTY(m.ElementName)
				THROW "Unclosed array"
			ENDIF

			RETURN LTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9))

		ENDIF

		DO WHILE !EMPTY(m._JSon)

			IF LEFT(m._JSon, 1) == ","

				IF BITAND(m.Flags, JX_MUST_FOLLOW) != 0
					This.ParsePosition = m._JSon
					THROW "Expected element or value not found"
				ENDIF

				m._JSon = LTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9))

			ENDIF

			IF LEFT(m._JSon, 1) == "{"

				IF BITAND(m.Flags, JX_MUST_FOLLOW + JX_IN_ARRAY) = 0
					This.ParsePosition = m._JSon
					THROW "Expected element or value not found"
				ENDIF

				m._JSon = LTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9))

			ENDIF

			m.JSValue = .NULL.
			m.Next_TokenLength = 0
			This.ParsePosition = m._JSon

			IF LEFT(m._JSon, 1) == '"'

				m.ObjectName = This.GetValue(m._JSon, @m.Next_TokenLength)
				IF !ISNULL(m.ObjectName)
					m._JSon = LTRIM(SUBSTR(m._JSon, m.Next_TokenLength + 1), 0, " ", CHR(13), CHR(10), CHR(9))
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
				m._JSon = LTRIM(SUBSTR(m._JSon, AT(":", m._JSon) + 1), 0, " ", CHR(13), CHR(10), CHR(9))
			ENDIF

			m.Next_JSon = LEFT(m._JSon, 1)

			IF m.Next_JSon == "["

				m._JSon = This.ConvertObject(SUBSTR(m._JSon, 2), m.ObjectName, m.XMLRoot, BITAND(m.Flags, JX_IN_ARRAY + JX_IN_OBJECT) + JX_IS_ARRAY)

			ELSE 

				IF m.Next_JSon == "{"

					m.XMLElement = m.XMLRoot.ownerDocument.createElement(m.ObjectName)
					m._JSon = This.ConvertObject(SUBSTR(m._JSon, 2), "", m.XMLElement, BITAND(m.Flags, JX_IN_ARRAY) + JX_IN_OBJECT)
					m.XMLRoot.appendChild(m.XMLElement)

				ELSE

					IF !m.Next_JSon $ "]}" OR !ISNULL(m.JSValue)

						This.ParsePosition = m._JSon

						IF ISNULL(m.JSValue)

							m.JSValue = This.GetValue(m._JSon, @m.Next_TokenLength)
							IF ISNULL(m.JSValue)
								THROW "Unexpected value format"
							ENDIF

							m._JSon = LTRIM(SUBSTR(m._JSon, m.Next_TokenLength + 1), 0, " ", CHR(13), CHR(10), CHR(9))

							IF ISNULL(m.JSValue)
								THROW "Invalid value encoding"
							ENDIF
						ENDIF

						m.XMLElement = m.XMLRoot.ownerDocument.createElement(m.ObjectName)
						m.XMLElement.text = m.JSValue
						m.XMLRoot.appendChild(m.XMLElement)

					ENDIF

				ENDIF

				This.ParsePosition = m._JSon
				m.Next_JSon = LEFT(m._JSon, 1)

				DO CASE
				CASE m.Next_JSon == ","

					IF BITAND(m.Flags, JX_IN_OBJECT + JX_IN_ARRAY) = 0
						THROW "Elements not allowed"
					ENDIF

					m._JSon = LTRIM(SUBSTR(m._JSon, 2), 0,  " ", CHR(13), CHR(10), CHR(9))

				CASE m.Next_JSon == "]" AND BITAND(m.Flags, JX_IN_ARRAY + JX_IS_ARRAY) != 0

					* signal end of array
					RETURN m._JSon

				CASE m.Next_JSon == "}" AND BITAND(m.Flags, JX_IS_ARRAY) = 0

					* signal end of object
					RETURN LTRIM(SUBSTR(m._JSon, 2), 0,  " ", CHR(13), CHR(10), CHR(9))

				CASE !EMPTY(m._JSon)

					THROW "Unexpected character"

				ENDCASE

			ENDIF

		ENDDO
	
		RETURN ""

	ENDFUNC

	HIDDEN FUNCTION GetValue (JSon AS String, TokenLength AS Integer) AS String

		LOCAL Reg
		LOCAL JSBuffer AS String
		LOCAL ChAt AS Character
		LOCAL EndPos AS Integer
		LOCAL Token AS String
		LOCAL JSonLength AS Integer

		IF LEFT(m.JSon, 1) == '"'

			m.JSonLength = LEN(m.JSon)
			m.ChAt = SUBSTR(m.JSon, 2, 1)
			m.EndPos = 2
			m.Token = ""

			DO WHILE m.EndPos <= m.JSonLength AND !m.ChAt == '"'
				IF m.ChAt == "\"
					IF m.EndPos + 2 >= m.JSonLength
						RETURN .NULL.
					ENDIF
					m.ChAt = SUBSTR(m.JSBuffer, 2, 1)
					IF m.ChAt $ '"\/bfnrt'
						m.EndPos = m.EndPos + 2
						m.Token = m.Token + CHRTRAN(m.ChAt, "bfnrt", 0h7f0c0a0d09)
					ELSE
						IF m.ChAt == "u" AND m.EndPos + 6 <= m.JSonLength
							m.EndPos = m.EndPos + 6
							m.Token = m.Token + STRCONV(BINTOC(VAL("0x" + SUBSTR(m.JSBuffer, 3, 4)), "2RS"), 6)
						ELSE
							RETURN .NULL.
						ENDIF
					ENDIF
				ELSE
					m.EndPos = m.EndPos + 1
					m.Token = m.Token + m.ChAt
				ENDIF
				m.JSBuffer = SUBSTR(m.JSon, m.EndPos, 6)
				m.ChAt = LEFT(m.JSBuffer, 1)
			ENDDO
	
			IF m.EndPos > m.JSonLength
				RETURN .NULL.
			ENDIF

			m.TokenLength = m.EndPos
			RETURN m.Token

		ELSE

			This.RegExp.Pattern = '^((-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?)|(true)|(false)|(null))'
			m.Reg = This.RegExp.Execute(m.JSon)
			IF m.Reg.Count = 1
				m.Token = m.Reg.Item(0).Value
				m.TokenLength = LEN(m.Token)
				RETURN m.Token
			ELSE
				RETURN .NULL.
			ENDIF

		ENDIF
	
	ENDFUNC

ENDDEFINE
