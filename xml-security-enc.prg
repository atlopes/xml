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
	ADD OBJECT ImportXMLSecurityKey AS XMLSecurityKey NOINIT

	PROTECTED EncDoc
	PROTECTED RawNode
	
	EncDoc = .NULL.
	RawNode = .NULL.
	Type = ""
	EncKey = .NULL.
	KeyLibrary = .NULL.

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

	PROCEDURE SetKeyLibrary (KLib AS StringOrObject)
		This.ImportXMLSecurityKey.SetLibrary(m.KLib)
		This.KeyLibrary = m.KLib
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

		m.RefURI = This.ImportXMLSecurityDSig.generateGUID()
		
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
				DO WHILE This.RawNode.hasChildNodes
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

	PROCEDURE EncryptRereferences (ObjKey AS XMLSecurityKey)

		LOCAL EncReference AS _XMLSecEnc_Reference
		LOCAL CurRawNode AS MSXML2.IXMLDOMElement
		LOCAL EncNode AS MSXML2.IXMLDOMElement
		LOCAL CurType AS String
		LOCAL EncError AS Exception

		m.CurRawNode = This.RawNode
		m.CurType = This.Type

		FOR EACH m.EncReference IN This.References

			This.EncDoc = m.EncReference.EncNode
			This.RawNode = m.EncReference.Node
			This.Type = m.EncReference.Type

			TRY
				m.EncNode = This.EncryptNode(m.ObjKey)
				m.EncReference.EncNode = m.EncNode
			CATCH TO m.EncError
				This.RawNode = m.CurRawNode
				This.Type = m.CurType
				THROW m.EncError
			ENDTRY

		ENDFOR

		This.RawNode = m.CurRawNode
		This.Type = m.CurType

	ENDPROC

	FUNCTION GetCipherValue () AS String

		IF ISNULL(This.RawNode)
			ERROR "Node to decrypt has not been set."
		ENDIF

		LOCAL CurNamespaces AS String
		LOCAL Doc AS MSXML2.DOMDocument60
		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
		LOCAL CipherValue AS String

		m.Doc = NVL(This.RawNode.OwnerDocument, This.RawNode)

		m.CurNamespaces = m.Doc.getProperty("SelectionNamespaces")
		m.Doc.setProperty("SelectionNamespaces", "xmlns:enc='" + XMLENC_NS + "'")
		
		m.Nodes = This.RawNode.selectNodes("./enc:CipherData/enc:CipherValue")
		IF m.Nodes.length > 0
			m.CipherValue = STRCONV(m.Nodes.item(0).text, 14)
		ELSE
			m.CipherValue = ""
		ENDIF
		
		m.Doc.setProperty("SelectionNamespaces", m.CurNamespaces)

		RETURN m.CipherValue
	ENDFUNC

	* NoReplace = .F. -> returns the decrypted element inserted in the document
	* NoReplace = .T. -> returns the decrypted data as a string
	FUNCTION DecryptNode (ObjKey AS XMLSecurityKey, NoReplace AS Boolean) AS StringOrXMLDOMElement

		LOCAL EncryptedData AS String
		LOCAL DecryptedData AS String
		LOCAL Doc AS MSXML2.DOMDocument60
		LOCAL TmpDoc AS MSXML2.DOMDocument60
		LOCAL EncNode AS MSXML2.IXMLDOMElement
		LOCAL ParentNode AS MSXML2.IXMLDOMElement
		LOCAL TmpNode AS MSXML2.IXMLDOMElement

		m.EncryptedData = This.GetCipherValue()

		IF !EMPTY(m.EncryptedData)

			m.DecryptedData = m.ObjKey.DecryptData(m.EncryptedData)

			IF !m.NoReplace

				DO CASE
				CASE This.Type == ELEMENT_URI

					m.Doc = CREATEOBJECT("MSXML2.DOMDocument.6.0")
					m.Doc.LoadXML(m.DecryptedData)

					IF This.RawNode.NodeType = 9		&& Document
						RETURN m.Doc
					ENDIF

					m.EncNode = This.RawNode.ownerDocument.importNode(m.Doc.Documentelement, .T.)
					This.RawNode.parentNode.replaceChild(m.EncNode, This.RawNode)

					RETURN m.EncNode

				CASE This.Type == CONTENT_URI

					IF This.RawNode.NodeType = 9		&& Document
						m.Doc = This.RawNode
					ELSE
						m.Doc = This.RawNode.ownerDocument
					ENDIF

					m.ParentNode = This.RawNode.parentNode

					m.TmpDoc = CREATEOBJECT("MSXML2.DOMDocument.6.0")
					m.TmpDoc.LoadXML("<root>" + m.DecryptedData + "</root>")

					FOR EACH m.TmpNode IN m.TmpDoc.Documentelement.Childnodes
						m.EncNode = This.RawNode.ownerDocument.importNode(m.TmpNode, .T.)
						m.ParentNode.insertBefore(m.EncNode, This.RawNode)
					ENDFOR

					m.ParentNode.removeChild(This.RawNode)
	
					RETURN m.ParentNode

				OTHERWISE
					RETURN m.DecryptedData
				ENDCASE

			ELSE

				RETURN m.DecryptedData

			ENDIF

		ELSE
		
			ERROR "Cannot locate encrypted data."

		ENDIF

	ENDFUNC

	FUNCTION DecryptKey (EncKey AS XMLSecurityKey) AS MSXML2.IXMLDOMElement

		IF !m.EncKey.IsEncrypted
			ERROR "Key is not encrypted."
		ENDIF

		IF ISNULL(m.EncKey.Key)
			ERROR "Key is missing data to perform the decryption."
		ENDIF

		RETURN This.DecryptNode(m.EncKey, .T.)

	ENDFUNC

	FUNCTION LocateEncryptedData (Element AS MSXML2.IXMLDOMElement) AS MSXML2.IXMLDOMElement

		LOCAL Doc AS MSXML2.DOMDocument60
		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
	
		m.Doc = NVL(m.Element.ownerDocument, m.Element)

		IF !ISNULL(m.Doc)
			m.Nodes = m.Doc.Selectnodes("//*[local-name() = 'EncryptedData' and namespace-uri() = '" + XMLENC_NS + "']")
			RETURN m.Nodes.Item(0)
		ENDIF

		RETURN .NULL.

	ENDFUNC

	FUNCTION LocateKey (DOMNode AS MSXML2.IXMLDOMElement) AS XMLSecurityKey

		LOCAL Node AS MSXML2.IXMLDOMElement
		LOCAL EncMethod AS MSXML2.IXMLDOMElement
		LOCAL Algorithm AS String
		LOCAL EncKey AS XMLSecurityKey
		LOCAL Doc AS MSXML2.DOMDocument60
		LOCAL CurNamespaces AS String

		IF PCOUNT() = 0 OR ISNULL(m.DOMNode)
			m.Node = This.RawNode
		ELSE
			m.Node = m.DOMNode
		ENDIF

		m.EncKey = .NULL.

		m.Doc = m.Node.ownerDocument
		IF !ISNULL(m.Doc)

			m.CurNamespaces = m.Doc.GetProperty("SelectionNamespaces")
			m.Doc.SetProperty("SelectionNamespaces", "xmlns:enc='" + XMLENC_NS + "'")
			m.EncMethod= m.Node.selectNodes(".//enc:EncryptionMethod").item(0)

			IF !ISNULL(m.EncMethod)
				m.Algorithm = m.EncMethod.getAttribute("Algorithm")
				m.EncKey = CREATEOBJECT("XMLSecurityKey", m.Algorithm, "private", This.KeyLibrary)
				IF TYPE("m.EncKey") != "O"
					m.EncKey = .NULL.
				ENDIF
			ENDIF

			m.Doc.SetProperty("SelectionNamespaces", m.CurNamespaces)
		ENDIF

		RETURN m.EncKey

	ENDFUNC

	HIDDEN FUNCTION _LocateKeyInfo (BaseKey AS XMLSecurityKey, Node AS MSXML2.IXMLDOMElement) AS XMLSecurityKey

		LOCAL Doc AS MSXML2.DOMDocument60
		LOCAL CurNamespaces AS String
		LOCAL EncMethod AS MSXML2.IXMLDOMElement
		LOCAL KeyChild AS MSXML2.IXMLDOMElement
		LOCAL KeyValue AS MSXML2.IXMLDOMElement
		LOCAL Element AS MSXML2.IXMLDOMElement
		LOCAL AttrValue AS String
		LOCAL Modulus AS String
		LOCAL Exponent AS String
		LOCAL PublicKey AS String
		LOCAL IdRef AS String
		LOCAL X509 AS String
		LOCAL Splitter AS String

		IF ISNULL(m.Node)
			RETURN .NULL.
		ENDIF

		m.Doc = m.Node.ownerDocument
		IF ISNULL(m.Doc)
			RETURN .NULL.
		ENDIF

		m.CurNamespaces = m.Doc.GetProperty("SelectionNamespaces")
		m.Doc.SetProperty("SelectionNamespaces", "xmlns:enc='" + XMLENC_NS + "' xmlns:ds='" + XMLDSIG_NS + "'")

		m.EncMethod = m.Node.selectNodes("./ds:KeyInfo").item(0)
		IF ISNULL(m.EncMethod)
			m.Doc.setProperty("SelectionNamespaces", m.CurNamespaces)
			RETURN m.BaseKey
		ENDIF

		FOR EACH m.KeyChild IN m.EncMethod.childNodes

			DO CASE

			CASE m.KeyChild.baseName == "KeyName" AND !ISNULL(m.BaseKey)

				m.BaseKey.KName = m.KeyChild.nodeValue

			CASE m.KeyChild.baseName == "KeyValue"

				FOR EACH m.KeyValue IN m.KeyChild.childNodes

					DO CASE

					CASE m.KeyValue.baseName == "DSAKeyValue"

						ERROR "DSAKeyValue not supported."

					CASE m.KeyValue.baseName == "RSAKeyValue" AND !ISNULL(m.BaseKey)

						STORE "" TO m.Modulus, m.Exponent
						m.Element = m.KeyValue.getElementsByTagName("ds:Modulus").item(0)
						IF !ISNULL(m.Element)
							m.Modulus = STRCONV(m.Element.nodeValue, 14)
						ENDIF
						m.Element = m.KeyValue.getElementsByTagName("ds:Exponent").item(0)
						IF !ISNULL(m.Element)
							m.Exponent = STRCONV(m.Element.nodeValue, 14)
						ENDIF

						IF EMPTY(m.Modulus) OR EMPTY(m.Exponent)
							ERROR "Missing Modulus or Exponent."
						ENDIF

						m.BaseKey.LoadKey(This.ImportXMLSecurityKey.ConvertRSA(m.Modulus, m.Exponent))

					ENDCASE
				ENDFOR

			CASE m.KeyChild.baseName == "RetrievalMethod"

				IF m.KeyChild.getAttribute("Type") == "http://www.w3.org/2001/04/xmlenc#EncryptedKey"
				
					m.AttrValue = m.KeyValue.getAttribute("URI")
					IF LEFT(m.AttrValue, 1) == "#"

						m.IdRef = SUBSTR(m.AttrValue, 2)
						m.Element = m.Doc.selectNodes("//enc:EncryptedKey[@Id = '" + m.IdRef + "']").item(0)
						IF ISNULL(m.Element)
							ERROR TEXTMERGE("Unable to locate EncryptedKey[@Id = '<<m.IdRef>>']")
						ENDIF

						m.Doc.setProperty("SelectionNamespaces", m.CurNamespaces)
						RETURN This.ImportXMLSecurityKey.FromEncryptedKeyElement(m.Element)
					ENDIF
				ENDIF

			CASE m.KeyChild.baseName == "EncryptedKey"

				m.Doc.setProperty("SelectionNamespaces", m.CurNamespaces)
				RETURN This.ImportXMLSecurityKey.FromEncryptedKeyElement(m.KeyChild)

			CASE m.KeyChild.baseName == "X509Data" AND !ISNULL(m.BaseKey)

				m.Element = m.KeyChild.getElementsByTagName("ds:X509Certificate").item(0)
				IF !ISNULL(m.Element)
					m.Splitter = CHRTRAN(m.Element.text, CHR(9) + CHR(13) + CHR(10) + " ", "")
					m.X509 = "-----BEGIN CERTIFICATE-----" + CHR(10)
					DO WHILE LEN(m.Splitter) != 0
						m.X509 = m.X509 + LEFT(m.Splitter, 64) + CHR(10)
						m.Splitter = SUBSTR(m.Splitter, 65)
					ENDDO
					m.X509 = m.X509 + "-----END CERTIFICATE-----" + CHR(10)

					m.BaseKey.LoadKey(m.X509, .F., .T.)

				ENDIF
			ENDCASE
		ENDFOR

		m.Doc.setProperty("SelectionNamespaces", m.CurNamespaces)

		RETURN m.BaseKey

	ENDFUNC

	FUNCTION LocateKeyInfo (BaseKey AS XMLSecurityKey, Node AS MSXML2.IXMLDOMElement) AS XMLSecurityKey

		IF PCOUNT() < 2
			m.Node = .NULL.
		ENDIF
		IF PCOUNT() = 0
			m.BaseKey = .NULL.
		ENDIF

		RETURN This._LocateKeyInfo(m.BaseKey, NVL(m.Node, This.RawNode))

	ENDFUNC

ENDDEFINE

DEFINE CLASS _XMLSecEnc_Reference AS Custom

	Node = .NULL.
	Type = ""
	EncNode = .NULL.
	RefURI = ""

ENDDEFINE
