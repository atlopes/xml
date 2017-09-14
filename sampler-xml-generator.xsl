<?xml version="1.0" encoding="UTF-8"?>
<!-- 
  Sampler XML generator

  Generic XML sample generator, based on an XML Schema (xsd).
  Targeted at version 1.0, no extensions added or expected (MSXML6 should be able to use the stylesheet).

  Receives as the input an XML Schema (or an XML document that hosts an XML Schema, like a WSDL).
  Creates an XML document that can be edited before full validation.

  Work in progress.

  Notable missing points:
  * many XML Schema types not yet covered
  * a few XML Schema elements not yet covered

  Notable constraints:
  * main or imported schema should declare targetNamespace: that's on what the generator depends to determine the schema elements' namespace
  * no rules
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0">

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

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

  <!-- the default values for binary data (encoding of the string "binary data")  -->
  <xsl:param name="sampleDefaultBase64Binary">YmluYXJ5IGRhdGE=</xsl:param>
  <xsl:param name="sampleDefaultHexBinary">62696E6172792064617461</xsl:param>

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

  <!-- fetch and store the prefix used for XML Schema namespace in the main schema -->
  <xsl:variable name="xs">
    <xsl:for-each select="//xs:schema[@targetName = $sampleNamespace or position() = 1]/namespace::*[. = 'http://www.w3.org/2001/XMLSchema']">
      <xsl:value-of select="name()"/>
    </xsl:for-each>
  </xsl:variable>
  <!-- set the prefix, with colon, or empty, if default namespace -->
  <xsl:variable name="qxs">
    <xsl:if test="$xs != ''">
      <xsl:value-of select="concat($xs, ':')"/>
    </xsl:if>
  </xsl:variable>

  <!-- fetch and store the target namespace of the main schema -->
  <xsl:variable name="namespace">
    <xsl:value-of select="//xs:schema[@targetName = $sampleNamespace or position() = 1]/@targetNamespace"/>
  </xsl:variable>

  <!-- get the namespace associated to a particular prefix -->
  <xsl:template name="getNamespace">
    <xsl:param name="qname"/>

    <xsl:variable name="prefix" select="substring-before($qname, ':')"/>
    <xsl:value-of select="ancestor-or-self::*/namespace::*[name() = $prefix]"/>
  </xsl:template>

  <!-- get the prefix associated to a particular namespace -->
  <xsl:template name="getPrefix">
    <xsl:param name="namespace"/>

    <xsl:value-of select="name(ancestor-or-self::*/namespace::*[. = $namespace])"/>
  </xsl:template>

  <!-- get the local prefix - if any - associated to the XML Schema namespace, for a typed attribute value -->
  <xsl:template name="getLocalXS">
    <xsl:param name="dtype" select="@type"/>

    <xsl:variable name="localPrefix">
      <xsl:for-each select="/*/namespace::*[. = 'http://www.w3.org/2001/XMLSchema']">
        <xsl:value-of select="name()"/>
      </xsl:for-each>
    </xsl:variable>

    <!-- recreate the value using the global prefix denoted by variable $xs -->
    <xsl:choose>
      <xsl:when test="$localPrefix = '' and $xs != ''">
        <xsl:value-of select="concat($qxs, $dtype)"/>
      </xsl:when>
      <xsl:when test="$localPrefix != $xs">
        <xsl:value-of select="concat($qxs, substring-after($dtype, ':'))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$dtype"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!-- string types -->
  <xsl:variable name="xsID" select="concat($qxs, 'ID')"/>
  <xsl:variable name="xsIDREF" select="concat($qxs, 'IDREF')"/>
  <xsl:variable name="xsString" select="concat($qxs, 'string')"/>
  <xsl:variable name="xsLanguage" select="concat($qxs, 'language')"/>
  <xsl:variable name="xsToken" select="concat($qxs, 'token')"/>
  <xsl:variable name="xsNormalizedString" select="concat($qxs, 'normalizedString')"/>

  <!-- numeric types -->
  <xsl:variable name="xsByte" select="concat($qxs, 'byte')"/>
  <xsl:variable name="xsDecimal" select="concat($qxs, 'decimal')"/>
  <xsl:variable name="xsInt" select="concat($qxs, 'int')"/>
  <xsl:variable name="xsInteger" select="concat($qxs, 'integer')"/>
  <xsl:variable name="xsLong" select="concat($qxs, 'long')"/>
  <xsl:variable name="xsNegativeInteger" select="concat($qxs, 'negativeInteger')"/>
  <xsl:variable name="xsNonNegativeInteger" select="concat($qxs, 'nonNegativeInteger')"/>
  <xsl:variable name="xsNonPositiveInteger" select="concat($qxs, 'nonPositiveInteger')"/>
  <xsl:variable name="xsPositiveInteger" select="concat($qxs, 'positiveInteger')"/>
  <xsl:variable name="xsShort" select="concat($qxs, 'short')"/>
  <xsl:variable name="xsUnsignedByte" select="concat($qxs, 'unsignedByte')"/>
  <xsl:variable name="xsUnsignedInt" select="concat($qxs, 'unsignedInt')"/>
  <xsl:variable name="xsUnsignedLong" select="concat($qxs, 'unsignedLong')"/>
  <xsl:variable name="xsUnsignedShort" select="concat($qxs, 'unsignedShort')"/>

  <!-- date types -->
  <xsl:variable name="xsDate" select="concat($qxs, 'date')"/>
  <xsl:variable name="xsDateTime" select="concat($qxs, 'dateTime')"/>

  <!-- boolean -->
  <xsl:variable name="xsBoolean" select="concat($qxs, 'boolean')"/>

  <!-- binary -->
  <xsl:variable name="xsBase64Binary" select="concat($qxs, 'base64Binary')"/>
  <xsl:variable name="xsHexBinary" select="concat($qxs, 'hexBinary')"/>

  <!-- URI -->
  <xsl:variable name="xsAnyURI" select="concat($qxs, 'anyURI')"/>

  <!-- convenient reference to types, grouped by base type -->
  <xsl:variable name="xsGroupString">
    <xsl:value-of select="concat('|', $xsID)"/>
    <xsl:value-of select="concat('|', $xsIDREF)"/>
    <xsl:value-of select="concat('|', $xsString)"/>
    <xsl:value-of select="concat('|', $xsLanguage)"/>
    <xsl:value-of select="concat('|', $xsNormalizedString)"/>
    <xsl:value-of select="concat('|', $xsToken, '|')"/>
  </xsl:variable>
  <xsl:variable name="xsGroupNumeric">
    <xsl:value-of select="concat('|', $xsByte)"/>
    <xsl:value-of select="concat('|', $xsDecimal)"/>
    <xsl:value-of select="concat('|', $xsInteger)"/>
    <xsl:value-of select="concat('|', $xsInt)"/>
    <xsl:value-of select="concat('|', $xsLong)"/>
    <xsl:value-of select="concat('|', $xsPositiveInteger)"/>
    <xsl:value-of select="concat('|', $xsNonPositiveInteger)"/>
    <xsl:value-of select="concat('|', $xsNegativeInteger)"/>
    <xsl:value-of select="concat('|', $xsNonNegativeInteger)"/>
    <xsl:value-of select="concat('|', $xsShort)"/>
    <xsl:value-of select="concat('|', $xsUnsignedByte)"/>
    <xsl:value-of select="concat('|', $xsUnsignedInt)"/>
    <xsl:value-of select="concat('|', $xsUnsignedLong)"/>
    <xsl:value-of select="concat('|', $xsUnsignedShort, '|')"/>
  </xsl:variable>
  <xsl:variable name="xsGroupDate">
    <xsl:value-of select="concat('|', $xsDate)"/>
    <xsl:value-of select="concat('|', $xsDateTime, '|')"/>
  </xsl:variable>
  <xsl:variable name="xsGroupBinary">
    <xsl:value-of select="concat('|', $xsBase64Binary)"/>
    <xsl:value-of select="concat('|', $xsHexBinary, '|')"/>
  </xsl:variable>
  
  <!--
    the main template: locate the root element, as given by the parameters or default, and start the sampling from there
  -->
  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="//xs:schema[@targetName = $sampleNamespace or position() = 1]/xs:element[@name = $sampleRootElement]">
        <xsl:for-each select="//xs:schema[@targetName = $sampleNamespace or position() = 1]/xs:element[@name = $sampleRootElement]">
          <xsl:call-template name="element">
            <xsl:with-param name="root" select="true()"/>
            <xsl:with-param name="tree" select="''"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <!-- if the root element was not given, use the first defined element -->
        <xsl:for-each select="//xs:schema[@targetName = $sampleNamespace or position() = 1]/xs:element[1]">
          <xsl:call-template name="element">
            <xsl:with-param name="root" select="true()"/>
            <xsl:with-param name="tree" select="''"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--

    include* (Elements, Attributes, ComplexTypes, SimpleTypes, Groups, AttributeGroups)

    these templates look for references in included or imported schemas
    at the main schema, and then (recursively) in all linked schemas (by inclusion or importing)

    the namespace may be set differently, in these linked schemas (that's what is expected with imported schemas)
  -->
  <xsl:template name="includeElements">
    <xsl:param name="elementRef"/>
    <xsl:param name="root" select="false()"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:element[@name = $elementRef or @name = substring-after($elementRef, ':')]">
            <xsl:for-each select="xs:element[@name = $elementRef or @name = substring-after($elementRef, ':')]">
              <xsl:call-template name="element">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="root" select="$root"/>
                <xsl:with-param name="tree" select="$tree"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeElements">
              <xsl:with-param name="elementRef" select="$elementRef"/>
              <xsl:with-param name="root" select="$root"/>
              <xsl:with-param name="tree" select="$tree"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeAttributes">
    <xsl:param name="attribRef"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:attribute[@name = $attribRef or @name = substring-after($attribRef, ':')]">
            <xsl:for-each select="xs:attribute[@name = $attribRef or @name = substring-after($attribRef, ':')]">
              <xsl:call-template name="attribute">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeAttributes">
              <xsl:with-param name="attribRef" select="$attribRef"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeComplexTypes">
    <xsl:param name="typeRef"/>
    <xsl:param name="root" select="false()"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="nodeName"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:complexType[@name = $typeRef or @name = substring-after($typeRef, ':')]">
            <xsl:for-each select="xs:complexType[@name = $typeRef or @name = substring-after($typeRef, ':')]">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="instance" select="$instance"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeComplexTypes">
              <xsl:with-param name="typeRef" select="$typeRef"/>
              <xsl:with-param name="tree" select="$tree"/>
              <xsl:with-param name="instance" select="$instance"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeGroups">
    <xsl:param name="typeRef"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="nodeName"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="/@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:group[@name = $typeRef or @name = substring-after($typeRef, ':')]">
            <xsl:for-each select="/xs:group[@name = $typeRef or @name = substring-after($typeRef, ':')]/xs:*">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="instance" select="$instance"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeGroups">
              <xsl:with-param name="typeRef" select="$typeRef"/>
              <xsl:with-param name="tree" select="$tree"/>
              <xsl:with-param name="instance" select="$instance"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeAttributeGroups">
    <xsl:param name="typeRef"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:attributeGroup[@name = $typeRef or @name = substring-after($typeRef, ':')]">
            <xsl:for-each select="xs:attributeGroup[@name = $typeRef or @name = substring-after($typeRef, ':')]">
              <xsl:call-template name="attributeGroup">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeAttributeGroups">
              <xsl:with-param name="typeRef" select="$typeRef"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeSimpleTypes">
    <xsl:param name="typeRef"/>
    <xsl:param name="nodeName"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:simpleType[@name = $typeRef or @name = substring-after($typeRef, ':')]">
            <xsl:for-each select="/xs:simpleType[@name = $typeRef or @name = substring-after($typeRef, ':')]">
              <xsl:call-template name="simpleType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeSimpleTypes">
              <xsl:with-param name="typeRef" select="$typeRef"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!--
    *****************************************************************************
    sample an XML Schema element
    *****************************************************************************
  -->
  <xsl:template name="element">
    <!-- is is the root? -->
    <xsl:param name="root" select="false()"/>
    <!-- it may be the nth instance of the element -->
    <xsl:param name="instance" select="1"/>
    <!-- this will be true for mandatory elements, no matter what -->
    <xsl:param name="forceInstantiate" select="false()"/>
    <!-- hold the namespace for imported schemas -->
    <xsl:param name="includeNamespace"/>
    <!-- are we building a comment? -->
    <xsl:param name="commented" select="false()"/>
    <!-- the ancestor tree for this element (to prevent infinite recursion) -->
    <xsl:param name="tree"/>

    <xsl:choose>

      <xsl:when test="not($forceInstantiate) and $sampleOptionalElements = 'n' and @minOccurs = '0'">
        <!-- do nothing, if the element is not to appear in the sample -->
      </xsl:when>

      <!-- if the element is based on a reference -->
      <xsl:when test="@ref">

        <xsl:variable name="elementRef" select="@ref"/>

        <!-- look for it in the current schema, or in its included schemas -->
        <xsl:choose>
          <xsl:when test="ancestor::xs:schema[1]/xs:element[@name = $elementRef or @name = substring-after($elementRef, ':')]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:element[@name = $elementRef or @name = substring-after($elementRef, ':')]">
              <xsl:call-template name="element">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="root" select="$root"/>
                <xsl:with-param name="commented" select="$commented"/>
                <xsl:with-param name="tree" select="$tree"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <!-- reference not found: we'll have to look somewhere else -->
            <xsl:call-template name="includeElements">
              <xsl:with-param name="elementRef" select="$elementRef"/>
              <xsl:with-param name="commented" select="$commented"/>
              <xsl:with-param name="tree" select="$tree"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:when>

      <xsl:otherwise>

        <!-- we have the element name and definition: it may be sampled -->

        <!-- create an identifier for this element to add to the tree, for verification and to pass to its descendants -->
        <xsl:variable name="nodeId">
          <xsl:choose>
            <xsl:when test="$includeNamespace and $includeNamespace != ''">
              <xsl:value-of select="concat('&#xa;', @name, '&#x9;', $includeNamespace, '&#xa;')"/>
            </xsl:when>
            <xsl:when test="string-length($namespace) &gt; 0">
              <xsl:value-of select="concat('&#xa;', @name, '&#x9;', $namespace, '&#xa;')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('&#xa;', @name, '&#x9;', '&#xa;')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- sample it only if the identifier is not already present in the element's ancestor tree -->
        <xsl:if test="not(contains($tree, $nodeId))">

          <!-- use annotations to put some information on the sample document -->
          <xsl:if test="xs:annotation/xs:documentation and $instance = 1 and not($commented) and $sampleComments = 'y'">
            <xsl:comment><xsl:value-of select="xs:annotation/xs:documentation"/></xsl:comment>
          </xsl:if>

          <!--
                this level just creates the element in the result tree
                an important thing to consider is to which namespace the element belongs
                if an included namespace, the main schema's, or no namespace at all (if it wasn't declared as a targetNamespace)
                either way, the actual contents of the element are arranged by the elementContents template
          -->
          <xsl:choose>
            <xsl:when test="$includeNamespace and $includeNamespace != ''">
              <xsl:element name="{@name}" namespace="{$includeNamespace}">
                <xsl:call-template name="elementContents">
                  <xsl:with-param name="commented" select="$commented"/>
                  <xsl:with-param name="tree" select="concat($tree, $nodeId)"/>
                  <xsl:with-param name="instance" select="$instance"/>
                </xsl:call-template>
              </xsl:element>
            </xsl:when>
            <xsl:when test="string-length($namespace) &gt; 0">
              <xsl:element name="{@name}" namespace="{$namespace}">
                <!-- special case: -->
                <xsl:if test="$root">
                  <xsl:copy-of select="/*/namespace::*[. != $namespace and . != 'http://www.w3.org/2001/XMLSchema']"/>
                </xsl:if>
                <xsl:call-template name="elementContents">
                  <xsl:with-param name="commented" select="$commented"/>
                  <xsl:with-param name="tree" select="concat($tree, $nodeId)"/>
                  <xsl:with-param name="instance" select="$instance"/>
                </xsl:call-template>
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:element name="{@name}">
                <xsl:call-template name="elementContents">
                  <xsl:with-param name="commented" select="$commented"/>
                  <xsl:with-param name="tree" select="concat($tree, $nodeId)"/>
                  <xsl:with-param name="instance" select="$instance"/>
                </xsl:call-template>
              </xsl:element>
            </xsl:otherwise>
          </xsl:choose>

        </xsl:if>
      </xsl:otherwise>

    </xsl:choose>

    <!-- check for the necessity of creating new instances of this element -->
    <xsl:choose>

      <!-- but never reinstantiate inside comments -->
      <xsl:when test="$commented">
        <!-- do nothing -->
      </xsl:when>

      <!-- reinstantiate until minOccurs is reached -->
      <xsl:when test="@minOccurs &gt; 0 and $instance &lt; @minOccurs">
        <xsl:comment> mandatory instance # <xsl:value-of select="1 + $instance"/> </xsl:comment>
        <xsl:call-template name="element">
          <xsl:with-param name="instance" select="1 + $instance"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="tree" select="$tree"/>
        </xsl:call-template>
      </xsl:when>

      <!-- reinstantiate for unbounded cardinality, and reistantiation maximum parameter is not reached -->
      <xsl:when test="(@maxOccurs = 'unbounded' or $instance &lt; @maxOccurs) and $instance &lt; $sampleUnbounded">
        <xsl:comment> optional instance # <xsl:value-of select="1 + $instance"/></xsl:comment>
        <xsl:call-template name="element">
          <xsl:with-param name="instance" select="1 + $instance"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="tree" select="$tree"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <!--
      Sample the contents of an element (either of simple, complex, or mixed nature)
  -->
  <xsl:template name="elementContents">
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="elementName" select="@name"/>
    
    <xsl:choose>

      <!-- fixed or default values have higher priority: if present, they are used to create the sample value -->
      <xsl:when test="@fixed or @default">
        <xsl:value-of select="@fixed | @default"/>
      </xsl:when>

      <!-- if of XSD type, create an appropriate sample value -->
      <xsl:when test="starts-with(@type, $qxs)">
        <xsl:call-template name="types">
          <xsl:with-param name="nodeName" select="$elementName"/>
        </xsl:call-template>
      </xsl:when>

      <!-- if typed -->
      <xsl:when test="@type">

        <!-- consider the possibility of XSD having a different prefix in an imported schema
              so get a copy with the global xs prefix -->
        <xsl:variable name="qtype">
          <xsl:call-template name="getLocalXS"/>
        </xsl:variable>

        <xsl:variable name="elementType" select="@type"/>

        <xsl:choose>

          <!-- make a second try for basic XSD types (if the XML Schema namespace changed prefix) -->
          <xsl:when test="starts-with($qtype, $qxs)">
            <xsl:call-template name="types">
              <xsl:with-param name="xstype" select="$qtype"/>
              <xsl:with-param name="nodeName" select="$elementName"/>
            </xsl:call-template>
          </xsl:when>

          <!-- if the type is a reference to a complex type defined in the current schema, use it to build the element -->
          <xsl:when test="ancestor::xs:schema[1]/xs:complexType[@name = $elementType or @name = substring-after($elementType, ':')]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:complexType[@name = $elementType or @name = substring-after($elementType, ':')]">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="commented" select="$commented"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="instance" select="$instance"/>
                <xsl:with-param name="nodeName" select="$elementName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>

          <!-- if the type is a reference to a simple type defined in the current schema, use it to build the element -->
          <xsl:when test="ancestor::xs:schema[1]/xs:simpleType[@name = $elementType or @name = substring-after($elementType, ':')]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:simpleType[@name = $elementType or @name = substring-after($elementType, ':')]">
              <xsl:call-template name="simpleType">
                <xsl:with-param name="nodeName" select="$elementName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>

          <xsl:otherwise>
            <!-- the reference was not found in the current schema:
                  look for it somewhere else, either as complex or simple types -->
            <xsl:call-template name="includeComplexTypes">
              <xsl:with-param name="typeRef" select="$elementType"/>
              <xsl:with-param name="commented" select="$commented"/>
              <xsl:with-param name="tree" select="$tree"/>
              <xsl:with-param name="instance" select="$instance"/>
              <xsl:with-param name="nodeName" select="$elementName"/>
            </xsl:call-template>
            <xsl:call-template name="includeSimpleTypes">
              <xsl:with-param name="typeRef" select="$elementType"/>
              <xsl:with-param name="commented" select="$commented"/>
              <xsl:with-param name="nodeName" select="$elementName"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>

        <!-- the definition for the element is inline, so it's either of complex or simple type
              (only one of these will be present in the schema) -->
        <xsl:for-each select="xs:complexType">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="instance" select="$instance"/>
            <xsl:with-param name="nodeName" select="$elementName"/>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="xs:simpleType">
          <xsl:call-template name="simpleType">
            <xsl:with-param name="nodeName" select="$elementName"/>
          </xsl:call-template>
          
        </xsl:for-each>

      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>

  <!--
    *****************************************************************************
    sample an XML Schema attribute
    *****************************************************************************
  -->
  <xsl:template name="attribute">
    <xsl:param name="includeNamespace"/>

    <!-- optional attributes aren't sampled unless the stylesheet is parametrized otherwise -->
    <xsl:if test="($sampleOptionalAttributes = 'y' or @use = 'required') and not(@use = 'prohibited')">

      <xsl:choose>

        <!-- if there is a reference to an attribute definition, use it -->
        <xsl:when test="@ref">

          <xsl:variable name="attribRef" select="@ref"/>

          <!-- the reference is at the current schema, or at some other included schema -->
          <xsl:choose>
            <xsl:when test="ancestor::xs:schema[1]/xs:attribute[@name = $attribRef or @name = substring-after($attribRef, ':')]">
              <xsl:for-each select="ancestor::xs:schema[1]/xs:attribute[@name = $attribRef or @name = substring-after($attribRef, ':')]">
                <xsl:call-template name="attribute">
                  <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                </xsl:call-template>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="includeAttributes">
                <xsl:with-param name="attribRef" select="$attribRef"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>

        <!-- treat xml:* attributes as a special case: create the attribute with default values -->
        <xsl:when test="$includeNamespace = 'http://www.w3.org/XML/1998/namespace'">
          <xsl:attribute name="{concat('xml:', @name)}">
            <xsl:choose>
              <xsl:when test="@name = 'space'">
                <xsl:value-of select="$sampleDefaultXMLSpace"/>
              </xsl:when>
              <xsl:when test="@name = 'lang'">
                <xsl:value-of select="$sampleDefaultXMLLang"/>
              </xsl:when>
              <xsl:when test="@name = 'base'">
                <xsl:value-of select="$sampleDefaultXMLBase"/>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
        </xsl:when>

        <!-- when the attribute is namespaced, check for the necessity of qaulify its name -->
        <xsl:when test="$includeNamespace">

          <!-- get the prefix for the namespace, as declared in the main schema -->
          <xsl:variable name="prefix">
            <xsl:call-template name="getPrefix">
              <xsl:with-param name="namespace" select="$includeNamespace"/>
            </xsl:call-template>
          </xsl:variable>

          <!-- if the prefix is declared, it can be safely prepended to the attribute name -->
          <xsl:choose>
            <xsl:when test="$prefix != ''">
              <xsl:attribute name="{concat($prefix, ':', @name)}">
                <xsl:call-template name="attributeContents"/>
              </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <!-- if not, then just link to the attribute (an autogenerated prefix will be provided by the DOM) -->
              <xsl:attribute name="{@name}" namespace="{$includeNamespace}">
                <xsl:call-template name="attributeContents"/>
              </xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>

        <xsl:otherwise>
          <!-- no namespaced attributes: just create it -->
          <xsl:attribute name="{@name}">
            <xsl:call-template name="attributeContents"/>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!--
      Sample the contents of an attribute
  -->
  <xsl:template name="attributeContents">

    <xsl:variable name="attributeName" select="@name"/>

    <xsl:choose>

      <!-- fixed or default values have higher priority: if present, they will be used as the attribute's value -->
      <xsl:when test="@fixed or @default">
        <xsl:value-of select="@fixed | @default"/>
      </xsl:when>

      <!-- if simply based in an XSD type, create the appropriate value -->
      <xsl:when test="starts-with(@type, $qxs)">
        <xsl:call-template name="types">
          <xsl:with-param name="nodeName" select="$attributeName"/>
        </xsl:call-template>
      </xsl:when>

      <!-- if typed -->
      <xsl:when test="@type">

        <!-- get a new version of the type, if it is referring a type in the XML Schema namespace -->
        <xsl:variable name="qtype">
          <xsl:call-template name="getLocalXS"/>
        </xsl:variable>

        <xsl:variable name="elementType" select="@type"/>

        <xsl:choose>

          <!-- make a new attempt: is it a XSD type? -->
          <xsl:when test="starts-with($qtype, $qxs)">
            <xsl:call-template name="types">
              <xsl:with-param name="xstype" select="$qtype"/>
              <xsl:with-param name="nodeName" select="$attributeName"/>
            </xsl:call-template>
          </xsl:when>

          <!-- look for the type definition at the current schema -->
          <xsl:when test="ancestor::xs:schema[1]/xs:simpleType[@name = $elementType or @name = substring-after($elementType, ':')]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:simpleType[@name = $elementType or @name = substring-after($elementType, ':')]">
              <xsl:call-template name="simpleType">
                <xsl:with-param name="nodeName" select="$attributeName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <!-- or at somewhere else -->
            <xsl:call-template name="includeSimpleTypes">
              <xsl:with-param name="typeRef" select="$elementType"/>
              <xsl:with-param name="nodeName" select="$attributeName"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:when>

      <!-- type is inline? create the value based in the definition -->
      <xsl:when test="xs:simpleType">
        <xsl:for-each select="xs:simpleType">
          <xsl:call-template name="simpleType">
            <xsl:with-param name="nodeName" select="$attributeName"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

    </xsl:choose>

    <!-- for all other cases, the attribute value will be left blank -->

  </xsl:template>

  <!--
      Sample a group of attributes under an attributeGroup XML Schema element
  -->
  <xsl:template name="attributeGroup">
    <xsl:param name="includeNamespace"/>
    <xsl:param name="groupRef"/>

    <xsl:choose>

      <!-- if the definition of the group is inline, check for attribute groups and attributes under it -->
      <xsl:when test="not($groupRef)">
        <xsl:for-each select="xs:attributeGroup">
          <xsl:call-template name="attributeGroup">
            <xsl:with-param name="groupRef" select="@ref"/>
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="xs:attribute">
          <xsl:call-template name="attribute">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

      <!-- if there is a reference to the definition, look for it in the current schema -->
      <xsl:when test="ancestor::xs:schema[1]/xs:attributeGroup[@name = $groupRef or @name = substring-after($groupRef, ':')]">
        <xsl:for-each select="ancestor::xs:schema[1]/xs:attributeGroup[@name = $groupRef or @name = substring-after($groupRef, ':')]">
          <xsl:call-template name="attributeGroup">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

      <xsl:otherwise>
        <!-- reference not found? look for it somewhere else -->
        <xsl:call-template name="includeAttributeGroups">
          <xsl:with-param name="typeRef" select="@ref"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!--
      Sample a complex typed element, under an XML Schema complexType element, or one of its descendants

      This template is called to process a complexType, or to process one direct descendant of complexType.
      The actual sample generator is the template complexTypeComposition, that this calls
  -->
  <xsl:template name="complexType">
    <!-- same parameters as in the "element" sampler -->
    <xsl:param name="includeNamespace"/>
    <xsl:param name="root" select="false()"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="nodeName"/>

    <!-- deal with attributes, frontmost, either as groups or single -->
    <xsl:for-each select="xs:attributeGroup">
      <xsl:call-template name="attributeGroup">
        <xsl:with-param name="groupRef" select="@ref"/>
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:for-each select="xs:attribute">
      <xsl:call-template name="attribute">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:choose>

      <!-- for extensions and restrictions, ignore -->
      <xsl:when test="local-name() = 'extension' or local-name() = 'restriction'">
        <!-- do nothing, just deal with attributes, the extended items will come back later on -->
      </xsl:when>

      <!-- if (other) complexType descendant, process its composition -->
      <xsl:when test="local-name() != 'complexType'">
        <xsl:call-template name="complexTypeComposition">
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="instance" select="$instance"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>

        <!-- it's a complexType: process the composition of all of its descendants, except for attributes -->
        <xsl:for-each select="xs:*[not(starts-with(local-name(), 'attribute'))]">
          <xsl:call-template name="complexTypeComposition">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="instance" select="$instance"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!--
      Controller for a complex type composition: directs the processing to adequate templates
  -->
  <xsl:template name="complexTypeComposition">
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="nodeName"/>

    <xsl:choose>

      <!-- for sequences, iterate through all of its components -->
      <xsl:when test="local-name() = 'sequence'">
        <xsl:call-template name="iteratorComplexTypes">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="last" select="number($sampleUnbounded)"/>
        </xsl:call-template>
      </xsl:when>

      <!-- for all, forcibly instantiate all of its elements -->
      <xsl:when test="local-name() = 'all'">
        <xsl:for-each select="xs:element">
          <xsl:call-template name="element">
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="forceInstantiate" select="true()"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

      <!-- for choice, just one of its elements (but it may be repeated) -->
      <xsl:when test="local-name() = 'choice'">
        <xsl:call-template name="iteratorChoices">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="current" select="$instance"/>
          <xsl:with-param name="last" select="number($sampleUnbounded)"/>
        </xsl:call-template>
      </xsl:when>

      <!-- for groups, iterate through all of its components (one of the previous structures) -->
      <xsl:when test="local-name() = 'group'">
        <xsl:call-template name="iteratorGroups">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="last" select="number($sampleUnbounded)"/>
        </xsl:call-template>
      </xsl:when>

      <!-- a simpleContent (text only) -->
      <xsl:when test="local-name() = 'simpleContent'">
        <xsl:call-template name="complexTypeSimpleContent">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
        </xsl:call-template>
      </xsl:when>

      <!-- a complexContent (text and elements) -->
      <xsl:when test="local-name() = 'complexContent'">
        <xsl:call-template name="complexTypeComplexContent">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="last" select="number($sampleUnbounded)"/>
        </xsl:call-template>
      </xsl:when>

      <!-- an element (as descendant of other complexType structures) -->
      <xsl:when test="local-name() = 'element'">
        <xsl:call-template name="element">
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
        </xsl:call-template>
      </xsl:when>

    </xsl:choose>

  </xsl:template>

  <!-- sample an XML Schema choice element -->
  <xsl:template name="complexTypeChoice">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="instance" select="1"/>
    
    <!--
          for choices, there are 3 possible strategies:
            sequence - the nth instance samples the nth element (the first samples the first, the second samples the second...)
            first - samples the first element
            comment - samples the first, comment the rest
      -->
    <xsl:choose>
      <!-- strategy: sequence -->
      <xsl:when test="$sampleChoiceStrategy = 'sequence'">
        <xsl:for-each select="xs:*[position() = $instance or ($instance &gt; last() and position() = 1)]">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="instance" select="$instance"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <!-- strategies: first and comment -->
        <xsl:for-each select="xs:*[1]">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:for-each>
        <!-- strategy: comment (the first was just sampled) -->
        <xsl:if test="$sampleChoiceStrategy = 'comment'">
          <xsl:variable name="subtree">
            <xsl:for-each select="xs:*[position() &gt; 1]">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="commented" select="true()"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:variable>
          <!-- start comment, if it was not already in course -->
          <xsl:if test="not($commented)"><xsl:text disable-output-escaping="yes">&lt;!-- </xsl:text></xsl:if>
          <xsl:copy-of select="$subtree"/>
          <!-- end comment, if it was not already in course -->
          <xsl:if test="not($commented)"><xsl:text disable-output-escaping="yes">--&gt;</xsl:text></xsl:if>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- sample an XML Schema simpleContent element -->
  <xsl:template name="complexTypeSimpleContent">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>

    <!-- process attributes -->
    <xsl:for-each select="xs:extension | xs:restriction">
      <xsl:call-template name="complexType">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:for-each>

    <!-- hold a reference to the content, and to its identifier or type -->
    <xsl:variable name="definition" select="xs:extension | xs:restriction"/>
    <xsl:variable name="typeRef" select="$definition/@base"/>

    <!-- for the current schema, get the local prefix for the XML Schema namespace -->
    <xsl:variable name="qtype">
      <xsl:call-template name="getLocalXS">
        <xsl:with-param name="dtype" select="$typeRef"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- try to produce a sample, if the simple types can be found or derived -->
    <xsl:choose>

      <!-- for direct extensions, sample the value -->
      <xsl:when test="starts-with(xs:extension/@base, $qxs)">
        <xsl:call-template name="types">
          <xsl:with-param name="xstype" select="xs:extension/@base"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- for direct restrictions, sample the restricted value -->
      <xsl:when test="starts-with(xs:restriction/@base, $qxs)">
        <xsl:call-template name="restrictedTypes">
          <xsl:with-param name="xstype" select="xs:restriction/@base"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <!-- do the same, when the type is localized to the current schema -->
      <xsl:when test="starts-with($qtype, $qxs)">
        <xsl:choose>
          <xsl:when test="xs:extension">
            <xsl:call-template name="types">
              <xsl:with-param name="xstype" select="$qtype"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="restrictedTypes">
              <xsl:with-param name="xstype" select="$qtype"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- the reference to the extension must be located either at the current schema, or at some included one -->
      <xsl:when test="xs:extension">
        <xsl:choose>
          <xsl:when test="ancestor::xs:schema[1]/xs:complexType[@name = $typeRef or @name = substring-after($typeRef, ':')]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:complexType[@name = $typeRef or @name = substring-after($typeRef, ':')]">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="commented" select="$commented"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeSimpleTypes">
              <xsl:with-param name="typeRef" select="$typeRef"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <!-- for a restriction, locate the reference to XML Schema types and, if found, apply the restriction to sample a value -->
      <xsl:when test="xs:restriction">
        <xsl:variable name="rtype">
          <xsl:call-template name="getXSType">
            <xsl:with-param name="dbase" select="$typeRef"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="starts-with($rtype, $qxs)">
          <xsl:call-template name="restrictedTypes">
            <xsl:with-param name="xstype" select="$rtype"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      
    </xsl:choose>

    <!-- go deeper in the definition, by sampling whatever has yet to be sampled -->
    <xsl:for-each select="$definition/xs:*[not(starts-with(local-name(), 'attribute'))]">
      <xsl:call-template name="complexType">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>                
      </xsl:call-template>
    </xsl:for-each>
    
  </xsl:template>

  <!-- sample an XML Schema complexContent element -->
  <xsl:template name="complexTypeComplexContent">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="instance" select="1"/>
  
    <xsl:for-each select="xs:extension | xs:restriction">
      <xsl:call-template name="complexType">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:for-each>
    
    <xsl:variable name="definition" select="xs:extension | xs:restriction"/>
    
    <xsl:choose>
      
      <xsl:when test="starts-with(xs:extension/@base, $qxs)">
        <xsl:call-template name="types">
          <xsl:with-param name="xstype" select="xs:extension/@base"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:when test="starts-with(xs:restriction/@base, $qxs)">
        <xsl:call-template name="restrictedTypes">
          <xsl:with-param name="xstype" select="xs:restriction/@base"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>
      
      <xsl:otherwise>
        
        <xsl:if test="xs:extension">
          
          <xsl:variable name="typeRef" select="$definition/@base"/>
          
          <xsl:choose>
            <xsl:when test="ancestor::xs:schema[1]/xs:complexType[@name = $typeRef or @name = substring-after($typeRef, ':')]">
              <xsl:for-each select="ancestor::xs:schema[1]/xs:complexType[@name = $typeRef or @name = substring-after($typeRef, ':')]">
                <xsl:call-template name="complexType">
                  <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                  <xsl:with-param name="commented" select="$commented"/>
                  <xsl:with-param name="tree" select="$tree"/>
                  <xsl:with-param name="nodeName" select="$nodeName"/>
                </xsl:call-template>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="includeComplexTypes">
                <xsl:with-param name="typeRef" select="$typeRef"/>
                <xsl:with-param name="commented" select="$commented"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
        
        <xsl:for-each select="$definition/xs:*">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>                
          </xsl:call-template>
        </xsl:for-each>
        
      </xsl:otherwise>
      
    </xsl:choose>

    <xsl:if test="@mixed = 'true'">
      <xsl:value-of select="$sampleDefaultTextData"/>
    </xsl:if>

  </xsl:template>

  <xsl:template name="getXSType">
    <xsl:param name="dbase" select="@base"/>

    <xsl:variable name="qtype">
      <xsl:call-template name="getLocalXS">
        <xsl:with-param name="dtype" select="$dbase"/>
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="starts-with($dbase, $qxs)">
        <xsl:value-of select="$dbase"/>
      </xsl:when>
      
      <xsl:when test="starts-with($qtype, $qxs)">
        <xsl:value-of select="$qtype"/>
      </xsl:when>

      <xsl:when test="ancestor::xs:schema[1]/xs:complexType[@name = $dbase]/xs:simpleContent/xs:extension">
        <xsl:call-template name="getXSType">
          <xsl:with-param name="dbase" select="ancestor::xs:schema[1]/xs:complexType[@name = $dbase]/xs:simpleContent/xs:extension/@base"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="ancestor::xs:schema[1]/xs:complexType[@name = $dbase]/xs:simpleContent/xs:restriction">
        <xsl:call-template name="getXSType">
          <xsl:with-param name="dbase" select="ancestor::xs:schema[1]/xs:complexType[@name = $dbase]/xs:simpleContent/xs:restriction/@base"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
          <xsl:variable name="impNamespace" select="@namespace"/>
          <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
            <xsl:call-template name="getXSType">
              <xsl:with-param name="dbase" select="$dbase"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="iteratorGroups">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="current" select="1"/>
    <xsl:param name="last" select="1"/>
    
    <xsl:variable name="ref" select="@ref"/>

    <xsl:choose>
      <xsl:when test="ancestor::xs:schema[1]/xs:group[@name = $ref or @name = substring($ref, ':')]">
        <xsl:for-each select="ancestor::xs:schema[1]/xs:group[@name = $ref or @name = substring($ref, ':')]/xs:*">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="instance" select="$current"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="includeGroups">
          <xsl:with-param name="typeRef" select="$ref"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="instance" select="$current"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="$current &lt; $last and (@maxOccurs = 'unbounded' or $current &lt; @maxOccurs)">
      <xsl:call-template name="iteratorGroups">
        <xsl:with-param name="last" select="$last"/>
        <xsl:with-param name="current" select="$current + 1"/>
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="iteratorComplexTypes">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="current" select="1"/>
    <xsl:param name="last" select="1"/>

    <xsl:for-each select="xs:*">
      <xsl:call-template name="complexType">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="instance" select="$current"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:if test="$current &lt; $last and (@maxOccurs = 'unbounded' or $current &lt; @maxOccurs)">
      <xsl:call-template name="iteratorComplexTypes">
        <xsl:with-param name="last" select="$last"/>
        <xsl:with-param name="current" select="$current + 1"/>
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="iteratorChoices">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="current" select="1"/>
    <xsl:param name="last" select="1"/>

    <xsl:call-template name="complexTypeChoice">
      <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
      <xsl:with-param name="commented" select="$commented"/>
      <xsl:with-param name="tree" select="$tree"/>
      <xsl:with-param name="instance" select="$current"/>
      <xsl:with-param name="nodeName" select="$nodeName"/>
    </xsl:call-template>
    
    <xsl:if test="$current &lt; $last and (@maxOccurs = 'unbounded' or $current &lt; @maxOccurs)">
      <xsl:call-template name="iteratorChoices">
        <xsl:with-param name="last" select="$last"/>
        <xsl:with-param name="current" select="$current + 1"/>
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:if>
    
  </xsl:template>

  <xsl:template name="simpleType">
    <xsl:param name="nodeName" select="@name"/>

    <xsl:choose>

      <xsl:when test="xs:restriction">
        <xsl:call-template name="restrictedTypes">
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <!-- get the actual element/attribute contents, based on its type -->
  <xsl:template name="types">
    <xsl:param name="xstype" select="@type"/>
    <xsl:param name="nodeName" select="@name"/>

    <xsl:choose>
      <xsl:when test="contains($xsGroupString, $xstype)">
        <xsl:call-template name="string">
          <xsl:with-param name="base" select="$xstype"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupNumeric, $xstype)">
        <xsl:call-template name="number">
          <xsl:with-param name="base" select="$xstype"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupDate, $xstype)">
        <xsl:call-template name="date">
          <xsl:with-param name="base" select="$xstype"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupBinary, $xstype)">
        <xsl:call-template name="binary">
          <xsl:with-param name="base" select="$xstype"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$xstype = $xsBoolean">
        <xsl:call-template name="boolean"/>
      </xsl:when>
      <xsl:when test="$xstype = $xsAnyURI">
        <xsl:call-template name="URI"/>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="URI">
    <xsl:choose>
      <xsl:when test="$sampleURIasHTTP = 'y'">
        <xsl:value-of select="$sampleDefaultHTTP"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultURI"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="boolean">
    <xsl:choose>
      <xsl:when test="$sampleBooleanAsNumber = 'y'">1</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultBoolean"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="binary">
    <xsl:param name="base"/>
    <xsl:choose>
      <xsl:when test="$base = $xsBase64Binary">
        <xsl:value-of select="$sampleDefaultBase64Binary"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultHexBinary"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="date">
    <xsl:param name="base"/>
    <xsl:choose>
      <xsl:when test="$base = $xsDateTime">
        <xsl:value-of select="$sampleDefaultDate"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring($sampleDefaultDate, 1, 10)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="number">
    <xsl:param name="base"/>
    <xsl:choose>
      <xsl:when test="$base = $xsNegativeInteger">-1</xsl:when>
      <xsl:when test="$base = $xsPositiveInteger">1</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultNumber"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="string">
    <xsl:param name="base"/>
    <xsl:param name="nodeName"/>

    <xsl:choose>
      <xsl:when test="$base = $xsID">
        <xsl:value-of select="generate-id()"/>
      </xsl:when>
      <xsl:when test="$base = $xsLanguage">
        <xsl:value-of select="$sampleDefaultXMLLang"/>
      </xsl:when>
      <xsl:when test="$sampleStringSource = 'name'">
        <xsl:value-of select="$nodeName"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultString"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- get the actual element/attribute contents, based on its type and some restrition that applies -->
  <xsl:template name="restrictedTypes">
    <xsl:param name="nodeName" select="@name"/>
    <xsl:param name="xstype" select="xs:restriction/@base"/>

    <xsl:variable name="definition" select="xs:restriction"/>
    <xsl:variable name="base" select="$xstype"/>

    <xsl:choose>
      <xsl:when test="contains($xsGroupString, $base)">
        <xsl:call-template name="restrictedString">
          <xsl:with-param name="definition" select="$definition"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupNumeric, $base)">
        <xsl:call-template name="restrictedNumber">
          <xsl:with-param name="definition" select="$definition"/>
          <xsl:with-param name="base" select="$base"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupDate, $base)">
        <xsl:call-template name="restrictedDate">
          <xsl:with-param name="definition" select="$definition"/>
          <xsl:with-param name="base" select="$base"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@type = $xsBoolean">
        <xsl:call-template name="boolean"/>
      </xsl:when>
      <xsl:when test="@type = $xsAnyURI">
        <xsl:call-template name="URI"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="restrictedDate">
    <xsl:param name="definition"/>
    <xsl:param name="base"/>

    <xsl:choose>
      <xsl:when test="$definition/xs:pattern and $samplePattern = 'y'">
        <xsl:value-of select="$definition/xs:pattern/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:enumeration">
        <xsl:value-of select="$definition/xs:enumeration[1]/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:minInclusive">
        <xsl:value-of select="$definition/xs:minInclusive/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:maxInclusive">
        <xsl:value-of select="$definition/xs:maxInclusive/@value"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="date">
          <xsl:with-param name="base" select="$base"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="restrictedNumber">
    <xsl:param name="definition"/>
    <xsl:param name="base"/>

    <xsl:variable name="numericValue">
      <xsl:choose>
        <xsl:when test="($definition/xs:minInclusive | $definition/xs:minExclusive) and ($definition/xs:maxInclusive | $definition/xs:maxExclusive)">
          <xsl:value-of
            select="($definition/xs:minInclusive/@value | $definition/xs:minExclusive/@value) + floor((($definition/xs:maxInclusive/@value | $definition/xs:maxExclusive/@value) - ($definition/xs:minInclusive/@value | $definition/xs:minExclusive/@value)) div 2)"
          />
        </xsl:when>
        <xsl:when test="$definition/xs:minInclusive">
          <xsl:value-of select="$definition/xs:minInclusive/@value"/>
        </xsl:when>
        <xsl:when test="$definition/xs:maxInclusive">
          <xsl:value-of select="$definition/xs:maxInclusive/@value"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="number">
            <xsl:with-param name="base" select="$base"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$definition/xs:pattern and $samplePattern = 'y'">
        <xsl:value-of select="$definition/xs:pattern/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:enumeration">
        <xsl:value-of select="$definition/xs:enumeration[1]/@value"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="floor($numericValue)"/>
        <xsl:if test="$base = $xsDecimal and (not($definition/xs:fractionDigits) or $definition/xs:fractionDigits/@value &gt; 0)">.</xsl:if>
        <xsl:choose>
          <xsl:when test="$definition/xs:fractionDigits">
            <xsl:value-of select="substring('000000000000000000', 1, $definition/xs:fractionDigits/@value)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$base = $xsDecimal">
              <xsl:text>00</xsl:text>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="restrictedString">
    <xsl:param name="definition"/>
    <xsl:param name="base"/>
    <xsl:param name="nodeName"/>

    <xsl:choose>
      <xsl:when test="$base = $xsID">
        <xsl:value-of select="generate-id()"/>
      </xsl:when>
      <xsl:when test="$definition/xs:enumeration">
        <xsl:value-of select="$definition/xs:enumeration[1]/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:pattern and $samplePattern = 'y'">
        <xsl:value-of select="$definition/xs:pattern/@value"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="string">
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="$sampleStringLength = 'y' and $definition and ($definition/xs:minLength or $definition/xs:maxLength)">
      <xsl:text>[</xsl:text>
      <xsl:value-of select="$definition/xs:minLength/@value"/>
      <xsl:text>..</xsl:text>
      <xsl:value-of select="$definition/xs:maxLength/@value"/>
      <xsl:text>]</xsl:text>
    </xsl:if>

  </xsl:template>

</xsl:stylesheet>