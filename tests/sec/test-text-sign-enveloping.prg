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
LOCAL KLib AS XMLSecurityLib
LOCAL Source AS String
LOCAL Obj AS MSXML2.IXMLDOMElement

* load the text that is going to be signed
TEXT TO m.Source NOSHOW
An arbitrary text that is going to be signed.
The XML signature will envelope the text
(under an Object element).
ENDTEXT

* instantiate a security library
m.KLib = CREATEOBJECT("XMLSecurityLibChilkat")

* instantiate a private key object
m.SKey = CREATEOBJECT("XMLSecurityKey", RSA_SHA1, "private")
* attach the crypto library to it
m.SKey.SetLibrary(m.KLib)
* and load the private key
m.SKey.LoadKey("alice-privkey.pem", .T., .F.)

* instantiate a signature object
m.DSig = CREATEOBJECT("XMLSecurityDSig")

* attach the key object to it
m.DSig.SetXMLkey(m.SKey)

* import the text into the Signature element
m.Obj = m.DSig.AddObjectElement(m.Source) 

* add a reference to the signed object
m.DSig.AddReference(m.Obj, HASH_SHA1, .NULL., "ForceURI=.T.")

* set a canonicalization method that will normalize the document and the signature
m.DSig.SetCanonicalMethod(EXC_C14N)

* now sign it
m.DSig.Sign()

* and add the key info, based on the X509 certificate
m.DSig.AddX509Cert(FILETOSTR("alice-cert.pem"), .T.)

* all is done, just save the signed document, enveloped by the signature
m.DSig.Save("test-text-sign-enveloping.xml")
