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
						'<memberdata name="decryptprivate" type="method" display="DecryptPrivate"/>' + ;
						'<memberdata name="decryptPublic" type="method" display="DecryptPublic"/>' + ;
						'<memberdata name="decryptsymmetric" type="method" display="DecryptSymmetric"/>' + ;
						'<memberdata name="encryptprivate" type="method" display="EncryptPrivate"/>' + ;
						'<memberdata name="encryptPublic" type="method" display="EncryptPublic"/>' + ;
						'<memberdata name="encryptsymmetric" type="method" display="EncryptSymmetric"/>' + ;
						'<memberdata name="getprivatekey" type="method" display="GetPrivateKey"/>' + ;
						'<memberdata name="getpublickey" type="method" display="GetPublicKey"/>' + ;
						'<memberdata name="randombytes" type="method" display="RandomBytes"/>' + ;
						'<memberdata name="hash" type="method" display="Hash"/>' + ;
						'<memberdata name="sha1" type="method" display="SHA1"/>' + ;
						'<memberdata name="signdata" type="method" display="SignData"/>' + ;
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

	FUNCTION GetPrivateKey (Cert AS String) AS String
		RETURN ""
	ENDFUNC

	FUNCTION GetPublicKey (Cert AS String) AS String
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
		RETURN ""
	ENDFUNC

	FUNCTION X509Export (Cert AS String) AS String
		RETURN ""
	ENDFUNC

	FUNCTION X509Parse (Cert AS String) AS Collection
		RETURN .NULL.
	ENDFUNC

ENDDEFINE
