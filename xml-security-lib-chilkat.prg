*
* XMLSecurityLib - Chilkat implementation
*

IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-security.h"

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSecurityLibChilkat AS XMLSecurityLib

	Crypto = .NULL.
	Cert = .NULL.
	BinaryData = .NULL.
	RSA = .NULL.

	FUNCTION Init

		* Requires unlocked components (use Global unlock)
		This.Crypto = CREATEOBJECT("Chilkat_9_5_0.Crypt2")
		This.RSA = CREATEOBJECT("Chilkat_9_5_0.RSA")
		This.RSA.LittleEndian = 0
		This.Cert = CREATEOBJECT("Chilkat_9_5_0.Cert")
		This.BinaryData = CREATEOBJECT("Chilkat_9_5_0.BinData")

	ENDFUNC

	FUNCTION DecryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String

		This.SetOAEPPadding(m.XMLKey)

		This.BinaryData.LoadEncoded(STRCONV(m.Data, 13), "base64")

		This.RSA.ImportPrivateKeyObj(m.XMLKey.Key)
		RETURN This.RSA.DecryptBytes(This.BinaryData.GetBinary(), 1)

	ENDFUNC

	FUNCTION DecryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String

		This.SetOAEPPadding(m.XMLKey)

		This.BinaryData.LoadEncoded(STRCONV(m.Data, 13), "base64")

		This.RSA.ImportPublicKeyObj(m.XMLKey.Key)
		RETURN This.RSA.DecryptBytes(This.BinaryData.GetBinary(), 0)

	ENDFUNC

	FUNCTION DecryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String

		LOCAL PaddedData AS String

		This.BinaryData.LoadEncoded(STRCONV(m.Data, 13), "base64")

		This.Crypto.CryptAlgorithm = m.XMLKey.CryptParams("Algorithm")
		This.Crypto.CipherMode = m.XMLKey.CryptParams("Mode")
		This.Crypto.KeyLength = m.XMLKey.CryptParams("KeySize") * 8

		This.Crypto.SetEncodedKey(STRCONV(m.XMLKey.Key, 15), "hex")
		
		IF This.Crypto.DecryptBd(This.BinaryData) = 1
			m.PaddedData = SUBSTR("" + This.BinaryData.GetBinary(), m.XMLKey.CryptParams("BlockSize") + 1)
			RETURN m.XMLKey.UnpadISO10126(m.PaddedData)
		ELSE
			RETURN .NULL.
		ENDIF

	ENDFUNC

	FUNCTION EncryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String

		This.SetOAEPPadding(m.XMLKey)

		This.BinaryData.LoadEncoded(STRCONV(m.Data, 13), "base64")
		
		This.RSA.ImportPrivateKeyObj(m.XMLKey.Key)
		RETURN This.RSA.EncryptBytes(This.BinaryData.GetBinary(), 1)

	ENDFUNC

	FUNCTION EncryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String
	
		This.SetOAEPPadding(m.XMLKey)
	
		This.BinaryData.LoadEncoded(STRCONV(m.Data, 13), "base64")
		
		This.RSA.ImportPublicKeyObj(m.XMLKey.Key)
		RETURN This.RSA.EncryptBytes(This.BinaryData.GetBinary(), 0)

	ENDFUNC

	FUNCTION EncryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String

		LOCAL PaddedData AS String
		LOCAL SecretKey AS String

		m.PaddedData = m.XMLKey.PadISO10126(m.Data, m.XMLKey.CryptParams("BlockSize"))
		This.BinaryData.LoadEncoded(STRCONV(m.PaddedData, 13), "base64")

		This.Crypto.CryptAlgorithm = m.XMLKey.CryptParams("Algorithm")
		This.Crypto.CipherMode = m.XMLKey.CryptParams("Mode")
		This.Crypto.KeyLength = m.XMLKey.CryptParams("KeySize") * 8

		This.Crypto.RandomizeIV()

		m.SecretKey = m.XMLKey.Key
		IF ISNULL(m.SecretKey) OR EMPTY(m.SecretKey)
			This.Crypto.RandomizeKey()
			m.XMLKey.Key = STRCONV(This.Crypto.GetEncodedKey("hex"), 16)
		ELSE
			This.Crypto.SetEncodedKey(STRCONV(m.SecretKey, 15), "hex")
		ENDIF

		IF This.Crypto.EncryptBd(This.BinaryData) = 1
			RETURN "" + STRCONV(This.Crypto.GetEncodedIV("hex"), 16) + This.BinaryData.GetBinary()
		ELSE
			RETURN .NULL.
		ENDIF

	ENDFUNC

	FUNCTION GetPrivateKey (PEM AS String, Password AS String) AS String

		LOCAL PKey AS Chilkat_v9_5_0.PrivateKey

		m.PKey = CREATEOBJECT("Chilkat_9_5_0.PrivateKey")

		RETURN IIF(m.PKey.LoadPem(m.PEM) = 1, m.PKey, .NULL.)

	ENDFUNC

	FUNCTION GetPublicKey (Cert AS String) AS String

		RETURN IIF(This.TemporaryFile(m.Cert), This.Cert.ExportPublicKey(), .NULL.)

	ENDFUNC

	FUNCTION RandomBytes (Size AS Integer) AS String

		This.Crypto.EncodingMode = "hex"
		RETURN STRCONV(This.Crypto.GenRandomBytesENC(m.Size), 16)

	ENDFUNC

	FUNCTION Hash (AlgorithmCode AS String, ToHash AS String) AS String

		LOCAL AlgorithmName AS String
		LOCAL HashedData AS String

		DO CASE
		CASE m.AlgorithmCode == HASH_SHA1
			m.AlgorithmName = "sha1"
		CASE m.AlgorithmCode == HASH_SHA256
			m.AlgorithmName = "sha256"
		CASE m.AlgorithmCode == HASH_SHA384
			m.AlgorithmName = "sha384"
		CASE m.AlgorithmCode == HASH_SHA512
			m.AlgorithmName = "sha512"
		CASE m.AlgorithmCode == HASH_RIPEMD160
			m.AlgorithmName = "ripemd160"
		OTHERWISE
			RETURN .NULL.
		ENDCASE

		This.BinaryData.LoadEncoded(STRCONV(m.ToHash, 13), "base64")

		This.Crypto.HashAlgorithm = m.AlgorithmName
		This.Crypto.EncodingMode = "base64"

		m.HashedData = This.Crypto.HashBytesENC(This.BinaryData.GetBinary())

		RETURN STRCONV(m.HashedData, 14)

	ENDFUNC

	FUNCTION SHA1 (ToHash AS String) AS String

		This.BinaryData.LoadEncoded(STRCONV(m.ToHash, 13), "base64")

		This.Crypto.HashAlgorithm = "sha1"
		This.Crypto.EncodingMode = "hex"

		RETURN This.Crypto.HashBytesENC(This.BinaryData.GetBinary())

	ENDFUNC

	FUNCTION SignData (Data AS String, XMLKey AS XMLSecurityKey) AS String

		This.BinaryData.LoadEncoded(STRCONV(m.Data, 13), "base64")

		LOCAL Algorithm AS String

		IF m.XMLKey.CryptParams.GetKey("Type") != 0

			m.Algorithm = "sha1"
			IF m.XMLKey.CryptParams.GetKey("Digest") != 0
				m.Algorithm = LOWER(m.XMLKey.CryptParams("Digest"))
			ENDIF
			IF LEFT(m.Algorithm, 3) == "sha"
				m.Algorithm = "sha-" + SUBSTR(m.Algorithm, 4)
			ENDIF

			This.RSA.ImportPrivateKeyObj(m.XMLKey.Key)

			RETURN This.RSA.SignBytes(This.BinaryData.GetBinary(), m.Algorithm)

		ELSE

			This.Crypto.MacAlgorithm = "hmac"
			This.Crypto.HashAlgorithm = "sha-1"
			This.Crypto.SetMacKeyEncoded(STRCONV(m.XMLKey.Key, 15), "hex")

			RETURN This.Crypto.MacBytes(This.BinaryData.GetBinary())

		ENDIF

	ENDFUNC

	FUNCTION VerifySignature (Data AS String, Signature AS String,	XMLKey AS XMLSecurityKey) AS Boolean

		LOCAL Verified AS Boolean

		This.BinaryData.LoadEncoded(STRCONV(m.Data, 13), "base64")

		LOCAL Algorithm AS String

		IF m.XMLKey.CryptParams.GetKey("Type") != 0

			m.Algorithm = "sha1"
			IF m.XMLKey.CryptParams.GetKey("Digest") != 0
				m.Algorithm = LOWER(m.XMLKey.CryptParams("Digest"))
			ENDIF
			IF LEFT(m.Algorithm, 3) == "sha"
				m.Algorithm = "sha-" + SUBSTR(m.Algorithm, 4)
			ENDIF

			This.RSA.ImportPublicKeyObj(m.XMLKey.Key)
			This.RSA.EncodingMode = "base64"
			
			m.Verified = This.RSA.VerifyBytesENC(This.BinaryData.GetBinary(), m.Algorithm, STRCONV(m.Signature, 13)) = 1

		ELSE

			This.Crypto.MacAlgorithm = "hmac"
			This.Crypto.HashAlgorithm = "sha-1"
			This.Crypto.SetMacKeyEncoded(STRCONV(m.XMLKey.Key, 15), "hex")

			m.Verified = This.Crypto.MacBytes(This.BinaryData.GetBinary()) == m.Signature

		ENDIF

		RETURN m.Verified

	ENDFUNC

	FUNCTION X509Export (Cert AS String) AS String

		RETURN IIF(This.TemporaryFile(m.Cert), This.Cert.ExportCertPem(), .NULL.)

	ENDFUNC

	FUNCTION X509Parse (Cert AS String) AS String

		LOCAL Parsed AS Collection
		LOCAL SubParsed AS Collection

		IF This.TemporaryFile(m.Cert)

			m.Parsed = CREATEOBJECT("Collection")
			WITH This.Cert AS Chilkat_v9_5_0.ChilkatCert
				m.Parsed.Add(TRANSFORM(.CertVersion), "Version")
				m.Parsed.Add(.SerialDecimal, "SerialNumber")
				m.Parsed.Add(.ValidFromStr, "ValidFrom")
				m.Parsed.Add(.ValidToStr, "ValidTo")
				IF !EMPTY(.AuthorityKeyId)
					m.Parsed.Add(.AuthorityKeyId, "AuthorityKeyId")
				ENDIF´
				IF !EMPTY(.IssuerDN)
					m.Parsed.Add(.IssuerDN, "Issuer")
				ELSE
					m.SubParsed = CREATEOBJECT("Collection")
					IF !EMPTY(.IssuerC)
						m.SubParsed.Add(.IssuerC, "C")
					ENDIF
					IF !EMPTY(.IssuerCN)
						m.SubParsed.Add(.IssuerCN, "CN")
					ENDIF
					IF !EMPTY(.IssuerE)
						m.SubParsed.Add(.IssuerE, "E")
					ENDIF
					IF !EMPTY(.IssuerL)
						m.SubParsed.Add(.IssuerL, "L")
					ENDIF
					IF !EMPTY(.IssuerO)
						m.SubParsed.Add(.IssuerO, "O")
					ENDIF
					IF !EMPTY(.IssuerOU)
						m.SubParsed.Add(.IssuerOU, "OU")
					ENDIF
					IF !EMPTY(.IssuerS)
						m.SubParsed.Add(.IssuerS, "S")
					ENDIF
					IF m.SubParsed.Count != 0
						m.Parsed.Add(m.SubParsed, "Issuer")
					ENDIF
				ENDIF
				IF !EMPTY(.SubjectDN)
					m.Parsed.Add(.SubjectDN, "Subject")
				ELSE
					m.SubParsed = CREATEOBJECT("Collection")
					IF !EMPTY(.SubjectC)
						m.SubParsed.Add(.SubjectC, "C")
					ENDIF
					IF !EMPTY(.SubjectCN)
						m.SubParsed.Add(.SubjectCN, "CN")
					ENDIF
					IF !EMPTY(.SubjectE)
						m.SubParsed.Add(.SubjectE, "E")
					ENDIF
					IF !EMPTY(.SubjectKeyId)
						m.SubParsed.Add(.SubjectKeyId, "KeyId")
					ENDIF
					IF !EMPTY(.SubjectL)
						m.SubParsed.Add(.SubjectL, "L")
					ENDIF
					IF !EMPTY(.SubjectO)
						m.SubParsed.Add(.SubjectO, "O")
					ENDIF
					IF !EMPTY(.SubjectOU)
						m.SubParsed.Add(.SubjectOU, "OU")
					ENDIF
					IF !EMPTY(.SubjectS)
						m.SubParsed.Add(.SubjectS, "S")
					ENDIF
					IF m.SubParsed.Count != 0
						m.Parsed.Add(m.SubParsed, "Subject")
					ENDIF
				ENDIF
			ENDWITH
			
		ELSE
			m.Parsed = .NULL.
		ENDIF		

		RETURN m.Parsed

	ENDFUNC

	HIDDEN FUNCTION TemporaryFile (Cert AS String) AS Boolean

		LOCAL CertFile AS String

		m.CertFile = ADDBS(SYS(2023)) + "~cer" + SYS(2015)
		ERASE (m.CertFile)
		STRTOFILE(m.Cert, m.CertFile, 0)

		m.Success = This.Cert.LoadFromFile(m.CertFile) = 1

		ERASE (m.CertFile)

		RETURN m.Success

	ENDFUNC

	HIDDEN PROCEDURE SetOAEPPadding (XMLKey AS XMLSecurityKey)

		IF m.XMLKey.CryptParams.GetKey("Padding") != 0
			IF m.XMLKey.CryptParams("Padding") = PKCS1_OAEP_PADDING
				This.RSA.OaepPadding = 1
			ELSE
				This.RSA.OaepPadding = 0
			ENDIF
		ENDIF

	ENDPROC

ENDDEFINE
