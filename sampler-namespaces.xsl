<?xml version="1.0" encoding="UTF-8"?>
<!--
  Sampler Namespaces

  To be used as a first stpe of the XML sampler process.

  Create a new stylesheet, based on the general sampler, to perform the actual sampling.
  Copy into the new sampler stylesheet the namespaces declared at the root of the document that contains an XML Schema.
  Attributes that belong to these namespaces will be sampled using the associated prefixes.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <xsl:variable name="xsl" select="document('sampler-xml-generator.xsl')"/>

    <!-- create a new stylesheet -->
    <xsl:element name="xsl:stylesheet">

      <!-- fetch the original namespaces -->
      <xsl:copy-of select="$xsl/*/namespace::*"/>

      <!-- and those declared (with their prefixes) at the root of the document hosting an XML Schema -->
      <xsl:copy-of select="/*/namespace::*[. != 'http://www.w3.org/2001/XMLSchema' and . != 'http://www.w3.org/1999/XSL/Transform']"/>

      <xsl:attribute name="version">1.0</xsl:attribute>

      <!-- now, copy all of the base stylesheet into the new one as the result tree -->
      <xsl:for-each select="$xsl/*">
        <xsl:apply-templates select="@* | node()" xml:space="preserve"/>
      </xsl:for-each>
    </xsl:element>

  </xsl:template>

  <xsl:template match="@* | node()">
    <xsl:copy><xsl:apply-templates select="@* | node()" xml:space="preserve"/></xsl:copy>
  </xsl:template>

</xsl:stylesheet>