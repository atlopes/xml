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
LOCAL Segment AS MSXML2.IXMLDOMElement

* load the XML document that will be signed
m.XML = CREATEOBJECT("MSXML2.DOMDocument.6.0")
m.XML.preserveWhiteSpace = .T.
m.XML.async = .F.
m.XML.Load("hw.xml")
MESSAGEBOX(m.XML.xml)

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

* set a canonicalization method that will normalize the document and the signature
m.DSig.SetCanonicalMethod(EXC_C14N)

* add a reference to the signed object (in this case, a segment of the document)
m.Segment = m.XML.selectNodes("//Child").item(0)
m.DSig.AddReference(m.Segment, HASH_SHA1, "http://www.w3.org/2000/09/xmldsig#enveloped-signature")

* now sign it
m.DSig.Sign()
* and add the key info, based on the X509 certificate
m.DSig.AddX509Cert(FILETOSTR("alice-cert.pem"), .T.)

* all is done, just append the signature to the XML document
m.DSig.AppendSignature(m.XML)

* and save the signed document
m.XML.Save("test-hw-child-sign.xml")
MESSAGEBOX(m.XML.xml)
