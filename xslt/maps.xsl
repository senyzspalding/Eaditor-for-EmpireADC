<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:eaditor="http://code.google.com/p/eaditor/" exclude-result-prefixes="#all"
	version="2.0">
	<xsl:output method="xhtml" encoding="UTF-8" indent="yes"/>
	<xsl:include href="templates.xsl"/>
	<xsl:include href="functions.xsl"/>

	<xsl:variable name="exist-url" select="/exist-url"/>
	<xsl:variable name="config" as="node()*">
		<xsl:copy-of select="document(concat($exist-url, 'eaditor/config.xml'))"/>
	</xsl:variable>
	<xsl:variable name="flickr-api-key" select="$config/config/flickr_api_key"/>
	<xsl:variable name="solr-url" select="concat($config/config/solr_published, 'select/')"/>
	<xsl:variable name="facets">
		<xsl:for-each select="tokenize($config/config/theme/facets, ',')">
			<xsl:text>&amp;facet.field=</xsl:text>
			<xsl:value-of select="."/>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="ui-theme" select="$config/config/theme/jquery_ui_theme"/>
	<xsl:variable name="display_path">../</xsl:variable>
	<xsl:variable name="pipeline">maps</xsl:variable>

	<xsl:param name="q" select="doc('input:params')/request/parameters/parameter[name='q']/value"/>
	<xsl:param name="lang" select="doc('input:params')/request/parameters/parameter[name='lang']/value"/>
	<xsl:variable name="tokenized_q" select="tokenize($q, ' AND ')"/>

	<!-- initial solr_query -->
	<xsl:variable name="service">
		<xsl:value-of select="concat($solr-url, '?q=georef:*&amp;start=0&amp;rows=0&amp;facet.limit=1', $facets)"/>
	</xsl:variable>

	<xsl:variable name="response" as="node()*">
		<xsl:copy-of select="document($service)/response"/>
	</xsl:variable>

	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="$config/config/title"/>
					<xsl:text>: Maps</xsl:text>
				</title>
				<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/3.8.0/build/cssgrids/grids-min.css"/>
				<!-- EADitor styling -->
				<link rel="stylesheet" href="{$display_path}css/style.css"/>
				<link rel="stylesheet" href="{$display_path}css/themes/{$ui-theme}.css"/>

				<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js"/>
				<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.23/jquery-ui.min.js"/>

				<!-- menu -->
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.core.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.widget.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.position.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.button.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.menu.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.menubar.js"/>
				<script type="text/javascript" src="{$display_path}javascript/menu.js"/>

				<!-- map functions -->
				<xsl:if test="$response//result[@name='response']/@numFound &gt; 0">
					<!-- fancybox -->
					<link rel="stylesheet" href="{$display_path}css/jquery.fancybox-1.3.4.css"/>
					<script type="text/javascript" src="{$display_path}javascript/jquery.fancybox-1.3.4.min.js"/>

					<!-- multselect -->
					<link rel="stylesheet" href="{$display_path}css/jquery.multiselect.css"/>
					<script type="text/javascript" src="{$display_path}javascript/jquery.multiselect.min.js"/>
					<script type="text/javascript" src="{$display_path}javascript/jquery.multiselectfilter.js"/>
					<script type="text/javascript" src="{$display_path}javascript/jquery.livequery.js"/>

					<!-- maps -->
					<script type="text/javascript" src="http://www.openlayers.org/api/OpenLayers.js"/>
					<script type="text/javascript" src="http://maps.google.com/maps/api/js?v=3.2&amp;sensor=false"/>
					<script type="text/javascript" src="{$display_path}javascript/maps_functions.js"/>
					<script type="text/javascript" src="{$display_path}javascript/facet_functions.js"/>
				</xsl:if>
			</head>
			<body>
				<xsl:call-template name="header"/>
				<xsl:call-template name="content"/>
				<xsl:call-template name="footer"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="content">
		<div class="yui3-g">
			<div id="backgroundPopup"/>
			<div class="yui3-u-1">
				<div class="content">
					<h1>Maps</h1>
					<xsl:choose>
						<xsl:when test="$response//result[@name='response']/@numFound &gt; 0">
							<div style="display:table;width:100%">
								<ul id="filter_list" section="maps">
									<xsl:apply-templates select="$response//lst[@name='facet_fields']/lst[descendant::int]"/>
								</ul>
							</div>
							<div id="mapcontainer"/>
							<a name="results"/>
							<div id="results"/>
							<input id="facet_form_query" name="q" value="*:*" type="hidden"/>
							<xsl:if test="string($lang)">
								<input type="hidden" name="lang" value="{$lang}"/>
							</xsl:if>
							<span style="display:none" id="pipeline">
								<xsl:value-of select="$pipeline"/>
							</span>
							<select style="display:none" id="ajax-temp"/>
							<ul style="display:none" id="decades-temp"/>
						</xsl:when>
						<xsl:otherwise>
							<h2> No results found.</h2>
						</xsl:otherwise>
					</xsl:choose>
				</div>
			</div>
		</div>
	</xsl:template>

	<xsl:template match="lst">
		<li class="fl">
			<xsl:variable name="val" select="@name"/>
			<xsl:variable name="new_query">
				<xsl:for-each select="$tokenized_q[not(contains(., $val))]">
					<xsl:value-of select="."/>
					<xsl:if test="position() != last()">
						<xsl:text> AND </xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>

			<xsl:variable name="title">
				<xsl:value-of select="eaditor:normalize_fields(@name)"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="contains(@name, '_hier')">
					<xsl:variable name="title" select="eaditor:normalize_fields(@name)"/>

					<button class="ui-multiselect ui-widget ui-state-default ui-corner-all hierarchical-facet" type="button" title="{$title}" aria-haspopup="true" style="width: 200px;"
						id="{@name}_link" label="{$q}">
						<span class="ui-icon ui-icon-triangle-2-n-s"/>
						<span>
							<xsl:value-of select="$title"/>
						</span>
					</button>

					<div class="ui-multiselect-menu ui-widget ui-widget-content ui-corner-all hierarchical-div" id="{substring-before(@name, '_hier')}-container" style="width: 200px;">
						<div class="ui-widget-header ui-corner-all ui-multiselect-header ui-helper-clearfix ui-multiselect-hasfilter">
							<ul class="ui-helper-reset">
								<li class="ui-multiselect-close">
									<a class="ui-multiselect-close hier-close" href="#"> close<span class="ui-icon ui-icon-circle-close"/>
									</a>
								</li>
							</ul>
						</div>
						<ul class="{substring-before(@name, '_hier')}-multiselect-checkboxes ui-helper-reset hierarchical-list" id="{@name}-list" style="height: 195px;" title="{$title}"/>
					</div>
					<br/>
				</xsl:when>
				<xsl:when test="@name='century_num'">
					<button class="ui-multiselect ui-widget ui-state-default ui-corner-all" type="button" title="Date" aria-haspopup="true" style="width: 200px;" id="{@name}_link" label="{$q}">
						<span class="ui-icon ui-icon-triangle-2-n-s"/>
						<span>Date</span>
					</button>
					<div class="ui-multiselect-menu ui-widget ui-widget-content ui-corner-all date-div" style="width: 200px;">
						<div class="ui-widget-header ui-corner-all ui-multiselect-header ui-helper-clearfix ui-multiselect-hasfilter">
							<ul class="ui-helper-reset">
								<li class="ui-multiselect-close">
									<a class="ui-multiselect-close century-close" href="#"> close<span class="ui-icon ui-icon-circle-close"/>
									</a>
								</li>
							</ul>
						</div>
						<ul class="century-multiselect-checkboxes ui-helper-reset" id="{@name}-list" style="height: 195px;"/>
					</div>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="select_new_query">
						<xsl:choose>
							<xsl:when test="string($new_query)">
								<xsl:value-of select="$new_query"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>*:*</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<select id="{@name}-select" multiple="multiple" class="multiselect" size="10" title="{$title}" q="{$q}" new_query="{if (contains($q, @name)) then $select_new_query else ''}">
						<xsl:if test="$pipeline='maps'">
							<xsl:attribute name="style">width:200px</xsl:attribute>
						</xsl:if>
					</select>
				</xsl:otherwise>
			</xsl:choose>
		</li>
	</xsl:template>
</xsl:stylesheet>
