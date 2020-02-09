*
* XMLSecurityLib - foxCryptoNG implementation
*

IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-security.h"

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSecurityLibFoxCryptoNG AS XMLSecurityLib

	Crypto = .NULL.

	_MemberData = "<VFPData>" + ;
						'<memberdata name="crypto" type="property" display="Crypto"/>' + ;
						"</VFPData>"

	FUNCTION Init

		TRY
			IF _VFP.StartMode = 0
				This.Crypto = NEWOBJECT("foxCryptoNG", (LOCFILE("foxCryptoNG.prg")))
			ELSE
				This.Crypto = NEWOBJECT("foxCryptoNG", "foxCryptoNG.prg")
			ENDIF
		CATCH
			This.Crypto = .NULL.
		ENDTRY

		IF ISNULL(This.Crypto)
			RETURN .NULL.
		ENDIF

	ENDFUNC

*!*		FUNCTION DecryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String
*!*			RETURN ""
*!*		ENDFUNC

*!*		FUNCTION DecryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String
*!*			RETURN ""
*!*		ENDFUNC

	FUNCTION DecryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String

		IF !(UPPER(LEFT(m.XMLKey.CryptParams("Algorithm"), 3)) == "AES")
			RETURN .NULL.
		ENDIF

		LOCAL PaddedData AS String
		LOCAL EncryptedData AS String
		LOCAL SecretKey AS String
		LOCAL IV AS String

		m.IV = LEFT(m.Data, m.XMLKey.CryptParams("BlockSize"))

		m.EncryptedData = SUBSTR(m.Data, m.XMLKey.CryptParams("BlockSize") + 1)

		m.SecretKey = m.XMLKey.Key

		LOCAL Decrypted AS String

		m.Decrypted = .NULL.

		m.PaddedData = This.Crypto.Decrypt_AES(m.EncryptedData, m.SecretKey, m.IV)
		IF !EMPTY(m.PaddedData)
			m.Decrypted = This.UnpadISO10126(LEFT(m.PaddedData, LEN(m.PaddedData) - m.XMLKey.CryptParams("BlockSize")))
		ENDIF

		RETURN m.Decrypted

	ENDFUNC

*!*		FUNCTION EncryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String
*!*			RETURN ""
*!*		ENDFUNC

*!*		FUNCTION EncryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String
*!*			RETURN ""
*!*		ENDFUNC

	FUNCTION EncryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String

		LOCAL PaddedData AS String
		LOCAL SecretKey AS String
		LOCAL IV AS String
		LOCAL BSize AS Integer
		LOCAL Encrypted AS String

		IF !(UPPER(LEFT(m.XMLKey.CryptParams("Algorithm"), 3)) == "AES")
			RETURN .NULL.
		ENDIF

		m.BSize = m.XMLKey.CryptParams("BlockSize")
		m.PaddedData = This.PadISO10126(m.Data, m.BSize)

		m.IV = This.RandomBytes(m.BSize)

		m.SecretKey = m.XMLKey.Key
		IF ISNULL(m.SecretKey) OR EMPTY(m.SecretKey)
			m.SecretKey = This.RandomBytes(m.XMLKey.CryptParams("KeySize"))
			m.XMLKey.Key = m.SecretKey
		ENDIF

		m.Encrypted = This.Crypto.Encrypt_AES(m.PaddedData, m.SecretKey, m.IV)
		IF !EMPTY(m.Encrypted)
			RETURN m.IV + m.Encrypted
		ELSE
			RETURN .NULL.
		ENDIF

	ENDFUNC

*!*		FUNCTION GetPrivateKey (Cert AS String, Password AS String) AS String
*!*			RETURN ""
*!*		ENDFUNC

*!*		FUNCTION GetPublicKey (Cert AS String, IsCert AS Boolean) AS String
*!*			RETURN ""
*!*		ENDFUNC

	FUNCTION RandomBytes (Size AS Integer) AS String

		LOCAL BIndex AS Integer
		LOCAL RandomBytes AS String

		m.RandomBytes = ""
		FOR m.BIndex = 1 TO m.Size
			m.RandomBytes = m.RandomBytes + CHR(INT(RAND() * 255))
		ENDFOR

		RETURN m.RandomBytes

	ENDFUNC

	FUNCTION Hash (AlgorithmCode AS String, ToHash AS String) AS String

		LOCAL HashedData AS String

		DO CASE
		CASE m.AlgorithmCode == HASH_SHA1
			m.AlgorithmName = "SHA1"
		CASE m.AlgorithmCode == HASH_SHA256
			m.AlgorithmName = "SHA256"
		CASE m.AlgorithmCode == HASH_SHA384
			m.AlgorithmName = "SHA384"
		CASE m.AlgorithmCode == HASH_SHA512
			m.AlgorithmName = "SHA512"
		CASE m.AlgorithmCode == HASH_RIPEMD160
			m.AlgorithmName = "RIPEMD160"
		OTHERWISE
			RETURN .NULL.
		ENDCASE

		m.HashedData = This.Crypto.HashData(m.AlgorithmName, m.ToHash)

		IF EMPTY(m.HashedData)
			RETURN .NULL.
		ELSE
			RETURN STRCONV(m.HashedData, 16)
		ENDIF

	ENDFUNC

	FUNCTION SHA1 (ToHash AS String) AS String
		RETURN STRCONV(This.Hash(HASH_SHA1, m.ToHash), 15)
	ENDFUNC

*!*		FUNCTION SignData (Data AS String, XMLKey AS XMLSecurityKey)
*!*			RETURN ""
*!*		ENDFUNC

*!*		FUNCTION VerifySignature (Data AS String, Signature AS String, XMLKey AS XMLSecurityKey)
*!*			RETURN ""
*!*		ENDFUNC

*!*		FUNCTION X509Export (Cert AS String) AS String
*!*			RETURN ""
*!*		ENDFUNC

*!*		FUNCTION X509Parse (Cert AS String) AS Collection
*!*			RETURN .NULL.
*!*		ENDFUNC

ENDDEFINE
