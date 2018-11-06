*
* XMLSecurityKey
*

DO LOCFILE("xml-security-lib.prg")

IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-security.h"

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSecurityKey AS Custom

	ADD OBJECT CryptParams AS Collection

	* Key
	Key = .NULL.
	* Key type
	Type = .NULL.
	* Pass phrase to access private key
	PassPhrase = ""
	* X509 Certificate
	X509Certificate = .NULL.
	X509Thumbprint = .NULL.
	* EncryptedKey context
	IsEncrypted = .F.
	EncryptedCtx = .NULL.
	* Encryption library
	Library = .NULL.

	FUNCTION Init (KeyType AS String, Scope AS String)

		SAFETHIS

		LOCAL MissingScope AS Boolean

		m.MissingScope  = .F.

		DO CASE
		CASE m.KeyType == TRIPLEDES_CBC

			This.CryptParams.Add("des-ede3-cbc", "Cipher")
			This.CryptParams.Add("symmetric", "Type")
			This.CryptParams.Add(m.KeyType, "Method") 
			This.CryptParams.Add("des", "Algorithm")
			This.CryptParams.Add("cbc", "Mode")
			This.CryptParams.Add(24, "KeySize")
			This.CryptParams.Add(8, "BlockSize")

		CASE m.KeyType == AES128_CBC

			This.CryptParams.Add("aes-128-cbc", "Cipher")
			This.CryptParams.Add("symmetric", "Type")
			This.CryptParams.Add(m.KeyType, "Method") 
			This.CryptParams.Add("aes", "Algorithm")
			This.CryptParams.Add("cbc", "Mode")
			This.CryptParams.Add(16, "KeySize")
			This.CryptParams.Add(16, "BlockSize")

		CASE m.KeyType == AES192_CBC

			This.CryptParams.Add("aes-192-cbc", "Cipher")
			This.CryptParams.Add("symmetric", "Type")
			This.CryptParams.Add(m.KeyType, "Method") 
			This.CryptParams.Add("aes", "Algorithm")
			This.CryptParams.Add("cbc", "Mode")
			This.CryptParams.Add(24, "KeySize")
			This.CryptParams.Add(16, "BlockSize")

		CASE m.KeyType == AES256_CBC

			This.CryptParams.Add("aes-256-cbc", "Cipher")
			This.CryptParams.Add("symmetric", "Type")
			This.CryptParams.Add(m.KeyType, "Method") 
			This.CryptParams.Add("aes", "Algorithm")
			This.CryptParams.Add("cbc", "Mode")
			This.CryptParams.Add(32, "KeySize")
			This.CryptParams.Add(16, "BlockSize")

		CASE m.KeyType == RSA_1_5

			This.CryptParams.Add(PKCS1_PADDING, "Padding")
			This.CryptParams.Add(m.KeyType, "Method")
			m.MissingScope = This._IsScopeMissing(m.Scope)

		CASE m.KeyType == RSA_OAEP_MGF1P

			This.CryptParams.Add(PKCS1_OAEP_PADDING, "Padding")
			This.CryptParams.Add(m.KeyType, "Method")
			m.MissingScope = This._IsScopeMissing(m.Scope)

		CASE m.KeyType == RSA_SHA1

			This.CryptParams.Add(PKCS1_PADDING, "Padding")
			This.CryptParams.Add(m.KeyType, "Method")
			m.MissingScope = This._IsScopeMissing(m.Scope)

		CASE m.KeyType == RSA_SHA256

			This.CryptParams.Add(PKCS1_PADDING, "Padding")
			This.CryptParams.Add(m.KeyType, "Method")
			This.CryptParams.Add("SHA256", "Digest")
			m.MissingScope = This._IsScopeMissing(m.Scope)

		CASE m.KeyType == RSA_SHA384

			This.CryptParams.Add(PKCS1_PADDING, "Padding")
			This.CryptParams.Add(m.KeyType, "Method")
			This.CryptParams.Add("SHA384", "Digest")
			m.MissingScope = This._IsScopeMissing(m.Scope)

		CASE m.KeyType == RSA_SHA512

			This.CryptParams.Add(PKCS1_PADDING, "Padding")
			This.CryptParams.Add(m.KeyType, "Method")
			This.CryptParams.Add("SHA512", "Digest")
			m.MissingScope = This._IsScopeMissing(m.Scope)

		CASE m.KeyType == HMAC_SHA1

			This.CryptParams.Add(m.KeyType, "Method")

		OTHERWISE

			ERROR "Unrecognized key type."

		ENDCASE

		IF m.MissingScope
			ERROR "Certificate type (private/public) must be passed to initialization."
		ENDIF

		This.Type = m.KeyType

	ENDFUNC

	FUNCTION Destroy
		This.Library = .NULL.
	ENDFUNC

	FUNCTION SetLibrary (Library AS StringOrObject)

		IF TYPE("m.Library") != "O"
			This.Library = CREATEOBJECT(m.Library)
		ELSE
			This.Library = m.Library
		ENDIF

	ENDFUNC

	FUNCTION GetSysmmetricKeySize () AS Integer

		IF This.CryptParams.GetKey("KeySize") != 0
			RETURN This.CryptParams("KeySize")
		ELSE
			RETURN .NULL.
		ENDIF
	ENDFUNC

	FUNCTION GenerateSessionKey () AS String

		LOCAL KeySize AS Integer
		LOCAL Key AS String
		LOCAL LoopIndex AS Integer
		LOCAL BitIndex AS Integer
		LOCAL Byte AS Integer
		LOCAL Parity AS Integer

		m.KeySize = This.GetSysmmetricKeySize()
		IF ISNULL(m.KeySize)
			ERROR "Unknown key size."
		ENDIF

		m.Key = This.Library.RandomBytes(m.KeySize)

		IF This.Type == TRIPLEDES_CBC
		
			FOR m.LoopIndex = 1 TO m.KeySize
				m.Byte = BITAND(CHR(SUBSTR(m.Key, m.LoopIndex, 1)), 0xfe)
				m.Parity = 1
				FOR m.BitIndex = 1 TO 7
					m.Parity = BITXOR(m.Parity, BITAND(BITRSHIFT(m.Byte, m.BitIndex), 1))
				ENDFOR
				m.Byte = BITOR(m.Byte, m.Parity)
				m.Key = STUFF(m.Key, m.LoopIndex, 1, CHR(m.Byte))
			ENDFOR
		
		ENDIF

		This.Key = m.Key

		RETURN m.Key

	ENDFUNC

	FUNCTION GetRawThumbprint (Cert AS String) AS String
	
		LOCAL ARRAY Lines[1]
		LOCAL LineIndex AS Integer
		LOCAL InData AS Boolean
		LOCAL RawThumbprint AS String

		m.InData = .F.
		m.RawThumbprint = ""

		FOR m.LineIndex = 1 TO ALINES(m.Lines, m.Cert, 1 + 4, CHR(10), CHR(13))

			IF !m.InData
				IF LEFT(m.Lines(m.LineIndex), 22) == "-----BEGIN CERTIFICATE"
					m.InData = .T.
				ENDIF
			ELSE
				IF LEFT(m.Lines(m.LineIndex), 20) == "-----END CERTIFICATE"
					EXIT
				ENDIF
				m.RawThumbprint = m.RawThumbprint + ALLTRIM(m.Lines(m.LineIndex), 0, " ", CHR(9), CHR(10), CHR(13))
			ENDIF

		ENDFOR

		IF !EMPTY(m.RawThumbprint)
			m.RawThumbprint = LOWER(This.Library.SHA1(STRCONV(m.RawThumbprint, 14)))
		ELSE
			m.RawThumbprint = .NULL.
		ENDIF

		RETURN m.RawThumbprint

	ENDFUNC

	FUNCTION LoadKey (Key AS String, IsFile AS Boolean, IsCert AS Boolean)

		LOCAL Type AS String

		This.Key = IIF(m.IsFile, FILETOSTR(m.Key), m.Key)

		IF m.IsCert
			STORE This.Library.X509Export(This.Key) TO This.Key, This.X509Certificate
		ELSE
			This.X509Certificate = .NULL.
		ENDIF

		IF This.CryptParams.GetKey("Type") != 0

			m.Type = This.CryptParams("Type")

			DO CASE
			CASE m.Type == "public"

				IF m.IsCert
					This.X509Thumbprint = This.GetRawThumbprint(This.X509Certificate)
				ENDIF
				This.Key = This.Library.GetPublicKey(This.Key)
				IF ISNULL(This.Key) OR (TYPE("This.Key") $ "NCL" AND EMPTY(This.Key))
					ERROR "Unable to extract public key."
				ENDIF

			CASE m.Type == "private"

				IF ISNULL(This.PassPhrase) OR EMPTY(This.PassPhrase)
					This.Key = This.Library.GetPrivateKey(This.Key)
				ELSE
					This.Key = This.Library.GetPrivateKey(This.Key, This.PassPhrase)
				ENDIF
				IF ISNULL(This.Key) OR (TYPE("This.Key") $ "NCL" AND EMPTY(This.Key))
					ERROR "Unable to extract private key."
				ENDIF

			CASE m.Type == "symmetric"

				IF This.CryptParams("KeySize") = 0
					ERROR "Undefined key size."
				ENDIF

				IF LEN(This.Key) < This.CryptParams("KeySize")
					ERROR "Key of insufficient length."
				ENDIF

			OTHERWISE
				ERROR "Unknown type."
			ENDCASE
		ENDIF
				
	ENDFUNC

	FUNCTION EncryptData (Data AS String) AS String
	
		LOCAL Type AS String

		IF This.CryptParams.GetKey("Type") != 0

			m.Type = This.CryptParams("Type")

			DO CASE
			CASE m.Type == "symmetric"
				RETURN This.Library.EncryptSymmetric(m.Data, This)

			CASE m.Type == "private"
				RETURN This.Library.EncryptPrivate(m.Data, This)

			CASE m.Type == "public"
				RETURN This.Library.EncryptPublic(m.Data, This)

			ENDCASE
		ENDIF
		
		RETURN .NULL.

	ENDFUNC

	FUNCTION DecryptData (Data AS String) AS String
	
		LOCAL Type AS String

		IF This.CryptParams.GetKey("Type") != 0

			m.Type = This.CryptParams("Type")

			DO CASE
			CASE m.Type == "symmetric"
				RETURN This.Library.DecryptSymmetric(m.Data, This)

			CASE m.Type == "private"
				RETURN This.Library.DecryptPrivate(m.Data, This)

			CASE m.Type == "public"
				RETURN This.Library.DecryptPublic(m.Data, This)

			ENDCASE
		ENDIF
		
		RETURN .NULL.

	ENDFUNC

	FUNCTION SignData (Data AS String) AS String
		RETURN This.Library.SignData(m.Data, This)
	ENDFUNC

	FUNCTION HashData (AlgorithmCode AS Integer, Data AS String) AS String
		RETURN This.Library.Hash(m.AlgorithmCode, m.Data)
	ENDFUNC

	FUNCTION VerifySignature (Data AS String, Signature AS String) AS Boolean
		RETURN This.Library.VerifySignature(m.Data, m.Signature, This)
	ENDFUNC

	FUNCTION GetAlgorithm () AS String
		RETURN IIF(This.CryptParams.GetKey("Method") != 0, This.CryptParams("Method"), .NULL.)
	ENDFUNC

	FUNCTION GetX509Certificate () AS String
		RETURN This.X509Certificate
	ENDFUNC

	FUNCTION GetX509Thumbprint () AS String
		RETURN This.X509Thumbprint
	ENDFUNC

	FUNCTION PadISO10126 (Data AS String, BlockSize AS Integer) AS String

		IF m.BlockSize > 256
			ERROR "Block size greater than 256 not allowed."
		ENDIF

		LOCAL PadChr AS Integer

		m.PadChr = m.BlockSize - (LEN(m.Data) % m.BlockSize)

		RETURN m.Data + REPLICATE(CHR(m.PadChr), m.PadChr)

	ENDFUNC

	FUNCTION UnpadISO10126 (Data AS String) AS String

		RETURN LEFT(m.Data, LEN(m.Data) - ASC(RIGHT(m.Data, 1)))

	ENDFUNC

	FUNCTION FromEncrypedKeyElement (Element AS MSXML2.IXMLDOMElement) AS XMLSecurityKey

		LOCAL ObjEnc AS XMLSecurityEnc
		LOCAL ObjKey AS XMLSeurityKey

		m.ObjEnc = CREATEOBJECT("XMLSecurityEnc")
		m.ObjEnc.SetNode(m.Element)
		m.ObjKey = m.ObjEnc.LocateKey()
		IF ISNULL(m.ObjKey)
			ERROR "Unable to locate algorithm for Encrypted key."
		ENDIF

		m.ObjKey.IsEncrypted = .T.
		m.ObjKey.EncryptedCtx = m.ObjEnc
		m.ObjEnc.LocateKeyInfo(m.ObjKey, m.Element)

		RETURN m.ObjKey

	ENDFUNC

	FUNCTION ConvertRSA (Modulus AS String, Exponent AS String) AS String

		LOCAL ExponentEncoding AS String
		LOCAL ModulusEncoding AS String
		LOCAL SequenceEncoding AS String
		LOCAL BitStringEncoding AS String
		LOCAL RSAAlgorithmIdentifier AS String
		LOCAL PublicKeyInfo AS String
		LOCAL Encoding AS String
		
		m.ExponentEncoding = This.MakeASNSegment(0x02, m.Exponent)
		m.ModulusEncoding = This.MakeASNSegment(0x02, m.Modulus)
		m.SequenceEncoding = This.MakeASNSegment(0x30, m.ModulusEncoding + m.ExponentEncoding)
		m.BitStringEncoding = This.MakeASNSegment(0x03, m.SequenceEncoding)
		m.RSAAlgorithmIdentifier = "" + 0h300D06092A864886F70D0101010500
		m.PublicKeyInfo = This.MakeASNSegment(0x30, m.RSAAlgorithmIdentifier + m.BitStringEncoding)

		m.PublicKeyInfo = STRCONV(m.PublicKeyInfo, 13)

		m.Encoding = "-----BEGIN PUBLIC KEY-----" + LF
		DO WHILE !EMPTY(m.PublicKeyInfo)
			m.Encoding = m.Encoding + LEFT(m.PublicKeyInfo, 64) + LF
			m.PublicKeyInfo = SUBSTR(m.PublicKeyInfo, 65)
		ENDDO
		m.Encoding = m.Encoding + "-----END PUBLIC KEY-----" + LF

		RETURN m.Encoding

	ENDFUNC
	
	HIDDEN FUNCTION MakeASNSegment (Type AS Integer, String AS String) AS String

		LOCAL Segment AS String
		LOCAL Length AS Integer

		DO CASE
		CASE m.Type = 0x02 AND ASC(LEFT(m.String, 1)) > 0x7f
			m.Segment = CHR(0) + m.String

		CASE m.Type = 0x03
			m.Segment = CHR(0) + m.Segment

		OTHERWISE
			m.Segment = m.String
		ENDCASE

		m.Length = LEN(m.Segment)

		DO CASE
		CASE m.Length < 128
			m.Segment = CHR(m.Type) + CHR(m.Length) + m.Segment

		CASE m.Length < 0x0100
			m.Segment = CHR(m.Type) + CHR(0x81) + CHR(m.Length) + m.Segment

		CASE m.Length < 0x010000
			m.Segment = CHR(m.Type) + CHR(0x82) + CHR(INT(m.Length / 0x0100)) + CHR(m.Length % 0x0100) + m.Segment

		OTHERWISE
			m.Segment = .NULL.
		ENDCASE
		
		RETURN m.Segment
	ENDFUNC

	FUNCTION ParseX509Certificate (Cert AS String) AS Collection
		RETURN This.Library.X509Parse(m.Cert)
	ENDFUNC

	HIDDEN FUNCTION _IsScopeMissing (Scope AS String) AS Boolean

		IF TYPE("m.Scope") == "C" AND ;
				(m.Scope == "public" OR m.Scope == "private")
			This.CryptParams.Add(m.Scope, "Type")
			RETURN .F.
		ENDIF

		RETURN .T.
	ENDFUNC

ENDDEFINE