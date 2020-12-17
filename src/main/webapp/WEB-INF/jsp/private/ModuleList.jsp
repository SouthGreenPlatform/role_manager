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
		var moduleData, editableFields;
		
		<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
		function createModule(moduleName, host)
		{
			let itemRow = $("#row_" + moduleName);
			$.getJSON('<c:url value="<%= BackOfficeController.moduleCreationURL %>" />', { module:moduleName,host:host }, function(created){
				if (!created)
					alert("Unable to create " + moduleName);
				else
				{
					$("#newModuleName").val("");
					$("#newModuleName").keyup();
					moduleData[moduleData.length] = {	id:moduleName,
														'<%= BackOfficeController.DTO_FIELDNAME_HOST %>' : $("select#hosts").val(),
														'<%= BackOfficeController.DTO_FIELDNAME_PUBLIC %>' : false,
														'<%= BackOfficeController.DTO_FIELDNAME_HIDDEN %>' : false
					}
					$('#moduleTable tbody').prepend(buildRow(moduleData.length - 1));
				}
			}).error(function(xhr) { handleError(xhr); });
		}
		
		function handleError(xhr) {
			if (!xhr.getAllResponseHeaders())
				return;	// user is probably leaving the current page
			
		    if (xhr.status == 403) {
		        alert("You do not have access to this resource");
		        return;
		    }

		  	var errorMsg;
		  	if (xhr != null && xhr.responseText != null) {
		  		try {
		  			errorMsg = $.parseJSON(xhr.responseText)['errorMsg'];
		  		}
		  		catch (err) {
		  			errorMsg = xhr.responseText;
		  		}
		  	}
		  	alert(errorMsg);
		}
		
		function removeItem(rowId)
		{
			let itemRow = $("#row_" + rowId);
			let moduleName = itemRow.find("td:eq(0)").text();
			if (confirm("Do you really want to discard database " + moduleName + "?\nThis will delete all data it contains.")) {
				itemRow.find("td:eq(6)").prepend("<div style='position:absolute; margin-left:60px; margin-top:5px;'><img src='img/progress.gif'></div>");
				$.getJSON('<c:url value="<%= BackOfficeController.moduleRemovalURL %>" />', { module:moduleName }, function(deleted){
					if (!deleted) {
						alert("Unable to discard " + moduleName);
						itemRow.find("td:eq(6) div").remove();
					}
					else
					{
						delete moduleData[moduleName];
						itemRow.remove();
					}
				}).error(function(xhr) { itemRow.find("td:eq(6) div").remove(); handleError(xhr); });
			}
		}

		function saveChanges(rowId)
		{
			let itemRow = $("#row_" + rowId);
			let moduleName = itemRow.find("td:eq(0)").text();
			let setToPublic = itemRow.find(".publicCol").prop("checked");
			let setToHidden = itemRow.find(".hiddenCol").prop("checked");
			let bodyJson = { module:moduleName,public:setToPublic,hidden:setToHidden };
			for (var customFieldKey in editableFields)
				bodyJson[customFieldKey] = itemRow.find("." + customFieldKey).val();
			$.getJSON('<c:url value="<%= BackOfficeController.moduleFieldModificationURL %>" />', bodyJson, function(updated){
				if (!updated)
					alert("Unable to apply changes for " + moduleName);
				else
				{
					moduleData[rowId]['<%= BackOfficeController.DTO_FIELDNAME_PUBLIC %>'] = setToPublic;
					moduleData[rowId]['<%= BackOfficeController.DTO_FIELDNAME_HIDDEN %>'] = setToHidden;
					setDirty(rowId, false);
				}
			}).error(function(xhr) { handleError(xhr); });
		}
		
		function resetFlags(rowId)
		{
			let itemRow = $("#row_" + rowId);
			itemRow.find(".publicCol").prop("checked", moduleData[rowId]['<%= BackOfficeController.DTO_FIELDNAME_PUBLIC %>']);
			itemRow.find(".hiddenCol").prop("checked", moduleData[rowId]['<%= BackOfficeController.DTO_FIELDNAME_HIDDEN %>']);
			for (var customFieldKey in editableFields)
				itemRow.find("." + customFieldKey).val(moduleData[rowId][customFieldKey]);
			setDirty(rowId, false);
		}
		
		function setDirty(rowId, flag)
		{
			let itemRow = $("#row_" + rowId);
			if (flag)
				itemRow.addClass("dirtyField");
			else
				itemRow.removeClass("dirtyField");
			itemRow.find(".resetButton").prop("disabled", !flag);
			itemRow.find(".applyButton").prop("disabled", !flag);
		}
		</c:if>

		
		function buildRow(key)
		{
		   	let rowContents = "<td>" + moduleData[key]["id"] + "</td>";
		   	
		   	<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
	   		if (moduleData[key] != null) {
	   			rowContents += "<td>" + moduleData[key]['<%= BackOfficeController.DTO_FIELDNAME_HOST %>'] + "</td>";
				rowContents += "<td><input onclick='setDirty(\"" + encodeURIComponent(key) + "\", true);' class='publicCol' type='checkbox'" + (moduleData[key]['<%= BackOfficeController.DTO_FIELDNAME_PUBLIC %>'] ? " checked" : "") + "></td>";
				rowContents += "<td><input onclick='setDirty(\"" + encodeURIComponent(key) + "\", true);' class='hiddenCol' type='checkbox'" + (moduleData[key]['<%= BackOfficeController.DTO_FIELDNAME_HIDDEN %>'] ? " checked" : "") + "></td>";
			}
			</c:if>

			rowContents += "<td>";
			<c:forEach var="level1Type" items="${rolesByLevel1Type}">
			rowContents += "<div><a id='${urlEncoder.urlEncode(moduleName)}_${level1Type.key}PermissionLink' style='text-transform:none;' href=\"javascript:openModuleContentDialog('${loggedUser.username}', '" + moduleData[key]["id"] + "', '${level1Type.key}');\">${level1Type.key} entities</a></div>";
			</c:forEach>
			rowContents += "</td>";
			<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
			for (var customFieldKey in editableFields) {
				let fNumeric = ['Integer', 'Float', 'Double', 'Byte', 'Long'].indexOf(editableFields[customFieldKey]) != -1;
				rowContents += "<td><input style='width:" + (fNumeric ? 70 : 160) + "px;' type='" + (fNumeric ? 'number' : 'text') + "' onkeyup='if ($(this).val() != \"" + moduleData[key][customFieldKey] + "\" && !$(this).parent().parent().hasClass(\"dirtyField\")) setDirty(\"" + encodeURIComponent(key) + "\", true);' class='customField " + customFieldKey + "' value=\"" + (moduleData[key][customFieldKey] == null ? "" : moduleData[key][customFieldKey]) + "\"></td>";
			}
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
			$.getJSON('<c:url value="<%= BackOfficeController.moduleFieldsURL %>" />', {}, function(fields){
				editableFields = fields;
				var customFields = "";
				for (var key in editableFields)
					customFields += "<th>" + key + "</th>";
				$("th#changesColumn").before(customFields);
			}).error(function(xhr) { handleError(xhr); });

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
		<th style="text-transform:capitalize;"><%= BackOfficeController.DTO_FIELDNAME_HOST %></th>
		<th style="text-transform:capitalize;"><%= BackOfficeController.DTO_FIELDNAME_PUBLIC %></th>
		<th style="text-transform:capitalize;"><%= BackOfficeController.DTO_FIELDNAME_HIDDEN %></th>
		</c:if>
		<th>Entity management</th>
		<c:if test="${fn:contains(loggedUser.authorities, adminRole)}">
		<th id="changesColumn">Changes</th>
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