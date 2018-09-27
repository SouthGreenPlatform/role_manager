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
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="fr.cirad.web.controller.BackOfficeController,fr.cirad.security.base.IRoleDefinition,org.springframework.security.core.context.SecurityContextHolder" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="loggedUser" value="<%= SecurityContextHolder.getContext().getAuthentication().getPrincipal() %>" />
<c:set var='adminRole' value='<%= IRoleDefinition.ROLE_ADMIN %>' />

<html>

<head>
	<link type="text/css" rel="stylesheet" href="css/bootstrap-select.min.css "> 
	<link type="text/css" rel="stylesheet" href="css/bootstrap.min.css">
	<link media="screen" type="text/css" href="css/role_manager.css" rel="StyleSheet" />
	<link media="screen" type="text/css" href="../css/main.css" rel="StyleSheet" />
	<script type="text/javascript" src="js/jquery-1.12.4.min.js"></script>
	<script type="text/javascript" src="js/bootstrap.min.js"></script>
	<script type="text/javascript">
		var moduleData;
		
		<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
		function createModule(moduleName, host)
		{
			let itemRow = $("#row_" + moduleName);
			$.getJSON('<c:url value="<%= BackOfficeController.moduleCreationURL %>" />', { module:moduleName,host:host }, function(created){
				if (!created)
					alert("Unable create " + moduleName);
				else
				{
					$("#newModuleName").val("");
					moduleData[moduleName] = [false, false];
					$('#moduleTable tbody').prepend(buildRow(moduleName));
				}
			});
		}
		
		function removeItem(moduleName)
		{
			let itemRow = $("#row_" + moduleName);
			if (confirm("Do you really want to discard database " + moduleName + "?\nThis will delete all data it contains."))
				$.getJSON('<c:url value="<%= BackOfficeController.moduleRemovalURL %>" />', { module:moduleName }, function(deleted){
					if (!deleted)
						alert("Unable to discard " + moduleName);
					else
					{
						delete moduleData[moduleName];
						itemRow.remove();
					}
				});
		}

		function saveChanges(moduleName)
		{
			let itemRow = $("#row_" + moduleName);
			let setToPublic = itemRow.find(".flagCol0").prop("checked");
			let setToHidden = itemRow.find(".flagCol1").prop("checked");
			$.getJSON('<c:url value="<%= BackOfficeController.moduleVisibilityURL %>" />', { module:moduleName,public:setToPublic,hidden:setToHidden }, function(updated){
				if (!updated)
					alert("Unable to apply changes for " + moduleName);
				else
				{
					moduleData[moduleName][0] = setToPublic;
					moduleData[moduleName][1] = setToHidden;
					setDirty(moduleName, false);
				}
			});
		}
		
		function resetFlags(moduleName)
		{
			let itemRow = $("#row_" + moduleName);
			itemRow.find(".flagCol0").prop("checked", moduleData[moduleName][0]);
			itemRow.find(".flagCol1").prop("checked", moduleData[moduleName][1]);
			setDirty(moduleName, false);
		}
		
		function setDirty(moduleName, flag)
		{
			let itemRow = $("#row_" + moduleName);
			itemRow.css("background-color", flag ? "#ffff80" : "");
			itemRow.find(".resetButton").prop("disabled", !flag);
			itemRow.find(".applyButton").prop("disabled", !flag);
		}
		</c:if>

		
		function buildRow(key)
		{
		   	let rowContents = "<td>" + key + "</td>";
		   	
		   	<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
	   		if (moduleData[key] != null)
			   	for (var subkey in moduleData[key])
					rowContents += "<td><input onclick='setDirty(\"" + encodeURIComponent(key) + "\", true);' class='flagCol" + subkey + "' type='checkbox'" + (moduleData[key][subkey] ? " checked" : "") + "></td>";
			</c:if>

			rowContents += "<td>";
			<c:forEach var="level1Type" items="${rolesByLevel1Type}">
			rowContents += "<a id='${urlEncoder.urlEncode(moduleName)}_${level1Type.key}PermissionLink' style='text-transform:none;' href=\"javascript:openModuleContentDialog('${loggedUser.username}', '" + key + "', '${level1Type.key}');\">${level1Type.key} entities</a>"
			</c:forEach>
			rowContents += "</td>";
			
			<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
	   		rowContents += "<td><input type='button' value='Reset' class='resetButton btn btn-default btn-sm' disabled onclick='resetFlags(\"" + encodeURIComponent(key) + "\");'><input type='button' class='applyButton btn btn-default btn-sm' value='Apply' disabled onclick='saveChanges(\"" + encodeURIComponent(key) + "\");'></td>";
	   		rowContents += "<td align='center'><a style='padding-left:10px; padding-right:10px;' href='javascript:removeItem(\"" + encodeURIComponent(key) + "\");' title='Discard module'><img src='img/delete.gif'></a></td>";
	   		</c:if>
	   		return '<tr id="row_' + encodeURIComponent(key) + '">' + rowContents + '</tr>';
		}

		function loadData()
		{
			let tableBody = $('#moduleTable tbody');
			$.getJSON('<c:url value="<%=BackOfficeController.moduleListDataURL%>" />', {}, function(jsonResult){
				moduleData = jsonResult;
				nAddedRows = 0;
				for (var key in moduleData)
			   		tableBody.append(buildRow(key));
			});
			
			$.getJSON('<c:url value="<%=BackOfficeController.hostListURL%>" />', {}, function(jsonResult){
				$("#hosts").html("");
				for (var key in jsonResult)
					$("#hosts").append("<option value='" + jsonResult [key]+ "'>" + jsonResult [key]+ "</option>");
			});
		}
		
    	function isValidKeyForNewName(evt)
    	{
             return isValidCharForNewName((evt.which) ? evt.which : evt.keyCode);
    	}

        function isValidCharForNewName(charCode) {
            return ((charCode >= 48 && charCode <= 57) || (charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122) || charCode == 8 || charCode == 9 || charCode == 35 || charCode == 36 || charCode == 37 || charCode == 39 || charCode == 45 || charCode == 46 || charCode == 95);
        }

        function isValidNewName(newName) {
        	if (newName.trim().length == 0)
        		return false;
            for (var i = 0; i < newName.length; i++)
                if (!isValidCharForNewName(newName.charCodeAt(i))) {
                    return false;
                }
            return true;
        }
        
		function openModuleContentDialog(username, module, entityType)
		{
	    	$('#moduleContentFrame').contents().find("body").html("");
	        $("#moduleContentDialog #moduleContentDialogTitle").html(entityType + " entities for user <u>" + username + "</u> in database <u id='moduleName'>" + module);
	        $("#moduleContentDialog").modal('show');
	        $("#moduleContentFrame").attr('src', '<c:url value="<%= BackOfficeController.moduleContentPageURL %>" />?user=' + username + '&module=' + module + '&entityType=' + entityType);
		}
		
		function resizeIFrame() {
			$('#moduleContentFrame').css('height', (document.body.clientHeight - 200)+'px');
		}

	    $(document).ready(function() {
	    	resizeIFrame();
	    	loadData();
	    });
	    $(window).resize(function() {
	    	resizeIFrame();
	    });
	</script>
</head>

<body style='background-color:#f0f0f0;'>
	<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
		<div style="max-width:600px; padding:10px; margin-bottom:10px; border:2px dashed grey; background-color:lightgrey;">
			<b>Create new empty database</b><br/>
			On host <select id="hosts"></select> named <input type="text" id="newModuleName" onkeypress="if (!isValidKeyForNewName(event)) { event.preventDefault(); event.stopPropagation(); }" onkeyup="$(this).next().prop('disabled', !isValidNewName($(this).val()));">
			<input type="button" value="Create" class="btn btn-xs btn-primary" onclick="createModule($(this).prev().val(), $('#hosts').val());" disabled>
		</div>
	</c:if>
	<table class="adminListTable" id="moduleTable">
	<thead>
	<tr>
		<th>Database name</th>
		<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
		<th>Public</th>
		<th>Hidden</th>
		</c:if>
		<th>Entity management</th>
		<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
		<th>Changes</th>
		<th>Removal</th>
		</c:if>
	</tr>
	</thead>
	<tbody>
	</tbody>
	</table>

	<div class="modal fade" tabindex="-1" role="dialog" id="moduleContentDialog" aria-hidden="true">
		<div class="modal-dialog modal-lg">
			<div class="modal-content">
				<div class="modal-header" id="projectInfoContainer">
					<div id="moduleContentDialogTitle" style='font-weight:bold; margin-bottom:5px;'></div>
					<iframe style='margin-bottom:10px; width:100%;' id="moduleContentFrame" name="moduleContentFrame"></iframe>
					<br>
					<form>
						<input type='button' class='btn btn-sm btn-primary' value='Close' id="hlContentDialogClose" onclick="$('#moduleContentDialog').modal('hide');">
					</form>
				</div>
			</div>
		</div>
	</div>
</body>

</html>