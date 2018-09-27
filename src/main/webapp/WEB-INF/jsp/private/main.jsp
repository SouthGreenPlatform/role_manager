<%--
 * Role Manager - Generic web tool for managing user roles using Spring Security
 * Copyright (C) 2018, <CIRAD>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License, version 3 as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * See <http://www.gnu.org/licenses/agpl.html> for details about GNU General
 * Public License V3.
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="fr.cirad.web.controller.BackOfficeController" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="topFrameUrl" value="<%= BackOfficeController.topFrameURL %>" />

<jsp:include page="${topFrameUrl}?module=${param.module}" flush="true" />

	<iframe src='<c:url value="AdminFrameSet.html" />' name="bodyFrame" id="bodyFrame" style='width:100%; border:1px black solid; background-color:#fff;'></iframe>
	<script type="text/javascript">
	function setBodyFrameToFullHeight() {
		$('#bodyFrame').css('height', (document.documentElement.clientHeight - 27)+'px');
	}

    $(document).ready(function() {
    	setBodyFrameToFullHeight();
    });
    $(window).resize(function() {
    	setBodyFrameToFullHeight();
    });
	</script>

	</body>
</html>