*
* XMLSecurityLib - OpenSSL implementation
*

IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-security.h"

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSecurityLibOpenSSL AS XMLSecurityLib

	PKeyCtx = 0

	FUNCTION Init (OpenSSL_DLL AS String)

		LOCAL ARRAY Declared(1)

		ADLLS(m.Declared)
		IF ASCAN(m.Declared, "OpenSSL_CipherCtxRelease") = 0

			IF PCOUNT() = 0
				m.OpenSSL_DLL = LOCFILE("libcrypto-1_1.dll")			&& must be somewhere in VFP's path
			ENDIF

			DECLARE INTEGER EVP_EncryptInit_ex IN (m.OpenSSL_DLL) AS OpenSSL_EncryptInit ;
				INTEGER Context, INTEGER CipherType, INTEGER Engine, STRING Key, STRING IV
			DECLARE INTEGER EVP_EncryptUpdate IN (m.OpenSSL_DLL) AS OpenSSL_EncryptUpdate ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength, STRING In, INTEGER InLength
			DECLARE INTEGER EVP_EncryptFinal_ex IN (m.OpenSSL_DLL) AS OpenSSL_EncryptFinal ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength

			DECLARE INTEGER EVP_DecryptInit_ex IN (m.OpenSSL_DLL) AS OpenSSL_DecryptInit ;
				INTEGER Context, INTEGER CipherType, INTEGER Engine, STRING Key, STRING IV
			DECLARE INTEGER EVP_DecryptUpdate IN (m.OpenSSL_DLL) AS OpenSSL_DecryptUpdate ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength, STRING In, INTEGER InLength
			DECLARE INTEGER EVP_DecryptFinal_ex IN (m.OpenSSL_DLL) AS OpenSSL_DecryptFinal ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength

			DECLARE INTEGER EVP_DigestInit_ex IN (m.OpenSSL_DLL) AS OpenSSL_DigestInit ;
				INTEGER Context, INTEGER DigestType, INTEGER Engine
			DECLARE INTEGER EVP_DigestUpdate IN (m.OpenSSL_DLL) AS OpenSSL_DigestUpdate ;
				INTEGER Context, STRING In, INTEGER InLength
			DECLARE INTEGER EVP_DigestFinal_ex IN (m.OpenSSL_DLL) AS OpenSSL_DigestFinal ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength
			DECLARE INTEGER EVP_DigestSignInit IN (m.OpenSSL_DLL) AS OpenSSL_DigestSignInit ;
				INTEGER Context, INTEGER PKeyCtx, INTEGER DigestType, INTEGER Engine, INTEGER PKey
			DECLARE INTEGER EVP_DigestSignFinal IN (m.OpenSSL_DLL) AS OpenSSL_DigestSignFinal ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength
			DECLARE INTEGER EVP_DigestVerifyInit IN (m.OpenSSL_DLL) AS OpenSSL_DigestVerifyInit ;
				INTEGER Context, INTEGER PKeyCtx, INTEGER DigestType, INTEGER Engine, INTEGER PKey
			DECLARE INTEGER EVP_DigestVerifyFinal IN (m.OpenSSL_DLL) AS OpenSSL_DigestVerifyFinal ;
				INTEGER Context, STRING In, INTEGER InLen
			DECLARE INTEGER EVP_MD_size IN (m.OpenSSL_DLL) AS OpenSSL_DigestSize ;
				INTEGER DigestType
			DECLARE INTEGER EVP_get_digestbyname IN (m.OpenSSL_DLL) AS OpenSSL_DigestByName ;
				STRING DigestName

#DEFINE	OpenSSL_DigestSignUpdate	OpenSSL_DigestUpdate
#DEFINE	OpenSSL_DigestVerifyUpdate	OpenSSL_DigestUpdate

			DECLARE INTEGER EVP_PKEY_encrypt_init IN (m.OpenSSL_DLL) AS OpenSSL_PKeyEncryptInit ;
				INTEGER Context
			DECLARE INTEGER EVP_PKEY_encrypt IN (m.OpenSSL_DLL) AS OpenSSL_PKeyEncrypt ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength, STRING In, INTEGER InLength
			DECLARE INTEGER EVP_PKEY_decrypt_init IN (m.OpenSSL_DLL) AS OpenSSL_PKeyDecryptInit ;
				INTEGER Context
			DECLARE INTEGER EVP_PKEY_decrypt IN (m.OpenSSL_DLL) AS OpenSSL_PKeyDecrypt ;
				INTEGER Context, STRING @ Out, INTEGER @ OutLength, STRING In, INTEGER InLength
			DECLARE INTEGER RSA_pkey_ctx_ctrl IN (m.OpenSSL_DLL) AS OpenSSL_PKeyCtxCtrl ;
				INTEGER Context, INTEGER N1, INTEGER N2, INTEGER Padding, INTEGER N3

			DECLARE INTEGER EVP_aes_128_cbc IN (m.OpenSSL_DLL) AS OpenSSL_AES_128_CBC
			DECLARE INTEGER EVP_aes_192_cbc IN (m.OpenSSL_DLL) AS OpenSSL_AES_192_CBC
			DECLARE INTEGER EVP_aes_256_cbc IN (m.OpenSSL_DLL) AS OpenSSL_AES_256_CBC
			DECLARE INTEGER EVP_des_ede3_cbc IN (m.OpenSSL_DLL) AS OpenSSL_DES_EDE3_CBC

			DECLARE INTEGER EVP_sha1 IN (m.OpenSSL_DLL) AS OpenSSL_SHA1
			DECLARE INTEGER EVP_sha256 IN (m.OpenSSL_DLL) AS OpenSSL_SHA256
			DECLARE INTEGER EVP_sha384 IN (m.OpenSSL_DLL) AS OpenSSL_SHA384
			DECLARE INTEGER EVP_sha512 IN (m.OpenSSL_DLL) AS OpenSSL_SHA512
			DECLARE INTEGER EVP_ripemd160 IN (m.OpenSSL_DLL) AS OpenSSL_RIPEMD160

			DECLARE INTEGER PEM_read_bio_PUBKEY IN (m.OpenSSL_DLL) AS OpenSSL_BioLoadPublicKey ;
				INTEGER Bio, INTEGER @ PKey, INTEGER CallBack, INTEGER XData
			DECLARE INTEGER PEM_read_bio_PrivateKey IN (m.OpenSSL_DLL) AS OpenSSL_BioLoadPrivateKey ;
				INTEGER Bio, INTEGER @ PKey, INTEGER CallBack, INTEGER PassPhrase
			DECLARE INTEGER PEM_read_bio_X509 IN (m.OpenSSL_DLL) AS OpenSSL_BioLoadX509 ;
				INTEGER Bio, INTEGER @ Type, INTEGER CallBack, INTEGER XData
			DECLARE INTEGER PEM_write_bio_X509 IN (m.OpenSSL_DLL) AS OpenSSL_BioWriteX509 ;
				INTEGER Bio, INTEGER X509
			DECLARE INTEGER X509_NAME_print_ex IN (m.OpenSSL_DLL) AS OpenSSL_BioWriteX509Name ;
				INTEGER Bio, INTEGER X509Name, INTEGER Indent, INTEGER Flags
			DECLARE INTEGER X509_get_pubkey IN (m.OpenSSL_DLL) AS OpenSSL_X509GetPublicKey ;
				INTEGER X509
			DECLARE INTEGER X509_free IN (m.OpenSSL_DLL) AS OpenSSL_X509Release ;
				INTEGER X509
			DECLARE INTEGER X509_get_version IN (m.OpenSSL_DLL) AS OpenSSL_X509GetVersion ;
				INTEGER X509
			DECLARE INTEGER X509_get_subject_name IN (m.OpenSSL_DLL) AS OpenSSL_X509GetSubjectName ;
				INTEGER X509
			DECLARE INTEGER X509_get_issuer_name IN (m.OpenSSL_DLL) AS OpenSSL_X509GetIssuerName ;
				INTEGER X509

			DECLARE INTEGER RAND_bytes IN (m.OpenSSL_DLL) AS OpenSSL_RandBytes ;
				STRING @ Buf, INTEGER Num

			DECLARE INTEGER BIO_new IN (m.OpenSSL_DLL) AS OpenSSL_BioNew ;
				INTEGER BioType
			DECLARE INTEGER BIO_s_mem IN (m.OpenSSL_DLL) AS OpenSSL_BioMem
			DECLARE INTEGER BIO_write IN (m.OpenSSL_DLL) AS OpenSSL_BioWrite ;
				INTEGER Bio, STRING Source, INTEGER Length
			DECLARE INTEGER BIO_read IN (m.OpenSSL_DLL) AS OpenSSL_BioRead ;
				INTEGER Bio, STRING @ Dest, INTEGER Length
			DECLARE INTEGER BIO_ctrl_pending IN (m.OpenSSL_DLL) AS OpenSSL_BioPending ;
				INTEGER Bio
			DECLARE INTEGER BIO_free_all IN (m.OpenSSL_DLL) AS OpenSSL_BioRelease ;
				INTEGER Bio

			DECLARE INTEGER EVP_PKEY_CTX_new IN (m.OpenSSL_DLL) AS OpenSSL_PKeyCtxNew ;
				INTEGER PKey, INTEGER Engine
			DECLARE INTEGER EVP_PKEY_CTX_free IN (m.OpenSSL_DLL) AS OpenSSL_PKeyCtxRelease ;
				INTEGER Context

			DECLARE INTEGER EVP_MD_CTX_new IN (m.OpenSSL_DLL) AS OpenSSL_DigestCtxNew
			DECLARE INTEGER EVP_MD_CTX_free IN (m.OpenSSL_DLL) AS OpenSSL_DigestCtxRelease ;
				INTEGER Context

			DECLARE INTEGER EVP_CIPHER_CTX_new IN (m.OpenSSL_DLL) AS OpenSSL_CipherCtxNew
			DECLARE INTEGER EVP_CIPHER_CTX_free IN (m.OpenSSL_DLL) AS OpenSSL_CipherCtxRelease ;
				INTEGER Context

		ENDIF

	ENDFUNC

	FUNCTION Destroy

		This.PKeyCtx = 0

	ENDFUNC

	FUNCTION PKeyCtx_assign (Ctx AS Integer)

		IF !EMPTY(This.PKeyCtx)
			OpenSSL_PKeyCtxRelease(This.PKeyCtx)
		ENDIF

		This.PKeyCtx = m.Ctx

	ENDFUNC

	FUNCTION DecryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String

		RETURN This.DecryptPublic(m.Data, m.XMLKey)

	ENDFUNC

	FUNCTION DecryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String

		LOCAL Context AS Integer
		LOCAL Decrypted AS String
		LOCAL DecryptedLength AS Integer

		m.Decrypted = .NULL.

		IF !EMPTY(This.PKeyCtx)

			IF OpenSSL_PKeyDecryptInit(This.PKeyCtx) > 0

				This.SetPadding(m.XMLKey)
	
				m.DecryptedLength = 0
				IF OpenSSL_PKeyDecrypt(This.PKeyCtx, 0, @m.DecryptedLength, m.Data, LEN(m.Data)) > 0

					m.Decrypted = REPLICATE(CHR(0), m.DecryptedLength)

					IF OpenSSL_PKeyDecrypt(This.PKeyCtx, @m.Decrypted, @m.DecryptedLength, m.Data, LEN(m.Data)) <= 0
						m.Decrypted = .NULL.
					ENDIF
				ENDIF
			ENDIF

		ENDIF

		RETURN m.Decrypted

	ENDFUNC

	FUNCTION DecryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String

		LOCAL Context AS Integer
		LOCAL Cipher AS Integer

		m.Cipher = This.GetCipherType(m.XMLKey)
		IF ISNULL(m.Cipher)
			RETURN .NULL.
		ENDI

		LOCAL PaddedData AS String
		LOCAL SecretKey AS String
		LOCAL IV AS String

		m.IV = LEFT(m.Data, m.XMLKey.CryptParams("BlockSize"))

		m.PaddedData = SUBSTR(m.Data, m.XMLKey.CryptParams("BlockSize") + 1)

		m.SecretKey = m.XMLKey.Key

		LOCAL BlockDecrypted AS String
		LOCAL BlockLength AS Integer
		LOCAL Decrypted AS String

		m.Decrypted = .NULL.

		m.Context = OpenSSL_CipherCtxNew()
		IF !EMPTY(m.Context)

			IF OpenSSL_DecryptInit(m.Context, m.Cipher, 0, m.SecretKey, m.IV) = 1

				m.BlockDecrypted = REPLICATE(CHR(0), LEN(m.Data) * 2)
				m.BlockLength = 0

				IF OpenSSL_DecryptUpdate(m.Context, @m.BlockDecrypted, @m.BlockLength, m.PaddedData, LEN(m.PaddedData)) = 1
					m.PaddedData = LEFT(m.BlockDecrypted, m.BlockLength)

					m.BlockLength = 0

					IF OpenSSL_DecryptFinal(m.Context, @m.BlockDecrypted, @m.BlockLength) = 1
						m.PaddedData = m.PaddedData + LEFT(m.BlockDecrypted, m.BlockLength)
						m.Decrypted = This.UnpadISO10126(m.PaddedData)
					ENDIF
				ENDIF
			ENDIF

			OpenSSL_CipherCtxRelease(m.Context)
		ENDIF

		RETURN m.Decrypted
	
	ENDFUNC

	FUNCTION EncryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String

		RETURN This.EncryptPublic(m.Data, m.XMLKey)

	ENDFUNC

	FUNCTION EncryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String
	
		LOCAL Encrypted AS String
		LOCAL EncryptedLength AS Integer

		m.Encrypted = ""

		IF !EMPTY(This.PKeyCtx)

			IF OpenSSL_PKeyEncryptInit(This.PKeyCtx) > 0

				This.SetPadding(m.XMLKey)
	
				m.EncryptedLength = 0
				IF OpenSSL_PKeyEncrypt(This.PKeyCtx, 0, @m.EncryptedLength, m.Data, LEN(m.Data)) > 0

					m.Encrypted = REPLICATE(CHR(0), m.EncryptedLength)

					IF OpenSSL_PKeyEncrypt(This.PKeyCtx, @m.Encrypted, @m.EncryptedLength, m.Data, LEN(m.Data)) <= 0
						m.Encrypted = ""
					ENDIF
				ENDIF
			ENDIF

		ENDIF

		RETURN EVL(m.Encrypted, .NULL.)

	ENDFUNC

	FUNCTION EncryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String

		LOCAL Context AS Integer
		LOCAL Cipher AS Integer

		m.Cipher = This.GetCipherType(m.XMLKey)
		IF ISNULL(m.Cipher)
			RETURN .NULL.
		ENDIF

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

		m.Encrypted = .NULL.

		m.Context = OpenSSL_CipherCtxNew()

		IF !EMPTY(m.Context)

			m.BlockEncrypted = REPLICATE(CHR(0), LEN(m.PaddedData) * 2 + LEN(m.IV) * 2) 
			m.BlockLength = 0

			IF OpenSSL_EncryptInit(m.Context, m.Cipher, 0, m.SecretKey, m.IV) = 1

				IF OpenSSL_EncryptUpdate(m.Context, @m.BlockEncrypted, @m.BlockLength, m.PaddedData, LEN(m.PaddedData)) = 1

					m.Encrypted = LEFT(m.BlockEncrypted, m.BlockLength)
					m.BlockLength = 0

					IF OpenSSL_EncryptFinal(m.Context, @m.BlockEncrypted, @m.BlockLength) = 1
						m.Encrypted = m.IV + m.Encrypted + LEFT(m.BlockEncrypted, m.BlockLength)
					ELSE
						m.Encrypted = .NULL.
					ENDIF

				ENDIF
			ENDIF

			OpenSSL_CipherCtxRelease(m.Context)

		ENDIF

		RETURN m.Encrypted

	ENDFUNC

	FUNCTION GetPrivateKey (PEM AS String, Password AS String) AS Object

		LOCAL PKey AS Integer
		LOCAL Bio AS Integer
		LOCAL Bytes AS Integer

		This.PKeyCtx = 0

		m.PKey = 0

		m.Bio = OpenSSL_BioNew(OpenSSL_BioMem())

		IF !EMPTY(m.Bio)

			m.Bytes = OpenSSL_BioWrite(m.Bio, m.PEM, LEN(m.PEM))

			IF m.Bytes > 0
				IF PCOUNT() = 2
					m.PKey = OpenSSL_BioLoadPrivateKey(m.Bio, 0, 0, m.Password)
				ELSE
					m.PKey = OpenSSL_BioLoadPrivateKey(m.Bio, 0, 0, 0)
				ENDIF

				OpenSSL_BioRelease(m.Bio)
			ENDIF
		ENDIF

		IF !EMPTY(m.PKey)
			This.PKeyCtx = OpenSSL_PKeyCtxNew(m.PKey, 0)
			IF EMPTY(This.PKeyCtx)
				m.PKey = 0
			ENDIF
		ENDIF

		RETURN EVL(m.PKey, .NULL.)

	ENDFUNC

	FUNCTION GetPublicKey (Cert AS String, IsCert AS Boolean) AS Object

		LOCAL PKey AS Integer
		LOCAL Bio AS Integer
		LOCAL Bytes AS Integer
		LOCAL X509 AS Integer

		This.PKeyCtx = 0

		m.PKey = 0

		m.Bio = OpenSSL_BioNew(OpenSSL_BioMem())
		IF !EMPTY(m.Bio)

			m.Bytes = OpenSSL_BioWrite(m.Bio, m.Cert, LEN(m.Cert))

			IF m.Bytes > 0
				IF m.IsCert
					m.X509 = OpenSSL_BioLoadX509(m.Bio, 0, 0, 0)
					IF !EMPTY(m.X509)
						m.PKey = OpenSSL_X509GetPublicKey(m.X509)
						OpenSSL_X509Release(m.X509)
					ENDIF
				ELSE
					m.PKey = OpenSSL_BioLoadPublicKey(m.Bio, 0, 0, 0)
				ENDIF

			ENDIF

			OpenSSL_BioRelease(m.Bio)
		ENDIF

		IF !EMPTY(m.PKey)
			This.PKeyCtx = OpenSSL_PKeyCtxNew(m.PKey, 0)
			IF EMPTY(This.PKeyCtx)
				m.PKey = 0
			ENDIF
		ENDIF

		RETURN EVL(m.PKey, .NULL.)

	ENDFUNC

	FUNCTION RandomBytes (Size AS Integer) AS String

		LOCAL Bytes AS String

		m.Bytes = REPLICATE(CHR(0), m.Size)
		OpenSSL_RandBytes(@m.Bytes, m.Size)

		RETURN m.Bytes

	ENDFUNC

	FUNCTION Hash (AlgorithmCode AS String, ToHash AS String) AS String

		LOCAL DigestType AS Integer
		LOCAL HashedData AS String
		LOCAL HashLength AS Integer

		DO CASE
		CASE m.AlgorithmCode == HASH_SHA1
			m.DigestType = OpenSSL_SHA1()
		CASE m.AlgorithmCode == HASH_SHA256
			m.DigestType = OpenSSL_SHA256()
		CASE m.AlgorithmCode == HASH_SHA384
			m.DigestType = OpenSSL_SHA384()
		CASE m.AlgorithmCode == HASH_SHA512
			m.DigestType = OpenSSL_SHA512()
		CASE m.AlgorithmCode == HASH_RIPEMD160
			m.DigestType = OpenSSL_RIPEMD160()
		OTHERWISE
			RETURN .NULL.
		ENDCASE

		LOCAL Context AS Integer

		m.Context = OpenSSL_DigestCtxNew()
		IF !EMPTY(m.Context)

			OpenSSL_DigestInit(m.Context, m.DigestType, 0)
			OpenSSL_DigestUpdate(m.Context, m.ToHash, LEN(m.ToHash))
			
			m.HashLength = OpenSSL_DigestSize(m.DigestType)
			m.HashedData = REPLICATE(CHR(0), m.HashLength)
			OpenSSL_DigestFinal(m.Context, @m.HashedData, @m.HashLength)
			m.HashedData = LEFT(m.HashedData, m.HashLength)

			OpenSSL_DigestCtxRelease(m.Context)

		ELSE

			m.HashedData = .NULL.

		ENDIF

		RETURN m.HashedData

	ENDFUNC

	FUNCTION SHA1 (ToHash AS String) AS String

		RETURN STRCONV(This.Hash(HASH_SHA1, m.ToHash), 15)

	ENDFUNC

	FUNCTION SignData (Data AS String, XMLKey AS XMLSecurityKey) AS String

		LOCAL Context AS Integer
		LOCAL DigestType AS Integer
		LOCAL Digest AS String
		LOCAL DigestLen AS Integer
		LOCAL CheckLen AS Integer
		LOCAL IsHMAC AS Boolean

		m.Digest = .NULL.

		m.Context = OpenSSL_DigestCtxNew()
		IF !EMPTY(m.Context)

			m.DigestType = OpenSSL_SHA1()
			IF m.XMLKey.CryptParams.GetKey("Type") != 0

				IF m.XMLKey.CryptParams.GetKey("Digest") != 0
					m.DigestType = OpenSSL_DigestByName(m.XMLKey.CryptParams("Digest"))
				ENDIF

				m.IsHMAC = .F.

			ELSE
			
				m.IsHMAC = .T.

			ENDIF

			IF !m.IsHMAC OR OpenSSL_DigestInit(m.Context, m.DigestType, 0) = 1

				IF OpenSSL_DigestSignInit(m.Context, 0, m.DigestType, 0, m.XMLKey.Key) = 1

					IF OpenSSL_DigestSignUpdate(m.Context, m.Data, LEN(m.Data)) = 1

						m.DigestLen = 0
						IF OpenSSL_DigestSignFinal(m.Context, 0, @m.DigestLen) = 1

							IF m.DigestLen > 0
								m.CheckLen = m.DigestLen
								m.Digest = REPLICATE(CHR(0), m.DigestLen)
								IF OpenSSL_DigestSignFinal(m.Context, @m.Digest, @m.DigestLen) != 1
									m.Digest = .NULL.
								ELSE
									IF m.CheckLen != m.DigestLen
										m.Digest = .NULL.
									ENDIF
								ENDIF
							ENDIF
						ENDIF
					ENDIF
				ENDIF
			ENDIF

			OpenSSL_DigestCtxRelease(m.Context)
 		ENDIF

		RETURN m.Digest

	ENDFUNC

	FUNCTION VerifySignature (Data AS String, Signature AS String,	XMLKey AS XMLSecurityKey) AS Boolean

		LOCAL Context AS Integer
		LOCAL DigestType AS Integer
		LOCAL Verified AS Integer

		m.Verified = .F.

		IF m.XMLKey.CryptParams.GetKey("Type") != 0

			m.Context = OpenSSL_DigestCtxNew()
			IF !EMPTY(m.Context)
	
				IF m.XMLKey.CryptParams.GetKey("Digest") != 0
					m.DigestType = OpenSSL_DigestByName(m.XMLKey.CryptParams("Digest"))
				ELSE
					m.DigestType = OpenSSL_SHA1()
				ENDIF

				IF OpenSSL_DigestVerifyInit(m.Context, 0, m.DigestType, 0, m.XMLKey.Key) = 1

					IF OpenSSL_DigestVerifyUpdate(m.Context, m.Data, LEN(m.Data)) = 1

						m.Verified = (OpenSSL_DigestVerifyFinal(m.Context, m.Signature, LEN(m.Signature)) = 1)

					ENDIF
				ENDIF

			ENDIF

			OpenSSL_DigestCtxRelease(m.Context)

		ELSE
			m.Verified = m.Signature == NVL(This.SignData(m.Data, m.XMLKey), "")
 		ENDIF

		RETURN m.Verified	

	ENDFUNC

	FUNCTION X509Export (Cert AS String) AS String

		LOCAL BioIn AS Integer
		LOCAL BioOut
		LOCAL Bytes AS Integer
		LOCAL X509 AS Integer
		LOCAL Export AS String
		LOCAL ExportLen AS Integer

		m.Export = .NULL.

		m.BioIn = OpenSSL_BioNew(OpenSSL_BioMem())
		IF !EMPTY(m.BioIn)

			m.Bytes = OpenSSL_BioWrite(m.BioIn, m.Cert, LEN(m.Cert))

			IF m.Bytes > 0
				m.X509 = OpenSSL_BioLoadX509(m.BioIn, 0, 0, 0)
				IF !EMPTY(m.X509)

					m.BioOut = OpenSSL_BioNew(OpenSSL_BioMem())
					IF !EMPTY(m.BioOut)
						IF OpenSSL_BioWriteX509(m.BioOut, m.X509) = 1
							m.ExportLen = OpenSSL_BioPending(m.BioOut)
							IF m.ExportLen > 0
								m.Export = SPACE(m.ExportLen)
								OpenSSL_BioRead(m.BioOut, @m.Export, m.ExportLen)
							ENDIF
						ENDIF

						OpenSSL_BioRelease(m.BioOut)
					ENDIF
					OpenSSL_X509Release(m.X509)

				ENDIF

			ENDIF

			OpenSSL_BioRelease(m.BioIn)
		ENDIF

		RETURN m.Export

	ENDFUNC

	FUNCTION X509Parse (Cert AS String) AS Collection

		LOCAL BioIn AS Integer
		LOCAL BioOut
		LOCAL Bytes AS Integer
		LOCAL X509 AS Integer
		LOCAL Parsed AS Collection
		LOCAL Part AS String
		LOCAL Length AS Integer

		m.Parsed = .NULL.

		m.BioIn = OpenSSL_BioNew(OpenSSL_BioMem())
		IF !EMPTY(m.BioIn)

			m.Bytes = OpenSSL_BioWrite(m.BioIn, m.Cert, LEN(m.Cert))

			IF m.Bytes > 0
				m.X509 = OpenSSL_BioLoadX509(m.BioIn, 0, 0, 0)
				IF !EMPTY(m.X509)

					m.BioOut = OpenSSL_BioNew(OpenSSL_BioMem())
					IF !EMPTY(m.BioOut)

						m.Parsed = CREATEOBJECT("Collection")
						m.Parsed.Add(TRANSFORM(OpenSSL_X509GetVersion(m.X509)), "Version")

						IF OpenSSL_BioWriteX509Name(m.BioOut, OpenSSL_X509GetSubjectName(m.X509), 0, 0) = 1
							This.X509GetName(m.BioOut, m.Parsed, "Subject")
						ENDIF

						IF OpenSSL_BioWriteX509Name(m.BioOut, OpenSSL_X509GetIssuerName(m.X509), 0, 0) = 1
							This.X509GetName(m.BioOut, m.Parsed, "Issuer")
						ENDIF

						OpenSSL_BioRelease(m.BioOut)

					ENDIF

					OpenSSL_X509Release(m.X509)

				ENDIF

			ENDIF

			OpenSSL_BioRelease(m.BioIn)
		ENDIF

		RETURN m.Parsed

	ENDFUNC

	HIDDEN FUNCTION SetPadding (XMLKey AS XMLSecurityKey)

		IF m.XMLKey.CryptParams.GetKey("Padding") != 0
			OpenSSL_PKeyCtxCtrl(This.PKeyCtx, -1, 0x1001, IIF(m.XMLKey.CryptParams("Padding") = PKCS1_OAEP_PADDING, 4, 1), 0)
		ENDIF

	ENDFUNC

	HIDDEN FUNCTION GetCipherType (XMLKey AS XMLSecurityKey) as Integer

		LOCAL Cipher AS Integer
		LOCAL CipherName AS String

		m.CipherName = m.XMLKey.CryptParams("Cipher")
		DO CASE
		CASE m.CipherName == "des-ede3-cbc"
			m.Cipher = OpenSSL_DES_EDE3_CBC()
		CASE m.CipherName == "aes-128-cbc"
			m.Cipher = OpenSSL_AES_128_CBC()
		CASE m.CipherName == "aes-192-cbc"
			m.Cipher = OpenSSL_AES_192_CBC()
		CASE m.CipherName == "aes-256-cbc"
			m.Cipher = OpenSSL_AES_256_CBC()
		OTHERWISE
			m.Cipher = .NULL.
		ENDCASE

		RETURN m.Cipher

	ENDFUNC

	HIDDEN FUNCTION X509GetName (Bio AS Integer, Parsing AS Collection, PartName AS String)

		LOCAL Part AS String
		LOCAL Length AS Integer

		m.Length = OpenSSL_BioPending(m.Bio)
		IF m.Length > 0
			m.Part = SPACE(m.Length)
			IF OpenSSL_BioRead(m.Bio, @m.Part, m.Length) > 0
				m.Parsing.Add(m.Part, m.PartName)
			ENDIF
		ENDIF

	ENDFUNC

ENDDEFINE
