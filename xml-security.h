* Namespaces
#DEFINE	XMLDSIG_NS				"http://www.w3.org/2000/09/xmldsig#"
#DEFINE	XMLENC_NS				"http://www.w3.org/2001/04/xmlenc#"

* encryption scope URI
#DEFINE	ELEMENT_URI				"http://www.w3.org/2001/04/xmlenc#Element"
#DEFINE	CONTENT_URI				"http://www.w3.org/2001/04/xmlenc#Content"

* Canonicalization URI
#DEFINE	C14N						"http://www.w3.org/TR/2001/REC-xml-c14n-20010315"
#DEFINE	C14N_COMMENTS			"http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments"
#DEFINE	EXC_C14N					"http://www.w3.org/2001/10/xml-exc-c14n#"
#DEFINE	EXC_C14N_COMMENTS 	"http://www.w3.org/2001/10/xml-exc-c14n#WithComments"
#DEFINE	C14N_XPATH				"http://www.w3.org/TR/1999/REC-xpath-19991116"

* XML encryption and signing URI
#DEFINE	TRIPLEDES_CBC			"http://www.w3.org/2001/04/xmlenc#tripledes-cbc"
#DEFINE	AES128_CBC				"http://www.w3.org/2001/04/xmlenc#aes128-cbc"
#DEFINE	AES192_CBC				"http://www.w3.org/2001/04/xmlenc#aes192-cbc"
#DEFINE	AES256_CBC				"http://www.w3.org/2001/04/xmlenc#aes256-cbc"
#DEFINE	RSA_1_5					"http://www.w3.org/2001/04/xmlenc#rsa-1_5"
#DEFINE	RSA_OAEP_MGF1P			"http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
#DEFINE	DSA_SHA1					"http://www.w3.org/2000/09/xmldsig#dsa-sha1"
#DEFINE	RSA_SHA1					"http://www.w3.org/2000/09/xmldsig#rsa-sha1"
#DEFINE	RSA_SHA256				"http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
#DEFINE	RSA_SHA384				"http://www.w3.org/2001/04/xmldsig-more#rsa-sha384"
#DEFINE	RSA_SHA512				"http://www.w3.org/2001/04/xmldsig-more#rsa-sha512"
#DEFINE	HMAC_SHA1				"http://www.w3.org/2000/09/xmldsig#hmac-sha1"
#DEFINE	HASH_SHA1				"http://www.w3.org/2000/09/xmldsig#sha1"
#DEFINE	HASH_SHA256				"http://www.w3.org/2001/04/xmlenc#sha256"
#DEFINE	HASH_SHA384				"http://www.w3.org/2001/04/xmldsig-more#sha384"
#DEFINE	HASH_SHA512				"http://www.w3.org/2001/04/xmlenc#sha512"
#DEFINE	HASH_RIPEMD160			"http://www.w3.org/2001/04/xmlenc#ripemd160"

* Padding constants
#DEFINE	PKCS1_PADDING			0
#DEFINE	SSLV23_PADDING			1
#DEFINE	NO_PADDING				2
#DEFINE	PKCS1_OAEP_PADDING	3

* some other useful constants
#DEFINE	LF	CHR(10)
