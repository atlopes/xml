*
* XMLSecEnc
*

DO LOCFILE("xml-security-dsig.prg")

IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-security.h"

DEFINE CLASS XMLSecEnc AS Custom

	ADD OBJECT References AS Collection
	ADD OBJECT ImportXMLSecurityDSig AS XMLSecurityDSig NOINIT

	PROTECTED EncDoc
	PROTECTED RawNode
	
	EncDoc = .NULL.
	RawNode = .NULL.
	Type = .NULL.
	EncKey = .NULL.

	FUNCTION Init
		This._resetTemplate()
	ENDFUNC
	
	HIDDEN PROCEDURE _resetTemplate

		This.EncDoc = .NULL.
		This.EncDoc = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		This.EncDoc.async = .F.
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

ENDDEFINE

DEFINE CLASS _XMLSecEnc_Reference AS Custom

	Node = .NULL.
	Type = .NULL.
	EncNode = .NULL.
	RefURI = .NULL.

ENDDEFINE
