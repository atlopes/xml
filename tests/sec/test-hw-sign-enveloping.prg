CLEAR

SET DEFAULT TO (JUSTPATH(SYS(16)))

DO LOCFILE("xml-security-enc.prg")
DO LOCFILE("xml-security-key.prg")
DO LOCFILE("xml-security-lib-openssl.prg")

#INCLUDE "..\..\xml-security.h"

LOCAL DSig AS XMLSecurityDSig
LOCAL SKey AS XMLSecurityKey
LOCAL KLib AS XMLSecurityLib
LOCAL XML AS MSXML2.DOMDocument60
LOCAL Obj AS MSXML2.IXMLDOMElement

* load the XML document that will be signed
m.XML = CREATEOBJECT("MSXML2.DOMDocument.6.0")
m.XML.preserveWhiteSpace = .T.
m.XML.async = .F.
m.XML.Load("hw.xml")
MESSAGEBOX(m.XML.XML)

* instantiate a security library
m.KLib = CREATEOBJECT("XMLSecurityLibOpenSSL")

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

* import the enveloped object into the Signature element
m.Obj = m.DSig.AddObjectElement(m.XML) 

* add a reference to the signed object
m.DSig.AddReference(m.Obj, HASH_SHA1, .NULL., "ForceURI=.T.")

* set a canonicalization method that will normalize the document and the signature
m.DSig.SetCanonicalMethod(EXC_C14N)

* now sign it
m.DSig.Sign()

* and add the key info, based on the X509 certificate
m.DSig.AddX509Cert(FILETOSTR("alice-cert.pem"), .T.)

* all is done, just save the signed document, enveloped by the signature
m.DSig.Save("test-hw-sign-enveloping.xml")
MESSAGEBOX(FILETOSTR("test-hw-sign-enveloping.xml"))

