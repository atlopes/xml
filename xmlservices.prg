* install itself
IF !"\XMLSERVICE.FXP" $ SET("Procedure")
	SET PROCEDURE TO SYS(16) ADDITIVE
ENDIF

DEFINE CLASS XMLService AS Custom 

	_memberdata = '<VFPData>' + ;
						'<memberdata name="encode" type="method" display="Encode"/>' + ;
						'<memberdata name="loaddocument" type="method" display="LoadDocument"/>' + ;
						'<memberdata name="selectnodes" type="method" display="SelectNodes"/>' + ;
						'</VFPData>'
	XMLParser = .NULL.

	PROCEDURE Init as Boolean
	LOCAL llResult as Boolean
		TRY
			This.XMLParser = CREATEOBJECT("MSXML2.DOMDocument.6.0")
			m.llResult = .T.
		CATCH
			m.llResult = .F.
		ENDTRY
		
		RETURN m.llResult
	ENDPROC

	PROCEDURE Destroy
		This.XMLParser = .NULL.
	ENDPROC

	FUNCTION LoadDocument AS Boolean
	LPARAMETERS tcDocument
	LOCAL llResult as Boolean
		TRY
			This.XMLParser.async = .T.
			This.XMLParser.LoadXML(m.tcDocument)
			m.llResult = .T.
		CATCH
			m.llResult = .F.
		ENDTRY
		
		RETURN m.llResult
	ENDFUNC

	FUNCTION SelectNodes AS MSXML2.IXMLDOMNodeList
	LPARAMETERS toTree AS MSXML2.IXMLDOMElement, tcPath as String
		IF !ISNULL(m.toTree)
			RETURN m.toTree.selectNodes(m.tcPath)
		ELSE
			RETURN This.XMLParser.selectNodes(m.tcPath)
		ENDIF
	ENDFUNC

	FUNCTION Encode AS String
	LPARAMETERS Source AS String, CData AS Boolean
	LOCAL Encoded AS String

		IF PCOUNT() = 2 AND m.CData
			m.Encoded = "<![CDATA[" + STRTRAN(m.Source,"]]>","]]]]>&" + "gt;<![CDATA[") + "]]>"
		ELSE
			m.Encoded = STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(m.Source,"&","&" + "amp;"),"'","&" + "apos;"),'"',"&" + "quot;"),">","&" + "gt;"),"<","&" + "lt;")
		ENDIF
		
		RETURN m.Encoded
	ENDFUNC
	
ENDDEFINE
