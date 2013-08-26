<?xml version="1.0" encoding="UTF-8"?>
<!--
	Copyright (C) 2010 Ethan Gruber
	EADitor: http://code.google.com/p/eaditor/
	Apache License 2.0: http://code.google.com/p/eaditor/
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>
	
	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request/parameters</include>
			</config>
		</p:input>
		<p:output name="data" id="params"/>
	</p:processor>
	
	<p:processor name="oxf:pipeline">
		<p:input name="config" href="config.xpl"/>		
		<p:output name="data" id="config"/>
	</p:processor>

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="params" href="#params"/>
		<p:input name="data" href="#config"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">				
				<!-- url params -->
				<xsl:param name="q" select="doc('input:params')/request/parameters/parameter[name='q']/value"/>	
				<xsl:param name="century" select="doc('input:params')/request/parameters/parameter[name='century']/value"/>
				<xsl:param name="pipeline" select="doc('input:params')/request/parameters/parameter[name='pipeline']/value"/>
				
				<!-- config variables -->
				<xsl:variable name="solr-url" select="concat(/config/solr_published, 'select/')"/>
								
				<xsl:variable name="service">
					<xsl:choose>
						<xsl:when test="$pipeline='results'">
							<xsl:value-of select="concat($solr-url, '?q=', encode-for-uri($q), '&amp;start=0&amp;rows=0&amp;facet.field=decade_num&amp;facet.sort=index&amp;fq=century_num:', $century)"/>
						</xsl:when>
						<xsl:when test="$pipeline='maps'">
							<xsl:value-of select="concat($solr-url, '?q=', encode-for-uri(concat($q, ' AND georef:*')), '&amp;start=0&amp;rows=0&amp;facet.field=decade_num&amp;facet.sort=index&amp;fq=century_num:', $century)"/>
						</xsl:when>			
					</xsl:choose>					
				</xsl:variable>
				
				<xsl:template match="/">
					<xsl:copy-of select="document($service)/response"/>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" ref="data"/>
	</p:processor>


</p:config>
