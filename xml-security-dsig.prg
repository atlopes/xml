*
* XMLSecurityDSig
*

DO LOCFILE("guid.prg")
DO LOCFILE("xml-canonicalizer.prg")
DO LOCFILE("url.prg")

DO LOCFILE("xml-security-key.prg")

IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-security.h"
#INCLUDE "url.h"

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSecurityDSig AS Custom

	ADD OBJECT GUID AS GUID
	ADD OBJECT IdKeys AS Collection
	ADD OBJECT IdNS AS Collection
	ADD OBJECT ValidatedNodes AS Collection

	SigNode = .NULL.

	HIDDEN SignedInfo
	HIDDEN CanonicalMethod
	HIDDEN Prefix
	HIDDEN SearchPrefix
	HIDDEN SecurityKey AS XMLSecurityKey

	SignedInfo = .NULL.
	CanonicalMethod = .NULL.
	Prefix = ""
	SearchPrefix = "secdsig"
	SecurityKey = .NULL.

	_memberdata = "<VFPData>" + ;
						'<!-- properties -->' + ;
						'<memberdata name="guid" type="property" display="GUID"/>' + ;
						'<memberdata name="idkeys" type="property" display="IdKeys"/>' + ;
						'<memberdata name="idns" type="property" display="IdNS"/>' + ;
						'<memberdata name="signode" type="property" display="ValidatedNodes"/>' + ;
						'<memberdata name="validatednodes" type="property" display="SigNode"/>' + ;
						'<!-- methods -->' + ;
						'<memberdata name="addreference" type="method" display="AddReference"/>' + ;
						'<memberdata name="calculatedigest" type="method" display="CalculateDigest"/>' + ;
						'<memberdata name="canonicalizedata" type="method" display="CanonicalizeData"/>' + ;
						'<memberdata name="canonicalizesignedinfo" type="method" display="CanonicalizeSignedInfo"/>' + ;
						'<memberdata name="createnewnode" type="method" display="CreateNewNode"/>' + ;
						'<memberdata name="createnewsignnode" type="method" display="CreateNewSignNode"/>' + ;
						'<memberdata name="getrefids" type="method" display="GetRefIDs"/>' + ;
						'<memberdata name="getrefnodeid" type="method" display="GetRefNodeID"/>' + ;
						'<memberdata name="locatesignature" type="method" display="LocateSignature"/>' + ;
						'<memberdata name="processrefnode" type="method" display="ProcessRefNode"/>' + ;
						'<memberdata name="processtransforms" type="method" display="ProcessTransforms"/>' + ;
						'<memberdata name="setcanonicalmethod" type="method" display="SetCanonicalMethod"/>' + ;
						'<memberdata name="sign" type="method" display="Sign"/>' + ;
						'<memberdata name="validatedigest" type="method" display="ValidateDigest"/>' + ;
						"</VFPData>"

	FUNCTION Init (Prefix AS String) AS Boolean

		SAFETHIS

		LOCAL Base AS String
		LOCAL PrefixRef AS String
		LOCAL PrefixNS AS String
		LOCAL SigDoc AS MSXML2.DOMDocument60

		IF PCOUNT() = 0
			m.Prefix = "ds"
		ENDIF

		IF !EMPTY(m.Prefix)
			m.PrefixRef = m.Prefix + ":"
			m.PrefixNS = ":" + m.Prefix
		ELSE
			STORE "" TO m.PrefixRef, m.PrefixNS
		ENDIF

		This.Prefix = m.PrefixRef

		m.Base = TEXTMERGE('<{m.PrefixRef}Signature xmlns{m.PrefixNS}="http://www.w3.org/2000/09/xmldsig#">' + LF + ;
									"  <{m.PrefixRef}SignedInfo>" + LF + ;
									"    <{m.PrefixRef}SignatureMethod />" + LF + ;
									"  </{m.PrefixRef}SignedInfo>" + LF + ;
									"</{m.PrefixRef}Signature>", .T., "{", "}")
		
		m.SigDoc = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		m.SigDoc.PreserveWhiteSpace = .T.
		m.SigDoc.async = .F.
		m.SigDoc.setProperty("SelectionNamespaces", "xmlns:" + This.SearchPrefix + '="' + XMLDSIG_NS + '"')
		m.SigDoc.loadXML(m.Base)
		This.SigNode = m.SigDoc.documentElement

		RETURN .T.

	ENDFUNC

	PROCEDURE Destroy
		This.SecurityKey = .NULL.
	ENDPROC

	PROCEDURE SetXMLKey (XMLKey AS XMLSecurityKey)
		This.SecurityKey = m.XMLKey
	ENDPROC

	FUNCTION LocateSignature (ObjDoc AS MSXML2.IXMLDOMElement, Pos AS Integer) AS MSXML2.IXMLDOMElement

		SAFETHIS

		LOCAL Doc AS MSXML2.DOMDocument60
		LOCAL Nodes AS MSXML2.IXMLDOMNodeList

		IF PCOUNT() = 1
			m.Pos = 0
		ENDIF

		IF ISNULL(m.ObjDoc) OR ISNULL(m.ObjDoc.ownerDocument)
			m.Doc = m.ObjDoc
		ELSE
			m.Doc = m.ObjDoc.ownerDocument
		ENDIF

		IF !ISNULL(m.Doc)

			m.Doc.preserveWhiteSpace = .T.
			m.Doc.setProperty("SelectionNamespaces", "xmlns:" + This.SearchPrefix + '="' + XMLDSIG_NS + '"')
			m.Nodes = m.Doc.selectNodes(".//" + This.SearchPrefix + ":Signature")
			This.SigNode = IIF(m.Nodes.length > m.Pos, m.Nodes.item(m.Pos), .NULL.)

		ELSE

			This.SigNode = .NULL.

		ENDIF
		
		RETURN This.SigNode

	ENDFUNC

	FUNCTION CreateNewSignNode (Name AS String, Value AS String) AS MSXML2.IXMLDOMElement

		IF PCOUNT() = 2
			RETURN This.CreateNewNode(XMLDSIG_NS, This.Prefix, m.Name, m.Value)
		ELSE
			RETURN This.CreateNewNode(XMLDSIG_NS, This.Prefix, m.Name)
		ENDIF

	ENDFUNC

	FUNCTION CreateNewNode (Namespace AS String, Prefix AS String, Name AS String, Value AS String) AS MSXML2.IXMLDOMElement

		SAFETHIS

		LOCAL Doc AS MSXML2.DOMDocument60
		LOCAL Node AS MSXML2.IXMLDOMElement

		m.Doc = This.SigNode.ownerDocument

		m.Node = m.Doc.createNode(1, m.Prefix + m.Name, m.Namespace)
		IF PCOUNT() = 4
			m.Node.text = m.Value
		ENDIF

		RETURN m.Node
	ENDFUNC

	PROCEDURE SetCanonicalMethod (Method AS String)

		SAFETHIS

		ASSERT VARTYPE(m.Method) == "C" ;
			MESSAGE "String parameter expected."

		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
		LOCAL SInfo AS MSXML2.IXMLDOMElement
		LOCAL Canon AS MSXML2.IXMLDOMElement

		IF m.Method == C14N OR m.Method == C14N_COMMENTS OR m.Method == EXC_C14N OR m.Method == EXC_C14N_COMMENTS
			This.CanonicalMethod = m.Method
		ELSE
			ERROR "Invalid Canonical method"
		ENDIF

		m.Nodes = This.SigNode.selectNodes(This.SearchPrefix + ":SignedInfo")
		IF m.Nodes.length > 0

			m.SInfo = m.Nodes.item(0)
			
			m.Nodes = m.SInfo.selectNodes(This.SearchPrefix + ":CanonicalizationMethod")
			IF m.Nodes.length = 0
				m.Canon = This.CreateNewSignNode("CanonicalizationMethod")
				m.SInfo.insertBefore(m.Canon, m.SInfo.firstChild)
			ELSE
				m.Canon = m.Nodes.item(0)
			ENDIF

			m.Canon.setAttribute("Algorithm", This.CanonicalMethod)
		ENDIF

	ENDPROC

	FUNCTION CanonicalizeData (Node AS MSXML2.IXMLDOMNode, CanonicalMethod AS String, XPaths AS XMLSecXPath, PrefixList AS Collection) AS String

		LOCAL Canonicalizer AS XMLCanonicalizer
		LOCAL Canonicalized AS String
		LOCAL XPath AS String

		m.XPath = IIF(PCOUNT() > 2 AND !ISNULL(m.XPaths), m.XPaths.Query, "")
		
		m.Canonicalizer = CREATEOBJECT("XMLCanonicalizer")

		m.Canonicalizer.SetMethod(m.CanonicalMethod)

		DO CASE
		CASE PCOUNT() = 3 AND !ISNULL(m.XPaths)
			m.Canonicalized = m.Canonicalizer.Canonicalize(m.Node, m.XPaths.Query)
		CASE PCOUNT() = 4 AND !ISNULL(m.PrefixList)
			m.Canonicalized = m.Canonicalizer.Canonicalize(m.Node, m.XPath, m.PrefixList)
		CASE PCOUNT() > 3 AND !ISNULL(m.XPaths)
			m.Canonicalized = m.Canonicalizer.Canonicalize(m.Node, m.XPaths.Query, m.PrefixList)
		OTHERWISE
			m.Canonicalized = m.Canonicalizer.Canonicalize(m.Node)
		ENDCASE

		RETURN m.Canonicalized
	ENDFUNC

	FUNCTION CanonicalizeSignedInfo () AS String

		SAFETHIS

		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
		LOCAL Node AS MSXML2.IXMLDOMNode
		LOCAL Element AS MSXML2.IXMLDOMElement
		LOCAL CanonicalizationMethod AS String
		
		m.CanonicalizationMethod = ""

		IF TYPE("This.SigNode.ownerDocument") == "O" AND !ISNULL(This.SigNode.ownerDocument)
			m.Nodes = This.SigNode.selectNodes("./" + This.SearchPrefix + ":SignedInfo")
			IF !ISNULL(m.Nodes) AND m.Nodes.length > 0
				m.Node = m.Nodes.item(0)
				m.Nodes = m.Node.selectNodes("./" + This.SearchPrefix + ":CanonicalizationMethod")
				IF !ISNULL(m.Nodes) AND m.Nodes.length > 0
					m.Element = m.Nodes.item(0)
					m.CanonicalizationMethod = m.Element.getAttribute("Algorithm")
				ENDIF
				RETURN This.CanonicalizeData(m.Node, m.CanonicalizationMethod)
			ENDIF
		ENDIF
		
		RETURN .NULL.
	ENDFUNC

	FUNCTION CalculateDigest (Algorithm AS String, Source AS String, Encoded AS Boolean)

		ASSERT !ISNULL(This.SecurityKey) ;
			MESSAGE "XMLSecurityKey not set"

		LOCAL Digest AS String
		LOCAL EncodeBase64 AS Boolean

		m.EncodeBase64 = PCOUNT() = 2 OR m.Encoded

		m.Digest = This.SecurityKey.HashData(m.Algorithm, m.Source)
		IF m.EncodeBase64
			m.Digest = STRCONV(m.Digest, 13)
		ENDIF

		RETURN m.Digest

	ENDFUNC

	FUNCTION ValidateDigest (RefNode AS MSXML2.IXMLDOMElement, Source AS String) AS Boolean

		SAFETHIS

		LOCAL DOM AS MSXML2.DOMDocument60
		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
		LOCAL Element AS MSXML2.IXMLDOMElement
		LOCAL Namespaces AS String
		LOCAL IsValid AS Boolean
		LOCAL CalculatedDigest AS String
		LOCAL StoredDigest AS String

		m.IsValid = .F.

		m.DOM = m.RefNode.ownerDocument
		m.Namespaces = m.DOM.getProperty("SelectionNamespaces")
		m.DOM.setProperty("SelectionNamespaces", "xmlns:" + This.SearchPrefix + '="' + XMLDSIG_NS + '"')
		m.Nodes = m.DOM.selectNodes("./" + This.SearchPrefix + ":DigestMethod")
		IF !ISNULL(m.Nodes) AND m.Nodes.length > 0
			m.Element = m.Nodes.item(0)
			m.CalculatedDigest = This.CalculateDigest(m.Element.getAttribute("Algorithm"), m.Source, .F.)
			m.Nodes = m.DOM.selectNodes("./" + This.SearchPrefix + ":DigestValue")
			IF !ISNULL(m.Nodes) AND m.Nodes.length > 0
				m.Element = m.Nodes.item(0)
				m.StoredDigest = STRCONV(m.Element.text, 14)
				m.IsValid = m.CalculatedDigest == m.StoredDigest
			ENDIF
		ENDIF

		m.DOM.setProperty("SelectionNamespaces", m.Namespaces)

		RETURN m.IsValid

	ENDFUNC

	FUNCTION ProcessTransforms (RefNode AS MSXML2.IXMLDOMElement, ObjData AS MSXML2.IXMLDOMElement, IncludeComments AS Boolean) AS String

		LOCAL DOM AS MSXML2.DOMDocument60
		LOCAL TransformNodes AS MSXML2.IXMLDOMNodeList
		LOCAL TransformNode AS MSXML2.IXMLDOMElement
		LOCAL Element AS MSXML2.IXMLDOMElement
		LOCAL Namespaces AS String
		LOCAL Prefixes AS Collection
		LOCAL XPaths AS XMLSecXPath
		LOCAL CanonicalMethod AS String
		LOCAL Algorithm AS String
		LOCAL IncludeCommentNodes AS Boolean
		LOCAL TokenList AS String
		LOCAL TokenIndex AS Integer
		LOCAL NamespaceNodes AS MSXML2.IXMLDOMNodeList
		LOCAL NamespaceNode AS MSXML2.IXMLDOMElement

		m.DOM = m.RefNode.ownerDocument
		m.DOM.preserveWhiteSpace = .T.
		m.Namespaces = m.DOM.getProperty("SelectionNamespaces")
		m.DOM.setProperty("SelectionNamespaces", "xmlns:" + This.SearchPrefix + '="' + XMLDSIG_NS + '"')
		m.TransformNodes = m.DOM.selectNodes("./" + This.SearchPrefix + ":Transforms/" + This.SearchPrefix + ":Transform")

		m.CanonicalMethod = C14N
		m.Prefixes = .NULL.
		m.XPaths = .NULL.
		m.IncludeCommentNodes = PCOUNT() = 2 OR m.IncludeComments

		IF !ISNULL(m.TransformNodes)

			FOR EACH m.TransformNode IN m.TransformNodes

				m.Algorithm = m.TransformNode.getAttribute("Algorithm")

				DO CASE

				CASE m.Algorithm == EXC_C14N OR m.Algorithm == EXC_C14N_COMMENTS

					IF !m.IncludeCommentNodes
						m.CanonicalMethod = EXC_C14N
					ELSE
						m.CanonicalMethod = m.Algorithm
					ENDIF
					m.Element = m.TransformNode.firstChild
					DO WHILE !ISNULL(m.Element)
						IF m.Element.baseName == "InclusiveNamespaces"
							m.TokenList = m.Element.getAttribute("PrefixList")
							FOR m.TokenIndex = 1 TO GETWORDCOUNT(m.TokenList, " ")
								IF m.TokenIndex = 1
									m.Prefixes = CREATEOBJECT("Collection")
								ENDIF
								m.Prefixes.Add(GETWORDNUM(m.TokenList, m.TokenIndex, " "))
							ENDFOR
							EXIT
						ENDIF
						m.Element = m.Element.nextSibling
					ENDDO

				CASE m.Algorithm == C14N OR m.Algorithm == C14N_COMMENTS

					IF !m.IncludeCommentNodes
						m.CanonicalMethod = C14N
					ELSE
						m.CanonicalMethod = m.Algorithm
					ENDIF

				CASE m.Algorithm == C14N_XPATH

					m.Element = m.TransformNode.firstChild
					DO WHILE !ISNULL(m.Element)
						IF m.Element.baseName == 'XPath'
							m.XPaths = CREATEOBJECT("XMLSecXPath")
							m.XPaths.Query = "(.//. | .//@* | .//namespace::*)[" + m.Element.nodeValue + "]"
							m.NamespaceNodes = m.Element.selectNodes("./namespace::*")
							FOR EACH m.NamespaceNode IN m.NamespaceNodes
								IF m.NamespaceNode.baseName != "xml"
									m.XPaths.Namespaces.Add(m.NamespaceNode.nodeValue, m.NamespaceNode.baseName)
								ENDIF
							ENDFOR
							EXIT
						ENDIF
						m.Element = m.Element.nextSibling
					ENDDO

				ENDCASE
				
			ENDFOR

		ENDIF

		m.DOM.setProperty("SelectionNamespaces", m.Namespaces)

		RETURN This.CanonicalizeData(m.ObjData, m.CanonicalMethod, m.XPaths, m.Prefixes)
		
	ENDFUNC

	FUNCTION ProcessRefNode (RefNode AS MSXML2.IXMLDOMElement) AS Boolean

		LOCAL IncludeCommentNodes AS Boolean
		LOCAL URI AS String
		LOCAL URL AS URL
		LOCAL Identifier AS String
		LOCAL DataObject AS MSXML2.IXMLDOMNode
		LOCAL DataText AS String
		LOCAL DataIsNode AS Boolean
		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
		LOCAL DOM AS MSXML2.DOMDocument60
		LOCAL Namespaces AS String
		LOCAL IdsNamespaces AS String
		LOCAL IdList AS String
		LOCAL IdIndex AS Integer

		m.DataObject = .NULL.
		m.DataIsNode = .F.
		m.Identifier = .NULL.

		m.IncludeCommentNodes = .T.
		m.URL = CREATEOBJECT("url")

		m.URI = m.RefNode.getAttribute("URI")
		IF !EMPTY(NVL(m.URI, ""))
			m.URL.Parse(m.URI)
			IF ISNULL(m.URL.GetComponent(URL_PATH))
				m.Identifier = m.URL.GetComponent(URL_FRAGMENT)
				IF !ISNULL(m.Identifier) AND !EMPTY(m.Identifier)
					m.IncludeCommentNodes = .F.
					m.DOM = m.RefNode.ownerDocument
					m.Namespaces = m.DOM.getProperty("SelectionNamespaces")
					m.IdsNamespaces = ""
					FOR m.IdIndex = 1 TO This.IdNS.Count
						IF !EMPTY(m.IdsNamespaces)
							m.IdsNamespaces = m.IdsNamespaces + " "
						ENDIF
						m.IdsNamespaces = m.IdsNamespaces + TEXTMERGE('xmlns:<<This.IdNS.GetKey(m.IdIndex)>>="<<This.IdNS.Item(m.idIndex)>>"')
					ENDFOR
					m.DOM.setProperty("SelectionNamespaces", m.IdsNamespaces)
					m.IdList = '@Id="' + m.Identifier + '"'
					FOR m.IdIndex = 1 TO This.IdKeys.Count
						m.IdList = m.IdList + TEXTMERGE(' or <<This.IdKeys.Item(m.IdIndex)>>="<<m.Identifier>>"')
					ENDFOR
					m.Nodes = m.DOM.selectNodes("//*[" + m.IdList + "]")
					IF !ISNULL(m.Nodes) AND m.Nodes.length > 0
						m.DataObject = m.Nodes.item(0)
					ENDIF
					m.DOM.setProperty("SelectionNamespaces", m.Namespaces)
					m.DataIsNode = .T.
				ELSE
					m.DataObject = m.RefNode.ownerDocument
				ENDIF
			ELSE
				m.DataObject = m.URL.Load(m.URI)
			ENDIF
		ELSE
			m.IncludeCommentNodes = .F.
			m.DataObject = m.RefNode.ownerDocument
		ENDIF

		m.DataText = This.ProcessTransforms(m.RefNode, m.DataObject, m.IncludeCommentNodes)
		IF !This.ValidateDigest(m.RefNode, m.DataText)
			RETURN .F.
		ENDIF

		IF !ISNULL(m.DataObject) AND !ISNULL(m.DataObject.ownerDocument)
			IF !ISNULL(m.Identifier) AND !EMPTY(m.Identifier)
				This.ValidatedNodes.Add(m.DataObject, m.Identifier)
			ELSE
				This.ValidatedNodes.Add(m.DataObject, "#" + TRANSFORM(This.ValidatedNodes.Count))
			ENDIF
		ENDIF

		RETURN .T.

	ENDFUNC

	FUNCTION GetRefNodeID (RefNode AS MSXML2.IXMLDOMElement) AS String
	
		LOCAL URI AS String
		LOCAL URL AS URL
		LOCAL Identifier AS String

		m.Identifier = .NULL.

		m.URI = m.RefNode.getAttribute("URI")
		IF !EMPTY(NVL(m.URI, ""))
			m.URL = CREATEOBJECT("URL")
			m.URL.Parse(m.URI)
			IF EMPTY(NVL(m.URL.GetComponent(URL_PATH), ""))
				m.Identifier = m.URL.GetComponent(URL_FRAGMENT)
			ENDIF
		ENDIF

		RETURN m.Identifier

	ENDFUNC

	FUNCTION GetRefIDs () AS Collection

		SAFETHIS

		LOCAL RefIDs AS Collection
		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
		LOCAL NodeIndex AS Integer

		m.RefIDs = CREATEOBJECT("Collection")
		m.Nodes = This.SigNode.selectNodes("./" + This.SearchPrefix + ":SignedInfo/" + This.SearchPrefix + ":Reference")
		IF ISNULL(m.Nodes) OR m.Nodes.length = 0
			ERROR "Reference nodes not found."
		ENDIF
		FOR m.NodeIndex = 0 TO m.Nodes.length - 1
			m.RefIDs.Add(This.GetRefNodeID(m.Nodes.item(m.NodeIndex)))
		ENDFOR

		RETURN m.RefIDs

	ENDFUNC

	FUNCTION ValidateReference () AS Boolean
		
		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
		LOCAL NodeIndex AS Integer

		IF !(This.SigNode.xml == This.SigNode.ownerDocument.documentElement.xml)
			IF !ISNULL(This.SigNode.parentNode)
				This.SigNode.parentNode.removeChild(This.SigNode)
			ENDIF
		ENDIF

		This.ValidatedNodes.Remove(-1)

		m.Nodes = This.SigNode.selectNodes("./" + This.SearchPrefix + ":SignedInfo/" + This.SearchPrefix + ":Reference")
		IF ISNULL(m.Nodes) OR m.Nodes.length = 0
			ERROR "Reference nodes not found."
		ENDIF
		FOR m.NodeIndex = 0 TO m.Nodes.length - 1
			IF !This.ProcessRefNode(m.Nodes.item(m.NodeIndex))
				This.ValidatedNodes.Remove(-1)
				ERROR "Reference validation failed."
			ENDIF
		ENDFOR

		RETURN .T.		

	ENDFUNC

	HIDDEN FUNCTION _AddReference (sInfoNode AS MSXML2.IXMLDOMElement, Node AS MSXML2.IXMLDOMElement, Algorithm AS String, Transforms AS Collection, Options AS CollectionOrString)

		LOCAL Prefix AS String
		LOCAL Prefix_NS AS String
		LOCAL Id_Name AS String
		LOCAL Overwrite_Id AS Boolean
		LOCAL Force_URI AS Boolean
		LOCAL URI AS String

		IF PCOUNT() < 4
			m.Transforms = .NULL.
		ENDIF

		m.Prefix = This.GetOption(m.Options, "Prefix", .NULL.)
		m.Prefix_NS = This.GetOption(m.Options, "PrefixNS", .NULL.)
		m.Id_Name = This.GetOption(m.Options, "IdName", "Id")
		m.Overwrite_Id = This.GetOption(m.Options, "OverwriteId", .T., .T.)
		m.Force_URI = This.GetOption(m.Options, "ForceURI", .F., .T.)

		LOCAL AttName AS String
		LOCAL RefNode AS MSXML2.IXMLDOMElement

		m.AttName = IIF(ISNULL(m.Prefix), "", m.Prefix + ":") + m.Id_Name

		m.RefNode = This.CreateNewSignNode("Reference")
		m.sInfoNode.appendChild(m.RefNode)

		IF !(TYPE("m.Node.documentElement") == "O")
			m.URI = ""
			IF !m.Overwrite_Id
				m.URI = m.Node.getAttribute(m.AttName)
			ENDIF
			IF EMPTY(m.URI)
				m.URI = This.GenerateGUID()
				m.Node.setAttribute(m.AttName, m.URI)
			ENDIF
			m.RefNode.setAttribute("URI", "#" + m.URI)
		ELSE
			IF m.Force_URI
				m.RefNode.setAttribute("URI", "")
			ENDIF
		ENDIF

		LOCAL TransNodes AS MSXML2.IXMLDOMElement
		LOCAL TransNode AS MSXML2.IXMLDOMElement
		LOCAL XPathNode AS MSXML2.IXMLDOMElement
		LOCAL SecTransform AS XMLSecTransform
		LOCAL NamespaceIdx AS Integer

		m.TransNodes = This.CreateNewSignNode("Transforms")
		m.RefNode.appendChild(m.TransNodes)

		DO CASE
		CASE !ISNULL(m.Transforms) AND VARTYPE(m.Transforms) == "O"

			FOR EACH m.SecTransform IN m.Transforms 

				m.TransNode = This.CreateNewSignNode("Transform")
				m.TransNodes.appendChild(m.TransNode)

				m.TransNode.setAttribute("Algorithm", m.SecTransform.Algorithm)

				IF m.SecTransform.Algorithm == "http://www.w3.org/TR/1999/REC-xpath-19991116" AND !EMPTY(m.SecTransform.Query)

					m.XPathNode = This.CreateNewSignNode("XPath", m.SecTransform.Query)
					m.TransNode.appendChild(m.XPathNode)

					FOR m.NamespaceIdx = 1 TO m.SecTransform.Namespaces.Count
						m.XPathNode.setAttribute("xmlns:" + m.SecTransform.Namespaces.GetKey(m.NamespaceIdx), m.SecTransform.Namespaces.Item(m.NamespaceIdx))
					ENDFOR
				ENDIF
			ENDFOR

		CASE !ISNULL(m.Transforms) AND VARTYPE(m.Transforms) == "C"
	
			m.TransNode = This.CreateNewSignNode("Transform")
			m.TransNodes.appendChild(m.TransNode)

			m.TransNode.setAttribute("Algorithm", m.Transforms)

		CASE !EMPTY(This.CanonicalMethod)

			m.TransNode = This.CreateNewSignNode("Transform")
			m.TransNodes.appendChild(m.TransNode)

			m.TransNode.setAttribute("Algorithm", This.CanonicalMethod)

		ENDCASE

		LOCAL CanonicalData AS String
		LOCAL DigValue AS String
		LOCAL DigestMethod AS MSXML2.IXMLDOMElement
		LOCAL DigestValue AS MSXML2.IXMLDOMElement

		m.CanonicalData = This.ProcessTransforms(m.RefNode, m.Node)
		m.DigValue = This.CalculateDigest(m.Algorithm, m.CanonicalData)
		m.DigestMethod = This.CreateNewSignNode("DigestMethod")
		m.RefNode.appendChild(m.DigestMethod)
		m.DigestMethod.setAttribute("Algorithm", m.Algorithm)
		m.DigestValue = This.CreateNewSignNode("DigestValue", m.DigValue)
		m.RefNode.appendChild(m.DigestValue)

	ENDFUNC

	FUNCTION AddReference (Node AS MSXML2.IXMLDOMElement, Algorithm AS String, Transforms AS Collection, Options AS CollectionOrString)

		LOCAL Nodes AS MSXML2.IXMLDOMNodeList

		IF TYPE("m.Node.nodeType") != "N" OR !INLIST(m.Node.nodeType, 1, 9)
			ERROR "Node reference must be a document or an element." 
		ENDIF
	
		m.Nodes = This.SigNode.selectNodes(This.SearchPrefix + ":SignedInfo")
		IF m.Nodes.length > 0

			This._AddReference(m.Nodes.item(0), m.Node, m.Algorithm, IIF(PCOUNT() > 2, m.Transforms, .NULL.), IIF(PCOUNT() > 3, m.Options, .NULL.))
			
		ENDIF

	ENDFUNC

   FUNCTION SignData (SKey AS XMLSecurityKey, SData AS String)

        RETURN m.SKey.SignData(m.SData)

	ENDFUNC
	
	FUNCTION Sign (SKey AS XMLSecurityKey, appendToNode AS MSXML2.IXMLDOMElement)

		IF PCOUNT() = 0
			m.SKey = This.SecurityKey
		ENDIF
		IF PCOUNT() < 2
			m.appendToNode = .NULL.
		ENDIF

		IF !ISNULL(m.appendToNode)
			This.AppendSignature(m.appendToNode)
			This.SigNode = m.appendToNode.lastChild
		ENDIF

		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
		LOCAL SInfo AS MSXML2.IXMLDOMElement
		LOCAL SMethod AS MSXML2.IXMLDOMElement
		LOCAL SData AS String
		LOCAL SValue AS String
		LOCAL SValueNode AS MSXML2.IXMLDOMElement
		LOCAL SInfoSibling AS MSXML2.IXMLDOMElement
	
		m.Nodes = This.SigNode.selectNodes("./" + This.SearchPrefix + ":SignedInfo")
		IF m.Nodes.length > 0

			m.SInfo = m.Nodes.item(0)

			m.SMethod = m.SInfo.selectNodes("./" + This.SearchPrefix + ":SignatureMethod").item(0)
			m.SMethod.setAttribute("Algorithm", m.SKey.Type)
			m.SData = This.CanonicalizeData(m.SInfo, This.CanonicalMethod)
			
			m.SValue = STRCONV(This.SignData(m.SKey, m.SData), 13)
			
			m.SValueNode = This.CreateNewSignNode("SignatureValue", m.SValue)
			m.SInfoSibling = m.SInfo.nextSibling
			IF !ISNULL(m.SInfoSibling)
				m.SInfoSibling.parentNode.insertBefore(m.SValueNode, m.SInfoSibling)
			ELSE
				This.SigNode.appendChild(m.SValueNode)
			ENDIF
		ENDIF
	ENDFUNC

	FUNCTION InsertSignature (RefNode AS MSXML2.IXMLDOMElement, BeforeNode AS MSXML2.IXMLDOMElement)

		LOCAL DOM AS MSXML2.DOMDocument60
		LOCAL Signature AS MSXML2.IXMLDOMElement

		m.DOM = m.RefNode.ownerDocument
		m.Signature = m.DOM.importNode(This.SigNode, .T.)
		IF ISNULL(m.BeforeNode)
			RETURN m.RefNode.appendChild(m.Signature)
		ELSE
			RETURN m.RefNode.insertBefore(m.Signature, m.BeforeNode)
		ENDIF

	ENDFUNC

	FUNCTION AppendSignature (ParentNode AS MSXML2.IXMLDOMElement, InsertBefore AS Boolean)

		LOCAL RefNode AS MSXML2.IXMLDOMElement
		LOCAL BeforeNode AS MSXML2.IXMLDOMElement

		m.RefNode = IIF(ISNULL(m.ParentNode.ownerDocument), m.ParentNode.documentElement, m.ParentNode)
		m.BeforeNode = IIF(m.InsertBefore, m.RefNode.firstChild, .NULL.)
		RETURN This.InsertSignature(m.RefNode, m.BeforeNode)

	ENDFUNC

	HIDDEN FUNCTION GetX509Certs (Certs AS String, isPEMFormat AS Boolean) AS Collection

		LOCAL X509Certs AS Collection

		m.X509Certs = CREATEOBJECT("Collection")

		IF m.isPEMFormat

			LOCAL ARRAY CertList(1)
			LOCAL CertIdx AS Integer
			LOCAL InData AS Boolean
			LOCAL CertData AS String

			m.CertData = ""
			m.InData = .F.
			FOR m.CertIdx = 1 TO ALINES(m.CertList, m.Certs, 1)
				IF !m.InData
					m.InData = LEFT(m.CertList(m.CertIdx), 22) == "-----BEGIN CERTIFICATE"
				ELSE
					IF LEFT(m.CertList(m.CertIdx), 20) == "-----END CERTIFICATE"
						m.InData = .F.
						m.X509Certs.Add(m.CertData)
						m.CertData = ""
					ELSE
						m.CertData = m.CertData + m.CertList(m.CertIdx)
					ENDIF
				ENDIF
			ENDFOR
		ELSE
			m.X509Certs.Add(m.Certs)
		ENDIF

		RETURN m.X509Certs

	ENDFUNC

	FUNCTION AddX509Cert (Cert AS String, isPEMFormat AS Boolean, isURL AS Boolean, Options AS CollectionOrString)
		This._AddX509Cert(This.SigNode, m.Cert, m.isPEMFormat, m.isURL, m.Options)
	ENDFUNC

	HIDDEN FUNCTION _AddX509Cert (parentRef AS MSXML2.IXMLDOMElement, Cert AS String, isPEMFormat AS Boolean, isURL AS Boolean, Options AS CollectionOrString)

		LOCAL Certificate AS String

		IF m.isURL
			LOCAL HTTP AS URL

			m.HTTP = CREATEOBJECT("URL")
			m.Certificate = m.HTTP.Load(m.Cert)
		ELSE
			m.Certificate = m.Cert
		ENDIF
			
		LOCAL BaseDoc AS MSXML2.DOMDocument60
		LOCAL Nodes AS MSXML2.IXMLDOMNodeList
		LOCAL KeyInfo AS MSXML2.IXMLDOMElement

		m.BaseDoc = m.parentRef.ownerDocument
		m.BaseDoc.setProperty("SelectionNamespaces", "xmlns:" + This.SearchPrefix + '="' + XMLDSIG_NS + '"')

		LOCAL DSigPfx AS String
		LOCAL Pfx AS String
		m.DSigPfx = ""

		m.Nodes = m.parentRef.selectNodes("./" + This.SearchPrefix + ":KeyInfo")

		IF m.Nodes.length = 0

			m.Nodes = m.parentRef.selectNodes("./namespace::*[. = '" + XMLDSIG_NS + "']")
			IF m.Nodes.length != 0
				m.Pfx = m.Nodes.item(0).baseName
				IF !EMPTY(m.Pfx) AND !(m.Pfx == "xmlns") AND !(m.Pfx == "xml")
					m.DSigPfx = m.Pfx + ":"
				ENDIF
			ENDIF

			LOCAL Inserted AS Boolean

			m.Inserted = .F.
			m.KeyInfo = This.CreateNewNode(XMLDSIG_NS, m.DSigPfx, "KeyInfo")

			m.Nodes = m.parentRef.selectNodes("./" + This.SearchPrefix + ":Object")
			IF m.Nodes.length != 0
				m.Nodes.item(0).parentNode.insertBefore(m.KeyInfo, m.Nodes.item(0))
				m.Inserted = .T.
			ENDIF

			IF !m.Inserted
				m.parentRef.appendChild(m.KeyInfo)
			ENDIF

		ELSE

			m.Nodes = m.KeyInfo.selectNodes("./namespace::*[. = '" + XMLDSIG_NS + "']")
			IF m.Nodes.length != 0
				m.Pfx = m.Nodes.item(0).baseName
				IF !EMPTY(m.Pfx) AND !(m.Pfx == "xmlns") AND !(m.Pfx == "xml")
					m.DSigPfx = m.Pfx + ":"
				ENDIF
			ENDIF

		ENDIF

		LOCAL Certs AS Collection

		m.Certs = This.GetX509Certs(m.Certificate, m.isPEMFormat)

		LOCAL X509DataNode AS MSXML2.IXMLDOMElement
		LOCAL X509SubjectNode AS MSXML2.IXMLDOMElement
		LOCAL X509IssuerNode AS MSXML2.IXMLDOMElement
		LOCAL X509Node AS MSXML2.IXMLDOMElement
		LOCAL X509CertNode AS MSXML2.IXMLDOMElement
		LOCAL X509Cert AS String

		m.X509DataNode = This.CreateNewNode(XMLDSIG_NS, m.DSigPfx, "X509Data")
		m.KeyInfo.appendChild(m.X509DataNode)

		LOCAL IssuerSerial AS Boolean, SubjectName AS Boolean
		
		STORE .F. TO m.IssuerSerial, m.SubjectName

		m.IssuerSerial = This.GetOption(m.Options, "IssuerSerial", .F., .T.)
		m.SubjectName = This.GetOption(m.Options, "SubjectName", .F., .T.)

		LOCAL CertData AS Collection
		LOCAL CertProperty
		LOCAL CertPropertyIndex AS Integer
		LOCAL SubjectNameValue AS String
		LOCAL IssuerNameValue AS String

		FOR EACH m.X509Cert IN m.Certs

			IF m.IssuerSerial OR m.SubjectName

				m.CertData = This.SecurityKey.ParseX509Certificate("-----BEGIN CERTIFICATE-----" + CHR(13) + m.X509Cert + "-----END CERTIFICATE-----" + CHR(13))

				IF m.CertData.Count > 0

					IF m.SubjectName AND m.CertData.GetKey("Subject") != 0
						m.CertProperty = m.CertData.Item("Subject")
						IF TYPE("m.CertProperty") == "O"
							m.SubjectNameValue = ""
							FOR m.CertPropertyIndex = 1 TO m.CertProperty.Count
								m.SubjectNameValue = m.SubjectNameValue + IIF(EMPTY(m.SubjectNameValue), "", ",") + ;
									m.CertProperty.GetKey(m.CertPropertyIndex) + "=" + m.CertProperty.Item(m.CertPropertyIndex)
							ENDFOR
						ELSE
							m.SubjectNameValue = m.CertProperty
						ENDIF

						m.X509SubjectNode = This.CreateNewNode(XMLDSIG_NS, m.DSigPfx, "X509SubjectName", m.SubjectNameValue)
						m.X509DataNode.appendChild(m.X509SubjectNode)

					ENDIF

					IF m.IssuerSerial AND m.CertData.GetKey("Issuer") != 0 AND m.CertData.GetKey("SerialNumber") != 0
						m.CertProperty = m.CertData.Item("Issuer")
						IF TYPE("m.CertProperty") == "O"
							m.IssuerNameValue = ""
							FOR m.CertPropertyIndex = 1 TO m.CertProperty.Count
								m.IssuerNameValue = m.IssuerNameValue + IIF(EMPTY(m.IssuerNameValue), "", ",") + ;
									m.CertProperty.GetKey(m.CertPropertyIndex) + "=" + m.CertProperty.Item(m.CertPropertyIndex)
							ENDFOR
						ELSE
							m.IssuerNameValue = m.CertProperty
						ENDIF

						m.X509IssuerNode = This.CreateNewNode(XMLDSIG_NS, m.DSigPfx, "X509IssuerSerial")

						m.X509Node = This.CreateNewNode(XMLDSIG_NS, m.DSigPfx, "X509IssuerName", m.IssuerNameValue)
						m.X509IssuerNode.appendChild(m.X509Node)

						m.X509Node = This.CreateNewNode(XMLDSIG_NS, m.DSigPfx, "X509SerialNumber", m.CertData.Item("SerialNumber"))
						m.X509IssuerNode.appendChild(m.X509Node)

						m.X509DataNode.appendChild(m.X509IssuerNode)

					ENDIF
				ENDIF
			ENDIF

			m.X509CertNode = This.CreateNewNode(XMLDSIG_NS, m.DSigPfx, "X509Certificate", m.X509Cert)
			m.X509DataNode.appendChild(m.X509CertNode)

		ENDFOR

	ENDFUNC

	FUNCTION GenerateGUID (Prefix AS String) AS String

		ASSERT PCOUNT() = 0 OR VARTYPE(m.Prefix) == "C" ;
			MESSAGE "String parameter expected."

		IF PCOUNT() = 0
			m.Prefix = "pfx"
		ENDIF

		This.GUID.Create()

		RETURN m.Prefix + STREXTRACT(This.GUID.ToString(), "{", "}")

	ENDFUNC

	HIDDEN FUNCTION GetOption (Options AS CollectionOrString, Option AS String, DefaultValue AS AnyType, EvaluateValue AS Boolean) AS AnyType

		LOCAL Returned AS AnyType

		m.Returned = m.DefaultValue

		DO CASE
		CASE ISNULL(m.Options)
		CASE TYPE("m.Options") == "O"
			IF m.Options.GetKey(m.Option) != 0
				m.Returned = m.Options(m.Option)
			ENDIF
		CASE TYPE("m.Options") == "C"
			IF m.Option + "=" $ m.Options
				m.Returned = STREXTRACT(m.Options, m.Option + "=", ";", 1, 2)
				IF !EMPTY(m.Returned)
					IF m.EvaluateValue
						m.Returned = EVALUATE(m.Returned)
					ENDIF
				ELSE
					m.Returned = m.DefaultValue
				ENDIF
			ENDIF
		ENDCASE

		RETURN m.Returned

	ENDFUNC

ENDDEFINE

DEFINE CLASS XMLSecXPath AS Custom

	ADD OBJECT Namespaces AS Collection
	Query = ""

ENDDEFINE

DEFINE CLASS XMLSecTransform AS XMLSecXPath

	Algorithm = "http://www.w3.org/TR/1999/REC-xpath-19991116"

ENDDEFINE

	