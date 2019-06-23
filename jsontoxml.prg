*
* JsonToXML
* 
* A simple Json to XML converter
*
* m.jx = CREATEOBJECT("JsonToXML")
* m.xml = m.jx.Convert(m.JSonSource, "Root") && returns MSXML2.DOMDocument60
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

DEFINE CLASS JsonToXML AS Custom

	XML = .NULL.

	HIDDEN RegExp, XMLName
	RegExp = .NULL.
	XMLName = .NULL.

	_memberdata = '<VFPData>' + ;
						'<memberdata name="convert" type="method" display="Convert"/>' + ;
						'<memberdata name="xml" type="property" display="XML"/>' + ;
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

		This.XMLName.SetOriginalName(EVL(m.RootName, "JSON"))
		m._JSon = ALLTRIM(m.JsonSource, 0, " ", CHR(13), CHR(10), CHR(9), CHR(26)) 
		This.XML.LoadXML("<" + This.XMLName.GetName() + "/>")

		DO CASE

		CASE LEFT(m._JSon, 1) == "{" AND RIGHT(m._JSon, 1) == "}"
			This.ConvertObject(SUBSTR(m._JSon, 2, LEN(m._JSon) - 2), "", This.XML.DocumentElement)

		CASE LEFT(m._JSon, 1) == "[" AND RIGHT(m._JSon, 1) == "]"
			This.ConvertObject(SUBSTR(m._JSon, 2, LEN(m._JSon) - 2), "array", This.XML.DocumentElement)

		ENDCASE

		RETURN This.XML

	ENDFUNC

	HIDDEN FUNCTION ConvertObject (JsonObject AS String, ElementName AS String, XMLRoot AS MSXML2.IXMLDOMElement) AS String

		LOCAL _JSon AS String
		LOCAL JSValue AS String
		LOCAL ObjectName AS String
		LOCAL XMLElement AS MSXML2.IXMLDOMElement

		m._JSon = ALLTRIM(m.JsonObject, 0, " ", CHR(13), CHR(10), CHR(9))

		IF !EMPTY(m.ElementName)

			DO WHILE !(LEFT(m._JSon, 1) $ "}]") AND !EMPTY(m._JSon)
				m.XMLElement = m.XMLRoot.ownerDocument.createElement(m.ElementName)
				m._JSon = This.ConvertObject(m._JSon, "", m.XMLElement)
				m.XMLRoot.appendChild(m.XMLElement)
			ENDDO

			RETURN SUBSTR(m._JSon, 2)

		ENDIF

		IF LEFT(m._JSon, 1) == ","
			m._JSon = ALLTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9))
		ENDIF
		IF LEFT(m._JSon, 1) == "{"
			m._JSon = ALLTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9))
		ENDIF

		IF LEFT(m._JSon, 1) == '"'
			m.ObjectName = This.GetValue(m._JSon)
			IF !ISNULL(m.ObjectName)
				m._JSon = SUBSTR(m._JSon, LEN(m.ObjectName) + 1)
				m.ObjectName = This.UnencodeValue(m.ObjectName)
			ENDIF
		ELSE
			m.ObjectName = ""
		ENDIF
		IF ISNULL(m.ObjectName)
			ERROR "Invalid object name"
		ENDIF

		This.XMLName.SetOriginalName(m.ObjectName)
		m.ObjectName = This.XMLName.GetName()
		
		m._JSon = ALLTRIM(SUBSTR(m._JSon, AT(":", m._JSon) + 1), 0, " ", CHR(13), CHR(10), CHR(9))

		IF LEFT(m._JSon, 1) == "["

			m._JSon = This.ConvertObject(SUBSTR(m._JSon, 2), m.ObjectName, m.XMLRoot)

		ELSE 

			IF LEFT(m._JSon, 1) == "{"

				m.XMLElement = m.XMLRoot.ownerDocument.createElement(m.ObjectName)
				m._JSon = This.ConvertObject(SUBSTR(m._JSon, 2), "", m.XMLElement)
				m.XMLRoot.appendChild(m.XMLElement)

			ELSE

				IF !LEFT(m._JSon, 1) $ "]}"

					m.JSValue = This.GetValue(m._JSon)
					IF ISNULL(m.JSValue)
						ERROR "Unexpected value format"
					ENDIF

					m._JSon = ALLTRIM(SUBSTR(m._JSon, LEN(m.JSValue) + 1), 0, " ", CHR(13), CHR(10), CHR(9))

					m.JSValue = This.UnencodeValue(m.JSValue)
					IF ISNULL(m.JSValue)
						ERROR "Invalid value encoding"
					ENDIF

					m.XMLElement = m.XMLRoot.ownerDocument.createElement(m.ObjectName)
					m.XMLElement.text = m.JSValue
					m.XMLRoot.appendChild(m.XMLElement)

				ENDIF

			ENDIF

			DO CASE
			CASE LEFT(m._JSon, 1) == ","
				 m._JSon = This.ConvertObject(ALLTRIM(SUBSTR(m._JSon, 2), 0, " ", CHR(13), CHR(10), CHR(9)), "", m.XMLRoot)
			CASE LEFT(m._JSon, 1) == "]" AND !EMPTY(m.ElementName)
				* signal end of array
			CASE LEFT(m._JSon, 1) == "}" AND EMPTY(m.ElementName)
				m._JSon = SUBSTR(m._JSon, 2)
			CASE !EMPTY(m._JSon)
				ERROR "Unexpected character"
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

			This.RegExp.Pattern = '^-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?'
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
