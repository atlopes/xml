CLEAR

SET DEFAULT TO (JUSTPATH(SYS(16)))

DO LOCFILE("xml-security-enc.prg")
DO LOCFILE("xml-security-key.prg")
DO LOCFILE("xml-security-lib-foxcryptong.prg")

#INCLUDE "..\..\xml-security.h"

LOCAL XEnc AS XMLSecurityEnc
LOCAL KeyContext AS XMLSecurityEnc
LOCAL EncKey AS XMLSecurityKey
LOCAL DecKeyInfo AS XMLSecurityKey
LOCAL DecKey AS String
LOCAL KLib AS XMLSecurityLib
LOCAL XML AS MSXML2.DOMDocument60
LOCAL EncData AS MSXML2.IXMLDOMElement

* load the XML document that will be decrypted
m.XML = CREATEOBJECT("MSXML2.DOMDocument.6.0")
m.XML.async = .F.
* this comes from a previous test
m.XML.Load("test-hw-encrypt-symmetric-fng.xml")
MESSAGEBOX(m.XML.xml)

* instantiate a security library
m.KLib = CREATEOBJECT("XMLSecurityLibFoxCryptoNG")

* instantiate an encryption object
m.XEnc = CREATEOBJECT("XMLSecurityEnc")
* and set its key library
m.XEnc.SetKeyLibrary(m.KLib)

* locate the encrypted data inside the XML document
m.EncData = m.XEnc.LocateEncryptedData(m.XML)
IF ISNULL(m.EncData)
	ERROR "Cannot locate encrypted data."
ENDIF

* prepare the decryption process, based on the encrypted data
m.XEnc.SetNode(m.EncData)
m.XEnc.Type = m.EncData.getAttribute("Type")

* get the key in the encrypted document
m.EncKey = m.XEnc.LocateKey()
IF ISNULL(m.EncKey)
	ERROR "Cannot locate encrypted key."
ENDIF

* and its info (used algorithm and ciphered data)
m.DecKeyInfo = m.XEnc.LocateKeyInfo(m.EncKey)
IF !m.DecKeyInfo.IsEncrypted
	ERROR "Encryption key info not encrypted."
ENDIF

* decrypt the key (we must know the key for decrypting it, of course)
m.KeyContext = m.DecKeyInfo.EncryptedCtx
m.DecKeyInfo.LoadKey(PADR("sharedSecretKey", m.DecKeyInfo.CryptParams("KeySize"), "*"))
m.DecKey = m.KeyContext.DecryptKey(m.DecKeyInfo)

* now, we can decrypt the data / document
* by using the decrypted key
m.EncKey.LoadKey(m.DecKey)

* the decrypted version will replace the encrypted one
m.XEnc.DecryptNode(m.EncKey)

m.XML.Save("test-hw-decrypt-symmetric.xml")

* a quick look...
MESSAGEBOX(m.XML.xml)
