<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
 version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://www.w3.org/1999/xhtml"
 >
 <!-- this is useful for xml files like partial html code -->
<xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />

<xsl:template match="/">
    <xsl:apply-templates select="output"/>
</xsl:template>

<xsl:template match="output">
  <xsl:apply-templates select="entries"  mode="table" />
</xsl:template>

<xsl:template match="entries" mode="table" >
Feature<xsl:text>&#09;</xsl:text>Molecule<xsl:text>&#09;</xsl:text>Start<xsl:text>&#09;</xsl:text>Stop<xsl:text>&#09;</xsl:text> 
	<xsl:text>&#x0A;</xsl:text>
  <xsl:apply-templates select="entry" mode="table"/>
	<xsl:text>&#x0A;</xsl:text>

</xsl:template>

<xsl:template match="entry" mode="table">
    <xsl:value-of select="feature"/>
	<xsl:text>&#09;</xsl:text>
    <xsl:value-of select="mol"/>   
	<xsl:text>&#09;</xsl:text>
    <xsl:value-of select="start"/>  
	<xsl:text>&#09;</xsl:text>
    <xsl:value-of select="stop"/>    
	<xsl:text>&#09;</xsl:text>
    <xsl:value-of select="direction"/>    
	<xsl:text>&#09;</xsl:text>
    <xsl:value-of select="sequenceEntry"/>    
	<xsl:text>&#09;</xsl:text>
    <xsl:value-of select="sequence"/>    
<xsl:text>&#x0A;</xsl:text>
</xsl:template>


</xsl:stylesheet>
