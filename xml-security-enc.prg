*
* XMLSecEnc
*

DO LOCFILE("xml-security-dsig.prg")

IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-security.h"

DEFINE CLASS XMLSecurityEnc AS Custom

	ADD OBJECT References AS Collection
	ADD OBJECT ImportXMLSecurityDSig AS XMLSecurityDSig NOINIT

	PROTECTED EncDoc
	PROTECTED RawNode
	
	EncDoc = .NULL.
	RawNode = .NULL.
	Type = ""
	EncKey = .NULL.

	FUNCTION Init
		This._resetTemplate()
	ENDFUNC
	
	HIDDEN PROCEDURE _resetTemplate

		This.EncDoc = .NULL.
		This.EncDoc = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		This.EncDoc.PreserveWhiteSpace = .T.
		This.EncDoc.async = .F.
		This.EncDoc.SetProperty("SelectionNamespaces", "xmlns:xenc='http://www.w3.org/2001/04/xmlenc#'")
		This.EncDoc.loadXML("<xenc:EncryptedData xmlns:xenc='http://www.w3.org/2001/04/xmlenc#'>" + LF + ;
									"   <xenc:CipherData>" + LF + ;
									"      <xenc:CipherValue></xenc:CipherValue>" + LF + ;
									"   </xenc:CipherData>" + LF + ;
									"</xenc:EncryptedData>")
	ENDPROC

	PROCEDURE AddReference (Name AS String, Node AS MSXML2.IXMLDOMNode, Type AS String)

		LOCAL curEncDoc AS MSXML2.DOMDocument60
		LOCAL encDoc AS MSXML2.DOMDocument60
		LOCAL element AS MSXML2.IXMLDOMElement
		LOCAL RefURI AS String
		LOCAL Reference AS _XMLSecEnc_Reference

		m.curEncDoc = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		m.curEncDoc.async = .F.
		m.curEncDoc.load(This.EncDoc)
		
		This._resetTemplate()

		m.encDoc = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		m.encDoc.async = .F.
		m.encDoc.load(This.EncDoc)

		This.EncDoc.load(m.curEncDoc)

		m.RefURI = This.ImportXMLSecurityDSig.generateGUID();
		
		m.encDoc.documentElement.setAttribute("Id", m.RefURI)

		IF This.References.GetKey(m.Name) != 0
			This.References.Remove(m.Name)
		ENDIF

		m.Reference = CREATEOBJECT("_XMLSecEnc_Reference")
		m.Reference.Node = m.Node
		m.Reference.Type = m.Type
		m.Reference.EncNode = m.encDoc
		m.Reference.RefURI = m.RefURI
		This.References.Add(m.Reference, m.Name)

	ENDPROC

	PROCEDURE SetNode (Node AS MSXML2.IXMLDOMElement)
		This.RawNode = m.Node
	ENDPROC

	FUNCTION EncryptNode (ObjKey AS XMLSecurityKey, NoReplace AS Logical) AS MSXML2.IXMLDOMElement

		LOCAL EncData AS String
		LOCAL Encrypted AS String
		LOCAL EncryptedNode AS MSXML2.IXMLDOMText
		LOCAL Doc AS MSXML2.DOMDocument60
		LOCAL CipherList AS MSXML2.IXMLDOMNodeList
		LOCAL CipherValue AS MSXML2.IXMLDOMElement
		LOCAL EncMethod AS MSXML2.IXMLDOMElement
		LOCAL EncImport AS MSXML2.IXMLDOMElement
		LOCAL Child AS MSXML2.IXMLDOMElement

		IF ISNULL(This.RawNode)
			ERROR "Node to encrypt has not been set."
		ENDIF

		m.EncData = ""

		m.Doc = This.RawNode.OwnerDocument
		m.CipherList = This.EncDoc.selectNodes("/xenc:EncryptedData/xenc:CipherData/xenc:CipherValue")
		IF m.CipherList.length = 0
			ERROR "Error locating CipherValue element within template."
		ENDIF
		m.CipherValue = m.CipherList.item(0)

		DO CASE

		CASE This.Type == ELEMENT_URI
			m.EncData = This.RawNode.xml
			This.EncDoc.documentElement.setAttribute("Type", ELEMENT_URI)

		CASE This.Type == CONTENT_URI
			FOR EACH m.Child IN This.RawNode.childNodes
				m.EncData = m.EncData + m.Child.xml
			ENDFOR
			This.EncDoc.documentElement.setAttribute("Type", CONTENT_URI)

		OTHERWISE
			ERROR "Type currently not supported."

		ENDCASE

		m.EncMethod = This.EncDoc.documentElement.appendChild(This.EncDoc.createNode(1, "xenc:EncryptionMethod", XMLENC_NS))
		m.EncMethod.setAttribute("Algorithm", m.ObjKey.GetAlgorithm())
		m.CipherValue.parentNode.parentNode.insertBefore(m.EncMethod, m.CipherValue.parentNode.parentNode.firstChild)

		m.Encrypted = STRCONV(m.ObjKey.EncryptData(m.EncData), 13)

		m.EncryptedNode = This.EncDoc.createTextNode(m.Encrypted)
		m.CipherValue.appendChild(m.EncryptedNode)

		IF !m.NoReplace

			DO CASE
			CASE This.Type = ELEMENT_URI

				IF This.RawNode.NodeType = 9		&& Document
					RETURN This.EncDoc
				ENDIF

				m.EncImport = m.Doc.importNode(This.EncDoc.documentElement, .T.)
				This.RawNode.parentNode.replaceChild(m.EncImport, This.RawNode)

				RETURN m.EncImport

			CASE This.Type == CONTENT_URI

				m.EncImport = m.Doc.importNode(This.EncDoc.documentElement, .T.)
				DO WHILE This.RawNode.hasChild
					This.RawNode.removeChild(This.RawNode.firstChild)
				ENDDO
				This.RawNode.appendChild(m.EncImport)

				RETURN m.EncImport
			ENDCASE

		ELSE

			RETURN This.EncDoc.documentElement

		ENDIF
		
	ENDFUNC

	PROCEDURE EncryptKey (SrcKey AS XMLSecurityKey, RawKey AS XMLSecurityKey, NoAppend AS Logical)

		LOCAL StrEncKey AS String
		LOCAL Root AS MSXML2.IXMLDOMElement
		LOCAL EncKey AS MSXML2.IXMLDOMElement
		LOCAL KeyInfo AS MSXML2.IXMLDOMElement
		LOCAL EncMethod AS MSXML2.IXMLDOMElement
		LOCAL CipherData AS MSXML2.IXMLDOMElement
		LOCAL KeyElement AS MSXML2.IXMLDOMElement
		LOCAL RefList AS MSXML2.IXMLDOMElement
		LOCAL Reference AS _XMLSecEnc_Reference

		m.StrEncKey = STRCONV(m.SrcKey.EncryptData(m.RawKey.Key), 13)

		m.Root = This.EncDoc.documentElement
		m.EncKey = This.EncDoc.CreateNode(1, "xenc:EncryptedKey", XMLENC_NS)
		IF !m.NoAppend
			m.KeyInfo = m.Root.insertBefore(This.EncDoc.CreateNode(1, "dsig:KeyInfo", XMLDSIG_NS), m.Root.firstChild)
			m.KeyInfo.appendChild(m.EncKey)
		ELSE
			This.EncKey = m.EncKey
		ENDIF

		m.EncMethod = m.EncKey.appendChild(This.EncDoc.createNode(1, "xenc:EncryptionMethod", XMLENC_NS))
		m.EncMethod.setAttribute("Algorithm", m.SrcKey.GetAlgorithm())

		IF !EMPTY(m.SrcKey.KName)
			m.KeyInfo = m.EncKey.appendChild(This.EncDoc.createNode(1, "dsig:KeyInfo", XMLDSIG_NS))
			m.KeyElement = This.EncDoc.createNode(1, "dsig:KeyName",  XMLDSIG_NS)
			m.KeyElement.text = m.SrcKey.KName
			m.KeyInfo.appendChild(m.KeyElement)
		ENDIF

		m.CipherData = m.EncKey.appendChild(This.EncDoc.createNode(1, "xenc:CipherData", XMLENC_NS))
		m.KeyElement = This.EncDoc.createNode(1, "xenc:CipherValue", XMLENC_NS)
		m.KeyElement.text = m.StrEncKey
		m.CipherData.appendChild(m.KeyElement)

		IF This.References.Count != 0

			m.RefList = m.EncKey.appendChild(This.EncDoc.createNode(1, "xenc:ReferenceList", XMLENC_NS))

			FOR EACH m.Reference IN This.References
				m.KeyElement = m.RefList.appendChild(This.EncDoc.createNode(1, "xenc:DataReference", XMLENC_NS))
				m.KeyElement.setAttribute("URI", "#" + m.Reference.RefURI)
			ENDFOR

		ENDIF

	ENDPROC

ENDDEFINE

DEFINE CLASS _XMLSecEnc_Reference AS Custom

	Node = .NULL.
	Type = ""
	EncNode = .NULL.
	RefURI = ""

ENDDEFINE
