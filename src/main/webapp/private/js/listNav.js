/*******************************************************************************
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
 *******************************************************************************/
splittedPathName = window.location.pathname.split("/");
variableNameSuffix = splittedPathName[splittedPathName.length - 1].replace(".do", "");
module = getURLParameter("module");

function setVariable(varName, value, suffix)
{	
//	eval("window.parent." + varName + "_" + (suffix == null ? variableNameSuffix : suffix) + " = value;");
//	console.log(varName + "_" + (suffix == null ? variableNameSuffix : suffix) + "\n" + value);
	$.cookie(module + "_" + varName + "_" + (suffix == null ? variableNameSuffix : suffix), value);
}

function getVariable(varName, suffix)
{
	var value = $.cookie(module + "_" + varName + "_" + (suffix == null ? variableNameSuffix : suffix));
	return value == null ? "" : value;	// hack for IE bug
}

function incrementVariable(varName, fBackwards)
{
//	eval("window.parent." + varName + "_" + variableNameSuffix + " += " + (fBackwards ? "-1" : "1") + ";");
//	console.log(varName + "_" + variableNameSuffix + "\n" + getVariable(varName) + getVariable(varName) + "\n" + (fBackwards ? "-1" : "1"));
	setVariable(varName, parseInt(getVariable(varName)) + (fBackwards ? -1 : 1));
}

function applySorting(sortByCol)
{
	if (sortByCol == null)
		sortByCol = getVariable("sortBy");	//eval("window.parent.sortBy_" + variableNameSuffix);
	else
	{
		if (getVariable("sortBy") == sortByCol)
				setVariable("sortDir", getVariable("sortDir") == 'asc' ? 'desc' : 'asc');
		setVariable("sortBy", sortByCol);
	}
	loadData();
		
	$(".sortableTableHeader").each(function() {
		if (this.abbr == sortByCol)
		{
			$(this).addClass("selectedSortableTableHeaderActive_" + getVariable("sortDir"));
			$(this).removeClass("selectedSortableTableHeaderActive_" + (getVariable("sortDir") == 'asc' ? 'desc' : 'asc'));
		}
		else
		{
			$(this).removeClass("selectedSortableTableHeaderActive_desc");
			$(this).removeClass("selectedSortableTableHeaderActive_asc");
		}
	});
}
	
function loadData()
{
	if (typeof loadCurrentPage == 'undefined')
		alert("No loadCurrentPage() function found!");
	else
	{
		$(".navListFilter").each(function() {
			setVariable(this.id, $(this).val());
//			eval("window.parent." + this.id + "_" + variableNameSuffix + " = '" + $(this).val() + "';");
		});
		loadCurrentPage();
	}
}

function add_new_row(table, rowcontent)
{
    if ($(table).length>0){
        if ($(table+' > tbody').length==0) $(table).append('<tbody />');
        	($(table+' > tr').length>0)?$(table).children('tbody:last').children('tr:last').append(rowcontent):$(table).children('tbody:last').append(rowcontent);
    }
}

function getURLParameter(sParam)
{
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split('&');
    for (var i = 0; i < sURLVariables.length; i++) 
    {
        var sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] == sParam) 
        {
            return sParameterName[1];
        }
    }
}

// load filter values as they were when current page was left
$(document).ready(function () {
	$(".navListFilter").each(function() {
		$(this).val(getVariable(this.id));
//		$(this).val(eval("window.parent." + this.id + "_" + variableNameSuffix));
	});
});