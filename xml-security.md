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
- [Sign an XML element](tests/sec/test-hw-child-sign.prg "test-hw-child-sign.prg")
- [Sign an XML element with its own Id](tests/sec/test-hw-child-id-sign.prg "test-hw-child-id-sign.prg")
- [Sign an XML document and put it inside an enveloping signature](tests/sec/test-hw-sign-enveloping.prg "test-hw-sign-enveloping.prg")
- [Sign a text and put it inside an enveloping signature](tests/sec/test-text-sign-enveloping.prg "test-text-sign-enveloping.prg")

## Components

- [XMLSecurity header file](xml-security.h "xml-security.h")
- [XMLSecurityLib, a class to perform encryption and hashing operations](xml-security-lib.prg "xml-security-lib.prg")
- [XMLSecurityLibChilkat, a XMLSecurityLib subclass that interfaces to Chilkat RSA and Cert components](xml-security-lib-chilkat.prg "xml-security-lib-chilkat.prg")
- [XMLSecurityKey, a class to manage key related operations](xml-security-key.prg "xml-security-key.prg")
- [XMLSecurityDSig, a class to sign XML documents and fragments](xml-security-dsig.prg "xml-security-dsig.prg")
- [XMLSecEnc, a class to encrypt XML data)](xml-security-enc.prg "xml-security-enc.prg")

## Dependencies

- [XMLCanonicalizer](xml-canonicalizer.md "XMLCanonicalizer")
- [GUID](https://www.bitbucket.org/atlopes/GUID "GUID")
- [URL](https://www.bitbucket.org/atlopes/url "URL")

XMLSecurity requires a crypto library to provide the encryption and hashing functions. For the moment, the RSA and Cert components of Chilkat are being used, but in the future other providers may be added to the set.

