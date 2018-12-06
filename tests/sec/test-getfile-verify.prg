CLEAR

SET DEFAULT TO (JUSTPATH(SYS(16)))

*!*	make sure the Chilkat components are unlocked
*!*	LOCAL Chilkat AS Chilkat_v9_5_0.ChilkatGlobal

*!*	m.Chilkat = CREATEOBJECT("Chilkat_9_5_0.Global")
*!*	m.Chilkat.Unlockbundle(your unlock key)

DO LOCFILE("xml-security-enc.prg")
DO LOCFILE("xml-security-key.prg")
DO LOCFILE("xml-security-lib-chilkat.prg")

#INCLUDE "..\..\xml-security.h"

LOCAL DSig AS XMLSecurityDSig
LOCAL SKey AS XMLSecurityKey
LOCAL Enc AS XMLSecurityEnc
LOCAL KLib AS XMLSecurityLib
LOCAL XML AS MSXML2.DOMDocument60
LOCAL Signature AS MSXML2.IXMLDOMElement
LOCAL CertInfo AS Collection

* ask for the XML document that will be verified
m.XML = CREATEOBJECT("MSXML2.DOMDocument.6.0")
* setting this to False will change the way the document is read,
* and therefore will issue a "Verification failed!" message
m.XML.preserveWhiteSpace = .T.
m.XML.async = .F.
m.XML.Load(GETFILE("xml"))
* a first view of the signed document
MESSAGEBOX(m.XML.XML)

* instantiate a security library
m.KLib = CREATEOBJECT("XMLSecurityLibChilkat")
* and a support encryption object (to retreive key info from the signed document)
m.Enc = CREATEOBJECT("XMLSecurityEnc")
m.Enc.SetKeyLibrary(m.KLib)

* instantiate a dummy key object to access the key operations
m.SKey = CREATEOBJECT("XMLSecurityKey", RSA_SHA1, "public", m.KLib)

* instantiate a signature object
m.DSig = CREATEOBJECT("XMLSecurityDSig")

* attach the key object to it
m.DSig.SetXMLkey(m.SKey)

* locate the signature in the signed document
m.Signature = m.DSig.LocateSignature(m.XML)
IF ISNULL(m.Signature)
	ERROR "Cannot locate the signature in the signed document."
ENDIF

* canonicalize the SignedInfo element from the Signature
IF ISNULL(m.DSig.CanonicalizeSignedInfo())
	ERROR "Cannot canonicalize SignedInfo."
ENDIF

* fetch the public info on the key
IF ISNULL(m.Enc.LocateKeyInfo(m.SKey, m.Signature))
	ERROR "Cannot load the information into the key."
ENDIF

IF m.DSig.Verify()
	MESSAGEBOX("Signature is valid!")
	IF !ISNULL(m.SKey.X509Certificate)
		m.CertInfo = m.SKey.ParseX509Certificate(m.SKey.X509Certificate)
		MESSAGEBOX(TEXTMERGE("Issuer: <<m.CertInfo('Issuer')>>"))
	ENDIF
ELSE
	MESSAGEBOX("Verification failed!")
ENDIF
