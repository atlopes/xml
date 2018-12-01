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

LOCAL XEnc AS XMLSecurityEnc
LOCAL OKey AS XMLSecurityKey
LOCAL SKey AS XMLSecurityKey
LOCAL KLib AS XMLSecurityLib
LOCAL XML AS MSXML2.DOMDocument60

* load the XML document that will be encrypted
m.XML = CREATEOBJECT("MSXML2.DOMDocument.6.0")
m.XML.async = .F.
m.XML.Load("hw.xml")
MESSAGEBOX(m.XML.XML)

* instantiate a security library
m.KLib = CREATEOBJECT("XMLSecurityLibChilkat")

* instantiate a public key object
m.SKey = CREATEOBJECT("XMLSecurityKey", RSA_OAEP_MGF1P, "public")
* attach the crypto library to it
m.SKey.SetLibrary(m.KLib)
* and load the key
m.SKey.LoadKey("alice-cert.pem", .T., .F.)

* instantiate a session key for the object
m.OKey = CREATEOBJECT("XMLSecurityKey", AES256_CBC)
* attach the crypto library to it (may be reused)
m.OKey.SetLibrary(m.KLib)
* and generate a key
m.OKey.GenerateSessionKey()

* instantiate an encryption object
m.XEnc = CREATEOBJECT("XMLSecurityEnc")

* set the node that will be encrypted
m.XEnc.SetNode(m.XML.Documentelement)

* encrypt the key
m.XEnc.EncryptKey(m.SKey, m.OKey)

* and now the data
m.XEnc.Type = ELEMENT_URI
m.XEnc.EncryptNode(m.OKey)

* save the encrypted document
m.XML.Save("test-hw-encrypt.xml")
MESSAGEBOX(m.XML.XML)