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
	LPARAMETERS tcString AS String, tlCData AS Boolean
	LOCAL lcString AS String

#define C_AMP	CHR(38)
	
		IF PCOUNT() = 2 AND m.tlCData
			m.lcString = "<![CDATA[" + STRTRAN(m.tcString,"]]>","]]>]]&gt;<![CDATA[") + "]]>"
		ELSE
			m.lcString = STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(m.tcString,C_AMP,C_AMP + "amp;"),"'",C_AMP + "apos;"),'"',C_AMP + "quot;"),">",C_AMP + "gt;"),"<",C_AMP + "lt;")
		ENDIF
		
		RETURN m.lcString
	ENDFUNC
	
ENDDEFINE
