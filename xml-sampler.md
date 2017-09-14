# XMLSampler
A VFP class to create an XML sample document from an XML Schema.

The class wraps the transformation from the XSD to the XML, which is performed by two stylesheets that work in tandem: `samples-namespaces.xsl` reads required namespaces from the XML Schema, and inserts them into `samples-xml-generator.xsl`, a general purpose stylesheet to compose the actual sample.

The XML schema may be a standalone XSD document, or an XML document that includes XML Schemas, such as a WSDL.

The resulting XML source document may be used for editing, before real use, and may be helpful in code development, testing, and documentation.

Part of [VFP XML library set](README.md "VFP XML library set").

## Usage
```foxpro
*!* install the library
DO LOCFILE("xml-sampler.prg")
*!* instantiate an object
m.XMLSampler = CREATEOBJECT("XMLSampler")
*!* call methods...
```

## Components
```
xml-sampler.prg
sampler-namespaces.xsl
sampler-xml-generator.xsl
```

## Methods

### SampleSchema()
```foxpro
m.XML = m.XMLSampler.SampleSchema (m.Source)
```
Retrieves an XML Schema (standalone or contained) from a string, a URL, a file, or a DOM node, and returns a sample XML source document.

Example of sampling of an XML Schema (from *Definitive XML Schema*, by Priscilla Walmsley):
```xml
<?xml version="1.0"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="items" type="ItemsType"/>
  <xs:complexType name="ItemsType">
    <xs:all>
      <xs:element name="hat" type="ProductType"/>
      <xs:element name="umbrella" type="RestrictedProductType"/>
      <xs:element name="shirt" type="ShirtType"/>
    </xs:all>
  </xs:complexType>
  <!--Empty Content Type-->
  <xs:complexType name="ItemType" abstract="true">
    <xs:attribute name="routingNum" type="xs:integer"/>
  </xs:complexType>
  <!--Empty Content Extension (with Attribute Extension)-->
  <xs:complexType name="ProductType">
    <xs:complexContent>
      <xs:extension base="ItemType">
        <xs:sequence>
          <xs:element name="number" type="xs:integer"/>
          <xs:element name="name" type="xs:string"/>
          <xs:element name="description"
            type="xs:string" minOccurs="0"/>
        </xs:sequence>
        <xs:attribute name="effDate" type="xs:date"/>
        <xs:attribute name="lang" type="xs:language"/>
      </xs:extension>
    </xs:complexContent>
  </xs:complexType>
  <!--Complex Content Restriction-->
  <xs:complexType name="RestrictedProductType">
    <xs:complexContent>
      <xs:restriction base="ProductType">
        <xs:sequence>
          <xs:element name="number" type="xs:integer"/>
          <xs:element name="name" type="xs:token"/>
        </xs:sequence>
        <xs:attribute name="routingNum"
          type="xs:short" use="required"/>
        <xs:attribute name="effDate"
          type="xs:date" default="1900-01-01"/>
        <xs:attribute name="lang" use="prohibited"/>
      </xs:restriction>
    </xs:complexContent>
  </xs:complexType>
  <!--Complex Content Extension-->
  <xs:complexType name="ShirtType">
    <xs:complexContent>
      <xs:extension base="RestrictedProductType">
        <xs:choice maxOccurs="unbounded">
          <xs:element name="size" type="SmallSizeType"/>
          <xs:element name="color" type="ColorType"/>
        </xs:choice>
        <xs:attribute name="sleeve" type="xs:integer"/>
      </xs:extension>
    </xs:complexContent>
  </xs:complexType>
  <!--Simple Content Extension-->
  <xs:complexType name="SizeType">
    <xs:simpleContent>
      <xs:extension base="xs:integer">
        <xs:attribute name="system" type="xs:token"/>
      </xs:extension>
    </xs:simpleContent>
  </xs:complexType>
  <!--Simple Content Restriction-->
  <xs:complexType name="SmallSizeType">
    <xs:simpleContent>
      <xs:restriction base="SizeType">
        <xs:minInclusive value="2"/>
        <xs:maxInclusive value="6"/>
        <xs:attribute  name="system" type="xs:token"
          use="required"/>
      </xs:restriction>
    </xs:simpleContent>
  </xs:complexType>
  <xs:complexType name="ColorType">
    <xs:attribute name="value" type="xs:string"/>
  </xs:complexType>
</xs:schema>
```
results in an XML document
```xml
<?xml version="1.0"?>
<items>
  <hat effDate="2017-01-01" lang="en" routingNum="0">
    <number>0</number>
    <name>name</name>
   <description>description</description>
  </hat>
  <umbrella routingNum="0" effDate="1900-01-01">
    <number>0</number>
    <name>name</name>
  </umbrella>
  <shirt sleeve="0" routingNum="0" effDate="1900-01-01">
    <number>0</number>
    <name>name</name>
    <size system="system">4</size>
    <color value="value" />
   </shirt>
</items>
```

### SetOption() and GetOption()
```foxpro
m.XMLSampler.SetOption(m.Option, m.Setting)
m.Setting = m.XMLSampler.GetOption(m.Option)
```
Sets or gets sampling options.

Options are stored in `sampler-xml-generator.xsl`. For instance, to set value of optional elements sampling:

```foxpro
m.XMLSampler.SetOption("OptionalElements", "n")  && do not generate optional elements
```
Full list of sampler options:
```xml
 <!-- parameters that govern the sampling process -->

  <!-- leave blank for first schema defined in the document -->
  <xsl:param name="sampleNamespace"></xsl:param>

  <!-- leave blank for first element defined in the schema -->
  <xsl:param name="sampleRootElement"></xsl:param>

  <!-- y/n to generate optional elements and attributes -->
  <xsl:param name="sampleOptionalElements">y</xsl:param>
  <xsl:param name="sampleOptionalAttributes">y</xsl:param>

  <!-- y/n to generate comments from the annotations -->
  <xsl:param name="sampleComments">y</xsl:param>

  <!-- what unbounded means: a (probably) small number -->
  <xsl:param name="sampleUnbounded">2</xsl:param>

  <!-- in choice groups, fetch the elements in "sequence", or always the "first", or "comment" all others -->
  <xsl:param name="sampleChoiceStrategy">sequence</xsl:param>

  <!-- y/n to show the restricted string length -->
  <xsl:param name="sampleStringLength">n</xsl:param>

  <!-- generate strings based on the "default" setting, or on the element/attribute "name"  -->
  <xsl:param name="sampleStringSource">name</xsl:param>

  <!-- y/n to sample patterns -->
  <xsl:param name="samplePattern">y</xsl:param>

  <!-- y/n to sample Boolean as a number 1/0 -->
  <xsl:param name="sampleBooleanAsNumber">n</xsl:param>

  <!-- the default values for binary data (encoding of the string "binary data")  -->
  <xsl:param name="sampleDefaultBase64Binary">YmluYXJ5IGRhdGE=</xsl:param>
  <xsl:param name="sampleDefaultHexBinary">62696E6172792064617461</xsl:param>

  <!-- y/n to sample URI as http address -->
  <xsl:param name="sampleURIasHTTP">y</xsl:param>

  <!-- the default value for a string -->
  <xsl:param name="sampleDefaultString">string</xsl:param>

  <!-- the default value for a number -->
  <xsl:param name="sampleDefaultNumber">0</xsl:param>

  <!-- the default value for dates -->
  <xsl:param name="sampleDefaultDate">2017-01-01T12:00:00</xsl:param>

  <!-- the default value for untyped text data -->
  <xsl:param name="sampleDefaultTextData">text data</xsl:param>

  <!-- the default value for boolean -->
  <xsl:param name="sampleDefaultBoolean">true</xsl:param>

  <!-- the default value for URI -->
  <xsl:param name="sampleDefaultURI">URI:#</xsl:param>

  <!-- the default value for http URI -->
  <xsl:param name="sampleDefaultHTTP">http://www.example.com</xsl:param>

  <!-- the default value for xml:space attribute value -->
  <xsl:param name="sampleDefaultXMLSpace">default</xsl:param>

  <!-- the default value for xml:lang attribute value -->
  <xsl:param name="sampleDefaultXMLLang">en</xsl:param>

  <!-- the default value for xml:base attribute value -->
  <xsl:param name="sampleDefaultXMLBase">http://www.example.com</xsl:param>
```
