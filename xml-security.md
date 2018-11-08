# XMLSecurity
A VFP set of classes to secure an XML document (encrypt, signing, and verifying).

Part of [VFP XML library set](README.md "VFP XML library set").

## Credits

- A VFP porting of XMLSecLibs, a PHP library for XML Security by Rob Richards and contributors (at
[https://github.com/robrichards/xmlseclibs](https://github.com/robrichards/xmlseclibs))

## Status

- Not suited for production.
- See tests for current coverage of functionality.

## Usage
See examples at the tests folder:

- [Sign an XML document - basic](tests/sec/test-hw-sign.prg "test-hw-sign.prg")

## Components

- [XMLSecurity header file](xml-security.h "xml-security.h")
- [XMLSecurityLib, a class to perform encryption and hashing operations](xml-security-lib.prg "xml-security-lib.prg")
- [XMLSecurityLibChilkat, a XMLSecurityLib subclass that interfaces to Chilkat RSA and Cert components](xml-security-lib-chilkat.prg "xml-security-lib-chilkat.prg")
- [XMLSecurityKey, a class to manage key related operations)](xml-security-enc.prg "xml-security-enc.prg")
- [XMLSecurityDSig, a class to sign XML documents and fragments)](xml-security-enc.prg "xml-security-enc.prg")
- [XMLSecEnc, a class to encrypt XML data)](xml-security-enc.prg "xml-security-enc.prg")

## Dependencies

- [XMLCanonicalizer](xml-canonicalizer.md "XMLCanonicalizer")
- [GUID](https://www.bitbucket.org/atlopes/GUID "GUID")
- [URL](https://www.bitbucket.org/atlopes/url "URL")
