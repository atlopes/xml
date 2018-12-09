*
* XMLSecurityLib - OpenSSL implementation
*

IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-security.h"

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSecurityLibOpenSSL AS XMLSecurityLib

	FUNCTION Init (OpenSSL_DLL AS String)

		LOCAL ARRAY Declared(1)

		ADLLS(m.Declared)
		IF ASCAN(m.Declared, "OpenSSL_CipherCtxFree") = 0

			IF PCOUNT() = 0
				m.OpenSSL_DLL = "libcrypto-1_1.dll"			&& must be somewhere in VFP's path
			ENDIF

			DECLARE INTEGER EVP_EncryptInit_ex IN (m.OpenSSL_DLL) AS OpenSSL_EncryptInitEx ;
				INTEGER Context, INTEGER CipherType, INTEGER Engine, STRING Key, STRING IV
			DECLARE INTEGER EVP_EncryptUpdate IN (m.OpenSSL_DLL) AS OpenSSL_EncryptUpdate ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength, STRING In, INTEGER InLength
			DECLARE INTEGER EVP_EncryptFinal_ex  IN (m.OpenSSL_DLL) AS OpenSSL_EncryptFinalEx ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength

			DECLARE INTEGER EVP_DecryptInit_ex IN (m.OpenSSL_DLL) AS OpenSSL_DecryptInitEx ;
				INTEGER Context, INTEGER CipherType, INTEGER Engine, STRING Key, STRING IV
			DECLARE INTEGER EVP_DecryptUpdate IN (m.OpenSSL_DLL) AS OpenSSL_DecryptUpdate ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength, STRING In, INTEGER InLength
			DECLARE INTEGER EVP_DecryptFinal_ex  IN (m.OpenSSL_DLL) AS OpenSSL_DecryptFinalEx ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength

			DECLARE INTEGER EVP_aes_128_cbc IN (m.OpenSSL_DLL) AS OpenSSL_AES128CBC
			DECLARE INTEGER EVP_aes_192_cbc IN (m.OpenSSL_DLL) AS OpenSSL_AES192CBC
			DECLARE INTEGER EVP_aes_256_cbc IN (m.OpenSSL_DLL) AS OpenSSL_AES256CBC
			DECLARE INTEGER EVP_des_ede3_cbc IN (m.OpenSSL_DLL) AS OpenSSL_DESEDE3CBC

			DECLARE INTEGER RAND_bytes IN (m.OpenSSL_DLL) AS OpenSSL_RandBytes ;
				STRING @ Buf, INTEGER Num

			DECLARE INTEGER EVP_CIPHER_CTX_new IN (m.OpenSSL_DLL) AS OpenSSL_CipherCtxNew
			DECLARE INTEGER EVP_CIPHER_CTX_free IN (m.OpenSSL_DLL) AS OpenSSL_CipherCtxFree INTEGER Context

		ENDIF

	ENDFUNC

	FUNCTION DecryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION DecryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION DecryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String

		LOCAL Context AS Integer
		LOCAL CipherName AS String
		LOCAL Cipher AS Integer

		m.CipherName = m.XMLKey.CryptParams("Cipher")
		DO CASE
		CASE m.CipherName == "des-ede3-cbc"
			m.Cipher = OpenSSL_DESEDE3CBC()
		CASE m.CipherName == "aes-128-cbc"
			m.Cipher = OpenSSL_AES128CBC()
		CASE m.CipherName == "aes-192-cbc"
			m.Cipher = OpenSSL_AES192CBC()
		CASE m.CipherName == "aes-256-cbc"
			m.Cipher = OpenSSL_AES256CBC()
		OTHERWISE
			RETURN .NULL.
		ENDCASE

		LOCAL PaddedData AS String
		LOCAL SecretKey AS String
		LOCAL IV AS String

		m.IV = LEFT(m.Data, m.XMLKey.CryptParams("BlockSize"))

		m.PaddedData = SUBSTR(m.Data, m.XMLKey.CryptParams("BlockSize") + 1)

		m.SecretKey = m.XMLKey.Key

		LOCAL BlockDecrypted AS String
		LOCAL BlockLength AS Integer
		LOCAL Decrypted AS String

		m.Context = OpenSSL_CipherCtxNew()
		IF !EMPTY(m.Context)

			OpenSSL_DecryptInitEx(m.Context, m.Cipher, 0, m.SecretKey, m.IV)

			m.BlockDecrypted = REPLICATE(CHR(0), LEN(m.Data) * 2)
			m.BlockLength = 0

			OpenSSL_DecryptUpdate(m.Context, @m.BlockDecrypted, @m.BlockLength, m.PaddedData, LEN(m.PaddedData))
			m.PaddedData = LEFT(m.BlockDecrypted, m.BlockLength)

			m.BlockLength = 0

			OpenSSL_DecryptFinalEx(m.Context, @m.BlockDecrypted, @m.BlockLength)
			m.PaddedData = m.PaddedData + LEFT(m.BlockDecrypted, m.BlockLength)

			OpenSSL_CipherCtxFree(m.Context)

			RETURN This.UnpadISO10126(m.PaddedData)
		ELSE
			RETURN .NULL.
		ENDIF

	ENDFUNC

	FUNCTION EncryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION EncryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String
	
		ERROR "Not implemented."

	ENDFUNC

	FUNCTION EncryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String

		LOCAL Context AS Integer
		LOCAL CipherName AS String
		LOCAL Cipher AS Integer

		m.CipherName = m.XMLKey.CryptParams("Cipher")
		DO CASE
		CASE m.CipherName == "des-ede3-cbc"
			m.Cipher = OpenSSL_DESEDE3CBC()
		CASE m.CipherName == "aes-128-cbc"
			m.Cipher = OpenSSL_AES128CBC()
		CASE m.CipherName == "aes-192-cbc"
			m.Cipher = OpenSSL_AES192CBC()
		CASE m.CipherName == "aes-256-cbc"
			m.Cipher = OpenSSL_AES256CBC()
		OTHERWISE
			RETURN .NULL.
		ENDCASE

		LOCAL PaddedData AS String
		LOCAL SecretKey AS String
		LOCAL IV AS String

		m.IV = This.RandomBytes(m.XMLKey.CryptParams("BlockSize"))

		m.PaddedData = This.PadISO10126(m.Data, m.XMLKey.CryptParams("BlockSize"))

		m.SecretKey = m.XMLKey.Key
		IF ISNULL(m.SecretKey) OR EMPTY(m.SecretKey)
			m.SecretKey = This.RandomBytes(m.XMLKey.CryptParams("KeySize") * 8)
			m.XMLKey.Key = m.SecretKey
		ENDIF

		LOCAL Encrypted AS String
		LOCAL BlockEncrypted AS String
		LOCAL BlockLength AS String

		m.Context = OpenSSL_CipherCtxNew()

		IF !EMPTY(m.Context)

			m.BlockEncrypted = REPLICATE(CHR(0), LEN(m.PaddedData) * 2 + LEN(m.IV) * 2) 
			m.BlockLength = 0

			OpenSSL_EncryptInitEx(m.Context, m.Cipher, 0, m.SecretKey, m.IV)
			OpenSSL_EncryptUpdate(m.Context, @m.BlockEncrypted, @m.BlockLength, m.PaddedData, LEN(m.PaddedData))

			m.Encrypted = LEFT(m.BlockEncrypted, m.BlockLength)
			m.BlockLength = 0

			OpenSSL_EncryptFinalEx(m.Context, @m.BlockEncrypted, @m.BlockLength)
			m.Encrypted = m.Encrypted + LEFT(m.BlockEncrypted, m.BlockLength)

			OpenSSL_CipherCtxFree(m.Context)

			RETURN m.IV + m.Encrypted

		ELSE

			RETURN .NULL.

		ENDIF

	ENDFUNC

	FUNCTION GetPrivateKey (PEM AS String, Password AS String) AS Object

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION GetPublicKey (Cert AS String, IsCert AS Boolean) AS Object

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION RandomBytes (Size AS Integer) AS String

		LOCAL Bytes AS String

		m.Bytes = REPLICATE(CHR(0), m.Size)
		OpenSSL_RandBytes(@m.Bytes, m.Size)

		RETURN m.Bytes

	ENDFUNC

	FUNCTION Hash (AlgorithmCode AS String, ToHash AS String) AS String

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION SHA1 (ToHash AS String) AS String

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION SignData (Data AS String, XMLKey AS XMLSecurityKey) AS String

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION VerifySignature (Data AS String, Signature AS String,	XMLKey AS XMLSecurityKey) AS Boolean

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION X509Export (Cert AS String) AS String

		ERROR "Not implemented."

	ENDFUNC

	FUNCTION X509Parse (Cert AS String) AS String

		ERROR "Not implemented."

	ENDFUNC

ENDDEFINE
