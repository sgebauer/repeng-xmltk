<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/dblp/*">
  <xsl:copy>
    <xsl:apply-templates select="title"/>
    <xsl:apply-templates select="author"/>
    <xsl:apply-templates select="year"/>
    <xsl:apply-templates select="*[not(self::title) and not(self::author) and not(self::year)]"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="@* | node()">
  <xsl:copy>
    <xsl:apply-templates select="@* | node()"/>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
