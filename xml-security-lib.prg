*
* XMLSecurityLib
*

IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#INCLUDE "xml-security.h"

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSecurityLib AS Custom

	_MemberData = "<VFPData>" + ;
						'<memberdata name="convertrsa" type="method" display="ConvertRSA"/>' + ;
						'<memberdata name="decryptprivate" type="method" display="DecryptPrivate"/>' + ;
						'<memberdata name="decryptPublic" type="method" display="DecryptPublic"/>' + ;
						'<memberdata name="decryptsymmetric" type="method" display="DecryptSymmetric"/>' + ;
						'<memberdata name="encryptprivate" type="method" display="EncryptPrivate"/>' + ;
						'<memberdata name="encryptPublic" type="method" display="EncryptPublic"/>' + ;
						'<memberdata name="encryptsymmetric" type="method" display="EncryptSymmetric"/>' + ;
						'<memberdata name="getprivatekey" type="method" display="GetPrivateKey"/>' + ;
						'<memberdata name="getpublickey" type="method" display="GetPublicKey"/>' + ;
						'<memberdata name="padiso10126" type="method" display="PadISO10126"/>' + ;
						'<memberdata name="randombytes" type="method" display="RandomBytes"/>' + ;
						'<memberdata name="hash" type="method" display="Hash"/>' + ;
						'<memberdata name="sha1" type="method" display="SHA1"/>' + ;
						'<memberdata name="signdata" type="method" display="SignData"/>' + ;
						'<memberdata name="unpadiso10126" type="method" display="UnpadISO10126"/>' + ;
						'<memberdata name="verifysignature" type="method" display="VerifySignature"/>' + ;
						'<memberdata name="x509export" type="method" display="X509Export"/>' + ;
						'<memberdata name="x509parse" type="method" display="X509Parse"/>' + ;
						"</VFPData>"

	FUNCTION DecryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String
		RETURN ""
	ENDFUNC

	FUNCTION DecryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String
		RETURN ""
	ENDFUNC

	FUNCTION DecryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String
		RETURN ""
	ENDFUNC

	FUNCTION EncryptPrivate (Data AS String, XMLKey AS XMLSecurityKey) AS String
		RETURN ""
	ENDFUNC

	FUNCTION EncryptPublic (Data AS String, XMLKey AS XMLSecurityKey) AS String
		RETURN ""
	ENDFUNC

	FUNCTION EncryptSymmetric (Data AS String, XMLKey AS XMLSecurityKey) AS String
		RETURN ""
	ENDFUNC

	FUNCTION GetPrivateKey (Cert AS String, Password AS String) AS String
		RETURN ""
	ENDFUNC

	FUNCTION GetPublicKey (Cert AS String, IsCert AS Boolean) AS String
		RETURN ""
	ENDFUNC

	FUNCTION RandomBytes (Size AS Integer) AS String
		RETURN ""
	ENDFUNC

	FUNCTION Hash (AlgorithmCode AS String, ToHash AS String) AS String
		RETURN ""
	ENDFUNC

	FUNCTION SHA1 (ToHash AS String) AS String
		RETURN ""
	ENDFUNC

	FUNCTION SignData (Data AS String, XMLKey AS XMLSecurityKey)
		RETURN ""
	ENDFUNC

	FUNCTION VerifySignature (Data AS String, Signature AS String,	XMLKey AS XMLSecurityKey)
		RETURN .F.
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
			m.Segment = CHR(0) + m.String

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

	FUNCTION X509Export (Cert AS String) AS String
		RETURN ""
	ENDFUNC

	FUNCTION X509Parse (Cert AS String) AS Collection
		RETURN .NULL.
	ENDFUNC

ENDDEFINE
